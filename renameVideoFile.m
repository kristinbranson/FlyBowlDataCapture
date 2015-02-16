function handles = renameVideoFile(handles)

addToStatus(handles,'Renaming experiment...');

% files that are open
openfids = fopen('all');
openfilenames = cell(size(openfids));
for i = 1:numel(openfids),
  openfilenames{i} = fopen(openfids(i));
end

oldfilename = handles.FileName;
% if strcmpi(handles.params.Imaq_Adaptor,'bias'),
%   % BIAS appends stuff to the file name
%   [p,n,ext] = fileparts(oldfilename);
%   n = [n,'_guid_',handles.vid.biasconfig.camera.guid];
%   oldfilename = fullfile(p,[n,ext]);  
% end

if handles.params.DoRecordTemp ~= 0,
  oldtempfilename = handles.TempFileName;
end

% construct experiment name, directory
handles = setExperimentName(handles);

% already done everything by renaming directory
if ~handles.IsTmpFileName,
  addToStatus(handles,'Renaming completed by changing directory name.');
  return;
end

newfilename = fullfile(handles.ExperimentDirectory,handles.params.MovieFileStr);

% check if renaming already done
if exist(newfilename,'file') && ~exist(oldfilename,'file'),
  addToStatus(handles,{sprintf('Sanity check failed: %s already renamed to %s\n',oldfilename,newfilename)});
  handles.FileName = newfilename;
  handles.IsTmpFileName = false;
  return;
end

i = find(strcmp(oldfilename,openfilenames),1);
if ~isempty(i),
  addToStatus(handles,sprintf('Closing %s to rename %s to %s.',oldfilename,oldfilename,newfilename));
  fclose(openfids(i));
  openfilenames(i) = [];
  openfids(i) = [];
end
addToStatus(handles,sprintf('Renaming movie file from %s to %s',oldfilename,newfilename));
[success,msg] = renamefile(oldfilename,newfilename);
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
  addToStatus(handles,s);
  warning(cell2mat(s));
end

if handles.params.DoRecordTemp ~= 0,
  filestr = 'temperature.txt';
  newfilename = fullfile(handles.ExperimentDirectory,filestr);
  addToStatus(handles,sprintf('Renaming temperature stream file from %s to %s',oldtempfilename,newfilename));
  
  if ~exist(oldtempfilename,'file'),
    addToStatus(handles,sprintf('Temperature file %s does not exist, could not rename %s',oldtempfilename,newfilename));
  else
    
    % close the file if nec
    i = find(strcmp(oldtempfilename,openfilenames),1);
    if ~isempty(i),
      addToStatus(handles,sprintf('Closing %s to rename %s to %s.',oldtempfilename,oldtempfilename,newfilename));
      fclose(openfids(i));
    end
    
    [success,msg] = renamefile(oldtempfilename,newfilename);
    if success,
      %fprintf('Successfully renamed file from %s to %s\n',oldfilename,handles.FileName);
      handles.TempFileName = newfilename;
      %fprintf('Renamed successfully\n');
    else
      s = {sprintf('Temperature record temporarily stored to %s. ',oldtempfilename),...
        sprintf('Could not rename %s. ',handles.TempFileName),...
        msg};
      uiwait(errordlg(s,'Error renaming file'));
      addToStatus(handles,s);
      warning(cell2mat(s));
    end
  end
end

if strcmpi(handles.params.FileType,'ufmf'),
  if isfield(handles,'TmpUFMFLogFileName'),
    % TODO: no log file created for BIAS
    oldfilename = handles.TmpUFMFLogFileName;
    newfilename = fullfile(handles.ExperimentDirectory,handles.params.UFMFLogFileName);
    addToStatus(handles,sprintf('Renaming UFMF log file from %s to %s',oldfilename,newfilename));
    if ~exist(oldfilename,'file'),
      addToStatus(handles,sprintf('UFMF log file %s does not exist, could not rename %s',oldfilename,newfilename));
    else
      
      % close the file if nec
      i = find(strcmp(oldfilename,openfilenames),1);
      if ~isempty(i),
        addToStatus(handles,sprintf('Closing %s to rename %s to %s.',oldfilename,oldfilename,newfilename));
        fclose(openfids(i));
      end
      
      [success,msg] = renamefile(oldfilename,newfilename);
      if success,
        %fprintf('Successfully renamed file from %s to %s\n',oldfilename,newfilename);
        handles.params.UFMFLogFileName = newfilename;
        %fprintf('Renamed successfully\n');
      else
        s = {sprintf('UFMF log temporarily stored to %s. ',oldfilename),...
          sprintf('Could not rename %s to %s. ',oldfilename,newfilename),...
          msg};
        uiwait(errordlg(s,'Error renaming UFMF log file'));
        addToStatus(handles,s);
        warning(cell2mat(s));
      end
    end
  end
  if isfield(handles,'TmpUFMFStatFileName'),
    oldfilename = handles.TmpUFMFStatFileName;
    newfilename = fullfile(handles.ExperimentDirectory,handles.params.UFMFStatFileName);
    addToStatus(handles,sprintf('Renaming UFMF stats file from %s to %s',oldfilename,newfilename));
    if ~exist(oldfilename,'file'),
      addToStatus(handles,sprintf('UFMF stats file %s does not exist, could not rename %s',oldfilename,newfilename));
    else
    
      % close the file if nec
      i = find(strcmp(oldfilename,openfilenames),1);
      if ~isempty(i),
        addToStatus(handles,sprintf('Closing %s to rename %s to %s.',oldfilename,oldfilename,newfilename));
        fclose(openfids(i));
      end
      
      [success,msg] = renamefile(oldfilename,newfilename);
      if success,
        %fprintf('Successfully renamed file from %s to %s\n',oldfilename,newfilename);
        handles.UFMFStatFileName = newfilename;
        %fprintf('Renamed successfully\n');
      else
        s = {sprintf('UFMF diagnostics temporarily stored to %s. ',oldfilename),...
          sprintf('Could not rename %s to %s. ',oldfilename,newfilename),...
          msg};
        uiwait(errordlg(s,'Error renaming UFMF diagnostics file'));
        addToStatus(handles,s);
        warning(cell2mat(s));
      end
    end
  end
end