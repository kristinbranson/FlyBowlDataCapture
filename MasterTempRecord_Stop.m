function MasterTempRecord_Stop(obj,event,tc08_handle,IsMasterFile,ChannelFileNames) %#ok<INUSL>

global MasterTempRecordInfo;

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
    fprintf('Error removing semaphore file %s\n',IsMasterFile);
    disp(ME);
  end
  % close the probe
  ok = calllib('usbtc08','usb_tc08_close_unit',tc08_handle);
  if ok == 0,
    last_error=calllib('usbtc08','usb_tc08_get_last_error',tc08_handle);
    [errname,errstr] = USBTC08_error_table(last_error);
    fprintf('Stop(%s): Error %s: %s\n',datestr(now,13),errname,errstr);
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
      fprintf('Error removing temperature channel file %s\n',ChannelFileNames{i});
      disp(ME);
    end
  end
end
 
% delete the GUI
if ~isempty(GUIhandle) && ishandle(GUIhandle),
  delete(GUIhandle);
end

