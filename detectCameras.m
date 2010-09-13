function handles = detectCameras(handles)

handles.DetectCameras_Params = ...
  struct('DataDir','.DetectCamerasData',...
  'IsCameraRunningFileStr','IsCameraRunning');

handles.IsCameraRunningFiles = dir(fullfile(handles.DetectCameras_Params.DataDir,'*.mat'));
handles.IsCameraRunning = ~isempty(handles.IsCameraRunningFiles);

handles = clearVideoInput(handles);

% reset image acquisition
imaqreset;

%handles.DeviceIDs = {};

% check for adaptor
if handles.IsCameraRunning,
  try
    filename = fullfile(handles.DetectCameras_Params.DataDir,...
      handles.IsCameraRunningFiles(end).name);
    addToStatus(handles,...
      sprintf('Another camera is in operation, so reading adaptorinfo from %s. If this seems wrong, exit all FlyBowlDataCapture GUIs and run "CleanSemaphores"',filename));

    load(filename,'adaptorinfo');
  catch
    s = sprintf('Could not load adaptor info from %s',filename);
    uiwait(errordlg(s,'Error loading imaq adaptor'));
    return;
  end
else
  try
    %adaptorinfo =
    %imaqhwinfo_kb(handles.DetectCameras_Params,handles.params.Imaq_Adaptor);
    adaptorinfo = imaqhwinfo(handles.params.Imaq_Adaptor);
  catch ME
    getReport(ME)
    s = sprintf('Adaptor %s not registered, or no %s compatable camera found',handles.params.Imaq_Adaptor,handles.params.Imaq_Adaptor);
    uiwait(errordlg(s,'Error loading imaq adaptor'));
    return;
  end
end

% check for device
devnames = {adaptorinfo.DeviceInfo.DeviceName};
devidx = strcmpi(handles.params.Imaq_DeviceName,devnames);
if ~any(devidx),
  s = sprintf('Device %s not found for adaptor %s.',handles.params.Imaq_DeviceName,handles.params.Imaq_Adaptor);
  uiwait(errordlg(s,'Camera not found'));
  return;
end

% check for format
for devi = find(devidx),
  devinfo = adaptorinfo.DeviceInfo(devi);
  if ~any(strcmp(handles.params.Imaq_VideoFormat,devinfo.SupportedFormats)),
    devidx(devi) = false;
  end
end

if ~any(devidx),
  s = sprintf('Format %s not available for camera %s and adaptor %s.',...
    handles.params.Imaq_VideoFormat,handles.params.Imaq_DeviceName,handles.params.Imaq_Adaptor);
  uiwait(errordlg(s,'Camera format not found'));
end  

handles.DeviceIDs = cell2mat(adaptorinfo.DeviceIDs(devidx));

% % make names for each device
% handles.DeviceNames = cell(size(handles.DeviceIDs));
% for i = 1:length(handles.DeviceIDs),
%   handles.DeviceNames{i} = sprintf('Adaptor_%s___Name_%s___Format_%s___DeviceID_%d',...
%     handles.params.Imaq_Adaptor,...
%     handles.params.Imaq_DeviceName,...
%     handles.params.Imaq_VideoFormat,...
%     handles.DeviceIDs(i));
%   handles.DeviceNames{i} = strrep(handles.DeviceNames{i},' ','_');
% end

handles.adaptorinfo = adaptorinfo;