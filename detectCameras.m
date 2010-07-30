function handles = detectCameras(handles)

handles = clearVideoInput(handles);

% reset image acquisition
imaqreset;

handles.DeviceIDs = {};

% check for adaptor
try
  adaptorinfo = imaqhwinfo(handles.params.Imaq_Adaptor);
catch
  s = sprintf('Adaptor %s not registered, or no %s compatable camera found',handles.params.Imaq_Adaptor,handles.params.Imaq_Adaptor);
  uiwait(errordlg(s,'Error loading imaq adaptor'));
  return;
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