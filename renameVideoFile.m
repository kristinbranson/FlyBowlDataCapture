function handles = renameVideoFile(handles)

oldfilename = handles.FileName;

% generate a new name
filestr = sprintf('%s_Rig%sPlate%sBowl%s_%s.%s',handles.Fly_LineName,...
  handles.Assay_Rig,handles.Assay_Plate,handles.Assay_Bowl,...
  datestr(handles.StartRecording_Time_datenum,30),...
  handles.params.FileType);
newfilename = fullfile(handles.params.OutputDirectory,filestr);

% if name is the same, nothing to do
if strcmp(oldfilename,newfilename), return; end

% try moving
[success,msg] = movefile(oldfilename,newfilename,'f');
if success,
  handles.FileName = newfilename;
else
  s = {sprintf('Video temporarily stored to %s. ',oldfilename),...
    sprintf('Could not rename %s. ',newfilename),...
    msg};
  uiwait(errordlg(s,'Error renaming file'));
  warning(cell2mat(s));
end
