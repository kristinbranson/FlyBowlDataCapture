function UpdatePreview(obj,event,himage) 

% stop if we've halted
global FBDC_DIDHALT;
fprintf('In UpdatePreview at time %s\n',datestr(now,'HH:MM:SS'));

% should we update?
params = getappdata(himage,'PreviewParams');
lastupdate = getappdata(himage,'LastPreviewUpdateTime');

if numel(FBDC_DIDHALT)>=params.GUIi && FBDC_DIDHALT(params.GUIi),
  return;
end

if strcmpi(params.AdaptorName,'bias'),
  
  try
    res = loadjson1(urlread([params.BIASParams.BIASURL,'?get-status']));
  catch ME,
    warning(getReport(ME));
    return;
  end
  if res.success == 0,
    warning(sprintf('Could not get BIAS status: %s',res.message));
    return;
  end
  
  biasstatus = res.value;
  v = get(himage,'String');
  if biasstatus.capturing == 0 && strcmpi(v,'On'),
    set(himage,'String','Off','BackgroundColor',params.grayed_bkgdcolor);
    % signal that capturing has stopped
    %FBDC_DIDHALT = true;
    return;
  elseif biasstatus.capturing > 0 && strcmpi(v,'Off'),
    set(himage,'String','On','BackgroundColor',params.Status_Recording_bkgdcolor);    
  end
  
  v = get(params.text_Status_Recording,'String');
  if biasstatus.logging == 0,
    if strcmpi(v,'On'),
      set(params.text_Status_Recording,'BackgroundColor',params.grayed_bkgdcolor,...
        'String','Off');
      fprintf('Needed to change recording status in preview from On to Off\n')
    end
  else
    if strcmpi(v,'Off'),
      set(params.text_Status_Recording,'BackgroundColor',params.Status_Recording_bkgdcolor,...
        'String','On');
      fprintf('Needed to change recording status in preview from Off to On\n')
    end
    
    % set frames written
    set(params.text_Status_FramesWritten,'String',num2str(biasstatus.frameCount));
    
  end

  % set frame rate
  set(params.text_Status_FrameRate,'String',sprintf('%.2f Hz',biasstatus.framesPerSec));
  
  currenttime = biasstatus.timeStamp;
  % TODO: figure out the units for this timestamp
  history = get(params.hLine_Status_FrameRate,'UserData');
  
  % did preview get stuck?
  if history(1,end) == currenttime,
  else
    history(:,1) = [];
    history(:,end+1) = [currenttime,biasstatus.framesPerSec];
    set(params.hLine_Status_FrameRate,...
      'Xdata',history(1,:)-history(1,end),...
      'Ydata',history(2,:),...
      'UserData',history);
  end
  
  AveFrameRate = biasstatus.frameCount / biasstatus.timeStamp;
  setappdata(params.text_Status_FrameRate,'AveFrameRate',AveFrameRate);
  
else
  
if strcmpi(params.AdaptorName,'udcam'),
  currenttime = get(obj.Source,'lastCaptureTime');
  empFrameRate = get(obj.Source,'empFrameRate');
  FrameCount = get(obj.Source,'nFramesLogged');
  %set(handles.text_Status_Recording,'String',sprintf('%.1f s',handles.writeFrame_time));
  set(params.text_Status_FramesWritten,'String',sprintf('%d',FrameCount));
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

% make sure the figure is still there
if ~ishandle(himage) || ~ishandle(params.axes_PreviewVideo),
  return;
end

% Display image data.
set(himage, 'CData', event.Data);

if params.ColormapPreview,
  colormap(params.axes_PreviewVideo,jet(256));
end

end

% Update last update time
setappdata(himage,'LastPreviewUpdateTime',now);

if params.IsRecording,
    
  daysrecording = now - params.StartRecording_Time_datenum;
  daysleft = params.RecordTimeDays - daysrecording;
  if daysleft > 0 && ishandle(params.pushbutton_Done),
    set(params.pushbutton_Done,'String',datestr(daysleft,13));
  end
end