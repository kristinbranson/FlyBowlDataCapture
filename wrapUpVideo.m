function wrapUpVideo(obj,event,hObject,AdaptorName) %#ok<INUSL>

hwait = waitbar(0,'Closing video file. Please Wait.');

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

waitbar(.2);

% wait a few seconds
pause(3);

waitbar(.5);

% wait until actually stopped
%fprintf('Waiting for Running == Off...\n');
while true,
  if ~isrunning(obj) && ~islogging(obj)% && ...
    break;
  end
  pause(.5);
end
%fprintf('Running = Off.\n');

waitbar(.7);

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

handles = guidata(hObject);

waitbar(.8);

% close temperature file
if handles.params.DoRecordTemp ~= 0,
  fclose(handles.TempFid);
end

% no longer recording
%fprintf('No longer recording.\n');
handles = guidata(hObject);
handles.IsRecording = false;
handles.FinishedRecording = true;

oldname = handles.FileName;
%fprintf('Renaming file.\n');
handles = renameVideoFile(handles);
guidata(hObject,handles);
%fprintf('Renamed to %s\n',handles.FileName);
% add to status log
addToStatus(handles,{sprintf('Finished recording. Video file moved from %s to %s.',...
  oldname,handles.FileName)});

waitbar(.9);

PreviewParams = getappdata(handles.hImage_Preview,'PreviewParams');
PreviewParams.IsRecording = false;
setappdata(handles.hImage_Preview,'PreviewParams',PreviewParams);

% enable Done button
set(handles.pushbutton_Done,'Enable','on','BackgroundColor',handles.Done_bkgdcolor,'String','Done');

% set recording status
set(handles.text_Status_Recording,'String','Finished','BackgroundColor',handles.grayed_bkgdcolor);

% frame rate status
set(handles.text_Status_FrameRate,'String',sprintf('Ave: %.1f',handles.FrameCount / handles.writeFrame_time));

% disable abort button
set(handles.pushbutton_Abort,'Enable','off','BackgroundColor',handles.grayed_bkgdcolor);

% enable switching cameras
set(handles.popupmenu_DeviceID,'Enable','on');
set(handles.menu_Edit_DetectCameras,'Enable','on');

% enable file menus
set(handles.menu_File_New,'Enable','on');
set(handles.menu_File_Close,'Enable','on');
set(handles.menu_Quit,'Enable','on');

guidata(hObject,handles);

waitbar(1);
if ishandle(hwait),
  delete(hwait);
end
