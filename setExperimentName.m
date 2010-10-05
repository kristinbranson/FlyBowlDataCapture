function handles = setExperimentName(handles)

if isfield(handles,'ExperimentName'),
  oldexperimentname = handles.ExperimentName;
else
  oldexperimentname = '';
end
handles.ExperimentName = getExperimentName(handles);
if isempty(oldexperimentname),
  addToStatus(handles,sprintf('Experiment name initialized to %s',handles.ExperimentName));
elseif ~strcmp(handles.ExperimentName,oldexperimentname),
  addToStatus(handles,sprintf('Experiment renamed from %s to %s',oldexperimentname,handles.ExperimentName));
end

% save old names in case we will be renaming
if isfield(handles,'ExperimentDirectory'),
  OldExperimentDirectory = handles.ExperimentDirectory;  
else
  OldExperimentDirectory = '';
end

% construct experiment directory name
handles.ExperimentDirectory = fullfile(handles.params.OutputDirectory,handles.ExperimentName);

% move experiment directory if it exists
if ~isempty(OldExperimentDirectory) && ...
    ~strcmp(OldExperimentDirectory,handles.ExperimentDirectory) && ...
    exist(OldExperimentDirectory,'file'),
  addToStatus(handles,sprintf('Trying to rename experiment directory from %s to %s\n',OldExperimentDirectory,handles.ExperimentDirectory));
  [success,msg] = renamefile(OldExperimentDirectory,handles.ExperimentDirectory);
  if ~success,
    s = sprintf('Could not rename old experiment directory %s to %s: %s',...
      OldExperimentDirectory,handles.ExperimentDirectory,msg);
    addToStatus(handles,s);
    uiwait(errordlg(s,'Error saving metadata'));
  end
end

% create directory if it does not exist
if ~exist(handles.ExperimentDirectory,'file'),
  addToStatus(handles,sprintf('Creating experiment directory %s\n',handles.ExperimentDirectory));
  [success,msg] = mkdir(handles.ExperimentDirectory);
  if ~success,
    s = sprintf('Could not create experiment directory %s: %s',handles.ExperimentDirectory,msg);
    addToStatus(handles,s);
    guidata(handles.figure_main,handles);
    uiwait(errordlg(s,'Error saving metadata'));
    error(s);
  end
end

filestr = sprintf('movie.%s',handles.params.FileType);
newfilename = fullfile(handles.ExperimentDirectory,filestr);
if exist(newfilename,'file'),
  handles.FileName = newfilename;
  %fprintf('Setting movie file name to %s\n',handles.FileName);
end

% construct name for metadata file
handles.MetaDataFileName = fullfile(handles.ExperimentDirectory,handles.params.MetaDataFileName);

% construct name for log file
oldfilename = handles.LogFileName;
handles.LogFileName = fullfile(handles.ExperimentDirectory,handles.params.LogFileName);
%fprintf('Setting log file name to %s\n',handles.LogFileName);
if handles.IsTmpLogFile && exist(oldfilename,'file'),
  addToStatus(handles,sprintf('Renaming log file from %s to %s\n',oldfilename,handles.LogFileName));
  renamefile(oldfilename,handles.LogFileName);
  handles.IsTmpLogFile = false;
end

% copy parameters file into the experiment directory if this is the first
% time an experiment directory is created
if isempty(OldExperimentDirectory) && exist(handles.ExperimentDirectory,'file'),
  [success1,msg] = copyfile(handles.params_file,handles.ExperimentDirectory);
  if ~success1,
    addToStatus(handles,{sprintf('Error copying params file %s into directory %s:',...
      handles.params_file,handles.ExperimentDirectory),msg});
  end
end