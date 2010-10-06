classdef PropertiesBuilder < handle
    % Class for Creating a JIDE property grid from a default data xml tree.
    %
    % Note, currently the JIDE grid will be broken with the option
    % hierarchy=false set. I missed some sublties here. Basically I think I
    % need to generate unique leaf names in this case because the
    % PropertyGrid class uses the name (assumed to be unique??) to set
    % update the field.
    % ---------------------------------------------------------------------
   
    properties
        defaultsTree = XMLDefaultsNode.empty();
        mode = 'basic';
        hierarchy = true;
    end
    
    properties (Constant, Hidden)
        integerMaxListSize = 100;
        stringMaxListSize = 10000;
        otherMaxListSize = 1000;
    end
    
    properties (Access = private)
       % Used to cache linename property types. As the number of linenames 
       % can be pretty big, 7000+,  this helps speed things up a bit 
       lineNameTypeCache = [];                        
    end
   
    methods
        
        function self = PropertiesBuilder(defaultsTree, mode, hierarchy)
            % Constructor
            if nargin > 0
                self.defaultsTree = defaultsTree.root;
            end
            if nargin > 1
                self.mode = mode;
            end
            if nargin > 2
                self.hierarchy = hierarchy;
            end
        end
        
        function properties = getProperties(self)
            % Set value validators and defaults based on mode.
            
            % DEBUG -------------------------------------------------------
            % Note, assumes value validators etc agree with mode and
            % hierarchy setting.
            % -------------------------------------------------------------
            
            % Get properties for JIDE property grid  
            properties = self.getNodeProperties(self.defaultsTree);
            if self.hierarchy == true
                properties = properties.GetHierarchy();
            end
        end
        
        function showTestFigure(self)
            % Create figure and add property grid.
            %properties = self.getProperties();
            fig = figure( ...
                'MenuBar', 'none', ...
                'Name', 'pgridTest', ...
                'NumberTitle', 'off', ...
                'Toolbar', 'none');
            pgrid = PropertyGrid(fig,'Position', [0 0 1 1]);
            pgrid.defaultsTree = self.defaultsTree;
            uiwait(fig);
        end
        
        function properties = getNodeProperties(self,node)
            % Gets the properties for JIDE Property Grid for given node and
            % all its children for the specified mode string = 'basic' or
            % 'advanced'
            %disp([node.indent,node.name]);
            if node.isLeaf() == true
                % Handle nodes which are leaves of the tree
                properties = self.getLeafProperties(node);
            else
                % Handle nodes which are not leaves of the tree
                properties = self.getNonLeafProperties(node);
            end
        end
        
        function properties = getLeafProperties(self,node)       
            % Gets the properties for JIDE property grid when the node is a 
            % leaf.
            if node.isLeaf() == false
                error('node must be leaf');
            end
            if node.getValueAppear(self.mode,self.hierarchy) == true
                % Node is set to appear get properties based on data type.
                if self.hierarchy == true
                    name = node.getPathString();
                else
                    name = node.uniqueName;
                end
                displayName = node.uniqueName;
                properties = self.getPropertiesByType(node,name,displayName);
            else
                properties = PropertyGridField.empty();
            end
        end
        
        function properties = getNonLeafProperties(self,node)
            % Get properties for JIDE grid when node is not a leaf.
            if node.isLeaf() == true
                error('node cannot be leaf');
            end
            valueAppear = node.getValueAppear(self.mode,self.hierarchy);
            if node.isRoot() == true || valueAppear == false
                properties = PropertyGridField.empty();
            else
                % Set property name and display name
                if self.hierarchy == true
                    name = node.getPathString();
                else
                    name = node.uniqueName;
                end
                displayName = node.uniqueName;
                
                if node.isContentNode()
                    % Special case for content nodes.
                    childNode = node.children(1);
                    properties = self.getPropertiesByType(childNode,name,displayName);
                else
                    % -----------------------------------------------------------------
                    % Note, if is apparatus may want to display some type information
                    %------------------------------------------------------------------
                    properties = PropertyGridField( ...
                        name, '', ...
                        'Category', node.root.name, ...
                        'DisplayName', displayName, ...
                        'ReadOnly', true, ...
                        'Description', node.getValueDescription() ...
                        );
                end
            end
            % Loop over all children calling getNodeProperties
            for i = 1:node.numChildren
                childNode = node.children(i);
                if strcmpi(childNode.name,'content')
                    continue
                else
                    childProperties = self.getNodeProperties(childNode);
                    if ~isempty(childProperties)
                        properties = [properties, childProperties];
                    end
                end
            end
        end
        
        function properties = getPropertiesByType(self,node,name,displayName)
            % Get JIDE grid properties based on leaf node datatype
            % Node is set to appear
            switch lower(node.getDataType())    
                case 'string'
                    properties = self.getPropertiesString(node,name,displayName);
                case {'float', 'integer', 'datetime'}
                    properties = self.getPropertiesList(node,name,displayName); 
                case 'time24'
                    properties = self.getPropertiesBasic(node,name,displayName);
                otherwise
                    properties = self.getPropertiesBasic(node,name,displayName);     
            end
        end
        
        function properties = getPropertiesString(self,node,name,displayName)
            % Get JIDE grid properties for string types - make list of values 
            % if number of values is less than maxListSize. Provides
            % caching for linenames. 
            numValues = node.valueValidator.getNumValues();
            readOnly = node.getReadOnly(self.mode);
            maxListSize = self.getMaxListSize(node);

            if numValues < maxListSize

                valueArray = node.valueValidator.getValues();
                if length(valueArray) == 1
                    % If only one value set readonly to true.
                    readOnly = true;
                end
                
                % Get property type 
                if strcmpi(node.valueValidator.rangeType,'$LINENAME')
                    % If is linename validator use cached value of
                    % properties if possible. 
                    if isempty(self.lineNameTypeCache)
                        propType = PropertyType('char','row',valueArray);
                        self.lineNameTypeCache = propType;
                    else
                        propType = self.lineNameTypeCache;
                    end
                else
                    % Not a linename validator - just create proptery type 
                    % as usual
                    propType = PropertyType('char','row',valueArray);      
                end
               
                properties = PropertyGridField( ...
                    name, node.value, ...
                    'Type', propType, ...
                    'Category', node.root.name, ...
                    'DisplayName', displayName, ...
                    'ReadOnly', readOnly, ...
                    'Description', node.getValueDescription() ...
                    );        
             
            else
                
                properties = PropertyGridField( ...
                    name, {node.value, ''}, ...
                    'Category', node.root.name, ...
                    'DisplayName', displayName, ...
                    'ReadOnly', readOnly, ...
                    'Description', node.getValueDescription() ...
                    );
                
                
            end
        end
        
        function properties = getPropertiesList(self,node,name,displayName)
           % Get JIDE grid properties - make list of values if number 
           % of values is less than maxListSize     
            numValues = node.valueValidator.getNumValues();
            readOnly = node.getReadOnly(self.mode);
            maxListSize = self.getMaxListSize(node);
            
            if numValues < maxListSize 
               
                valueArray = node.valueValidator.getValues();  
                if length(valueArray) == 1
                    % If only one value set readonly to true.
                    readOnly = true;
                end
                
                % Create property type.
                propType = PropertyType('char','row',valueArray);
               
                properties = PropertyGridField( ...
                    name, node.value, ...
                    'Type', propType, ...
                    'Category', node.root.name, ...
                    'DisplayName', displayName, ...
                    'ReadOnly', readOnly, ...
                    'Description', node.getValueDescription() ...
                    );        
            else
                % Don't make drop down list
                switch class(node.valueValidator)
                    
                    case 'StringValidator'
                        % Special case for strings to get popup edit box.
                        % Have look thought the PropertyGrid class there
                        % may be a better way to do this.
                        properties = PropertyGridField( ...
                            name, {node.value, ''}, ...
                            'Category', node.root.name, ...
                            'DisplayName', displayName, ...
                            'ReadOnly', readOnly, ...
                            'Description', node.getValueDescription() ...
                            );
                        
                    otherwise
                        % All other types
                        propType = PropertyType('char','row');
                        properties = PropertyGridField( ...
                            name, node.value , ...
                            'Type', propType, ...
                            'Category', node.root.name, ...
                            'DisplayName', displayName, ...
                            'ReadOnly', readOnly, ...
                            'Description', node.getValueDescription() ...
                            );
                end
            end
        end
        
        function properties = getPropertiesBasic(self,node,name,displayName)
            % Get JIDE grid properties - basic version, doesn't try to make
            % drop down lists.
            properties = PropertyGridField( ...
                name, node.value, ...
                'Category', node.root.name, ...
                'DisplayName', displayName, ...
                'ReadOnly', node.getReadOnly(self.mode), ...
                'Description', node.getValueDescription() ...
                );
        end
        
        function maxListSize = getMaxListSize(self,node)
            % Returns the maximum allowed list list for the given node data
            % type. 
            dataType = node.getDataType();
            switch lower(dataType)
                case 'integer'
                    maxListSize = self.integerMaxListSize;
                case 'string'
                    maxListSize = self.stringMaxListSize;
                otherwise
                    maxListSize = self.otherMaxListSize;
            end
        end
               
    end   
end % classdef PropertiesBuilder