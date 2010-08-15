%FINISHDLG  Display a dialog to cancel quitting
%   Change the name of this file to FINISH.M and 
%   put it anywhere on your MATLAB path. When you 
%   quit MATLAB this file will be executed.

%   Copyright 1984-2000 The MathWorks, Inc. 
%   $Revision: 1.6 $  $Date: 2000/06/01 16:19:26 $

try

global MasterTempRecordInfo;

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
