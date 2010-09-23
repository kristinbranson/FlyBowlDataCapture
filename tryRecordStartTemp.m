function handles = tryRecordStartTemp(handles)

if ~(isfield(handles,'StartTempRecorded') && handles.StartTempRecorded),

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

end

if ~(isfield(handles,'StartHumidRecorded') && handles.StartHumidRecorded),

  % record from Precon probe
  if isfield(handles.params,'NPreconSamples') && ...
      handles.params.NPreconSamples > 0,
    [temp,humid,success] = getPreconReading(handles);
    if success ~= -1,
      handles.MetatData_PreconRoomTemperature = temp;
      handles.MetaData_RoomHumidity = humid;
      handles.StartHumidRecorded = true;
    end
  end
  
end