function UpdatePreview(obj,event,himage) %#ok<INUSL>

% should we update?
params = getappdata(himage,'PreviewParams');
lastupdate = getappdata(himage,'LastPreviewUpdateTime');
currenttime = now;

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