function handles = renameVideoFile(handles)

oldfilename = handles.FileName;

% construct experiment name, directory
handles = setExperimentName(handles);

% already done everything by renaming directory
if ~handles.IsTmpFileName,
  return;
end

filestr = sprintf('movie.%s',handles.params.FileType);
newfilename = fullfile(handles.ExperimentDirectory,filestr);

% check if renaming already done
if exist(newfilename,'file') && ~exist(oldfilename,'file'),
  fprintf('Hmm, %s already renamed to %s\n',oldfilename,newfilename);
  handles.FileName = newfilename;
  handles.IsTmpFileName = false;
  return;
end

[success,msg] = movefile(oldfilename,newfilename,'f');
if success,
  handles.IsTmpFileName = false;
  handles.FileName = newfilename;
  fprintf('Renamed successfully\n');
else
  s = {sprintf('Video temporarily stored to %s. ',oldfilename),...
    sprintf('Could not rename %s. ',handles.FileName),...
    msg};
  uiwait(errordlg(s,'Error renaming file'));
  warning(cell2mat(s));
end
