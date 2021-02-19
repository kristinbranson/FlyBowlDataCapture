function [success,hComm,errmsg] = InitializeChRStimulus(params,hComm)

success = false;
if nargin < 2,
  hComm = struct;
end
errmsg = ''; %#ok<NASGU>

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

% set LED pattern
% KB 20210124 I don't know what this is doing or what the equivalent is, I
% LEDPatt = sprintf('%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d',params.ChR_LEDpattern);
% flyBowl_LED_control(hComm.hLEDController, 'PATT', LEDPatt,false);

%remove all experiment steps
hComm.hLEDController.removeAllExperimentSteps();

%add new experiment
try
  for stepIndex = 1:length(hComm.protocol.stepNum)
    totalSteps = hComm.hLEDController.addOneStep(hComm.ExperimentSteps(stepIndex));
    if isempty(totalSteps) || (totalSteps ~= stepIndex),
      error('totalSteps returned from LED Controller -> addOneStep does not match');
    end
  end
  
  hComm.expData = hComm.hLEDController.getExperimentSteps();
  
catch ME
  errmsg = sprintf('Error in function %s() at line %d.\n\nError Message:\n%s', ...
    ME.stack(end).name, ME.stack(end).line, ME.message);
  fprintf(1, '%s\n', errmsg);
  return;
end

success = true;
