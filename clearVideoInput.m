function handles = clearVideoInput(handles)

if isfield(handles,'vid') && ...
    (strcmpi(handles.params.Imaq_Adaptor,'bias') || isvalid(handles.vid)) && ...
    handles.IsCameraInitialized,
  handles = unsetCamera(handles);
  % delete preview image
  if isfield(handles,'hImage_Preview') && ishandle(handles.hImage_Preview),
    delete(handles.hImage_Preview);
  end
  % delete the video input
  if ~strcmpi(handles.params.Imaq_Adaptor,'bias'),
    delete(handles.vid);
    if isfield(handles,'IsCameraRunningFile') && exist(handles.IsCameraRunningFile','file'),
      delete(handles.IsCameraRunningFile);
    end
  end
  set(handles.pushbutton_InitializeCamera,'Visible','on');
end
