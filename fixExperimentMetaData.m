function [DefaultsTree,success,errmsg,warnings] = fixExperimentMetaData(varargin)

success = false;
errmsg = '';
warnings = {};
DefaultsTree = [];

datetimeFormat = 'yyyy-mm-ddTHH:MM:SS';

% parse inputs
MetaDataFileName = 'Metadata.xml';
tmp = which('fixExperimentMetaData');
fbdcdir = fileparts(tmp);
DefaultsFileName = fullfile(fbdcdir,'flybowl_experimental_variables_defaults.xml');

% path
if ~exist('loadXMLDataTree','file'),
  addpath(genpath(fullfile(fbdcdir,'jfrc_metadata_tools','src')));
end

[MetaDataFileName,DefaultsFileName,expdir] = myparse(varargin,...
  'MetaDataFileName',MetaDataFileName,...
  'DefaultsFileName',DefaultsFileName,...
  'expdir','');

% choose experiment directory
if isempty(expdir),
  expdir = uigetdir('','Choose experiment directory');
  if ~ischar(expdir),
    return;
  end
end
% name of file to edit
MetaDataFileName = fullfile(expdir,MetaDataFileName);

if ~exist(MetaDataFileName,'file'),
  errmsg = sprintf('Metadata file %s does not exist',MetaDataFileName);
  return;
end

% read in the metadata file
[DataTree] = loadXMLDataTree(MetaDataFileName);

% read in the defaults file
DefaultsTree = loadXMLDefaultsTree(DefaultsFileName);

DataTree.walk(@TrySet);

basicMetaDataDlg(DefaultsTree);

success = true;

  function TrySet(DataNode)
    
    PathString = DataNode.getPathString();
    if ~isempty(DataNode.content),
      try
        node = DefaultsTree.getNodeByPathString(PathString);
        node.setContent(DataNode.content);
      catch ME,
        s = [sprintf('Could not set %s.content to %s: ',PathString,any2string(DataNode.content)),getReport(ME,'basic','hyperlinks','off')]; 
        warning(s);
        warnings{end+1} = s;
      end
    end
        
    if isempty(PathString),
      PathString1 = PathString;
    else
      PathString1 = [PathString,'.'];
    end
    for i = 1:length(DataNode.attributeNames),
      fn = DataNode.attributeNames{i};
      Value = DataNode.attribute.(fn);
      PathString2 = [PathString1,fn];
      try
        node = DefaultsTree.getNodeByPathString(PathString2);
        if strcmp(node.attribute.datatype,'datetime') && length(Value) ~= length(datetimeFormat),
          Value = datestr(datenum(Value),datetimeFormat);
        end
        DefaultsTree.setValueByPathString(PathString2,Value);
      catch ME,
        s = [sprintf('Could not set %s to %s: ',PathString2,any2string(Value)),getReport(ME,'basic','hyperlinks','off')]; 
        warning(s);
        warnings{end+1} = s; %#ok<AGROW>
      end
    end
    
  end

end