% [temp,humid,success] = getPreconReading(handles)
% success == -1 when busy and should retry
%             0 if there is an error
%             1 if successfully read
function [temp,humid,success] = getPreconReading(handles)

% if a reading was taken in the last 30 seconds, then we will reuse
MaxValidReadingTime = 30; 

success = 0;
temp = nan;
humid = nan;

if ~isfield(handles.params,'PreconSensorSerialPort'),
  addToStatus(handles,{'PreconSensorSerialPort not set in parameters. Not reading initial temp/humidity.'});
  return;
end

handles.PreconRecordDir = '.PreconRecordData';
handles.PreconInUseFileStr = 'InUse';
handles.PreconReadingFileStr = 'PreconTempHumid';
handles.PreconInUseFile = fullfile(handles.PreconRecordDir,sprintf('%s_%s.txt',handles.PreconInUseFileStr,handles.params.PreconSensorSerialPort));
handles.PreconReadingFile = fullfile(handles.PreconRecordDir,sprintf('%s_%s.txt',handles.PreconReadingFileStr,handles.params.PreconSensorSerialPort));

% in use, try again later
if exist(handles.PreconInUseFile,'file'),
  success = -1;
  return;
end

global FBDC_PreconSemaphoreFiles;
if isempty(FBDC_PreconSemaphoreFiles),
  FBDC_PreconSemaphoreFiles = {};
end

% try to read from file
if exist(handles.PreconReadingFile,'file'),
  fid = fopen(handles.PreconReadingFile,'r');
  if fid > 0,
    % read timestamp
    timestamp = fscanf(fid,'%f\n');
    
    % is the data still valid?
    dt = (now - timestamp)*86400; % days to seconds
    if dt <= MaxValidReadingTime,
      
      % read data
      [data,count] = fscanf(fid,'%f,%f\n');
      fclose(fid);
      
      % parse, take mean, and return
      if count >= 2,
        data = reshape(data,[2,count/2]);
        temp = data(1,:);
        humid = data(2,:);
        temp = nanmean(temp);
        humid = nanmean(humid);
        success = 1;
        return;
      end
      
    else
      
      % file no longer valid, delete
      fclose(fid);
      delete(handles.PreconReadingFile);
      
    end
  end
end

if ~exist(handles.PreconRecordDir,'file'),
  [success1,msg] = mkdir(handles.PreconRecordDir);
  if ~success1,
    addToStatus(handles,{sprintf('Could not create Precon semaphore directory %s:',handles.PreconRecordDir),msg});
    return;
  end
end
fid = fopen(handles.PreconInUseFile,'w');
if fid < 0,
  addToStatus(handles,{sprintf('Could not open semaphore file %s',handles.PreconInUseFile)});
  return;
end
FBDC_PreconSemaphoreFiles{end+1} = handles.PreconInUseFile;

fprintf(fid,datestr(now));
fclose(fid);
try
  psobj = PreconSensor(handles.params.PreconSensorSerialPort);
catch ME,
  addToStatus(handles,{sprintf('Failed to initialize PreconSensor object with port %s',handles.params.PreconSensorSerialPort),...
    getReport(ME,'basic','hyperlinks','off')});
  delete(handles.PreconInUseFile);
  FBDC_PreconSemaphoreFiles(end) = [];
  return;
end
[success1,errormsg] = open(psobj);
if ~success1,
  addToStatus(handles,{sprintf('Error opening Precon sensor with port %s:',handles.params.PreconSensorSerialPort),errormsg});
  delete(handles.PreconInUseFile);
  FBDC_PreconSemaphoreFiles(end) = [];
  return;
end
[temp,humid,success1,errormsg] = read(psobj);
if ~success1,
  addToStatus(handles,{'Error reading Precon sensor:',errormsg});
  delete(handles.PreconInUseFile);
  FBDC_PreconSemaphoreFiles(end) = [];
  return;
end
[success1,errormsg] = close(psobj);
if ~success1,
  addToStatus(handles,{'Error closing Precon sensor:',errormsg});
  delete(handles.PreconInUseFile);
  FBDC_PreconSemaphoreFiles(end) = [];
  return;
end
fid = fopen(handles.PreconReadingFile,'w');
if fid < 0,
  addToStatus(handles,{sprintf('Could not open Precon reading file %s',handles.PreconReadingFile)});
  delete(handles.PreconInUseFile);
  FBDC_PreconSemaphoreFiles(end) = [];
  return;
end
FBDC_PreconSemaphoreFiles{end+1} = handles.PreconReadingFile;
fprintf(fid,'%f\n',now);
fprintf(fid,'%f,%f\n',[temp;humid]);
fclose(fid);
delete(handles.PreconInUseFile);
FBDC_PreconSemaphoreFiles(end-1) = [];

temp = nanmean(temp);
humid = nanmean(humid);

addToStatus(handles,{sprintf('Read start temperature %f and humidity %f from Precon sensor',temp,humid)});

success = 1;
