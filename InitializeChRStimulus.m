function [success,hComm,errmsg] = InitializeChRStimulus(params)

success = false;
hComm = struct;
errmsg = ''; %#ok<NASGU>

global FBDC_CHR_LED_CONTROLLER_FID;

%initialize LED controller
try
  hComm.hLEDController = serial(params.ChR_serial_port_for_LED_Controller,...
    'BaudRate', 115200, 'Terminator', 'CR');
  fopen(hComm.hLEDController);

  if isempty(FBDC_CHR_LED_CONTROLLER_FID)
    FBDC_CHR_LED_CONTROLLER_FID = hComm.hLEDController;
  else
    FBDC_CHR_LED_CONTROLLER_FID(end+1) = hComm.hLEDController;
  end
    
catch ME,
  msg = getReport(ME,'basic');
  errmsg = sprintf('Error initializing LED controller: %s',msg);
  return;
end
  
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

% compute total stimulus time
hComm.TotalDuration_Seconds = sum(hComm.protocol.duration)/1000;

% reset LED controller
flyBowl_LED_control(hComm.hLEDController,'RESET',[],false);

% set IR LED intensity
flyBowl_LED_control(hComm.hLEDController,'IR',params.ChR_IrInt,false);

% set LED pattern
LEDPatt = sprintf('%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d',params.ChR_LEDpattern);
flyBowl_LED_control(hComm.hLEDController, 'PATT', LEDPatt,false);

success = true;
