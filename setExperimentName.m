function [handles,success] = setExperimentName(handles)

success = true;

if isfield(handles,'ExperimentName'),
  oldexperimentname = handles.ExperimentName;
else
  oldexperimentname = '';
end
NewExperimentName = getExperimentName(handles);
if strcmp(NewExperimentName,oldexperimentname),
  return;
end
if isempty(oldexperimentname),
  addToStatus(handles,sprintf('Experiment name initialized to %s',NewExperimentName));
elseif ~strcmp(NewExperimentName,oldexperimentname),
  addToStatus(handles,sprintf('Experiment renamed from %s to %s',oldexperimentname,NewExperimentName));
end

% save old names in case we will be renaming
if isfield(handles,'ExperimentDirectory'),
  OldExperimentDirectory = handles.ExperimentDirectory;  
else
  OldExperimentDirectory = '';
end

if isfield(handles,'QuickStats') && ...
    isfield(handles.QuickStats,'showufmf_handle') && ...
    ishandle(handles.QuickStats.showufmf_handle),
  res = questdlg('Need to close showufmf to change experiment name. Proceed?','Close UFMF?','Close UFMF','Cancel','Close UFMF');
  if ~strcmpi(res,'Close UFMF'),
    addToStatus(handles,'Renaming experiment aborted.');
    success = false;
    return;
  end
  delete(handles.QuickStats.showufmf_handle);
end


% construct experiment directory name
NewExperimentDirectory = fullfile(handles.params.OutputDirectory,NewExperimentName);

% move experiment directory if it exists
if ~isempty(OldExperimentDirectory) && ...
    ~strcmp(OldExperimentDirectory,NewExperimentDirectory) && ...
    exist(OldExperimentDirectory,'file'),
  addToStatus(handles,sprintf('Trying to rename experiment directory from %s to %s\n',OldExperimentDirectory,NewExperimentDirectory));
    
  for renametry = 1:5,
    [success1,msg] = renamefile(OldExperimentDirectory,NewExperimentDirectory);
    if success1, break; end
    addToStatus(handles,sprintf('Rename %s -> %s failed on try %d',...
      OldExperimentDirectory,NewExperimentDirectory,renametry));
    openfids = fopen('all');
    s = {sprintf('The following files are open, and will be closed:')};
    for filei = 1:numel(openfids),
      s{end+1} = fopen(openfids(filei)); %#ok<AGROW>
    end
    addToStatus(handles,s);
    if ~isempty(openfids),
      for filei = 1:numel(openfids),
        try %#ok<TRYNC>
          fclose(openfids(filei));
        end
      end
    end
    pause(3);
  end
  if ~success1,
    s = sprintf('Could not rename old experiment directory %s to %s: %s',...
      OldExperimentDirectory,NewExperimentDirectory,msg);
    addToStatus(handles,s);
    uiwait(errordlg(s,'Error saving metadata'));
    success = false;
  else
    handles.ExperimentDirectory = NewExperimentDirectory;
    handles.ExperimentName = NewExperimentName;
  end
end

% create directory if it does not exist
if success && ~exist(NewExperimentDirectory,'file'),
  addToStatus(handles,sprintf('Creating experiment directory %s\n',NewExperimentDirectory));
  [success1,msg] = mkdir(NewExperimentDirectory);
  if ~success1,
    s = sprintf('Could not create experiment directory %s: %s',NewExperimentDirectory,msg);
    addToStatus(handles,s);
    guidata(handles.figure_main,handles);
    uiwait(errordlg(s,'Error saving metadata'));
    error(s);
  else
    handles.ExperimentDirectory = NewExperimentDirectory;
    handles.ExperimentName = NewExperimentName;
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
if isempty(OldExperimentDirectory) && exist(handles.ExperimentDirectory,'dir'),
  [success1,msg] = copyfile(handles.params_file,handles.ExperimentDirectory);
  if ~success1,
    addToStatus(handles,{sprintf('Error copying params file %s into directory %s:',...
      handles.params_file,handles.ExperimentDirectory),msg});
    success = false;
  end
  
  % copy condition file
  [success1,msg] = copyfile(handles.ConditionFileName,handles.ExperimentDirectory);
  if ~success1,
    addToStatus(handles,{sprintf('Error copying conditions file %s into directory %s:',...
      handles.params_file,handles.ExperimentDirectory),msg});
    success = false;
  end
end

