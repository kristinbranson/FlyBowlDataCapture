function [success,info] = StartRecordingTemperature(id,varargin)

global TempRecordInfo;

success = false;
info = struct;

% parse parameters

% Total number of channels
NChannelsTotal = 8;
% Time in between temperature readings (seconds)
info.Period = 1;
% Which channels have temperature probes
info.Channels = 1:8;
% Thermocouple types
info.ChannelTypes = {'K'};
% if 1, temperature probe will reject 60 Hz, otherwise will reject 50 Hz
Reject60Hz = 0;

[NChannelsTotal,info.Period,info.Channels,info.ChannelTypes,Reject60Hz] = myparse(varargin,...
  'NChannelsTotal',NChannelsTotal,'Period',info.Period,...
  'Channels',info.Channels,'ChannelTypes',info.ChannelTypes,'Reject60Hz',Reject60Hz);

if ~libisloaded('usbtc08'),
  loadlibrary('usbtc08.dll', @usbtc08Header, 'alias', 'usbtc08')
end

% if temperature probe already running, nothing to do
if isstruct(TempRecordInfo) && isfield(TempRecordInfo,'tc08_handle'),
  try
    % TODO: grab temperature for this channel
    
    if ~isfield(TempRecordInfo,'idslistening'),
      TempRecordInfo.idslistening = [];
    end
    TempRecordInfo.idslistening(end+1) = id;
    info = TempRecordInfo;
    
    fprintf('Using handle for USB TC08 created at time %s\n',datestr(info.StartRunTimeStamp,'yyyymmddTHHMMSS'));
    success = true;
    
    return;
    
  catch %#ok<CTCH>
  end
end

% try to open a handle
info.tc08_handles=calllib('usbtc08','usb_tc08_open_unit');

% if error, give up
if info.tc08_handles < 0,
  errordlg(get_last_error(0),'Error opening USBTC08');
  return;
end

if info.tc08_handles == 0,
  
  % let's just try closing 1
  old_info.tc08_handles = 1;
  
  % close the old handle if possible
  try
    ok = calllib('usbtc08','usb_tc08_close_unit',old_info.tc08_handles);
  catch %#ok<CTCH>
    ok = 0;
  end
  if ok == 0,
    errordlg('Could not connect to TC08 temperature probe. Open failed and closing did not help. ','Error connecting to TC08 temperature probe');
    return;
  end
  info.tc08_handles=calllib('usbtc08','usb_tc08_open_unit');
  if info.tc08_handles < 0,
    errordlg(get_last_error(0),'Error opening USBTC08');
    return;
  elseif info.tc08_handles == 0,
    errordlg('Could not connect to TC08 temperature probe. Open failed and closing did not help. ','Error connecting to TC08 temperature probe');
    return;
  end
  
end

% set the semaphore that there is a master
info.StartRunTimeStamp = now;

% set the USB TC-08 to reject either 50 or 60 Hz
ok = calllib('usbtc08','usb_tc08_set_mains',info.tc08_handles,int16(Reject60Hz));
if ok == 0,
  errordlg(get_last_error(info.tc08_handles),'Error calling usb_tc08_set_mains');
  try
    calllib('usbtc08','usb_tc08_close_unit',info.tc08_handles);
  catch %#ok<CTCH>
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
  j = find(i == info.Channels,1);
  if ~isempty(j),
    j = min(j,length(info.ChannelTypes));
    ChannelIsSet(i)=calllib('usbtc08','usb_tc08_set_channel', info.tc08_handles,int16(i),int8(info.ChannelTypes{j}(1)));
    if ChannelIsSet(i) == 0,
      hwarn = warndlg(sprintf('Error calling usb_tc08_set_channel(%d): %s\n',i,get_last_error(info.tc08_handles)),'TempRecord Error');
    end
  else
    ChannelIsSet(i)=calllib('usbtc08','usb_tc08_set_channel', info.tc08_handles,int16(i),int8(' '));
  end
end

% just print to stdout
fprintf('USB TC08 started at %s\n',datestr(info.StartRunTimeStamp,'yyyymmddTHHMMSS'));

calllib('usbtc08','usb_tc08_run',info.tc08_handles,info.Period*1000);

info.idslistening = id;

TempRecordInfo = info;

if exist('hwarn','var') && ishandle(hwarn),
  delete(hwarn);
end

success = true;

function s = get_last_error(tc08_handles)

last_error=calllib('usbtc08','usb_tc08_get_last_error',tc08_handles);
[errname,errstr] = USBTC08_error_table(last_error);
s = sprintf('Error %s: %s',errname,errstr);

