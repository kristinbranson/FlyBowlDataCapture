classdef Time24Validator < NumericValidator
    % Used for validating timer24 data. Range is set using a range string 
    % argument. Validation consists of checking that the time values are 
    % within a given range which can be inclusive of exclusive of the end points. 
    % The end points are checked to insure that they are integers and the 
    % value is trucated to an integer during the check.
      
    methods
        
        function self = Time24Validator(rangeString)
            % Constructor.
            if nargin > 0
                self.setRange(rangeString);
            end
        end
          
        function setRange(self, rangeString)
            % Parses the range sting to produce boounds for validation. 
            if isempty(rangeString)
                self.hasBounds = false;
            else
                rangeString = strtrim(rangeString);
                self.setRangeTypes(rangeString);
                [lowerString, upperString] = self.getRangeStrings(rangeString);
                lowerTime = time24ToFloat(lowerString);
                upperTime = time24ToFloat(upperString);
                self.lowerBound = lowerTime;
                self.upperBound = upperTime;
                self.hasBounds = true;
            end
        end
        
        function [value,flag,msg] = validationFunc(self,value)
            % Applies validation to given value.
            
            if isempty(value)
                % Value is empty - return true. Only apply validatation if
                % the user actually sets a value.
                flag = true;
                msg = '';
                return;
            end
            
            try
                % Convert time24 string to float string
                valueFloatString = time24ToFloatString(value);
            catch ME
                flag = false;
                msg = sprintf('incorrect time24 value, %s', ME.message);
                return;
            end
            
            % Apply parent class validation
            [valueFloatString,flag,msg] = validationFunc@NumericValidator(self,valueFloatString);
            
            % Convert float string back to time24 string
            value = floatStringToTime24(valueFloatString);
        end
        
        function value = getValidValue(self)
            % Returns a valid value.
            valueFloatString = getValidValue@NumericValidator(self);
            value = floatStringToTime24(valueFloatString);
        end
        
    end
    
end % classdef Time24Validator

% -------------------------------------------------------------------------
function floatString = time24ToFloatString(time24String)
% Converts a time24 string to a float string
t = time24ToFloat(time24String);
floatString = num2str(t);
end

% -------------------------------------------------------------------------
function time24String = floatStringToTime24(floatString)
% Converts a float string to a time24 string
t = str2num(floatString);
time24String = floatToTime24(t);
end

% -------------------------------------------------------------------------
function t = time24ToFloat(timeString)
% Converts a time24 string to a floating point number
timeString = strtrim(timeString);
colonPos = findstr(timeString,':');
if isempty(colonPos)
    error('invalid time24 string - cannot find colon');
end
if length(colonPos) > 1
    errot('invalid time24 string - too many colons');
end
hourString = timeString(1:colonPos-1);
minuteString = timeString(colonPos+1:end);
hr = str2num(hourString);
min = str2num(minuteString);
if isempty(hr)
    error('invalid time24 string - cannot parse hours');
end
if isempty(min)
    error('invalid time24 string - cannot parse minute');
end
if (hr < 0) || (hr >= 24)
    error('invalid time24 string - hour out of range');
end
if (min < 0) || (min > 59)
    error('invalid time24 string - minute out of range');
end
t = hr + min/60.0;
end

% -------------------------------------------------------------------------
function timeString = floatToTime24(value)
% Convert floating point number to time24 string
if value < 0
    error('cannot convert value to time24 string, value < 0');
end
if value > (23+59/60)
    error('cannot convert value to time24 string, value too large');
end
hr = floor(value);
min = floor(60*(value - hr));
timeString = sprintf('%02d:%02d',hr,min);
end