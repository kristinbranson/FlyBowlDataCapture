classdef CVTerm < handle
    properties
        cv = ''
        name = ''
        displayName = ''
        definition = ''
    end
    
    methods
        function obj = CVTerm(cv, name, displayName, definition)
            obj.cv = cv;
            obj.name = name;
            obj.displayName = displayName;
            obj.definition = definition;
        end
    end
end