function [success,info] = MasterTempRecord(varargin)

global MasterTempRecordInfo;

% where we will save temperature data
TempRecordDir = '.TempRecordData';
IsMasterFileStr = 'IsMaster.mat';
ChannelFileStr = 'Channel';

% parse parameters

% Total number of channels
NChannelsTotal = 8;
% Time in between temperature readings (seconds)
Period = 1;
% Which channels have temperature probes
Channels = 1:8;
% Thermocouple types
ChannelTypes = {'K'};
% if 1, temperature probe will reject 60 Hz, otherwise will reject 50 Hz
Reject60Hz = 0;

[NChannelsTotal,Period,Channels,ChannelTypes,Reject60Hz,...
  TempRecordDir,IsMasterFileStr,ChannelFileStr] = myparse(varargin,...
  'NChannelsTotal',NChannelsTotal,'Period',Period,...
  'Channels',Channels,'ChannelTypes',ChannelTypes,'Reject60Hz',Reject60Hz,...
  'TempRecordDir',TempRecordDir,'IsMasterFileStr',IsMasterFileStr,...
  'ChannelFileStr',ChannelFileStr);

success = false;
info = struct;

IsMasterFile = fullfile(TempRecordDir,IsMasterFileStr);
ChannelFileNames = cell(1,numel(Channels));
for i = 1:numel(Channels),
  ChannelFileNames{i} = fullfile(TempRecordDir,sprintf('%s_%02d',ChannelFileStr,Channels(i)));
end

if ~libisloaded('usbtc08'),
  loadlibrary('usbtc08.dll', @usbtc08Header, 'alias', 'usbtc08')
end

% create directory if necessary
if isempty(dir(TempRecordDir)),
  mkdir(TempRecordDir);
end

% try to open a handle
tc08_handle=calllib('usbtc08','usb_tc08_open_unit');

% if error, give up
if tc08_handle < 0,
  errordlg(get_last_error(0),'Error opening USBTC08');
  return;
end

if tc08_handle == 0,
  
  % if no devices remain, should we try to grab control?

  % check to see if there is already a master
  if exist(IsMasterFile,'file'),
    answer = questdlg('Semaphore IsMaster is set. Another process may be controlling temperature. Try to grab control anyways?','Grab Temperature Control?','Yes','Cancel','Cancel');
    if strcmp(answer,'Cancel'),
      return;
    end
  
    % read in the handle if there already is a master
    try
      old_tc08_handle = load(IsMasterFile,'tc08_handle');
    catch
      old_tc08_handle = 1;
    end
  else
    
    % if no master file exists, let's just try closing 1
    old_tc08_handle = 1;
    
  end

  % close the old handle if possible
  try
    ok = calllib('usbtc08','usb_tc08_close_unit',old_tc08_handle);
  catch
    ok = 0;
  end
  if ok == 0,
    errordlg('Could not connect to TC08 temperature probe. Open failed and closing did not help. ','Error connecting to TC08 temperature probe');
    return;
  end
  tc08_handle=calllib('usbtc08','usb_tc08_open_unit');
  if tc08_handle < 0,
    errordlg(get_last_error(0),'Error opening USBTC08');
    return;
  elseif tc08_handle == 0,
    errordlg('Could not connect to TC08 temperature probe. Open failed and closing did not help. ','Error connecting to TC08 temperature probe');
  end
    
end

% set the semaphore that there is a master
StartRunTimeStamp = now;
save(IsMasterFile,'tc08_handle','TempRecordDir','ChannelFileNames','Channels',...
  'IsMasterFile','StartRunTimeStamp','Period','ChannelTypes');
% fid = fopen(IsMasterFile,'w');
% fprintf(fid,'%d ',tc08_handle);
% fclose(fid);

% set the USB TC-08 to reject either 50 or 60 Hz
ok = calllib('usbtc08','usb_tc08_set_mains',tc08_handle,int16(Reject60Hz));
if ok == 0,
  errordlg(get_last_error(tc08_handle),'Error calling usb_tc08_set_mains');
  try
    calllib('usbtc08','usb_tc08_close_unit',tc08_handle);
    delete(IsMasterFile);
  catch
  end
  return;
end

% Specify what type of thermocouple is connected to each
% channel. Set to one of the following characters: 'B', 'E', 'J',
% 'K', 'N', 'R', 'S', 'T.' Use a space in quotes to disable the
% channel. Voltage readings can be obtained by passing 'X' as
% the character.
ChannelIsSet = false(1,NChannelsTotal);
for i = 1:NChannelsTotal,
  j = find(i == Channels,1);
  if ~isempty(j),
    j = min(j,length(ChannelTypes));
    ChannelIsSet(i)=calllib('usbtc08','usb_tc08_set_channel', tc08_handle,int16(i),int8(ChannelTypes{j}(1)));
    if ChannelIsSet(i) == 0,
      hwarn = warndlg(sprintf('Error calling usb_tc08_set_channel(%d): %s\n',i,get_last_error(tc08_handle)),'MasterTempRecord Error');
    end
  else
    ChannelIsSet(i)=calllib('usbtc08','usb_tc08_set_channel', tc08_handle,int16(i),int8(' '));
  end
end

MasterTempRecord_timer=timer('ExecutionMode','FixedRate','Period',Period,...
  'TimerFcn',{@MasterTempRecord_GrabTemp,tc08_handle,Channels,ChannelFileNames,StartRunTimeStamp},...
  'StartDelay',1,...
  'Name','MasterTempRecord_USBTC08_Timer',...
  'StopFcn',{@MasterTempRecord_Stop,tc08_handle,IsMasterFile,ChannelFileNames});

calllib('usbtc08','usb_tc08_run',tc08_handle,Period*1000);

start(MasterTempRecord_timer);

success = true;
info.tc08_handle = tc08_handle;
info.TempRecordDir = TempRecordDir;
info.IsMasterFile = IsMasterFile;
info.ChannelFileNames = ChannelFileNames;
info.Channels = Channels;
info.MasterTempRecord_timer = MasterTempRecord_timer;
info.StartRunTimeStamp = StartRunTimeStamp;
info.Period = Period;
info.ChannelTypes = ChannelTypes;
info.GUI = MasterTempRecordGUI(info);

MasterTempRecordInfo = info;

if exist('hwarn','var') && ishandle(hwarn),
  delete(hwarn);
end

function s = get_last_error(tc08_handle)

last_error=calllib('usbtc08','usb_tc08_get_last_error',tc08_handle);
[errname,errstr] = USBTC08_error_table(last_error);
s = sprintf('Error %s: %s',errname,errstr);

