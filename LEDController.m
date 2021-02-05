% from Jin
classdef LEDController < handle
    properties
        serialPort
        docheckstatus 
        dispstatus;
        id = nan;
    end
    
    methods
        function obj = LEDController(COMPort)
            obj.serialPort = serial(COMPort, 'BaudRate', 115200, 'Terminator', 'CR');
            obj.docheckstatus = true;
            obj.dispstatus = 0;
            obj.id = now;
            try
                fopen(obj.serialPort);
            catch ME
                display(ME.message);
                obj.serialPort = 0;
            end
        end
        
        %%functions to set LED's power
        function [checReslt,status] = setIRLEDPower(obj,power)
          checReslt = -1;
          status = '';
            if  ~(obj.serialPort == 0)
                Ir_int_val = round(power);
                %send command to controller
                fprintf(obj.serialPort, ['IR ',num2str(Ir_int_val)]);
                if obj.docheckstatus, [checReslt,status] = checkControllerStatus(obj); end
            end
        end
        
        
        function [checReslt,status] = setRedLEDPower(obj,power)
            checReslt = -1;
            status = '';
            if  ~(obj.serialPort == 0)
                Chr_int_val = round(power);   % this is done so only one dec place
                
                %send command to controller
                fprintf(obj.serialPort, ['RED ',num2str(Chr_int_val)]);
                
                if obj.docheckstatus, [checReslt,status] = checkControllerStatus(obj); end
            end
        end
        
        function [checReslt,status] = setGreenLEDPower(obj,power)
            checReslt = -1;
            status = '';
            if  ~(obj.serialPort == 0)
                
                Chr_int_val = round(power);   % this is done so only one dec place
                
                %send command to controller
                fprintf(obj.serialPort, ['GRN ',num2str(Chr_int_val)]);
                if obj.docheckstatus, [checReslt,status] = checkControllerStatus(obj); end
            end
        end
        
        function [checReslt,status] = setBlueLEDPower(obj,power)
            checReslt = -1;
            status = '';
            if  ~(obj.serialPort == 0)
                Chr_int_val = round(power);   % this is done so only one dec place
                
                %send command to controller
                fprintf(obj.serialPort, ['BLU ',num2str(Chr_int_val)]);
                if obj.docheckstatus, [checReslt,status] = checkControllerStatus(obj); end
            end
        end
        
        
        function [checReslt,status] = setVisibleBacklightsOff(obj)
            checReslt = -ones(1,3);
            status = cell(1,3);
            [checReslt(1),status{1}] = setRedLEDPower(obj,0);
            [checReslt(2),status{2}] = setGreenLEDPower(obj,0);
            [checReslt(3),status{3}] = setBlueLEDPower(obj,0);
        end
        
        function [checReslt,status] = setIrBacklightsOff(obj)
            [checReslt,status] = setIRLEDPower(obj,0);
        end
        
        %% functions to set pulse
        
        function [checReslt,status] = setPulseParam(obj,param)
            checReslt = -1;
            status = '';
            if  ~(obj.serialPort == 0)
                fprintf(obj.serialPort, ['PULSE ', num2str(param.pulse_width),' ',num2str(param.pulse_period),' ',num2str(param.number_of_pulses), ' ', ...
                    num2str(param.pulse_train_interval),' ',num2str(param.LED_delay),' ',num2str(param.iteration),' ',param.color]);
                if obj.docheckstatus, [checReslt,status] = checkControllerStatus(obj); end
            end
        end
        
        function [checReslt,status] = startPulse(obj)
            checReslt = -1;
            status = '';
            if  ~(obj.serialPort == 0)
                fprintf(obj.serialPort, 'RUN');
                if obj.docheckstatus, [checReslt,status] = checkControllerStatus(obj); end
            end
        end
        
        function [checReslt,status] = stopPulse(obj)
            checReslt = -1;
            status = '';
            if  ~(obj.serialPort == 0)
                fprintf(obj.serialPort, 'STOP');
                if obj.docheckstatus, [checReslt,status] = checkControllerStatus(obj); end
            end
        end
        
        %% functions to turn on/off LEDs
        function [checReslt,status] = turnOnLED(obj)
            checReslt = -1;
            status = '';
            if  ~(obj.serialPort == 0)
                fprintf(obj.serialPort, 'ON');
                if obj.docheckstatus, [checReslt,status] = checkControllerStatus(obj); end
            end
        end
        
        function [checReslt,status] = turnOffLED(obj)
            checReslt = -1;
            status = '';
            if  ~(obj.serialPort == 0)
                fprintf(obj.serialPort, 'OFF');
                if obj.docheckstatus, [checReslt,status] = checkControllerStatus(obj); end
            end
        end
        

        %% functions to set up experiment protocols
        function totalSteps = addOneStep(obj,oneStep)
            if  ~(obj.serialPort == 0)
              x = [oneStep.NumStep, oneStep.RedIntensity, oneStep.RedPulsePeriod,...
                oneStep.RedPulseWidth, oneStep.RedPulseNum, oneStep.RedOffTime, oneStep.RedIteration, oneStep.GrnIntensity,...
                oneStep.GrnPulsePeriod, oneStep.GrnPulseWidth, oneStep.GrnPulseNum, oneStep.GrnOffTime, oneStep.GrnIteration,...
                oneStep.BluIntensity, oneStep.BluPulsePeriod, oneStep.BluPulseWidth, oneStep.BluPulseNum, oneStep.BluOffTime,...
                oneStep.BluIteration,oneStep.DelayTime, oneStep.Duration];
              s = 'addOneStep ';
              for i = 1:numel(x),
                if isequaln(x(i),fix(x(i))),
                  s = [s,sprintf('%d ',x(i))];
                else
                  s = [s,sprintf('%f ',x(i))];
                end
              end
                fprintf(obj.serialPort,s);
                [~,status] = checkControllerStatus(obj);
                totalSteps = str2double(status);
            end
        end
        
        function [checReslt,status] = removeAllExperimentSteps(obj)
            checReslt = -1;
            status = '';
            if  ~(obj.serialPort == 0)
                fprintf(obj.serialPort, 'removeAllSteps');
                if obj.docheckstatus, [checReslt,status] = checkControllerStatus(obj); end
            end             
        end        
                        
        function [steps,checReslt] = getExperimentSteps(obj)
            if  ~(obj.serialPort == 0)
                fprintf(obj.serialPort, 'getExperimentSteps');
                %if obj.docheckstatus, [~,steps] = checkControllerStatus(obj); end
                [checReslt,steps] = checkControllerStatus(obj,false);
            end
        end
        
        function runExperiment(obj)
            if  ~(obj.serialPort == 0)
                fprintf(obj.serialPort, 'runExperiment');
                %if obj.docheckstatus, [~,status] = checkControllerStatus(obj); end
            end
        end
        
        function [checReslt,status] = stopExperiment(obj)
            checReslt = -1;
            status = '';
            if  ~(obj.serialPort == 0)
                fprintf(obj.serialPort, 'StopExperiment');
                if obj.docheckstatus, [checReslt,status] = checkControllerStatus(obj); end
            end
        end
        
        function [status,checReslt] = getExperimentStatus(obj)
            status = {};
            checReslt = -1;
            if  ~(obj.serialPort == 0)
                fprintf(obj.serialPort, 'getExperimentStatus');
                %if obj.docheckstatus, [~,status] = checkControllerStatus(obj); end
                [checReslt,status] = checkControllerStatus(obj,false); 
                status = status{1};
            end            
        end
        
        %%other functions
        
        function synCamera(obj, freq)
            if  ~(obj.serialPort == 0)
                fprintf(obj.serialPort, ['SYNC ', freq]);
                if obj.docheckstatus, [~,status] = checkControllerStatus(obj); end
            end
        end
        
        function flyBowlsEnabled(obj, enableMap)
            if  ~(obj.serialPort == 0)
                fprintf(obj.serialPort, ['enableMap ', enableMap]);
                if obj.docheckstatus, [~,status] = checkControllerStatus(obj); end
            end               
        end
        
        function cameraTrigger(obj, trigRate)
            if  ~(obj.serialPort == 0)
                fprintf(obj.serialPort, ['SYNC ', trigRate]);
                if obj.docheckstatus, [~,status] = checkControllerStatus(obj); end
            end               
        end
        
        %reset controller, all power value reset to 0
        function resetController(obj)
            if  ~(obj.serialPort == 0)
                fprintf(obj.serialPort, 'RESET');
                if obj.docheckstatus, [~,status] = checkControllerStatus(obj); end
            end               
        end        
             
        function close(obj)
            if  ~(obj.serialPort == 0)
                disp(obj.serialPort);
                fclose(obj.serialPort);
                fprintf('Closed LEDController\n');
            end
            obj.serialPort = 0;
        end
        
        function delete(obj)
            if  ~(obj.serialPort == 0)
                disp(obj.serialPort);
                fclose(obj.serialPort);
                fprintf('Closed LEDController\n');
            end
        end
        
        function v = isequal(obj,obj1)
          v = obj.id == obj1.id;
        end
        
    end
    
    methods (Access = private)
        function [checReslt,status] = checkControllerStatus(obj,dispstatus)
            if nargin < 2,
                dispstatus = obj.dispstatus;
            end
            %pause(0.1);
            starttime = tic;
            maxwaittime = .5;
            waittime = 0;
            checReslt = 0;
            status = {};
            while obj.serialPort.BytesAvailable <= 1
                waittime = toc(starttime);
                if waittime >= maxwaittime
                    fprintf('No output found from serial port within %f seconds.\n',maxwaittime);
                    return;
                end
            end
            fprintf('Waited %f seconds for controller status\n',waittime);
            while obj.serialPort.BytesAvailable > 1
                checReslt = 1;
                s = strtrim(fscanf(obj.serialPort));
                if isempty(s)
                    continue;
                end
                if dispstatus
                    fprintf([s,'\n']);
                end
                status{end+1} = s; %#ok<AGROW>
            end
        end
    end
end