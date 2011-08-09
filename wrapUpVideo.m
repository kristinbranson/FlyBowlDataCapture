function wrapUpVideo(obj,event,hObject,AdaptorName,didabort) %#ok<INUSL>

%global FBDC_TempFid;

hwait = waitbar(0,'Closing video file: stopping recording');

if strcmpi(AdaptorName,'gdcam')
  set(obj.Source,'LogFlag',0);
elseif strcmpi(AdaptorName,'udcam')
  set(obj.Source,'nFramesTarget',0);
else
  % remove frames acquired function
  obj.framesacquiredfcn = '';

  % % set stop function to default
  % fprintf('Removing stop function\n');
  % obj.stopfcn = '';
end

% stop
if ~strcmpi(AdaptorName,'udcam')
  stop(obj);
else
  % nothing to do
end

hwait = mywaitbar(.2,hwait,'Closing video file: pausing for 3 seconds...');

% wait a few seconds
pause(3);

hwait = mywaitbar(.4,hwait,'Closing video file: waiting for Running == Off');

% wait until actually stopped
%fprintf('Waiting for Running == Off...\n');
tic;
handles = guidata(hObject);
MaxTimeWaitStopRunning = 30;
while true,
  if ~isrunning(obj) && ~islogging(obj)% && ...
    break;
  end
  pause(.5);
  dt = toc;
  if dt > MaxTimeWaitStopRunning,
    s = sprintf('Waited more than %f seconds for recording to stop. Erroring out.',MaxTimeWaitStopRunning);
    errordlg(s);
    error(s);
  end
  addToStatus(handles,sprintf('Waiting for recording to stop (%f/%f s)',dt,MaxTimeWaitStopRunning));
end
%fprintf('Running = Off.\n');

hwait = waitbar(.5,hwait,'Closing video file: cleaning up remaining frames.');

if ~(strcmpi(AdaptorName,'gdcam') || strcmpi(AdaptorName,'udcam')),

  %fprintf('Cleaning up remaining frames\n');
  % clean up remaining frames
  if obj.framesavailable > 0,
    %fprintf('Removing %d frames from buffer.\n',obj.framesavailable);
    getdata(obj,obj.framesavailable);
  end
  
  % wait a few seconds
  pause(3);
  
  % close file
  %fprintf('Closing file.\n');
  handles = guidata(hObject);
  switch handles.params.FileType,
    case 'avi'
      handles.logger.aviobj = close(handles.logger.aviobj);
    case 'fmf'
      fseek(handles.logger.fid,20,-1);
      fwrite(handles.logger.fid,handles.FrameCount,'uint64');
      fclose(handles.logger.fid);
  end
  
end

% handles = guidata(hObject);
% 
% hwait = mywaitbar(.6,hwait,'Closing video file: closing temperature stream file.');
% 
% % close temperature file
% if handles.params.DoRecordTemp ~= 0 && ~isempty(FBDC_TempFid) && ...
%     FBDC_TempFid > 0 && ~isempty(fopen(FBDC_TempFid)),
%   try
%     fclose(FBDC_TempFid);
%   catch ME,
%     addToStatus(handles,{'Error closing temperature stream file:',getReport(ME)});
%     warndlg(getReport(ME),'Error closing temperature stream file','modal');
%   end
% end

% no longer recording
%fprintf('No longer recording.\n');
handles = guidata(hObject);
handles.IsRecording = false;
handles.FinishedRecording = true;

hwait = mywaitbar(.65,hwait,'Closing video file: renaming experiment...');
oldname = handles.FileName;
%fprintf('Renaming file.\n');
handles = renameVideoFile(handles);
guidata(hObject,handles);
%fprintf('Renamed to %s\n',handles.FileName);
% add to status log
addToStatus(handles,{sprintf('Finished recording. Video file moved from %s to %s.',...
  oldname,handles.FileName)});

PreviewParams = getappdata(handles.hImage_Preview,'PreviewParams');
PreviewParams.IsRecording = false;
setappdata(handles.hImage_Preview,'PreviewParams',PreviewParams);

hwait = mywaitbar(.7,hwait,'Computing quick stats...');

% show some simple statistics
if strcmpi(handles.params.FileType,'ufmf'),
  
  try

    [handles.QuickStats,success,errmsg,warnings] = computeQuickStats(handles.ExperimentDirectory,...
      handles.ComputeQuickStatsParams{:});
  
    if ~success,
      addToStatus(handles,sprintf('Error computing quick statistics: %s',errmsg));
    end
    if ~isempty(warnings),
      addToStatus(handles,[{'Warnings computing quick statistics:'},warnings]);
    end
    
  catch ME,
    addToStatus(handles,['Error computing quickstats: ',getReport(ME)]);
    warndlg(getReport(ME),'Error computing quickstats','modal');
  end
end

hwait = mywaitbar(.899,hwait,'Closing video file: Enabling Save Metadata button...');

% if we did not abort, store this
if ~didabort,
  handles.didabort = false;
  handles = ChangedMetaData(handles);
end

hwait = mywaitbar(.9,hwait,'Closing video file: Waiting 5 seconds before resaving metadata...');

% add a wait period before resaving
pause(5);

% save metadata
hwait = mywaitbar(.98,hwait,'Closing video file: Saving metadata...');
handles = SaveMetaData(handles);

hwait = mywaitbar(.99,hwait,'Closing video file: Updating GUI...');

% enable Done button
set(handles.pushbutton_Done,'Enable','on','BackgroundColor',handles.Done_bkgdcolor,'String','Done');

% set recording status
set(handles.text_Status_Recording,'String','Finished','BackgroundColor',handles.grayed_bkgdcolor);

% frame rate status
set(handles.text_Status_FrameRate,'String',sprintf('Ave: %.1f',handles.FrameCount / handles.writeFrame_time));

% disable abort button
set(handles.pushbutton_Abort,'Enable','off','BackgroundColor',handles.grayed_bkgdcolor);

% enable switching cameras
if handles.IsAdvancedMode,
  set(handles.popupmenu_DeviceID,'Enable','on');
end
set(handles.menu_Edit_DetectCameras,'Enable','on');

% enable file menus
set(handles.menu_File_New,'Enable','on');
set(handles.menu_File_Close,'Enable','on');
set(handles.menu_Quit,'Enable','on');

guidata(hObject,handles);

hwait = mywaitbar(1,hwait,'Video file closed');
if ishandle(hwait),
  delete(hwait);
end
