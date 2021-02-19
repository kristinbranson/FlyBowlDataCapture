function [success,hComm,errmsg] = InitializeLEDPanel(params)

success = false;
hComm = struct;
errmsg = '';

global FBDC_CHR_LED_CONTROLLER_FID;

%initialize LED controller
try
  % KB 20210124 - new LED controller code
  hComm.hLEDController = LEDController(params.ChR_serial_port_for_LED_Controller);
  assert(hComm.hLEDController.serialPort ~= 0);
  % There's a try catch in this code so errors won't be caught, look for an
  % error with the serial port value. 
  
%   hComm.hLEDController = serial(params.ChR_serial_port_for_LED_Controller,...
%     'BaudRate', 115200, 'Terminator', 'CR');
%   fopen(hComm.hLEDController);

catch ME,
  msg = getReport(ME,'basic');
  errmsg = sprintf('Error initializing LED controller: %s',msg);
  try %#ok<TRYNC>
    hComm.hLEDController.close();
  end
  return;
end
% hComm.hLEDController.docheckstatus = true;
% hComm.hLEDController.dispstatus = true;

if isempty(FBDC_CHR_LED_CONTROLLER_FID)
  FBDC_CHR_LED_CONTROLLER_FID = {};
  %FBDC_CHR_LED_CONTROLLER_FID = hComm.hLEDController;
end
FBDC_CHR_LED_CONTROLLER_FID{end+1} = hComm.hLEDController;
  
% reset LED controller
% KB 20210124 - new version of LED controller code
hComm.hLEDController.resetController();
%flyBowl_LED_control(hComm.hLEDController,'RESET',[],false);

% set IR LED intensity
% KB 20210124 - new version of LED controller code
hComm.hLEDController.setIRLEDPower(params.ChR_IrInt);

success = true;
