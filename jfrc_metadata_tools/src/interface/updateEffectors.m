function updateEffectors()
% updateEffectors: updates the effectors file used by jfrc_metadata_tools
% by downloading the current list of effectory names from SAGE.
%
% Usage:  updateEffectors();
%
cacher = SAGEDataCacher();
cacher.updateEffectorsFile();