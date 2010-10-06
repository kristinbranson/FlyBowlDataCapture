function list = labs()
    % Return the list of all known labs.
    %
    % >> labs = SAGE.labs();
    % >> labs(1).displayName
    % >> 
    % >> ans = 
    % >> 
    % >> Baker Lab
    
    persistent labs;
    
    if isempty(labs)
        xmlDoc = xmlread([SAGE.urlBase 'lines.janelia-sage']);
        labElems = xmlDoc.getElementsByTagName('lineLab');
        labs = SAGE.Lab.empty(labElems.getLength(), 0);
        for i = 0:labElems.getLength()-1
            labElem = labElems.item(i);
            labName = ''; labDisplayName = '';
            childElems = labElem.getChildNodes();
            for j = 0:childElems.getLength()-1
                childElem = childElems.item(j);
                if childElem.getNodeType() == 1
                    if strcmp(childElem.getTagName(), 'name')
                        labName = char(childElem.getTextContent());
                    elseif strcmp(childElem.getTagName(), 'displayName')
                        labDisplayName = char(childElem.getTextContent());
                    end
                end
            end
            labs(i+1) = SAGE.Lab(labName, labDisplayName);
        end
    end
    
    list = labs;
end
