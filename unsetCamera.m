function handles = unsetCamera(handles)

handles.IsCameraInitialized = false;
if isfield(handles,'IsCameraRunningFile') && ...
    exist(handles.IsCameraRunningFile,'file'),
  delete(handles.IsCameraRunningFile);
  global FBDC_IsCameraRunningFiles; 
  FBDC_IsCameraRunningFiles = setdiff(FBDC_IsCameraRunningFiles,{handles.IsCameraRunningFile});
end