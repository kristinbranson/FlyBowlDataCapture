function ListSemaphores()

files = dir('.DetectCamerasData\*.mat');
files = {files.name};
nfiles = length(files);
if nfiles > 0,
  fprintf('%d semaphores in .DetectCamerasData:\n',nfiles);
  for i = 1:nfiles,
    fprintf('  %s\n',files{i});
  end
else
  fprintf('No semaphores in .DetectCamerasData\n');
end
files = dir('.TempRecordData\*');
files = {files.name};
files = setdiff(files,{'.','..'});
nfiles = length(files);
if nfiles > 0,
  fprintf('%d files from .TempRecordData\n',nfiles);
  for i = 1:length(files),
    fprintf('  %s\n',files{i});
  end
else
  fprintf('No semaphores in .TempRecordData\n');
end

files = dir(fullfile('.GUIInstances','*.mat'));
files = {files.name};
nfiles = length(files);
if nfiles > 0,
  fprintf('%d semaphores from .GUIInstances\n',nfiles);
  for i = 1:nfiles,
    fprintf('  %s\n',files{i});
  end
else
  fprintf('No semaphores in .GUIInstances\n');
end



files = dir('.PreconRecordData\*');
files = {files.name};
files = setdiff(files,{'.','..'});
nfiles = length(files);
if nfiles > 0,
  fprintf('%d files from .PreconRecordData\n',nfiles);
  for i = 1:length(files),
    fprintf('  %s\n',files{i});
  end
else
  fprintf('No semaphores in .PreconRecordData\n');
end
