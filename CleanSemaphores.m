function CleanSemaphores()

nfiles = length(dir('.DetectCamerasData\*.mat'));
if nfiles > 0,
  fprintf('Deleting %d semaphores from .DetectCamerasData\n',nfiles);
  delete('.DetectCamerasData\*.mat');
else
  fprintf('No semaphores in .DetectCamerasData\n');
end
files = dir('.TempRecordData\*');
files = {files.name};
files = setdiff(files,{'.','..'});
nfiles = length(files);
if nfiles > 0,
  fprintf('Deleting %d files from .TempRecordData\n',nfiles);
  for i = 1:length(files),
    delete(files{i});
  end
else
  fprintf('No semaphores in .TempRecordData\n');
end

nfiles = length(dir(fullfile('.GUIInstances','*.mat')));
if nfiles > 0,
  fprintf('Deleting %d semaphores from .GUIInstances\n',nfiles);
  delete(fullfile('.GUIInstances','*.mat'));
else
  fprintf('No semaphores in .GUIInstances\n');
end
