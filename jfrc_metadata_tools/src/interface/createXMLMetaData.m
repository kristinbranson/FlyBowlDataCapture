function metaDataTree = createXMLMetaData(defaultsTree)
% Creates XML metadata tree from the XML defaults data tree.
%
% Arguments:
%   defaultsTree = defaults data tree. 
%
% Output:
%   metaDataTree = metadata tree. 
% 
% -------------------------------------------------------------------------
defaultsTree = defaultsTree.root; % Make sure to start from the tree root
metaDataTree = createXMLDataNode(defaultsTree,XMLDataNode.empty());
metaDataTree.assignUniqueNames();


function dataNode = createXMLDataNode(defaultsNode,parent)
% Creates a XML metadata node from a defaults data node. This functin calls 
% itself recursively for child nodes of the defaults node which represent 
% subelements of the XML meta data, i.e., those which don't represent 
% attributes or node content. Notes, nodes of the default data represent
% attributes or content if they are leaves (have no children). 
dataNode = XMLDataNode();
dataNode.name = defaultsNode.name;
dataNode.parent = parent;
for i = 1:defaultsNode.numChildren 
    defaultsChild = defaultsNode.children(i);
    if defaultsChild.isLeaf()
        % Child is represents an attribute or Content in metadata.
        switch lower(defaultsChild.name) 
            case 'content'
                % defaultsChild represents node content. Add content
                % to dataNode.
                dataNode.setContent(defaultsChild.value);
            otherwise
                % defaultsChild represents an attribute. Add attrubute
                % to dataNode.
                attribName = defaultsChild.name;
                attribValue = defaultsChild.value;
                dataNode.addAttribute(attribName, attribValue);
        end
    else
        % Child is sub element
        dataNodeChild = createXMLDataNode(defaultsChild,dataNode);
        dataNode.addChild(dataNodeChild);
    end
    
end
