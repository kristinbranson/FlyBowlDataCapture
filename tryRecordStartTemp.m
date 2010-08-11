function handles = tryRecordStartTemp(handles)

lasttemp = handles.Status_Temp_History(2,end);
if ~isnan(lasttemp),
  handles.MetaData_RoomTemperature = lasttemp;
  handles.StartTempRecorded = true;
  handles.MetaDataNeedsSave = true;
end
