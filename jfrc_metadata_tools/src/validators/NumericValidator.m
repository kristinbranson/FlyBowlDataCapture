classdef NumericValidator < BaseValidator
    % Used for validating numeric data (floats,integers). The range is set 
    % using a range string argument. Validation consists of checking that 
    % the values are within a given range which can be inclusive of 
    % exclusive of the end points.
    properties
        lowerBoundType; % inclusive, exclusive
        upperBoundType; % inclusive, exclusive
        lowerBound; 
        upperBound;
        hasBounds = false;
        stepSize = eps;
    end
    
    methods
        
        function self = NumericValidator(rangeString)
            % Class Constructor
            if nargin > 0       
                self.setRangeAndOptions(rangeString);
            end
        end
        
        function setRangeAndOptions(self,rangeString)
            % Sets upper and lower bounds and the range options base on
            % range string.
            if isempty(rangeString)
                self.hasBounds = false;
                self.stepSize = eps;
            end
            rangeString = self.setOptions(rangeString);
            self.setRange(rangeString);
        end
 
        function setRange(self, rangeString)
            % Set upper and lower bounds of validator based on the rangeString.
            if isempty(rangeString)
                % range string is empty - this means there are no bounds.
                self.hasBounds = false;
            else             
                rangeString = strtrim(rangeString);
                self.setRangeTypes(rangeString);
                self.setRangeValues(rangeString);
                self.hasBounds = true;
            end
        end
        
        function rangeString = setOptions(self,rangeString)
            % Get floating point options such as stepSize.
            if isempty(rangeString)
                return;
            end
        end
        
        function setRangeValues(self,rangeString)
            % Get lower and upper bound values
            if isempty(rangeString)
                self.lowerBound = -Inf;
                self.upperBound = Inf;
            else
                [lowerString, upperString] = self.getRangeStrings(rangeString);
                lowerValue = str2num(lowerString);
                if isempty(lowerValue)
                    error('unable to parse range string - lower bound is not a number');
                end
                upperValue = str2num(upperString);
                if isempty(upperValue)
                    error('unable to parse range string - upper bound is not a number');
                end
                if lowerValue > upperValue
                    error('lower bound is greater than upper bound');
                end
                self.lowerBound = lowerValue;
                self.upperBound = upperValue;
            end 
        end
        
        function setRangeTypes(self,rangeString)
            % Get type of upper and lower bounds.
            rangeString = strtrim(rangeString);
            if isempty(rangeString)
                self.lowerBoundType = 'inclusive';
                self.upperBoundType = 'inclusive';
            else
                % Use first and last characters to determine if bounds are
                % inclusive or exclusive.
                firstChar = rangeString(1);
                switch firstChar
                    case '['
                        self.lowerBoundType = 'inclusive';
                    case '('
                        self.lowerBoundType = 'exclusive';
                    otherwise
                        error('range string has illegal first character %s', firstChar);
                end
                lastChar = rangeString(end);
                switch lastChar
                    case ']'
                        self.upperBoundType = 'inclusive';
                    case ')'
                        self.upperBoundType = 'exclusive';
                    otherwise
                        error('range string has illegal last character %s', lastChar);
                end
            end
        end
        
        function [lowerString, upperString] = getRangeStrings(self, rangeString)
            rangeString = strtrim(rangeString);
            % Find comma position and get lower and upper bound values.
            commaPos = findstr(rangeString,',');
            if isempty(commaPos)
                error('range string format unrecognized - no comma');
            end
            if length(commaPos) > 1
                error('range string format unrecognized - too many commas');
            end
            lowerString = rangeString(2:commaPos-1);
            if isempty(lowerString)
                error('unable to parse range string - lower bound string empty');
            end
            upperString = rangeString(commaPos+1:end-1);
             if isempty(upperString)
                error('unable to parse range string - upper bound string empty');
            end
            
        end
        
        function [value,flag, msg] = validationFunc(self,value)
            % Applies validation to the given value.
            
            % Check that we can convert value to number.
            valueFloat = str2num(value);
            if isempty(valueFloat)
                flag = false;
                msg = 'unable to convert value to number';
                return;
            end
            
            if self.hasBounds == false
                % There are no bounds, any number is ok.
                flag = true;
                msg = '';
                return;
            end
                
            % Value is number and we have bounds - check them
            flag = true;
            msg = '';
            
            % Check upper bound.
            switch self.lowerBoundType
                case 'inclusive'
                    if valueFloat < self.lowerBound
                        flag = false;
                        msg = 'value less than lower bound';
                        return;
                    end
                case 'exclusive'
                    if valueFloat <= self.lowerBound
                        flag = false;
                        msg = 'value less than or equal to upper bound';
                        return;
                    end 
                otherwise
                    error('unknown lower bound type');
            end
                
            % Check lower bound.
            switch self.upperBoundType
                case 'inclusive'
                    if valueFloat > self.upperBound
                        flag = false;
                        msg = 'value greater than upper bound';
                        return;
                    end
                case 'exclusive'
                    if valueFloat >= self.upperBound
                        flag = false;
                        msg = 'value greater than or equal to upper bound';
                        return;
                    end
                otherwise
                    error('unknown upper bound type');
            end
             
        end
        
        function value = getValidValue(self)
            % Return a valid value. Currently this is a bit of a kludge,
            % as I'm not really picking the values intelligently.
            if (self.lowerBound == -Inf) && (self.upperBound == Inf)
                value = 0.0;
            elseif self.lowerBound == -Inf
                % Lower bound is -Inf, but upper bound is not Inf
                value = self.upperBound - 1.0;
            elseif self.upperBound == Inf
                % Upper bound is Inf, but lower bound is not -Inf
                value = self.lowerBound + 1.0;
            else
                % neither bound is Inf - pick middle. 
                value = 0.5*(self.lowerBound + self.upperBound);
            end
            value = num2str(value);   
        end
        
        function test = isFiniteRange(self)
            % Test if range of values is finite. Currently this always
            % returns false. This could change if we implement some special
            % options. 
           test = false; 
        end
        
        function numValues = getNumValues(self)
            % Get number of possible values - current always return Inf.
            % This could change if we implement some special options.
            numValues = Inf;
        end
        
    end
end % classdef NumericValidator