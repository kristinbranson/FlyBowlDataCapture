function success = TempProbe_GrabTemp(obj,event,hObject) %#ok<INUSL>

global FBDC_DIDHALT;

try

success = false;
if ~ishandle(hObject),
  return;
end

handles = guidata(hObject);

% stop if we've halted
if numel(FBDC_DIDHALT) >= handles.GUIi && FBDC_DIDHALT(handles.GUIi),
  try
    if strcmpi(get(obj,'Running'),'on'),
      stop(obj);
    end
  catch ME
    getReport(ME)
  end
end

%global FBDC_TempFid;


% check if we are quitting
if ~isfield(handles,'figure_main') || ~ishandle(handles.figure_main),
  return;
end

if handles.params.DoRecordTemp == 0,
  return;
end
try
  fid = fopen(handles.TempProbe_ChannelFileName,'r');
  if fid <= 0,
    addToStatus(handles,sprintf('Error opening file %s to read temperature data',handles.TempProbe_ChannelFileName));
    guidata(hObject,handles);
    return;
  end
  % make sure fid is valid
  [filename,permission] = fopen(fid);
  if isempty(filename) || isempty(permission),
    addToStatus(handles,sprintf('Invalid temperature probe semaphore fid %d for file %s',fid,handles.TempProbe_ChannelFileName));
  end
  [data,count] = fscanf(fid,'%f',3);
  fclose(fid);
  if count < 3,
    addToStatus(handles,sprintf('Missing temperature data in file %s',handles.TempProbe_ChannelFileName));
    guidata(hObject,handles);
    return;
  end
catch ME,
  addToStatus(handles,sprintf('Error reading temperature data from file %s',handles.TempProbe_ChannelFileName));
  guidata(hObject,handles);
  getReport(ME)
  return;
end
timestamp = data(1)*86400; % convert from days to seconds
temp = data(2);
overflow = data(3);
if overflow,
  temp = nan;
end
if(handles.Status_Temp_History(1,end-5) == timestamp)
  addToStatus(handles,'No change in temperature over past 5 samples');
end
handles.Status_Temp_History(:,1) = [];
handles.Status_Temp_History(:,end+1) = [timestamp;temp];
%fprintf('Read: timestamp = %s, temp = %f\n',datestr(timestamp,13),temp);
if overflow ~= 0,
  addToStatus(handles,sprintf('Temp probe channel %d overflowed\n', handles.TempProbeID));
end
if handles.IsRecording,
  if ~isfield(handles,'StartTempRecorded') || ~handles.StartTempRecorded,
    handles = tryRecordStartTemp(handles);
  end
  success = false;
  if ~isfield(handles,'NTempGrabAttempts'),
    handles.NTempGrabAttempts = 0;
  end
  if ~isfield(handles,'TempStreamDisabled'),
    handles.TempStreamDisabled = false;
  end
  if handles.TempStreamDisabled,
    addToStatus(handles,'Temperature stream saving disabled');
  else
    if isfield(handles,'TempFileName') && ~isempty(handles.TempFileName),
      if handles.TempFileIsCreated,
        TempFid = fopen(handles.TempFileName,'a');
      else
        if exist(handles.TempFileName,'file'),
          addToStatus(handles,sprintf('TempFileIsCreated == false, but %s exists',handles.TempFileName));
          TempFid = -1;
        else
          TempFid = fopen(handles.TempFileName,'w');
          handles.TempFileIsCreated = true;
          guidata(hObject,handles);
          addToStatus(handles,sprintf('Created temperature file %s',handles.TempFileName));
        end
      end
      if TempFid <= 0,
        addToStatus(handles,sprintf('Could not open file %s',handles.TempFileName));
      else
        try
          fprintf(TempFid,'%f,%f\n',timestamp,temp);
          fclose(TempFid);
          success = true;
        catch ME,
          addToStatus(handles,{'Error writing temperature to file',getReport(ME,'extended','hyperlinks','off')});
        end
      end
    end
    if success,
      handles.NTempGrabAttempts = 0;
    else
      handles.NTempGrabAttempts = handles.NTempGrabAttempts + 1;
      if handles.NTempGrabAttempts > handles.MaxNTempGrabAttempts,
        handles.TempStreamDisabled = true;
        guidata(hObject,handles);
        warndlg(sprintf('Failed to write temperature for > %d consecutive attempts. Disabling temperature recording.',handles.MaxNTempGrabAttempts),'Error recording temperature','modal');
        pause(.1);
      end
    end
  end
end
guidata(hObject,handles);

% check if we are quitting
if ~isfield(handles,'figure_main') || ~ishandle(handles.figure_main),
  return;
end

set(handles.hLine_Status_Temp,'XData',handles.Status_Temp_History(1,:)-handles.Status_Temp_History(1,end),...
  'YData',handles.Status_Temp_History(2,:));
drawnow;

success = true;

catch ME
  
  getReport(ME)
  addToStatus(handles,{'Error grabbing temperature',getReport(ME,'extended','hyperlinks','off')});
  rethrow(ME);
  
end