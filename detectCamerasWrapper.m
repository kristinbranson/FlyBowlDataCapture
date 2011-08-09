function handles = detectCamerasWrapper(handles)

handles = unsetCamera(handles);
handles = detectCameras(handles);

% if no devices found
if ~isfield(handles,'DeviceIDs') || isempty(handles.DeviceIDs),
  handles.DeviceID = [];
  set(handles.popupmenu_DeviceID,'Enable','off','String','No devices found','Value',1,...
    'BackgroundColor',handles.shouldchange_bkgdcolor);
else
  
  % if invalid DeviceID, choose the first DeviceID
  if ~isfield(handles,'DeviceID') || isempty(handles.DeviceID) || ...
      ~ismember(handles.DeviceID,handles.DeviceIDs),
    handles.DeviceID = handles.DeviceIDs(1);
  end
  
  [isInUse,handles,DeviceIDsLeft] = checkDeviceInUse(handles,handles.DeviceID,false);
  if isInUse && ~isempty(DeviceIDsLeft),
    handles.DeviceID = DeviceIDsLeft(1);
  end
  
  % set possible values, current value, color to default
  set(handles.popupmenu_DeviceID,'String',cellstr(num2str(handles.DeviceIDs(:))),...
    'Value',find(handles.DeviceID == handles.DeviceIDs,1),...
    'BackgroundColor',handles.isdefault_bkgdcolor);
  if handles.IsAdvancedMode,
    set(handles.popupmenu_DeviceId,'Enable','on');
  end
  
  % enable initialize camera button
  set(handles.pushbutton_InitializeCamera,'Enable','on');
end
