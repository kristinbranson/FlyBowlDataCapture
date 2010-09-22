function [temp,humid,success] = getPreconReading(handles)

success = false;
temp = nan;
humid = nan;

handles.PreconRecordDir = '.PreconRecordData';
handles.PreconMasterFileStr = 'PreconTempHumid.txt';
handles.PreconMasterFile = fullfile(handles.PreconRecordDir,handles.PreconMasterFileStr);
if ~isfield(handles,'PreconSensorSerialPort'),
  addToStatus(handles,{'PreconSensorSerialPort not set in parameters. Not reading initial temp/humidity.'});
  return;
end
handles.PreconFid = fopen(handles.PreconMasterFile,'w');
try
  psobj = PreconSensor(handles.PreconSensorSerialPort);
catch ME,
  addToStatus(handles,{sprintf('Failed to initialize PreconSensor object with port %s',handles.PreconSensorSerialPort),...
    getReport(ME,'basic','hyperlinks','off')});
  fclose(handles.PreconFid);
  delete(handles.PreconMasterFile);
  return;
end
[success1,errormsg] = open(psobj);
if ~success1,
  addToStatus(handles,{sprintf('Error opening Precon sensor with port %s:',handles.PreconSensorSerialPort),errormsg});
  fclose(handles.PreconFid);
  delete(handles.PreconMasterFile);
  return;
end
[temp,humid,success1,errormsg] = read(psobj);
if ~success1,
  addToStatus(handles,{'Error reading Precon sensor:',errormsg});
  return;
end