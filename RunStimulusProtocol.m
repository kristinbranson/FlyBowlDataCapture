function [success] = RunStimulusProtocol(handles,expTimeFileID)

global FBDC_DIDHALT;
GUIi = handles.GUIi;
if numel(FBDC_DIDHALT) < GUIi,
  FBDC_DIDHALT(GUIi) = false;
end
if FBDC_DIDHALT(GUIi),
  addToStatus('PROBLEM!!! FBDC_DIDHALT == true at start of RunStimulusProtocol, setting to false...');
  FBDC_DIDHALT(GUIi) = false;
end

success = false;

% timestamp, start_pulse, step number

% TODO: move this elsewhere
% %stop update teh temperature and humidity value
% if ~(handles.ChRStuff.THSensor == 0)
%   stop(handles.tTemp);
% end

% TODO: move this elsewhere
% % save the protocol file
% protocol = handles.ChRStuff.protocol;
% protocolFile = [handles.expDataSubdir, '\protocol.mat'];
% save(protocolFile,'protocol');
% protocolCSV = [handles.expDataSubdir, '\protocol.csv'];
% csvwrite_with_headers(protocolCSV, handles.ChRStuff.protocolData, handles.ChRStuff.protocolHeader);
    
% TODO: move this elsewhere
% %save the json file
% jsonFile = [handles.expDataSubdir, '\cameraSettings.json'];
% if ~(handles.ChRStuff.flea3 == 0)
%   flyBowl_camera_control(handles.ChRStuff.flea3,'saveconfig', jsonFile);
% end

% TODO: move this elsewhere
% % create an experiment timestamp file
% expTimeFile = [handles.expDataSubdir, '\expTimeStamp.txt'];
% expTimeFileID = fopen(expTimeFile, 'w+');

%setappdata(handles.figure_main,'ChRExpRunning',true);

% TODO: put this back in?
% %Configure data acquisition and start the daq
% if ~isempty(handles.ChRStuff.daqC)
%   flyBowl_DAQ_control(handles.ChRStuff.daqC,'config');
%   binFileName = [handles.expDataSubdir, '\daqData.bin'];
%   handles.DAQFid1 = fopen(binFileName, 'w');
%   handles.DAQlh = addlistener(handles.ChRStuff.daqC,'DataAvailable', @(src,event) logData(src, event, handles.DAQFid1));
%   flyBowl_DAQ_control(handles.ChRStuff.daqC,'start');
% end

% TODO: do this elsewhere
% %record movie
% if ~(handles.ChRStuff.flea3 == 0)
%   flyBowl_camera_control(handles.ChRStuff.flea3,'stop');
%   %start recording
%   trialMovieName = [handles.expDataSubdir, '\movie.', handles.movieFormat];
%   flyBowl_camera_control(handles.ChRStuff.flea3,'start', trialMovieName);
%   fprintf(expTimeFileID, '%.10f , start camera recording.\n', now);
% end

addToStatus(handles,'Running stimulus experiment:' );
addToStatus(handles,handles.ChRStuff.expData);
fprintf(expTimeFileID, '%.10f,run_experiment\n', now);
handles.ChRStuff.hLEDController.runExperiment();

duration = handles.ChRStuff.TotalDuration_Seconds;
curTime = tic;

didhalt = false;
while toc(curTime) < duration,
  pause(0.1);
  if FBDC_DIDHALT(GUIi),
    fprintf('In RunStimulusProtocol, detected FBDC_DIDHALT == true, signifying experiment aborted.\n');
    addToStatus(handles,'In RunStimulusProtocol, detected FBDC_DIDHALT == true, signifying experiment aborted.');
    didhalt = true;
    break;
  end
  if ishandle(handles.ChRStuff.hCurrTimeLine),
    set(handles.ChRStuff.hCurrTimeLine,'XData',toc(curTime)+[0,0]);
  end
end

fprintf(expTimeFileID, '%.10f,stop_experiment,%d\n', now);
stopstatus = handles.ChRStuff.hLEDController.getExperimentStatus();
handles.ChRStuff.hLEDController.stopExperiment();
addToStatus(handles,'Experiment status when stopped:');
if isempty(stopstatus),
  addToStatus(handles,'NULL');
else
  try %#ok<TRYNC>
    addToStatus(handles,['>> ',stopstatus]);
  end
end
% fprintf(expTimeFileID, '%.10f,stop_pulse,%d\n', now, step );
% handles.ChRStuff.hLEDController.stopPulse();
% 
% for step=1:numel(handles.ChRStuff.protocol.stepNum),
% 
%   %fprintf(expTimeFileID, '%.10f , start step %d.\n', now, step);
%   % display current step
%   allOn = 0;
%   allOff = 0;
%   currentStep = sprintf('ST: %d, IT: %d, PW: %d, PP: %d, PN: %d, OT: %d, DT: %d, DU: %f, IR: %d',...
%     handles.ChRStuff.protocol.stepNum(step),handles.ChRStuff.protocol.intensity(step), ...
%     handles.ChRStuff.protocol.pulseWidthSP(step), handles.ChRStuff.protocol.pulsePeriodSP(step),...
%     handles.ChRStuff.protocol.pulseNum(step), handles.ChRStuff.protocol.offTime(step),...
%     handles.ChRStuff.protocol.delayTime(step), handles.ChRStuff.protocol.duration(step),...
%     handles.ChRStuff.protocol.iteration(step));
%   
%   addToStatus(handles,currentStep);
% 
%   % if intensity = 0, off this step
%   if handles.ChRStuff.protocol.intensity(step)==0
%     allOff = 1;
%     % if pulse period = 0, always on this step
%   elseif handles.ChRStuff.protocol.pulseWidthSP(step) == 0
%     allOn = 1;
%   end
%   
%   % set intensity
%   handles.ChRStuff.hLEDController.setRedLEDPower(power,handles.ChRStuff.protocol.intensity(step));
%   %flyBowl_LED_control(handles.ChRStuff.hLEDController, 'CHR',handles.ChRStuff.protocol.intensity(step),false);
%   pauseT = double(handles.ChRStuff.protocol.duration(step))/1000;
%         
%   % blink LED (calculate the iteration number)
%   if allOff == 1;
%     % if intensity is 0, then turn things off and wait
%     
%     error('Using allOff condition in RunStimulusProtocol -- this should not happen in FBDC!\n');
%     handles.ChRStuff.hLEDController.turnOffLED();
%     
%     %pause(double(handles.ChRStuff.protocol.duration(step))/1000);
%     curTime = tic;
%     while toc(curTime) < pauseT,
%       pause(0.01);
%       if FBDC_DIDHALT(GUIi),
%         return;
%       end
%     end
%     
%   elseif allOn == 1
%     % if pulsewidth is 0, control this through MATLAB!
%     
%     error('Using allOn condition in RunStimulusProtocol -- this should not happen in FBDC!\n');
%         
%     handles.ChRStuff.hLEDController.turnOnLED();
%     %flyBowl_LED_control(handles.ChRStuff.hLEDController, 'ON',[],false);
%     %pause(double(handles.ChRStuff.protocol.duration(step))/1000);
%     curTime = tic;
%     while toc(curTime) < pauseT
%       pause(0.01);
%       if FBDC_DIDHALT(GUIi),
%         return;
%       end
%     end
%     
%   else
%     
%     % THIS SHOULD ALWAYS BE THE CASE IN FBDC -- DO NOT USE MATLAB TIMING
%     
%     % set parameters for this step
%     param.pulse_width = handles.ChRStuff.protocol.pulseWidthSP(step);
%     param.pulse_period = handles.ChRStuff.protocol.pulsePeriodSP(step);
%     param.number_of_pulses = handles.ChRStuff.protocol.pulseNum(step);
%     param.pulse_train_interval = handles.ChRStuff.protocol.offTime(step);
%     param.delay_time = handles.ChRStuff.protocol.delayTime(step);
%     param.LED_delay = handles.ChRStuff.protocol.delayTime(step);
%     param.iteration = handles.ChRStuff.protocol.iteration(step);
%     param.color = 'RED'; % currently only supporting red LEDs
%         
%     % run this plan
%     handles.ChRStuff.hLEDController.setPulseParam(param);
%     %flyBowl_LED_control(handles.ChRStuff.hLEDController, 'PULSE', param,false);
%     delay(0.01);
%             
%     fprintf(expTimeFileID, '%.10f,start_pulse,%d\n', now, step );
%     handles.ChRStuff.hLEDController.startPulse();
%     %flyBowl_LED_control(handles.ChRStuff.hLEDController, 'RUN',[],false);
%             
%     %stop timer cannot stop the callback function, so we need to
%     %poll the state of the expRun
%     %pause(double(handles.ChRStuff.protocol.duration(step))/1000);
%     curTime = tic;
%     
%     % TODO: I think here is where we can pause for slightly less time, and
%     % then pause again after 
%     
%     while toc(curTime) < pauseT,
%       pause(0.01);
%       if FBDC_DIDHALT(GUIi),
%         return;
%       end
%     end
%             
%     fprintf(expTimeFileID, '%.10f,stop_pulse,%d\n', now, step );
%     handles.ChRStuff.hLEDController.stopPulse();
%     %flyBowl_LED_control(handles.ChRStuff.hLEDController, 'STOP',[],false);
%   end
%   
% end

%to guaranttee the leds are off at the end
handles.ChRStuff.hLEDController.turnOffLED();
%flyBowl_LED_control(handles.ChRStuff.hLEDController, 'OFF',[],false);
%setappdata(handles.figure_main,'ChRExpRunning',false);

% TODO: put this back?
%stop the daq
%   if ~isempty(handles.ChRStuff.daqC)
%     flyBowl_DAQ_control(handles.ChRStuff.daqC,'stop');
%     delete(handles.DAQlh);
%     fclose(handles.DAQFid1);
%   end

% TODO: move this elsewhere
%fclose(expTimeFileID);
if didhalt,
  addToStatus(handles,'Experiment aborted before protocol complete');
else
  addToStatus(handles,'Done running protocol!!');
  success = true;
end

% TODO: move this elsewhere
%   %start update temp and humidity value
%   if ~(handles.ChRStuff.THSensor == 0)
% %         handles.tTemp = timer('StartDelay', 3, 'Period', handles.THUpdateP, 'ExecutionMode', 'fixedRate', 'TimerFcn',{@displayTempHumd, handles.figure1} );
%     start(handles.tTemp);
%   end
