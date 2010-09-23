function success = TempProbe_GrabTemp(obj,event,hObject) %#ok<INUSL>

success = false;
handles = guidata(hObject);
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
handles.Status_Temp_History(:,1) = [];
handles.Status_Temp_History(:,end+1) = [timestamp;temp];
%fprintf('Read: timestamp = %s, temp = %f\n',datestr(timestamp,13),temp);
if overflow ~= 0,
  addToStatus(handles,sprintf('Temp probe channel %d overflowed\n', handles.TempProbeID));
end
if handles.IsRecording,
  if ~isfield(handles,'StartTempRecorded') || ~handles.StartTempRecorded || ...
      ~isfield(handles,'StartHumidRecorded') || ~handles.StartHumidRecorded,
    handles = tryRecordStartTemp(handles);
  end
  fprintf(handles.TempFid,'%f,%f\n',timestamp,temp);
end
guidata(handles.figure_main,handles);
set(handles.hLine_Status_Temp,'XData',handles.Status_Temp_History(1,:)-handles.Status_Temp_History(1,end),...
  'YData',handles.Status_Temp_History(2,:));
drawnow;

success = true;