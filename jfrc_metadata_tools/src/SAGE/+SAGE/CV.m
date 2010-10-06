classdef CV < handle
    % The CV class represents a set of controlled vocabulary terms.
    %
    % >> cv = SAGE.CV('effector');
    % >> effectors = cv.terms();
    % >> cv.displayName
    % 
    % ans = 
    % 
    % Effector
    
    properties
        name = ''           % The unique identifier of the CV.
        displayName = ''    % The human-readable name of the CV.
        definition = ''     % A human-readable definition of the CV useful in, for example, tooltips.
    end
    
    properties (Access = private)
        cvTerms = SAGE.CVTerm.empty(0, 0);
        termsFetched = false;
    end
    
    methods
        
        function obj = CV(name, displayName, definition)
            % Create or lookup a CV object.
            % If only a name is given then an existing CV will be looked up.
            if nargin == 3
                % Create a new instance.
                obj.name = name;
                obj.displayName = displayName;
                obj.definition = definition;
            else
                % Lookup an existing instance.
                cvs = SAGE.cvs();
                foundCV = false;
                for cv = cvs
                    if strcmp(cv.name, name)
                        obj = cv;
                        foundCV = true;
                        break
                    end
                end
                
                if ~foundCV
                    error(['There is no CV named ''' name ''' in SAGE.'])
                end
            end
        end
        
        function list = terms(obj)
            % Return the list of terms in the controlled vocabulary.
            %
            % >> cv = SAGE.CV('effector');
            % >> effectors = cv.terms();
            % >> effectors(1).displayName
            % 
            % ans = 
            % 
            % GFP
            %
            % The list of terms is cached, call the refreshTerms method to update the list.
            
            if ~obj.termsFetched
                xmlDoc = xmlread([SAGE.urlBase 'cvs/' obj.name '/with-object-related-cvs.janelia-sage?relationshipType=is_sub_cv_of']);
                termElems = xmlDoc.getElementsByTagName('term');
                obj.cvTerms = SAGE.CVTerm.empty(termElems.getLength(), 0);
                for i = 0:termElems.getLength()-1
                    termElem = termElems.item(i);
                    termName = ''; termDisplayName = ''; termDefinition = '';
                    childElems = termElem.getChildNodes();
                    for j = 0:childElems.getLength()-1
                        childElem = childElems.item(j);
                        if childElem.getNodeType() == 1
                            if strcmp(childElem.getTagName(), 'name')
                                termName = char(childElem.getTextContent());
                            elseif strcmp(childElem.getTagName(), 'displayName')
                                termDisplayName = char(childElem.getTextContent());
                            elseif strcmp(childElem.getTagName(), 'definition')
                                termDefinition = char(childElem.getTextContent());
                            end
                        end
                    end
                    obj.cvTerms(i+1) = SAGE.CVTerm(obj, termName, termDisplayName, termDefinition);
                end
                
                obj.termsFetched = true;
            end
            list = obj.cvTerms;
        end
        
        function refreshTerms(obj)
            % Fetch the current list of terms from SAGE.
            obj.termsFetched = false;
            obj.terms();
        end
        
    end
    
end
