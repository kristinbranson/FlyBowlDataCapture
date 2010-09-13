function [DeviceIDsUsed,handles] = getIsCameraRunningDevices(handles)

handles.IsCameraRunningFiles = dir(fullfile(handles.DetectCameras_Params.DataDir,'*.mat'));
DeviceIDsUsed = nan(1,length(handles.IsCameraRunningFiles));
for i = 1:length(handles.IsCameraRunningFiles),
  matches = regexp(handles.IsCameraRunningFiles(i).name,'^.*_(?<id>[0-9]+)\.mat$','names');
  if isempty(matches), continue; end
  DeviceIDsUsed(i) = str2double(matches(end).id);
end
badidx = isnan(DeviceIDsUsed);
handles.IsCameraRunningFiles(badidx) = [];
DeviceIDsUsed(badidx) = [];