%FINISHDLG  Display a dialog to cancel quitting
%   Change the name of this file to FINISH.M and 
%   put it anywhere on your MATLAB path. When you 
%   quit MATLAB this file will be executed.

%   Copyright 1984-2000 The MathWorks, Inc. 
%   $Revision: 1.6 $  $Date: 2000/06/01 16:19:26 $

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
  delete(FBDC_GUIInstaceFileName);
end

catch ME
  fprintf('Error checking for GUIiNstanceFile:\n');
  getReport(ME)
end

