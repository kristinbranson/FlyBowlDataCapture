function [handles,success] = GetMasterTempRecorderInfo(handles)

[ismaster,handles.TempProbe_MasterInfo,errstring] = IsMasterTempRecorder(handles.TempProbe_Params{:});
if ~isempty(errstring),
  addToStatus(handles,{'Error checking for master temperature recorder:',errstring});
end

% if no master yet, this Matlab instance will be the master temperature
% recorder
if ~ismaster,
  tmp = timerfind('name','MasterTempRecord_USBTC08_Timer');
  for i = 1:numel(tmp),
    stop(tmp);
    delete(tmp);
  end
  [success,handles.TempProbe_MasterInfo] = ...
    MasterTempRecord(handles.TempProbe_Params{:});
else
  success = true;
end