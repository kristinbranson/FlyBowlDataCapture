function oneStep = ProtocolExperimentStepsRGG(protocol)

oneStep = struct();

%calculate the four point value for each step
for stepIndex = 1:length(protocol.stepNum)
  oneStep(stepIndex).NumStep = protocol.stepNum(stepIndex);
  oneStep(stepIndex).Duration = protocol.duration(stepIndex)/1000; % specify in ms but firmware expects seconds;
  oneStep(stepIndex).DelayTime = protocol.delayTime(stepIndex);
  %red light
  oneStep(stepIndex).RedIntensity = protocol.Rintensity(stepIndex);
  oneStep(stepIndex).RedPulseWidth = protocol.RpulseWidth(stepIndex);
  oneStep(stepIndex).RedPulsePeriod = protocol.RpulsePeriod(stepIndex);
  oneStep(stepIndex).RedPulseNum = protocol.RpulseNum(stepIndex);
  oneStep(stepIndex).RedOffTime = protocol.RoffTime(stepIndex);
  oneStep(stepIndex).RedIteration = protocol.Riteration(stepIndex);
  %green light
  oneStep(stepIndex).GrnIntensity = protocol.Gintensity(stepIndex);
  oneStep(stepIndex).GrnPulseWidth = protocol.GpulseWidth(stepIndex);
  oneStep(stepIndex).GrnPulsePeriod = protocol.GpulsePeriod(stepIndex);
  oneStep(stepIndex).GrnPulseNum = protocol.GpulseNum(stepIndex);
  oneStep(stepIndex).GrnOffTime = protocol.GoffTime(stepIndex);
  oneStep(stepIndex).GrnIteration = protocol.Giteration(stepIndex);
  %blue light
  oneStep(stepIndex).BluIntensity = protocol.Gintensity(stepIndex);
  oneStep(stepIndex).BluPulseWidth = protocol.GpulseWidth(stepIndex);
  oneStep(stepIndex).BluPulsePeriod = protocol.GpulsePeriod(stepIndex);
  oneStep(stepIndex).BluPulseNum = protocol.GpulseNum(stepIndex);
  oneStep(stepIndex).BluOffTime = protocol.GoffTime(stepIndex);
  oneStep(stepIndex).BluIteration = protocol.Giteration(stepIndex);
end
