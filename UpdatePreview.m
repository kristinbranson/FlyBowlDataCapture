function UpdatePreview(obj,event,himage) 

% should we update?
params = getappdata(himage,'PreviewParams');
lastupdate = getappdata(himage,'LastPreviewUpdateTime');

if strcmpi(params.AdaptorName,'udcam'),
  currenttime = get(obj.Source,'lastCaptureTime');
  empFrameRate = get(obj.Source,'empFrameRate');
  handles.FrameCount = get(obj.Source,'nFramesLogged');
  %set(handles.text_Status_Recording,'String',sprintf('%.1f s',handles.writeFrame_time));
  set(params.text_Status_FramesWritten,'String',sprintf('%d',handles.FrameCount));
  set(params.text_Status_FrameRate,'String',sprintf('%.2f Hz',empFrameRate));
  history = get(params.hLine_Status_FrameRate,'UserData');
  
  % did preview get stuck?
  if history(1,end) == currenttime,
%     nochangeintimestamp = getappdata(himage,'NoChangeInTimestamp') + 1;
%     fprintf('No change in timestamp for %d updates to preview\n',nochangeintimestamp);
%     setappdata(himage,'NoChangeInTimestamp',nochangeintimestamp);
  else
    %setappdata(himage,'NoChangeInTimestamp',0);
    history(:,1) = [];
    history(:,end+1) = [currenttime,empFrameRate];
    set(params.hLine_Status_FrameRate,...
      'Xdata',history(1,:)-history(1,end),...
      'Ydata',history(2,:),...
      'UserData',history);
  end
else
  currenttime = now;
end

if params.IsRecording && (currenttime - lastupdate < params.PreviewUpdatePeriod),
  return;
end

% Display image data.
set(himage, 'CData', event.Data);

if params.ColormapPreview,
  colormap(params.axes_PreviewVideo,jet(256));
end

% Update last update time
setappdata(himage,'LastPreviewUpdateTime',now);

if params.IsRecording,
    
  daysrecording = now - params.StartRecording_Time_datenum;
  daysleft = params.RecordTimeDays - daysrecording;
  if daysleft > 0,
    set(params.pushbutton_Done,'String',datestr(daysleft,13));
  end
end