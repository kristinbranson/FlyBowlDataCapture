function UpdatePreview(obj,event,himage) 

% should we update?
params = getappdata(himage,'PreviewParams');
lastupdate = getappdata(himage,'LastPreviewUpdateTime');
currenttime = now;

if strcmpi(params.AdaptorName,'udcam'),
  empFrameRate = get(obj.Source,'empFrameRate');
  %set(handles.text_Status_Recording,'String',sprintf('%.1f s',handles.writeFrame_time));
  %set(handles.text_Status_FramesWritten,'String',sprintf('%d',handles.FrameCount));
  set(params.text_Status_FrameRate,'String',sprintf('%.2f Hz',empFrameRate));
  history = get(params.hLine_Status_FrameRate,'UserData');
  history(:,1) = [];
  history(:,end+1) = [now*86400,empFrameRate];
  set(params.hLine_Status_FrameRate,...
    'Xdata',history(1,:)-history(1,end),...
    'Ydata',history(2,:),...
    'UserData',history);
end

if params.IsRecording && (currenttime - lastupdate < params.PreviewUpdatePeriod),
  return;
end

% Display image data.
set(himage, 'CData', event.Data);

% Update last update time
setappdata(himage,'LastPreviewUpdateTime',currenttime);

if params.IsRecording,
    
  daysrecording = now - params.StartRecording_Time_datenum;
  daysleft = params.RecordTimeDays - daysrecording;
  if daysleft > 0,
    set(params.pushbutton_Done,'String',datestr(daysleft,13));
  end
end