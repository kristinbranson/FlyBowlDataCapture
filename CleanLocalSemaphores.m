
try

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

catch ME
  fprintf('Error checking whether we really want to stop Master Temperature Recorder:\n');
  getReport(ME)
end


try

global FBDC_IsCameraRunningFiles;

for i = 1:length(FBDC_IsCameraRunningFiles),
  if exist(FBDC_IsCameraRunningFiles{i},'file'),
    fprintf('Deleting %s\n',FBDC_IsCameraRunningFiles{i});
    delete(FBDC_IsCameraRunningFiles{i});
  end
end

catch ME
  fprintf('Error checking for IsCameraRunningFile:\n');
  getReport(ME)
end

try

global FBDC_GUIInstanceFileName;

if ~isempty(FBDC_GUIInstanceFileName) && exist(FBDC_GUIInstanceFileName,'file'),
  fprintf('Deleting %s\n',FBDC_GUIInstanceFileName);
  delete(FBDC_GUIInstanceFileName);
end

catch ME
  fprintf('Error checking for GUIInstanceFile:\n');
  getReport(ME)
end

try
  
  global FBDC_PreconSemaphoreFiles;
  if ~isempty(FBDC_PreconSemaphoreFiles),
    FBDC_PreconSemaphoreFiles = unique(FBDC_PreconSemaphoreFiles);
    for i = 1:length(FBDC_PreconSemaphoreFiles),
      if exist(FBDC_PreconSemaphoreFiles{i},'file'),
        fprintf('Deleting %s\n',FBDC_PreconSemaphoreFiles{i});
        delete(FBDC_PreconSemaphoreFiles{i});
      end
    end
    FBDC_PreconSemaphoreFiles = {};
  end
  
catch ME
  fprintf('Error checking for Precon semaphore files:\n');
  getReport(ME);
end
