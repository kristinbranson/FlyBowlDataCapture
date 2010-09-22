function handles = tryRecordStartTemp(handles)

if isfield(handles,'StartTempRecorded') && handles.StartTempRecorded,
  return;
end

% record from Pico probe stream
if handles.params.DoRecordTemp ~= 0,
  lasttemp = handles.Status_Temp_History(2,end);
  if ~isnan(lasttemp),
    handles.MetaData_RoomTemperature = lasttemp;
    handles.StartTempRecorded = true;
    handles.MetaDataNeedsSave = true;
    addToStatus(handles,sprintf('Recorded start temperature %f,lasttemp',lasttemp));
  end
end

% record from Precon probe
if isfield(handles.params,'NPreconSamples') && ...
    handles.params.NPreconSamples > 0,
  
end