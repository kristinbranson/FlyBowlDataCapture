function hax = DisplayStimulusProtocol(protocol,varargin)

hax = myparse(varargin,'hax',[]);

if isempty(hax) || ~ishandle(hax),
  hfig = figure;
  hax = gca;
end

oneStep = ProtocolExperimentSteps(protocol);

%% update the protocol in the axes
cla(hax);

totalDuration = sum(protocol.duration); %in seconds - change from old protocol files

X = (0:0.001:totalDuration)';
%xticks('auto');
xlim([0 totalDuration+5]);
Yr = zeros(totalDuration*1000+1,1);
Yg = zeros(totalDuration*1000+1,1);
Yb = zeros(totalDuration*1000+1,1);

stepStartPnt = 1;

%calculate the four point value for each step
for stepIndex = 1:length(protocol.stepNum)   

    powerG = oneStep(stepIndex).GrnIntensity/100;
    powerR = oneStep(stepIndex).RedIntensity/100;
    powerB = oneStep(stepIndex).BluIntensity/100;
    
    LEDOnStartPnt = oneStep(stepIndex).DelayTime*1000 + stepStartPnt;
    RedOnStartPnt = LEDOnStartPnt;
    GrnOnStartPnt = LEDOnStartPnt;
    BluOnStartPnt = LEDOnStartPnt;
    
    if oneStep(stepIndex).RedIntensity > 0       
        for index = 1:oneStep(stepIndex).RedIteration
            numPntOn = oneStep(stepIndex).RedPulsePeriod*oneStep(stepIndex).RedPulseNum;
            Yr(RedOnStartPnt:RedOnStartPnt+numPntOn-1) = ones(numPntOn,1).*powerR;
            RedOnStartPnt = RedOnStartPnt + numPntOn + oneStep(stepIndex).RedOffTime-1;
        end
    end
    
    if oneStep(stepIndex).GrnIntensity > 0
        for index = 1:oneStep(stepIndex).GrnIteration
            numPntOn = oneStep(stepIndex).GrnPulsePeriod*oneStep(stepIndex).GrnPulseNum;
            Yg(GrnOnStartPnt:GrnOnStartPnt+numPntOn-1) = ones(numPntOn,1).*powerG;
            GrnOnStartPnt = GrnOnStartPnt + numPntOn + oneStep(stepIndex).GrnOffTime-1;
        end
    end
    
    if oneStep(stepIndex).BluIntensity > 0
        for index = 1:oneStep(stepIndex).BluIteration
            numPntOn = oneStep(stepIndex).BluPulsePeriod*oneStep(stepIndex).BluPulseNum;
            Yb(BluOnStartPnt:BluOnStartPnt+numPntOn-1) = ones(numPntOn,1).*powerB;
            BluOnStartPnt = BluOnStartPnt + numPntOn + oneStep(stepIndex).BluOffTime-1;
        end
    end

    stepStartPnt = stepStartPnt + oneStep(stepIndex).Duration*1000;
end

%start to plot
if numel(X) < numel(Yr),
  warning('Protocol pulses defined require longer than the specified duration, cutting off at duration');
  Yr = Yr(1:numel(X));
  Yg = Yg(1:numel(X));
  Yb = Yb(1:numel(X));
end
protocolRL = line(X,Yr+2,'color','r','LineStyle','-','Parent',hax);

hold(hax,'on');
protocolGL = line(X,Yg+1,'color','g','LineStyle','-','Parent',hax);
grid(hax,'off');

protocolBL = line(X,Yb,'color','b','LineStyle','-','Parent',hax);

stepStartSec = 0;

%plot steps start and stop line
for stepIndex = 1:length(protocol.stepNum) 
    %plot steps sstart and stop line
    stepStartSec = stepStartSec + oneStep(stepIndex).Duration;
    plot(hax,[stepStartSec,stepStartSec], [0,3],'c', 'LineStyle','--');
end

set(hax,'XLim',[0,X(end)+1]);

legend off;
% legend('red light','green light','blue light','location','best');

% %The animatedline was created after the cla statement
% handles.expWL = animatedline(hax,'color','g','Marker','.','LineStyle','none');
% handles.expRL = animatedline(hax,'color','r','Marker','.','LineStyle','none');
% handles.expBL = animatedline(hax,'color','b','Marker','.','LineStyle','none');

% set(handles.run_exp, 'enable', 'on');
% 
% guidata(hObject, handles);
% 
% %% update the protocol to the controller
% 
% %remove all experiment steps
% handles.hComm.LEDCtrl.removeAllExperimentSteps();
% 
% %add new experiment days
% try
%     for stepIndex = 1:length(protocol.stepNum)
%         totalSteps = handles.hComm.LEDCtrl.addOneStep(oneStep(stepIndex));
%     end
%     
%     expData = handles.hComm.LEDCtrl.getExperimentSteps();
%     disp(expData);
%     
% catch ME
%     errorMessage = sprintf('Error in function %s() at line %d.\n\nError Message:\n%s', ...
%         ME.stack(end).name, ME.stack(end).line, ME.message);
%     fprintf(1, '%s\n', errorMessage);
%     uiwait(warndlg(errorMessage));
%     set(handles.run_exp,'enable', 'off');
% end
% 
% 
% %% winopen(expFile);
% %cd(oldPath);
% guidata(hObject, handles);
% end