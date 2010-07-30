function handles = clearVideoInput(handles)

if handles.IsCameraInitialized,
  % stop the preview if it is on
  handles.IsCameraInitialized = false;
  % delete preview image
  delete(handles.hImage_Preview);
  % delete the video input
  delete(handles.vid);
  set(handles.pushbutton_InitializeCamera,'Visible','on');
end
