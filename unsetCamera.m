function handles = unsetCamera(handles)

handles.IsCameraInitialized = false;
if isfield(handles,'IsCameraRunningFile') && ...
    exist(handles.IsCameraRunningFile,'file'),
  delete(handles.IsCameraRunningFile);
  global FBDC_IsCameraRunningFiles; 
  FBDC_IsCameraRunningFiles = setdiff(FBDC_IsCameraRunningFiles,{handles.IsCameraRunningFile});
end
if isfield(handles,'CheckPreviewTimer'),
  try
    stop(handles.CheckPreviewTimer);
    delete(handles.CheckPreviewTimer);
  catch ME
    addToStatus(handles,{'Error stopping/deleting CheckPreviewTimer:',getReport(ME,'basic','hyperlinks','off')});
  end
end