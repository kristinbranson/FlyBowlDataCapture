function CleanSemaphores()

nfiles = length(dir('.DetectCamerasData\*.mat'));
if nfiles > 0,
  fprintf('Deleting %d semaphores from .DetectCamerasData\n',nfiles);
  delete('.DetectCamerasData\*.mat');
else
  fprintf('No semaphores in .DetectCamerasData\n');
end
nfiles = length(dir('.TempRecordData\*'));
if nfiles > 0,
  fprintf('Deleting %d files from .TempRecordData\n',nfiles);
  delete('.TempRecordData\*');
else
  fprintf('No semaphores in .TempRecordData\n');
end
