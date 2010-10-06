classdef XMLDataNode < handle
    % Encapsultates a node (or element) of xml data. The nodes can be used
    % to create a tree representing the structure of an XML file.
    % 
    % More ...
    
    properties
        name = '';
        parent; 
        children; 
        attribute = struct;
        content =[];
        uniqueName;
    end
   
    properties (Dependent)
        numNodes;
        numChildren;
        childNames;
        uniqueChildNames;
        numAttribute;
        attributeNames;
        root;
        pathFromRoot;
        uniquePathFromRoot;
        depth;
    end
    
    properties (GetAccess=protected,Constant)
        printIndentNum = 3;
    end
    
    properties %(Access=private)
        mark = false;  
    end
    
    methods
        
        function self = XMLDataNode()
            % Class constructor. 
            self.parent = self.createEmptyNode();
            self.children = self.createEmptyNode();
        end
        
        function child = createChild(self)
            % Creates a child node. This is method should be implemented by
            % classes which inherit from the XMLDataNode class so that
            % child nodes of the same class are created when using
            % nodeFromStruct to create trees, etc.
            child = XMLDataNode();
        end
        
        function node = createEmptyNode(self)
            % Creates an empty object array. This method should be
            % implemented by classes which inherit from the XMLDataNode so
            % that the empty oject arrays, of children for example, are of 
            % the same class as the parent.
            node = XMLDataNode.empty();
        end
        
        function treeFromStruct(self,xmlStruct)
            % Create an xml data tree from an xml structure, also, assigns
            % children unique names. 
           self.nodeFromStruct(xmlStruct);
           self.assignUniqueNames();
        end
        
        function nodeFromStruct(self, xmlStruct)
            % This function should be made protected.
            % 
            % Creates nodes given the xml structure loaded via the xml_read
            % function in the xml_io_tools library.
            
            % Set attribute, content, etc. Note, I'm ignoring CDATA and
            % PROCESSING_INSTRUCTIONS fields. As they should not be present
            % if the structure from the xml file was read with
            % Pref.ReadSpec = false.
            if isfield(xmlStruct,'ATTRIBUTE')
                self.attribute = xmlStruct.ATTRIBUTE;
            end
            if isfield(xmlStruct, 'CONTENT')
                self.content = xmlStruct.CONTENT;
            end
            
            % Use remaining fields (other than ATTRIBUTE, CONTENT, etc) to create child
            % nodes by recursively call nodeFromStruct to create entire tree.
            fields = fieldnames(xmlStruct);
            for i = 1:length(fields)
                fieldname = fields{i};
                if strcmp(fieldname,'ATTRIBUTE')
                    continue;
                end
                if strcmp(fieldname,'CONTENT')
                    continue;
                end
                if strcmp(fieldname,'CDATA_SECTION')
                    continue;
                end
                if strcmp(fieldname,'PROCESSING_INSTRUCTIONS')
                    continue;
                end
                
                data = xmlStruct.(fieldname);
                if isstruct(data) || iscell(data)
                    % Data is struct array or cell array - loop over to get children.
                    for j = 1:length(data)
                        if isstruct(data)
                            child_xmlStruct = data(j);
                        else
                            child_xmlStruct = data{j};
                        end
                        childNode = self.createChild();
                        childNode.name = fieldname;
                        childNode.parent = self;
                        childNode.nodeFromStruct(child_xmlStruct);
                        self.addChild(childNode,false);
                    end
                else
                    % Data is not an array - create single child node.
                    childNode = self.createChild();
                    childNode.name = fieldname;
                    childNode.parent = self;
                    childNode.content = data;
                    self.addChild(childNode,false);
                end
            end
        end
        
        function [xmlStruct, name] = getXMLStruct(self)
            % Returns a structure (xmlStruct) which represents the tree
            % consisting of the current node and all nodes which are below
            % it. The structure xmlStruct is designed to be consistent with
            % The representation of XML file used by the xml_io_tools
            % library and specifically the xml_write and xml_read
            % functions. In addition to xmlStruct the name of the current
            % node is also returned.
            
            %disp([self.indent, self.name]);
            
            % Ensure that children have been given unique names.
            if self.numChildren ~= length(self.uniqueChildNames)
                self.root.assignUniquenames();
            end
           
            xmlStruct = struct;
            name = self.name;
            % Assign current node's data to xmlStruct
            if ~isempty(self.attribute)
                xmlStruct.ATTRIBUTE = self.attribute;
            end
            if ~isempty(self.content)
                xmlStruct.CONTENT = self.content;
            end
            % Loop over the current node's children and get thier xml
            % structures. Note, this function recursively calls itself until
            % the entire tree below this node has been covered.
            for i = 1:self.numChildren
                childNode = self.children(i);
                child_xmlStruct = childNode.getXMLStruct();
                if isfield(xmlStruct,childNode.name)
                    n = length(xmlStruct.(childNode.name));
                    xmlStruct.(childNode.name){n+1} = child_xmlStruct;
                else
                    xmlStruct.(childNode.name) = {child_xmlStruct};
                end
                
            end    
        end
               
        function addChild(self,childNode,assignUnique)
            % Adds a child node to the current node of the tree. The
            % optional argment assignUnique specifies whether or not unique
            % names are assigned/reassigned to the children (and their
            % children) of the current node. In general when adding alot of
            % nodes, say when building the tree, users will want to use
            % assignUnique = false and then explicitly call the method
            % assignUniqueNames to give uniques names to the nodes at each
            % level of the tree. This reduced significantly the amount of 
            % computation done. The default value for assignUnique is
            % false.
            if nargin == 2
                assignUnique = false;
            end  
            % Adds a child node to the current node.   
            self.children(self.numChildren+1) = childNode;
            childNode.parent = self;
            % Assign unique names to all child nodes.
            if assignUnique == true
                self.assignUniqueChildren();
            end 
        end
        
        function rmChild(self,index,assignUnique)
            % Removes a child node (and all nodes beneath it) from the
            % the current node. The optional argment assignUnique specifies 
            % whether or not the unique names are recalculated for the
            % current node after removal of the child node. The defualt
            % value for assignUnique is false.
            if nargin == 2
                assignUnique = false;
            end
            if self.numChildren >= index
                childNode = self.children(index);
                for i = childNode.numChildren:-1:1
                    childNode.rmChild(i);
                end
                delete(childNode);        
                self.children = self.createEmptyNode();
            end
            if assignUnique == true
                self.assignUniqueChildren();
            end
        end
        
        function children = getChildrenByName(self,name)
            % Returns an object array of all children of the current node 
            % with the given name.
            cnt = 0;
            children = self.createEmptyNode();
            for i = 1:self.numChildren
                childname = self.children(i).name;
                if strcmp(childname,name)
                   cnt = cnt+1;
                   children(cnt) = self.children(i);
                end
            end
        end
        
        function addAttribute(self,name,value)
            % Adds an attribute to the current node.
            self.attribute.(name) = value;
        end
        
        function rmAttribute(self,name)
            % Removes an attribute from the current node
            self.attribute = rmfield(self.attribute,name);
        end
        
        function setContent(self,value)
            % Sets a nodes content.
            self.content = value;
        end
        
        function rmContent(self)
            % Deletes the nodes content.
            self.content = [];
        end
              
        function num = getNumNodesBelow(self)
            % Returns the number of nodes in the tree below this node
            num = self.numChildren;
            for i = 1:self.numChildren
                child = self.children(i);
                num = num + child.getNumNodesBelow();
            end
        end
        
        function test = isRoot(self)
            % Tests if the current node is the root node of the tree.
            test = isempty(self.parent);
        end
        
        function pathFromRoot = getPathFromRoot(self)
            % Returns a cell array containing the path, in element names,
            % from the root of the tree to the current node.
            if self.isRoot()
                pathFromRoot = {self.name};
            else
                parentPath = self.parent.getPathFromRoot();
                pathFromRoot = {parentPath{:},self.name};
            end
        end
        
        function uniquePath = getUniquePathFromRoot(self)
            % Returns a cell array containing the path, in unique element
            % name from the root of the tree to the current node.
           if self.isRoot()
               uniquePath = {self.uniqueName};
           else
               parentPath = self.parent.getUniquePathFromRoot();
               uniquePath = {parentPath{:},self.uniqueName};
           end
        end
      
        function print(self,uniqueName)
            % Prints all nodes below and including the current node.
            % uniqueName allows users to select whether or not unique
            % node names are used for printing the node. 
            if nargin == 1
                uniqueName = false;
            end 
            self.printNode(uniqueName);    
            for i = 1:self.numChildren
                child = self.children(i);
                child.print(uniqueName);
            end
        end
        
        function printFromRoot(self)
            % Prints all nodes in the tree.
            self.root.print();
        end
        
        function printNode(self,uniqueName)
             % Prints the current node's data. The uniqueName options
             % allows users to select whether or not unique names are used 
             % when displaying the nodes name.
            if nargin == 1
                uniqueName = false;
            end
            if uniqueName
                name = self.uniqueName;
            else
                name = self.name;
            end
            fprintf('%s* Node(d%d): %s\n',self.indent, self.depth, name);
            self.printAttribute();
            self.printContent();
        end
          
        function printAttribute(self)
            % Print the current nodes attributes
            %
            % Note, I added the isstruct test because when testing the
            % class an ramdom xml files downloaded from the web I
            % encountered some for which the attributes in the xmlStruct
            % returned by xml_read was not a strucuture. I don't think this
            % will be an issue for the metadata files.
            if isstruct(self.attribute)
                for i = 1:self.numAttribute
                    name = self.attributeNames{i};
                    value = self.attribute.(name);
                    disp([self.indent,'  Attribute: ', name, ', ', value]);
                end
            else
                disp([self.indent,'  Attribute: ']);
                disp(self.attribute);
            end
        end
        
        function printContent(self)
            % Print the content of a node
            if ~isempty(self.content)
                content = self.content;
                disp([self.indent,'  Content: ', content]);
            end
        end
        
        function depth = getDepth(self)
            % Returns depth of the node in the tree. Note, the depth is the
            % distance of the node to the root node.
           if self.isRoot()
               depth = 0;
           else
               depth = self.parent.getDepth() + 1;
           end
        end
        
        function assignUniqueNames(self)
            % Assign names to nodes in the tree which are unique at each
            % level of the tree. Thus the names will be such that no two
            % nodes at the same level have the same name. Note, that nodes
            % at different levels in the tree may still have the same names.
            self.root.uniqueName = self.root.name;
            self.root.assignChildrenUniqueName();
        end
        
        function assignChildrenUniqueName(self)
            % Assign children of a node, and all its childrens' children, 
            % etc. Unique names for their level in the tree. The assigned 
            % names are such that no two nodes at the same level have the 
            % same name. Note, that nodes at different levels in the tree 
            % may still have the same names.
            childNames = self.childNames;
            for i = 1:length(childNames)
                name = self.childNames{i};
                childrenWithName = self.getChildrenByName(name);
                if length(childrenWithName) == 1
                    % Only one child has this name don't number
                    child = childrenWithName(1);
                    child.uniqueName = child.name;
                    child.assignChildrenUniqueName();
                else
                    % More than one child has this name number children
                    for j = 1:length(childrenWithName)
                        child = childrenWithName(j);
                        child.uniqueName = sprintf('%s_%d',child.name,j);
                        child.assignChildrenUniqueName();
                    end
                end
            end
        end
        
        function setMarks(self,value)
            % Sets all marks on the tree given by the current node and all 
            % nodes below its to the logical (true/false) value.
            assert(islogical(value), 'value must be locigal (true/false)');
            self.mark = value;
            for i = 1:self.numChildren
               child = self.children(i);
               child.setMarks(value);
            end
        end
        
        function setMarksTrue(self)
            % Sets all marks on the tree given by the current node and all
            % marks below it to true.
            self.setMarks(true);
        end
        
        function setMarksFalse(self)
            % Sets all marks on the tree given by the current node and all 
            % nodes below it to false.
            self.setMarks(false);
        end
        
        function node = getNodeByRelPath(self,path)
            % Get a node below the current node in the tree specified by a list of 
            % unique names relative to that node.       
            if isempty(path)
                node = self;
                return;
            end
            pathName = path{1};
            for i = 1:self.numChildren
                childName = self.uniqueChildNames{i};
                if strcmp(pathName, childName)
                    childNode = self.children(i);
                    childPath = {path{2:end}};
                    node = childNode.getNodeByRelPath(childPath);
                    return;
                end
            end
            error('unable to find child of node %s with name %s',self.uniqueName,pathName);
        end
        
        function node = getNodeByUniquePath(self,path)
            % Returns a node using the unique path name from the root node.
            rootNode = self.root;
            relPath = {path{2:end}};
            node = rootNode.getNodeByRelPath(relPath);
        end
           
        function indent = indent(self)
            % Returns indentation string based on node depth for pretty
            % printing node information.
            indent = blanks(self.depth*self.printIndentNum);
        end
        
        function walk(self, fhandle, varargin)
            % Walks tree in depth first manner apply function fhandle to
            % each node in the tree below and including the current node.
            fhandle(self,varargin{:});
            for i=1:self.numChildren
                child = self.children(i);
                child.walk(fhandle,varargin{:});
            end
        end
        
        function write(self,filename)
            % Writes the data tree containing the current node and all
            % nodes below it to an xml file.
            [xmlStruct, name] = self.getXMLStruct();
            wPref.StructItem = false;
            wPref.CellItem = false;
            wPref.XmlEngine = 'Xerces';
            xml_write(filename, xmlStruct, name, wPref);
        end
              
        function pathString = getPathString(self)
            % Creates a path name string name for use with JIDE Property 
            % Grids. The name consists of the unique path from the root
            % node of the tree to the node self with the name of the root 
            % node omitted. 
            if self.isRoot()
                pathString = '';
            else
                pathFromRoot = self.uniquePathFromRoot;
                pathCell = {pathFromRoot{2:end}};
                pathString = pathCell{1};
                for i=2:length(pathCell)
                    pathString = [pathString, '.', pathCell{i}];
                end   
            end
        end
                
        function test = isLeaf(self)
            % Tests whether or not the node self is a leaf of the tree.
            if self.numChildren == 0
                test = true;
            else
                test = false;
            end
        end
        
        function leaves = getLeaves(self)
            % Get object array containing all leaves below the current node
           if self.isLeaf()
               leaves = self;
           else
               leaves = self.createEmptyNode();
               cnt = 0;
               for i = 1:self.numChildren
                  child = self.children(i);
                  childLeaves = child.getLeaves();
                  for j = 1:length(childLeaves)
                      cnt = cnt + 1;
                      leaves(cnt) = childLeaves(j);
                  end
               end
           end
        end
        
        % set/get methods -------------------------------------------------
        function depth = get.depth(self)
            % Returns the depth of the current node.
           depth = self.getDepth();
        end
        
        function num = get.numNodes(self)
            % Returns the total number of nodes in the tree.
            root = self.root;
            num = root.getNumNodesBelow() + 1;
        end
        
        function root = get.root(self)
            % Returns the root node of the tree.
            currentNode = self;
            parentNode = currentNode.parent;
            while ~isempty(parentNode)
                currentNode = parentNode;
                parentNode = currentNode.parent;
            end
            root = currentNode;    
        end
        
        function pathFromRoot = get.pathFromRoot(self)
            % Returns a cell array containing the path, in element names,
            % from the tree root to the current node.
           pathFromRoot = self.getPathFromRoot(); 
        end
        
        function uniquePath = get.uniquePathFromRoot(self)
            % Returns a cell array containing the path, in unique element
            % names from the root of the tree to the current node.
            uniquePath = self.getUniquePathFromRoot();
        end
        
        function num = get.numChildren(self)
            % Returns the number of children of the current node.
            num = length(self.children);
        end
        
        function names = get.childNames(self)
            % Returns a cell array containing the names of all the children
            % of the current node.
           names = cell(1,self.numChildren);
           for i=1:self.numChildren
               names{i} = self.children(i).name;
           end
           names = unique(names);
        end
        
        function names = get.uniqueChildNames(self)
           % Returns a cell array containing the unique names of all the 
           % children of the current node.
           names = cell(1,self.numChildren);
           for i=1:self.numChildren
               names{i} = self.children(i).uniqueName;
           end
        end
        
        function num = get.numAttribute(self)
            % Returns the number of attributes of the current node.
            %
            % Note, I added the isstruct test because when testing the
            % class an ramdom xml files downloaded from the web I
            % encountered some for which the attributes in the xmlStruct
            % returned by xml_read was not a strucuture. I don't think this
            % will be an issue for the metadata files.
            if isstruct(self.attribute)
                num = length(fieldnames(self.attribute));
            else
                num = 1;
            end
        end
        
        function names = get.attributeNames(self)
            % Returns a cell array containing the names of all the 
            % attributes of the current node.
            names = fieldnames(self.attribute);
        end
  
    end
end % classdef XMLDataNode



