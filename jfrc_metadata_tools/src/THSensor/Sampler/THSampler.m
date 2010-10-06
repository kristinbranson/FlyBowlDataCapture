classdef THSampler < handle
    % Periodic sampling of temperature and humidity data using either a
    % fake sensor, or the Precon RS232 temperature and humidity sensors.
    %
    % Emits events of type THSampleAcquired to which listeners can be
    % added.
   
    properties
        sensorType = 'fake';
        period = 2.0;
        port = 'NA';
        timer;
        dev;
    end
    
    properties (Access=protected)
        getDataFunc;
        sensorInitFunc;
        sensorCleanUpFunc;
    end
    
    properties (Constant,Hidden)
        allowedSensorTypes = {'fake', 'precon'};
    end
    
    events
        THSampleAcquired;
    end
    
    methods 
        function self = THSampler(sensorType, port)
            % Constuctor
            sensorType = lower(sensorType);
            try
                validatestring(sensorType,self.allowedSensorTypes);
            catch ME
                error('unkown sensor type %s, %s',sensorType, ME.message);
            end
  
            % Switch yard for setting sensor initialization, cleanup and get
            % data functions based on sensor type.
            switch sensorType
                case 'fake'
                    % Fake sensor type - returns made up data
                    self.getDataFunc = @self.fakeSensorGetData;
                    self.sensorInitFunc = @self.fakeSensorInit;
                    self.sensorCleanUpFunc = @self.fakeSensorCleanUp; 
                    self.sensorType = sensorType;
                    self.port = 'NA';
                case 'precon'
                    % Precon RS232 sensor
                    if nargin < 2
                        self.port = 'COM1';
                    else
                        self.port = port;
                    end
                    self.getDataFunc = @self.preconSensorGetData;
                    self.sensorInitFunc = @self.preconSensorInit;
                    self.sensorCleanUpFunc = @self.preconSensorCleanUp; 
                    self.sensorType = sensorType;
                otherwise
                    error('unknown sensor type');
            end
            self.timer = [];
            self.dev = [];
        end
        
        function delete(self)
            % Class destructor. Cleans up and deletes object.
            if ~isempty(self.timer)
                try
                    % Stop any timer objects.
                    stop(self.timer);
                catch ME
                    warning('THSampler:timerstop','error stopping timer: %s\n', ME.messge);
                end
                
                try
                    % Delete any timer objects.
                    delete(self.timer);
                catch ME
                    error('error stopping timer: %s', ME.message);
                end
            end
            
            if ~isempty(self.dev);
                % if any open devices exist clean them up.
                try
                    self.sensorCleanUpFunc();
                catch ME
                    error('error cleaning up sesnor: %s', ME.message);
                end
            end
        end
                
        function [T,H,flag] = getData(self)
            % Get sample data form sensor.
           [T,H,flag] = self.getDataFunc(); 
        end
       
        function start(self)
            % Start periodic acquisition of data from sensor.
            self.sensorInitFunc()   
            % Setup timer
            self.timer = timer( ...
                'Period', self.period, ...
                'ExecutionMode','FixedSpacing' ...
                );
            self.timer.TimerFcn = @self.timerCallback;
            start(self.timer);      
        end
        
        function stop(self)
            % Stop periodic acquisition.
            stop(self.timer);
            delete(self.timer);
            self.timer = [];
            self.sensorCleanUpFunc();   
        end
        
        function timerCallback(self,~,~)
            % Timer callback funciton. Grabs data from sensor and notifies
            % any listeners.
            [T,H,flag] = self.getData();
            if flag == true
                self.notify('THSampleAcquired',THSamplerEventData(T,H));
                %fprintf('T = %f, H = %f\n',T,H); 
            end
        end
        
        function set.period(self,value)
            % Set acquisition period.
            if value <= 0
                error('period must be >= 0');
            end
            self.period = value;
        end
      
    end
    
    % Precon sensor functions -----------------------------------------
    
    methods (Access=protected)
        
        function [T,H,flag] = preconSensorGetData(self)
            % Get sample data from the RS232 precon sensor 
            try
                [T,H,success,errormsg] = self.dev.read(1);
            catch ME
                error('failed to get reading from precon sensor: %s',ME.message);
            end 
            if success == false
                fprintf('failed to get reading form precon sensor: %s\n', errormsg);
                flag = false;
            else
                flag = true;
            end
        end
        
        function preconSensorInit(self)
            % Initializes precon sensor for acquisition
            self.dev = PreconSensor(self.port);
            try
                self.dev.open();
            catch ME
                error('unable to open to precon sensor: %s',ME.message);
            end
        end
        
        function preconSensorCleanUp(self)
            % Cleans up precon sensor.
            self.dev.close();
            delete(self.dev);
            self.dev = [];
        end
        
        % Fake sensor functions -------------------------------------------
        function fakeSensorInit(self)
            % Dummy function for starting fake data acquisition - does
            % nothing.
        end
        
        function fakeSensorCleanUp(self)
            % Dummy function for stopping fake data acquisition - does
            % nothing.
        end
        
        function [T,H,flag] = fakeSensorGetData(self)
            % Fake get data function - returns fake data.
            T = 27 + 2*randn;
            H = 50 + randn;
            flag = true;
        end
        % -----------------------------------------------------------------
          
    end
end