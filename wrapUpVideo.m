function wrapUpVideo(obj,event,hObject) %#ok<INUSL>

% clean up remaining frames
f = obj.framesacquiredfcn;
if ~isempty(f) && iscell(f),
  while obj.framesavailable > 0,
    feval(f{1},obj,'',hObject);
  end
end
obj.framesacquiredfcn = '';
handles = guidata(hObject);

% close file
switch handles.params.FileType,
  case 'avi'
    handles.logger.aviobj = close(handles.logger.aviobj);
  case 'fmf'
    fseek(handles.logger.fid,20,-1);
    fwrite(handles.logger.fid,handles.FrameCount,'uint64');
    fclose(handles.logger.fid);
end

% no longer recording
handles.IsRecording = false;

handles = renameVideoFile(handles);

PreviewParams = getappdata(handles.hImage_Preview,'PreviewParams');
PreviewParams.IsRecording = false;
setappdata(handles.hImage_Preview,'PreviewParams',PreviewParams);

% enable Done button
set(handles.pushbutton_Done,'Enable','on','BackgroundColor',handles.Done_bkgdcolor,'String','Done');

% set recording status
set(handles.text_Status_Recording,'String','Finished','BackgroundColor',handles.grayed_bkgdcolor);

% frame rate status
set(handles.text_Status_FrameRate,'String',sprintf('Ave: %.1f',handles.FrameCount / handles.writeFrame_time));

% add to status log
handles = addToStatus(handles,{sprintf('%s: Finished recording. Video file moved to %s.',...
  datestr(now,handles.secondformat),handles.FileName)});

% disable abort button
set(handles.pushbutton_Abort,'Enable','off','BackgroundColor',handles.grayed_bkgdcolor);

guidata(hObject,handles);