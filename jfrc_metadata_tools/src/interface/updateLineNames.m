function updateLineNames()
% updateLineNames:  updates the linenames file used by jfrc_metadata_tools
% by downloading the current list of line names from SAGE.
% 
% Usage:  updateLineNames();
%   
cacher = SAGEDataCacher();
cacher.updateLineNamesFile();