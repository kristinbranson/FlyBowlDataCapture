function handles = CloseLEDControllerConnection(handles)

if ~isfield(handles,'ChRStuff') || ...
    ~isfield(handles.ChRStuff,'hLEDController') || ...
    isempty(handles.ChRStuff.hLEDController),
  return;
end

global FBDC_CHR_LED_CONTROLLER_FID;
try
  
  flyBowl_LED_control(handles.ChRStuff.hLEDController, 'STOP',[],false);
  flyBowl_LED_control(handles.ChRStuff.hLEDController, 'OFF',[],false);
  fclose(handles.ChRStuff.hLEDController);
  FBDC_CHR_LED_CONTROLLER_FID = setdiff(FBDC_CHR_LED_CONTROLLER_FID,handles.ChRStuff.hLEDController);
  handles.ChRStuff.hLEDController = [];
  addToStatus(handles,'Closed LED controller connection.');
catch ME,
  s = sprintf('Error closing LED controller connection: %s',getReport(ME));
  warndlg(s);
  warning(s); %#ok<SPWRN>
end