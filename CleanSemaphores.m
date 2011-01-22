function CleanSemaphores()

nfiles = length(dir('.DetectCamerasData\*.mat'));
hwaitbar = waitbar(0,'Cleaning Semaphores');
if nfiles > 0,
  s = sprintf('Deleting %d semaphores from .DetectCamerasData\n',nfiles);
  if exist('hwaitbar','var') && ishandle(hwaitbar),
    waitbar(.1,hwaitbar,s);
  else
    waitbar(.1,s);
  end

  delete('.DetectCamerasData\*.mat');
else
  s = sprintf('No semaphores in .DetectCamerasData\n');
  if exist('hwaitbar','var') && ishandle(hwaitbar),
    waitbar(.2,hwaitbar,s);
  else
    waitbar(.2,s);
  end

end

files = dir('.TempRecordData\*');
files = {files.name};
files = setdiff(files,{'.','..'});
nfiles = length(files);
if nfiles > 0,
  s = sprintf('Deleting %d files from .TempRecordData\n',nfiles);
  if exist('hwaitbar','var') && ishandle(hwaitbar),
    waitbar(.3,hwaitbar,s);
  else
    waitbar(.3,s);
  end

  for i = 1:length(files),
    delete(fullfile('.TempRecordData',files{i}));
  end
else
  s = sprintf('No semaphores in .TempRecordData\n');
  if exist('hwaitbar','var') && ishandle(hwaitbar),
    waitbar(.4,hwaitbar,s);
  else
    waitbar(.4,s);
  end
end

nfiles = length(dir(fullfile('.GUIInstances','*.mat')));
if nfiles > 0,
  s = sprintf('Deleting %d semaphores from .GUIInstances\n',nfiles);
  if exist('hwaitbar','var') && ishandle(hwaitbar),
    waitbar(.5,hwaitbar,s);
  else
    waitbar(.5,s);
  end

  delete(fullfile('.GUIInstances','*.mat'));
else
  s = sprintf('No semaphores in .GUIInstances\n');
  if exist('hwaitbar','var') && ishandle(hwaitbar),
    waitbar(.6,hwaitbar,s);
  else
    waitbar(.6,s);
  end

end



files = dir('.PreconRecordData\*');
files = {files.name};
files = setdiff(files,{'.','..'});
nfiles = length(files);
if nfiles > 0,
  s = sprintf('Deleting %d files from .PreconRecordData\n',nfiles);
  if exist('hwaitbar','var') && ishandle(hwaitbar),
    waitbar(.8,hwaitbar,s);
  else
    waitbar(.8,s);
  end
  for i = 1:length(files),
    delete(fullfile('.PreconRecordData',files{i}));
  end
else
  s = sprintf('No semaphores in .PreconRecordData\n');
  if exist('hwaitbar','var') && ishandle(hwaitbar),
    waitbar(.9,hwaitbar,s);
  else
    waitbar(.9,s);
  end
end

if exist('hwaitbar','var') && ishandle(hwaitbar),
  delete(hwaitbar);
end