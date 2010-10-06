classdef IntegerListValidator < BaseValidator
    % Used for validating lists of integer data. The range is set
    % using a range string argument. 
    % 
    % Note, this function isn't
    properties
       unique = false;
       rangeValidator = IntegerValidator.empty();
    end
    
    methods
        function self = IntegerListValidator(rangeString)
            % Class Constructor
            if nargin > 0
                self.setRange(rangeString);
            end
        end
        
        function setRange(self,rangeString)
            % Set the range of the validator using the range sting.
            rangeString = strtrim(rangeString);
            self.rangeValidator = IntegerValidator(rangeString);
        end
        
        function [value,flag,msg] = validationFunc(self,value)
            % Applies validation to the given value.
            if isempty(value)
                flag = true;
                msg = '';
                return;
            end
            if ~ischar(value)
                error('value must be a character array');
            end
            
            % Convert to cell array of values 
            try
                valueCell = charArrayToCellArray(value);
            catch ME
                flag = false;
                msg = ME.message;
                return;
            end
            
            % Check ranges of elements in list. 
            for i = 1:length(valueCell)
                listItem = valueCell{i};
                [value, flag, msg] = self.rangeValidator.validationFunc(listItem);
                if flag == false
                    return;
                end
            end
                  
            % Convert cell array back to character array
            value = cellArrayToCharArray(valueCell);
            flag = true;
            msg = '';

        end
        
        function value = getValidValue(self)
            % Returns a valid value 
            % -------------------------------------------------------------
            % DEBUG NOTE:  this is currently pretty random, but I don't
            % really have a good way to choose what to return
            % -------------------------------------------------------------
            value = '1,2,3,4,5';
        end
        
        function test = isFiniteRange(self)
            % Dummy function - range for integer list is always infinite. 
            test = false;
        end
        
        function values = getValues(self)
            % Dummy function - as range is always infinite always returns
            % an empty array
           values = {}; 
        end
               
    end
    
end

function charArray = cellArrayToCharArray(cellArray)
% Convert cell array of integer values (represented as strings) to a
% character array where the values are separaeted by commas.
if isempty(cellArray)
    charArray = '';
else
    charArray = cellArray{1};
    for i=2:length(cellArray)
        charArray = sprintf('%s, %s', charArray, cellArray{i});
    end
end
end

function cellArray = charArrayToCellArray(charArray)
% Convert a character array representing a integer list to a cell array of
% the values (as strings).
cellArray = {};
charArrayOrig = charArray;
charArray = [',', charArray, ','];
commaPos = findstr(charArray,',');
cnt = 0;
for i = 1:length(commaPos)-1
   n1 = commaPos(i)+1;
   n2 = commaPos(i+1)-1;
   value = strtrim(charArray(n1:n2));
   if isempty(value)
       if i~=(length(charArray)-1)
           error('incorrect format for integer list: %s', charArrayOrig);
       end
   else
       cnt = cnt+1;
       cellArray{cnt} = value;
   end
   if isempty(charArray)
       error('incorrect format for integer list: %s', charArrayOrig);
   end
end
end