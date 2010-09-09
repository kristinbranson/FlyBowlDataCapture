function handles = detectCameras(handles)

handles.DetectCameras_Params = ...
  struct('DataDir','.DetectCamerasData',...
  'IsCameraRunningFileStr','IsCameraRunning');

% name of lock file
handles.IsCameraRunningFile = fullfile(handles.DetectCameras_Params.DataDir,...
  sprintf('%s.mat',handles.DetectCameras_Params.IsCameraRunningFileStr));
handles.IsCameraRunning = exist(handles.IsCameraRunningFile,'file');

handles = clearVideoInput(handles);

% reset image acquisition
imaqreset;

%handles.DeviceIDs = {};

% check for adaptor
if handles.IsCameraRunning,
  try
    load(handles.IsCameraRunningFile,'adaptorinfo','DevicesUsed','timestamp');
    addToStatus(handles,...
      sprintf('Another camera is in operation, and devices %s are in use, so reading adaptorinfo from %s, written at time %s. If this seems wrong, exit all FlyBowlDataCapture GUIs and run "CleanSemaphores"',...
      handles.IsCameraRunningFile,timestamp));
    if ~strcmpi(handles.params.Imaq_Adaptor,adaptorinfo.AdaptorName), %#ok<NODEF>
      s = sprintf('Adaptor %s requested, but other camera(s) are running adaptor %s. Cannot detect cameras.',handles.params.Imaq_Adaptor,adaptorinfo.AdaptorName);
      uiwait(errordlg(s,'Error loading imaq adaptor'));
      return;
    end
  catch
    s = sprintf('Could not load adaptor info from %s',filename);
    uiwait(errordlg(s,'Error loading imaq adaptor'));
    return;
  end
else
  try
    adaptorinfo = imaqhwinfo(handles.params.Imaq_Adaptor);
    DevicesUsed = [];
  catch
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

% don't allow devices already in use to be selected
handles.DeviceIDs = setdiff(cell2mat(adaptorinfo.DeviceIDs(devidx)),DevicesUsed);

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