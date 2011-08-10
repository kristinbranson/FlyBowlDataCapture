function MasterTempRecord_Stop(obj,event,tc08_handle,IsMasterFile,ChannelFileNames,LogFileName) %#ok<INUSL>

global MasterTempRecordInfo;

try

GUIhandle = [];
if isstruct(MasterTempRecordInfo) && isfield(MasterTempRecordInfo,'GUI') && ...
    ishandle(MasterTempRecordInfo.GUI),
  GUIhandle = MasterTempRecordInfo.GUI;
end

MasterTempRecordInfo = [];

% delete the semaphore
if exist(IsMasterFile,'file'),
  try
    delete(IsMasterFile);
  catch ME,
    
    s = [sprintf('Error removing semaphore file %s\n',IsMasterFile),getReport(ME)];
    if exist('hwarn','var') && ishandle(hwarn), delete(hwarn); end
    hwarn = warndlg(s,'Error stopping temperature recording');

  end
  % close the probe
  ok = calllib('usbtc08','usb_tc08_close_unit',tc08_handle);
  if ok == 0,
    last_error=calllib('usbtc08','usb_tc08_get_last_error',tc08_handle);
    [errname,errstr] = USBTC08_error_table(last_error);
    s = sprintf('Stop(%s): Error %s: %s\n',datestr(now,13),errname,errstr);
    if exist('hwarn','var') && ishandle(hwarn), delete(hwarn); end
    hwarn = warndlg(s,'Error stopping temperature recording');
  end  
else
  fprintf('Semaphore file %s already deleted\n',IsMasterFile);
end

% delete the channel files
for i = 1:length(ChannelFileNames),
  if exist(ChannelFileNames{i},'file'),
    try
      delete(ChannelFileNames{i});
    catch ME,
      s = [sprintf('Error removing temperature channel file %s\n',ChannelFileNames{i}),getReport(ME)];
      if exist('hwarn','var') && ishandle(hwarn), delete(hwarn); end
      hwarn = warndlg(s,'Error stopping temperature recording');
    end
  end
end
 
% delete the GUI
if ~isempty(GUIhandle) && ishandle(GUIhandle),
  delete(GUIhandle);
end

AddToLogFile(LogFileName,'%s: Stopped MasterTempRecord\n',datestr(now,30));

catch ME,
  
  uiwait(warndlg(getReport(ME),'Error stopping MasterTempRecord'));
  AddToLogFile(LogFileName,'%s: Error stopping MasterTempRecord: %s\n',datestr(now,30),getReport(ME));

end
