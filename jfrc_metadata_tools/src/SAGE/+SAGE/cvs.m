function list = cvs()
    % Return the list of all known controlled vocabularies.
    %
    % >> cvs = SAGE.cvs();
    % >> cvs(1).displayName
    % >> 
    % >> ans = 
    % >> 
    % >> Age
    
    persistent cvs;
    
    if isempty(cvs)
        xmlDoc = xmlread([SAGE.urlBase 'cvs.janelia-sage']);
        cvElems = xmlDoc.getElementsByTagName('cv');
        cvs = SAGE.CV.empty(cvElems.getLength(), 0);
        for i = 0:cvElems.getLength()-1
            cvElem = cvElems.item(i);
            cvName = ''; cvDisplayName = ''; cvDefinition = '';
            childElems = cvElem.getChildNodes();
            for j = 0:childElems.getLength()-1
                childElem = childElems.item(j);
                if childElem.getNodeType() == 1
                    if strcmp(childElem.getTagName(), 'name')
                        cvName = char(childElem.getTextContent());
                    elseif strcmp(childElem.getTagName(), 'displayName')
                        cvDisplayName = char(childElem.getTextContent());
                    elseif strcmp(childElem.getTagName(), 'definition')
                        cvDefinition = char(childElem.getTextContent());
                    end
                end
            end
            cvs(i+1) = SAGE.CV(cvName, cvDisplayName, cvDefinition);
        end
    end
    
    list = cvs;
end
