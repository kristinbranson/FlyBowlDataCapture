function handles = renameVideoFile(handles)

oldfilename = handles.FileName;
if handles.params.DoRecordTemp ~= 0,
  oldtempfilename = handles.TempFileName;
end

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
  handles = addToStatus(handles,{sprintf('Sanity check failed: %s already renamed to %s\n',oldfilename,newfilename)});
  handles.FileName = newfilename;
  handles.IsTmpFileName = false;
  return;
end

handles = addToStatus(handles,sprintf('Renaming movie file from %s to %s',oldfilename,newfilename));
[success,msg] = movefile(oldfilename,newfilename,'f');
if success,
  %fprintf('Successfully renamed file from %s to %s\n',oldfilename,handles.FileName);
  handles.IsTmpFileName = false;
  handles.FileName = newfilename;
  %fprintf('Renamed successfully\n');
else
  s = {sprintf('Video temporarily stored to %s. ',oldfilename),...
    sprintf('Could not rename %s. ',handles.FileName),...
    msg};
  uiwait(errordlg(s,'Error renaming file'));
  handles = addToStatus(handles,s);
  warning(cell2mat(s));
end

if handles.params.DoRecordTemp ~= 0,
  filestr = 'temperature.txt';
  newfilename = fullfile(handles.ExperimentDirectory,filestr);
  [success,msg] = movefile(oldtempfilename,newfilename,'f');
  if success,
    %fprintf('Successfully renamed file from %s to %s\n',oldfilename,handles.FileName);
    handles.TempFileName = newfilename;
    %fprintf('Renamed successfully\n');
  else
    s = {sprintf('Temperature record temporarily stored to %s. ',oldtempfilename),...
      sprintf('Could not rename %s. ',handles.TempFileName),...
      msg};
    uiwait(errordlg(s,'Error renaming file'));
    handles = addToStatus(handles,s);
    warning(cell2mat(s));
  end
end
