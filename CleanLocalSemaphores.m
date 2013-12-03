
try

hwaitbar = waitbar(0,'Cleaning Local Semaphores');
  
global MasterTempRecordInfo; %#ok<*TLEV>

if ~isempty(MasterTempRecordInfo) && ...
    exist(MasterTempRecordInfo.IsMasterFile,'file'),
  button = questdlg(['This Matlab is currently the master temperature ',...
    'recorder. Other instances of FlyBowlDataCapture may be relying on ',...
    'this recording. Are you sure you want to quit?'],...
    'Really quit???','Yes','No','No');
  switch button
    case 'Yes',
      disp('Stopping Temperature Recording');
      try
        stop(MasterTempRecordInfo.MasterTempRecord_timer);
      catch ME
        button = questdlg({'Error stopping temperature recorder:',...
          getReport(ME),'Really quit?'},...
          'Really quit???','Yes','No','No');
        if strcmp(button,'No'),
          quit cancel;
        end
      end
    case 'No',
      quit cancel;
  end
end
if exist('hwaitbar','var') && ishandle(hwaitbar),
  waitbar(.2,hwaitbar,'Cleaned temperature semaphores');
else
  waitbar(.2,'Cleaned temperature semaphores');
end

catch ME
  s =['Error checking whether we really want to stop Master Temperature Recorder:\n',getReport(ME)];
  errordlg(s,'Error Cleaning Local Semaphores');
end


try

global FBDC_IsCameraRunningFiles;

for i = 1:length(FBDC_IsCameraRunningFiles),
  if exist(FBDC_IsCameraRunningFiles{i},'file'),
    delete(FBDC_IsCameraRunningFiles{i});
  end
end

if exist('hwaitbar','var') && ishandle(hwaitbar),
  waitbar(.4,hwaitbar,'Cleaned camera semaphores');
else
  waitbar(.4,'Cleaned camera semaphores');
end


catch ME
  s =['Error checking for IsCameraRunningFile:\n',getReport(ME)];
  errordlg(s,'Error Cleaning Local Semaphores');
end

if true
  
  global FBDC_GUIInstances;
  FBDC_GUIInstances = [];

else

try  

global FBDC_GUIInstanceFileName;

if ~isempty(FBDC_GUIInstanceFileName) && exist(FBDC_GUIInstanceFileName,'file'),
  delete(FBDC_GUIInstanceFileName);
end

if exist('hwaitbar','var') && ishandle(hwaitbar),
  waitbar(.6,hwaitbar,'Cleaned GUI semaphores');
else
  waitbar(.6,'Cleaned GUI semaphores');
end

catch ME
  s =['Error checking for GUIInstanceFile:\n',getReport(ME)];
  errordlg(s,'Error Cleaning Local Semaphores');
end

end

try
  
  global FBDC_PreconSemaphoreFiles;
  if ~isempty(FBDC_PreconSemaphoreFiles),
    FBDC_PreconSemaphoreFiles = unique(FBDC_PreconSemaphoreFiles);
    for i = 1:length(FBDC_PreconSemaphoreFiles),
      if exist(FBDC_PreconSemaphoreFiles{i},'file'),
        delete(FBDC_PreconSemaphoreFiles{i});
      end
    end
    FBDC_PreconSemaphoreFiles = {};
  end
  
  if exist('hwaitbar','var') && ishandle(hwaitbar),
    waitbar(.8,hwaitbar,'Cleaned Precon semaphores');
  else
    waitbar(.8,'Cleaned Precon semaphores');
  end

  
catch ME
  s =['Error checking for Precon semaphore files:\n',getReport(ME)];
  errordlg(s,'Error Cleaning Local Semaphores');
  getReport(ME);
end

if exist('hwaitbar','var') && ishandle(hwaitbar),
  delete(hwaitbar);
end

global FBDC_BIASCAMERASINUSE;
FBDC_BIASCAMERASINUSE = [];