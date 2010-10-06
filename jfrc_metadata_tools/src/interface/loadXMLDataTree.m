function [tree, xmlStruct] = loadXMLDataTree(filename)
% Loads and XML Data file into a tree based on the XMLDataNode class from 
% the given xml file.
% 
% Arguments:
%  filename: the name of the xml file to read
%
% -------------------------------------------------------------------------

% Read xml file to xmlStruct using xml_io_tools
wPref.NoCells = false;
wPref.ReadSpec = false;
wPref.Str2Num = 'never';
[xmlStruct, name_cell] = xml_read(filename,wPref);
name = name_cell{1};

% Create xml tree
tree = XMLDataNode();
tree.name = name;
tree.treeFromStruct(xmlStruct);
