function handles = renameVideoFile(handles)

oldfilename = handles.FileName;
fprintf('Oldfilename = %s\n',oldfilename);

% generate a new name
filestr = sprintf('%s_Rig%sPlate%sBowl%s_%s.%s',handles.Fly_LineName,...
  handles.Assay_Rig,handles.Assay_Plate,handles.Assay_Bowl,...
  datestr(handles.StartRecording_Time_datenum,30),...
  handles.params.FileType);
newfilename = fullfile(handles.params.OutputDirectory,filestr);
fprintf('Newfilename = %s\n',newfilename);

% if name is the same, nothing to do
if strcmp(oldfilename,newfilename), return; end

% try moving
if exist(newfilename,'file') && ~exist(oldfilename,'file'),
  fprintf('Hmm, %s already renamed to %s\n',oldfilename,newfilename);
end
[success,msg] = movefile(oldfilename,newfilename,'f');
if success,
  handles.FileName = newfilename;
  fprintf('Renamed successfully\n');
else
  s = {sprintf('Video temporarily stored to %s. ',oldfilename),...
    sprintf('Could not rename %s. ',newfilename),...
    msg};
  uiwait(errordlg(s,'Error renaming file'));
  warning(cell2mat(s));
end
