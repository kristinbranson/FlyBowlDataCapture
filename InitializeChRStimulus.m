function [success,hComm,errmsg] = InitializeChRStimulus(params)

success = false;
hComm = struct;
errmsg = ''; %#ok<NASGU>

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
  
% TODO move this elsewhere
% %initialize precon sensor
% THSensor = PreconSensor(serial_port_for_precon_sensor);
% [success, errMsg] = THSensor.open();
% if success
%     hComm.THSensor = THSensor;
% else
%     hComm.THSensor = 0;    
%     display(errMsg);
% end

%initialize the daq card if there is one
if isfield(params,'ChR_isDaqCard') && params.ChR_isDaqCard,
  try
    daqC = daq.createSession('ni');
    addAnalogInputChannel(daqC,DanalogInput, 0:1, 'Voltage');
    hComm.daqC = daqC;
  catch ME,
    msg = getReport(ME,'basic');
    errmsg = sprintf('Error initializing DAQ card: %s',msg);
    return;
  end
  
else
  hComm.daqC = [];  
end

[success,hComm.protocol,errmsg] = ReadStimulusProtocol(params);
if ~success,
  return;
end
hComm.ExperimentSteps = ProtocolExperimentSteps(hComm.protocol);

% compute total stimulus time
hComm.TotalDuration_Seconds = sum(hComm.protocol.duration); % units changed in new protocol
%hComm.TotalDuration_Seconds = sum(hComm.protocol.duration)/1000;

% reset LED controller
% KB 20210124 - new version of LED controller code
hComm.hLEDController.resetController();
%flyBowl_LED_control(hComm.hLEDController,'RESET',[],false);

% set IR LED intensity
% KB 20210124 - new version of LED controller code
hComm.hLEDController.setIRLEDPower(params.ChR_IrInt);
%flyBowl_LED_control(hComm.hLEDController,'IR',params.ChR_IrInt,false);

% set LED pattern
% KB 20210124 I don't know what this is doing or what the equivalent is, I
% LEDPatt = sprintf('%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d',params.ChR_LEDpattern);
% flyBowl_LED_control(hComm.hLEDController, 'PATT', LEDPatt,false);

%remove all experiment steps
hComm.hLEDController.removeAllExperimentSteps();

%add new experiment
try
  for stepIndex = 1:length(hComm.protocol.stepNum)
    totalSteps = hComm.hLEDController.addOneStep(hComm.ExperimentSteps(stepIndex)); %#ok<NASGU>
  end
  
  hComm.expData = hComm.hLEDController.getExperimentSteps();
  
catch ME
  errmsg = sprintf('Error in function %s() at line %d.\n\nError Message:\n%s', ...
    ME.stack(end).name, ME.stack(end).line, ME.message);
  fprintf(1, '%s\n', errmsg);
  return;
end

success = true;
