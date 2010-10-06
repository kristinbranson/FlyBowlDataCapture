classdef DateTimeValidator < NumericValidator
    % Used for validating datetime data. Range is set using a range string
    % argument. Validation consists of checking that the time values are
    % within a given range which can be inclusive of exclusive of the end points.
    % The end points are checked to insure that they are integers and the
    % value is trucated to an integer during the check.
     
    properties
        format;  % The choice of format for the datetime string
    end
    
    properties (Constant, Hidden) 
        fullFormatString = 'yyyy-mm-ddTHH:MM:SS';
        daysFormatString = 'yyyy-mm-ddT00:00:00';
        hoursFormatString = 'yyyy-mm-ddT:HH:00:00'
        minutesFormatString = 'yyyy-mm-ddT:HH:MM:00';
        fullFormat = 0;
        daysFormat = 1;
        hoursFormat = 2;
        minutesFormat = 3;
        % Note, other formats which could be added include hours and
        % minutes. A seconds format would be the same as the full format so
        % it isn't needed. 
    end
    
    properties (Dependent)
        formatString;
        lowerBoundString;  % Display lower bound in datetime string format
        upperBoundString;  % Display upper bound in datetime string format
    end
    
    properties (Dependent, Hidden)
        formatIncr;
    end
    
    methods
        
        function self = DateTimeValidator(rangeString)
            % Constructor
            if nargin > 0
                self.setRangeAndOptions(rangeString);
            end
        end
        
        function setRangeAndOptions(self,rangeString)
            % Sets upper and lower bounds as well as range options based on
            % the range string.
            
            % Check if there are any bounds
            if isempty(rangeString)
                % No bounds set
                self.hasBounds = false;
                self.format = self.fullFormat;
            else
                % Set options
                rangeString = self.setOptions(rangeString);
                % Set the lower and upper bounds based on the range sting.
                %setRange@NumericValidator(self,rangeString);
                self.setRange(rangeString);
            end
        end
        
        function rangeString = setOptions(self,rangeString)
            % Check to see if any options such as "days" has been set on
            % the range.
            if isempty(rangeString)
                return;
            end
            rangeString = strtrim(rangeString);     
            % Check to see if any option has been set.
            commaPos = findstr(rangeString,',');
            if length(commaPos) > 2
                error('cannot parse range string - too many commas');
            end
            if length(commaPos) == 2     
                % There are two commas, this means a format string has
                % been specified - figure out which one it is.
                optionString = rangeString(commaPos(2)+1:end);
                optionString = strtrim(optionString);
                rangeString = rangeString(1:commaPos(2)-1);
                switch lower(optionString)
                    case 'days'
                        self.format = self.daysFormat;
                    case 'hours'
                        self.format = self.hoursFormat;
                    case 'minutes'
                        self.format = self.minutesFormat;
                    case 'full'
                        self.format = self.fullFormat;
                    otherwise
                        error('cannot parse range string - unknown format option');
                end
            else
                % Less than two commas means a format string has not been
                % specified. The default is full format.
                self.format = self.fullFormat;
            end          
        end
        
        function setRangeValues(self,rangeString)
            % Set upper and lower bound values.
            rangeString = strtrim(rangeString);
            if isempty(rangeString)
                % Range string is empty this means no bounds
                self.lowerBound = -Inf;
                self.upperBound = Inf;
                self.hasBounds = false;
            else
                [lowerString, upperString] = self.getRangeStrings(rangeString);
                try
                    lowerValue = eval(lowerString);
                catch ME
                    error('range string lower value format incorrent: %s', ME.message);
                end
                try
                    upperValue = eval(upperString);
                catch ME
                    error('range string upper value incorrect format: %s', ME.message);
                end
                if lowerValue > upperValue
                    error('lower bound is greater than upper bound');
                end
                
                % Pass values through format string to truncate them. This
                % errors out if either of the bounds is p/m Inf so those
                % cases are by passed.
                if abs(lowerValue) ~= Inf
                    lowerString = dateNumberToDateString(lowerValue,self.formatString);
                    lowerValue = dateStringToDateNumber(lowerString, self.formatString);
                end
                if abs(upperValue) ~= Inf
                    upperString = dateNumberToDateString(upperValue,self.formatString);
                    upperValue = dateStringToDateNumber(upperString, self.formatString);  
                end
           
                self.lowerBound = lowerValue; 
                self.upperBound = upperValue;    
            end
        end
        
        function [value,flag,msg] = validationFunc(self,value)
            % Apply validation to given value
            
            if isempty(value)
                % Value is empty - return true. Only apply validatation if
                % the user actually sets a value.
                flag = true;
                msg = '';
                return;
            end
            
            % Value is not empty - try to convert value to a string with a
            % floating point representation of the date number.
            try
                floatString = dateStringToFloatString(value,self.formatString);
            catch ME
                flag = false;
                msg = sprintf('unable to convert value to date number: %s',ME.message);
                return;
            end
            
            % Apply parent class validation
            [floatString,flag,msg] = validationFunc@NumericValidator(self,floatString);
            
            % Convert float string value back to date string
            value = floatStringToDateString(floatString,self.formatString);
        end
        
        function value = getValidValue(self)
            % Returns a valid value.
            floatString = getValidValue@NumericValidator(self);
            value = floatStringToDateString(floatString,self.formatString);
        end
        
        function test = isFiniteRange(self)
            % Test if range of possible values is finite.
            if self.hasBounds == false
                % There are no bounds set range is infinite
                test = false;
            else
                % Bounds have been set - get range from bounds.
                test = true;
                if (self.lowerBound == -Inf) || (self.upperBound == Inf)
                    test = false;
                end
            end
        end
        
        function numValues = getNumValues(self)
           % Returns the number of possible values
           if self.isFiniteRange() == true          
               % Range is finite - first figure out how many possible
               % days there are between the two bounds.
               numDays = abs(self.lowerBound - self.upperBound) + 1;
               if strcmp(self.lowerBoundType,'exclusive')
                    numDays = numDays - self.formatIncr;
                end
                if strcmp(self.upperBoundType,'exclusive')
                    numDays = numDays - self.formatIncr;
                end
               % Multiply days by correct amount based on format to get
               % number of values.
               numValues = numDays/self.formatIncr;
           else
               % The range is not fintie - return Inf.
               numValues = Inf;
           end
        end
        
        function valueArray = getValues(self)
            % Returns array of possible values if range is finite, otherwise
            % returns an empty array.
            if self.isFiniteRange() == true
                % Get lower and upper values for range based on the bounds
                % and bound types.
                switch self.lowerBoundType
                    case 'inclusive'
                        lowerValue = self.lowerBound;
                    case 'exclusive'
                        lowerValue = self.lowerBound+self.formatIncr;
                    otherwise
                        error('unkown lowerBoundType %s', self.lowerBoundType);
                end
                
                switch self.upperBoundType
                    case 'inclusive'
                        upperValue = self.upperBound;
                    case 'exclusive'
                        upperValue = self.upperBound-self.formatIncr;
                    otherwise
                        error('unknown upperBoundType %s', self.upperBoundType);
                end
                % Create array of date numbers and then convert them to
                % datetime strings.
                dateNumArray = [lowerValue:self.formatIncr:upperValue];
                valueArray = cell(1,length(dateNumArray));
                for i = 1:length(dateNumArray)
                   valueArray{i} = dateNumberToDateString(dateNumArray(i),self.formatString); 
                end
            else
                valueArray = {};
            end
        end

        function incr = get.formatIncr(self)
            % Return smallest numerical increment, in date numbers, between 
            % dates given the current format option.
            switch self.format
                case self.daysFormat
                    incr = 1.0;
                case self.hoursFormat
                    incr = 1.0/24.0;
                case self.minutesFormat
                    incr = 1.0/(24.0*60.0);
                case self.fullFormat
                    incr = 1.0/(24.0*3600.0);
                otherwise
                    error('unknown format option');
            end
        end
        
        function lowerBoundString = get.lowerBoundString(self)
            % Get dependent property lowerBoundString which gives the
            % lowerBound as a datetime string.
            if self.lowerBound == -Inf
                lowerBoundString = '-Inf';
            else
                lowerBoundString = dateNumberToDateString(self.lowerBound,self.formatString);
            end
        end
        
        function upperBoundString = get.upperBoundString(self)
            % Get the dependent property upperBoundStirng which gives the
            % upperBound as a datetime string.
            if self.upperBound == Inf
                upperBoundString = 'Inf';
            else
                upperBoundString = dateNumberToDateString(self.upperBound,self.formatString);
            end
        end
        
        function formatString = get.formatString(self)
            % Select format String based on format option
            switch self.format
                case self.fullFormat
                    formatString = self.fullFormatString;
                case self.daysFormat
                    formatString = self.daysFormatString;
                case self.hoursFormat  
                    formatString = self.hoursFormatString;
                case self.minutesFormat
                    formatString = self.minutesFormatString;
                otherwise
                    error('unknown format string');
            end
        end  
    end
end % classdef DateTimeValidator

% -------------------------------------------------------------------------
function dateString = floatStringToDateString(floatString,format)
% Converts a float string to a date string
dateNumber = str2num(floatString);
dateString = dateNumberToDateString(dateNumber,format);
end

% -------------------------------------------------------------------------
function floatString = dateStringToFloatString(dateString,format)
% Converts a date string to a float string
dateNumber = dateStringToDateNumber(dateString,format);
floatString = num2str(dateNumber);
end

% -------------------------------------------------------------------------
function dateString = dateNumberToDateString(dateNumber,format)
% Converts a date number to a date string.
dateString = datestr(dateNumber,format);
end

% -------------------------------------------------------------------------
function dateNumber = dateStringToDateNumber(dateString,format)
% Converts a date string to a date number.
try
    dateNumber = datenum(dateString,format);
catch ME
    error( ...
        'unable to convert date string to date number: %s, required format: %s', ...
        ME.message, ...
        format ...
        );
end
end
