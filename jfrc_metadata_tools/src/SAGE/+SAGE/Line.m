classdef Line < handle
    % The Line class represents a genetic line.
    
    properties
        lab = ''
        name = ''
    end
    
    methods
        function obj = Line(lab, name)
            obj.lab = lab;
            obj.name = name;
        end
    end
end
