function handles = unsetCamera(handles)

handles.IsCameraInitialized = false;
if isfield(handles,'IsCameraRunningFile') && ...
    exist(handles.IsCameraRunningFile,'file'),
  delete(handles.IsCameraRunningFile);
  global FBDC_IsCameraRunningFiles; 
  FBDC_IsCameraRunningFiles = setdiff(FBDC_IsCameraRunningFiles,{handles.IsCameraRunningFile});
end
if isfield(handles,'CheckPreviewTimer') && ~isempty(handles.CheckPreviewTimer),
  try
    if strcmp(get(handles.CheckPreviewTimer,'Running'),'on'),
      stop(handles.CheckPreviewTimer);
    end
    delete(handles.CheckPreviewTimer);
    handles.CheckPreviewTimer = [];
  catch ME
    addToStatus(handles,{'Error stopping/deleting CheckPreviewTimer:',getReport(ME,'basic','hyperlinks','off')});
  end
end