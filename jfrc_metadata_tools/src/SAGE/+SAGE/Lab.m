classdef Lab < handle
    % The Lab class represents a lab or group project.
    %
    % >> lab = SAGE.Lab('rubin');
    % >> lab.displayName
    % 
    % ans = 
    % 
    % Rubin Lab
    % 
    % >> lines = lab.lines();
    % >> length(lines)
    % 
    % ans = 
    % 
    %         7864
    
    properties
        name = ''
        displayName = ''
    end
    
    properties (Access = private)
        labLines = SAGE.Line.empty(0, 0);
        linesFetched = false;
    end
    
    methods
        function obj = Lab(name, displayName)
            % Create or lookup a Lab object.
            % If only a name is given then an existing lab will be looked up.
            if nargin == 2
                % Create a new instance.
                obj.name = name;
                obj.displayName = displayName;
            else
                % Lookup an existing instance.
                labs = SAGE.labs();
                foundLab = false;
                for lab = labs
                    if strcmp(lab.name, name)
                        obj = lab;
                        foundLab = true;
                        break
                    end
                end
                
                if ~foundLab
                    error(['The ''' name ''' lab does not exist in SAGE.'])
                end
            end
        end
        
        function list = lines(obj, query)
            % Return a list of the lines for the lab.
            %
            % lines() returns all lines for the lab.
            % lines(S) returns all lines whose name contains that match the pattern S (case sensitive).  The pattern can contain asterisks to do wildcard searches.
            %
            % >> lab = SAGE.Lab('rubin');
            % >> lines = lab.lines('*61A*');    % Find lines containing '61A'
            % >> lines(11).name
            % 
            % ans = 
            % 
            % GMR_61A11_AD_01
            % 
            % >> lines = lab.lines('*_AD_01');  % Find lines ending with '_AD_01'
            % >> length(lines)
            % 
            % ans = 
            % 
            %     64
            %
            % The complete list of lines is cached, call the refreshLines method to update the list.  Querying by substring always returns the latest information.
            
            if nargin == 2
                % TBD: if we have already fetched the complete list of lines is it faster to query locally?
                xmlDoc = xmlread([SAGE.urlBase 'lines/' obj.name '.janelia-sage?q=name%3D' char(java.net.URLEncoder.encode(query, 'UTF-8'))]);
                list = obj.linesFromXML(obj, xmlDoc);
            else
                if ~obj.linesFetched
                    xmlDoc = xmlread([SAGE.urlBase 'lines/' obj.name '.janelia-sage']);
                    obj.labLines = obj.linesFromXML(obj, xmlDoc);
                    obj.linesFetched = true;
                end
                list = obj.labLines;
            end
        end
        
        function refreshLines(obj)
            % Fetch the current list of lines from SAGE.
            obj.linesFetched = false;
            obj.lines();
        end
    end
    
    methods (Static, Access = private)
    
        function list = linesFromXML(lab, xmlElement)
            lineElems = xmlElement.getElementsByTagName('name');
            list = SAGE.Line.empty(lineElems.getLength(), 0);
            for i = 0:lineElems.getLength()-1
                lineElem = lineElems.item(i);
                list(i+1) = SAGE.Line(lab, char(lineElem.getTextContent()));
            end
        end
    
    end
end
