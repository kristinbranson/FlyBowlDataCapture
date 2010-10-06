classdef BaseValidator < handle
    % Base class for all validators. Has a dummy validation function which
    % checks nothing and always returns true. Also has get valid value
    % function which returns an empty string. 
   methods
       function [value,flag,msg] = validationFunc(self,value)
           flag = true;
           msg = '';
       end
       function value = getValidValue(self)
           % Return a valid value.
           value = '';
       end
   end
end % classdef BaseValidator