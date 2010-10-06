classdef IntegerValidator < NumericValidator
    % Used for validating integer data. Range is set using a range string 
    % argument. Validation consists of checking that the values are within 
    % a given range which can be inclusive of exclusive of the end points. 
    % The end points are checked to insure that they are integers and the 
    % value is trucated to an integer during the check.
    methods
        
        function self = IntegerValidator(rangeString)
            % Class constructor
            if nargin > 0
                self.setRange(rangeString);
            end
        end
        
        function setRange(self, rangeString)
            % Set upper and lower bounds of validator based on the
            % rangeString.
            setRange@NumericValidator(self,rangeString);
            if self.hasBounds == true
                % Insure that upper and lower bounds are integers if not throw
                % an error.
                if self.upperBound ~= Inf
                    upperFrac = self.upperBound - floor(self.upperBound);
                    if upperFrac ~= 0
                        error('upper bound of integer range in not an integer');
                    end
                end
                if self.lowerBound ~= -Inf
                    lowerFrac = self.lowerBound - floor(self.lowerBound);
                    if lowerFrac ~= 0
                        error('lower bound of integer range in not an integer');
                    end
                end
            end
        end
        
        function [value,flag,msg] = validationFunc(self,value)
            % Validate the given value
            
            if isempty(value)
                % Value is empty - return true. Only apply validatation if
                % the user actually sets a value.
                flag = true;
                msg = '';
                return;
            end
            
            try
                % Truncate to insure that value is an integer
                value = truncFloatString(value);
            catch ME
                flag = false;
                msg = sprintf('unable to convert value to number: %s', ME.message);
                return;
            end
            
            % Apply parent class validation 
            [value,flag,msg] = validationFunc@NumericValidator(self,value);
        end
        
        function value = getValidValue(self)
            % Returns a valid value.
            value = getValidValue@NumericValidator(self);
            value = truncFloatString(value);
        end
        
        function numValues = getNumValues(self)
            % Return number of possible values
            if self.hasBounds == false
                numValues = Inf;
            else
                numValues = abs(self.upperBound - self.lowerBound) + 1;
                if strcmp(self.lowerBoundType,'exclusive')
                    numValues = numValues - 1;
                end
                if strcmp(self.upperBoundType,'exclusive')
                    numValues = numValues - 1;
                end
            end
        end
        
        function test = isFiniteRange(self)
            % Tests if range of possible values is finite.
            numValues = self.getNumValues();
            if numValues < Inf
                test = true;
            else
                test = false;
            end
        end
        
        function valueArray = getValues(self)
           % Returns array of possible values if range is finite, otherwise
           % returns an empty array.
           if self.isFiniteRange() == true
               switch self.lowerBoundType
                   case 'inclusive'
                       lowerValue = self.lowerBound;
                   case 'exclusive'
                       lowerValue = self.lowerBound+1;
                   otherwise
                       error('unkown lowerBoundType %s', self.lowerBoundType);
               end
               
               switch self.upperBoundType
                   case 'inclusive'
                       upperValue = self.upperBound;
                   case 'exclusive'
                       upperValue = self.upperBound-1;
                   otherwise
                       error( ...
                           'unknown upperBoundType %s', ...
                           self.upperBoundType ...
                           );
               end
               % Create array of floating point values and convert to
               % strings.
               valueFloatArray = [lowerValue:upperValue];
               valueArray = cell(1,length(valueFloatArray));
               for i = 1:length(valueFloatArray)
                   valueArray{i} = num2str(valueFloatArray(i));
               end
           else
               %valueArray = [];
               valueArray = {};
           end
        end
        
    end
end % classdef IntegerValidator

% -------------------------------------------------------------------------
function valNew = truncFloatString(valOld)
% Truncates a floating point number represented as a string
val = str2num(valOld);
val = floor(val);
valNew = num2str(val);
end
