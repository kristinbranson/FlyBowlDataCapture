function handles = clearVideoInput(handles)

if isfield(handles,'vid') && isvalid(handles.vid) && handles.IsCameraInitialized,
  handles = unsetCamera(handles);
  % delete preview image
  if isfield(handles,'hImage_Preview') && ishandle(handles.hImage_Preview),
    delete(handles.hImage_Preview);
  end
  % delete the video input
  delete(handles.vid);
  set(handles.pushbutton_InitializeCamera,'Visible','on');
end
