function handles = tryRecordStartTemp(handles)

if ~isfield(handles,'StartTempRecorded'),
  return;
end

if ~handles.StartTempRecorded,

  % record from Precon probe
  if isfield(handles.params,'NPreconSamples') && ...
      handles.params.NPreconSamples > 0,
    [temp,humid,success] = getPreconReading(handles);
    if success ~= -1,
      handles.MetaData_RoomTemperature = temp;
      handles.MetaData_RoomHumidity = humid;
      handles.StartTempRecorded = true;
      addToStatus(handles,sprintf('Recorded start temp %f, humid %f',temp,humid));
    end
  end
  
end