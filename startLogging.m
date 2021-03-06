function startLogging(hObject)

%global FBDC_TempFid;

handles = guidata(hObject);

handles.StartRecording_Time_datenum = now;
handles.StartTempRecorded = false;
handles = tryRecordStartTemp(handles);

handles = SaveMetaData(handles);

% reserve this camera  
%load(handles.IsCameraRunningFile,'DevicesUsed');
%DevicesUsed(end+1) = handles.DeviceID; %#ok<NASGU>
%save('-append',handles.IsCameraRunningFile,'DevicesUsed');

% create a temporary name for the video
filestr = sprintf('FBDC_movie_%s.%s',...
  datestr(handles.StartRecording_Time_datenum,handles.TmpDateStrFormat),...
  handles.params.FileType);
handles.FileName = fullfile(handles.params.TmpOutputDirectory,filestr);
handles.IsTmpFileName = true;

% create a temporary name for the temperature
filestr = sprintf('FBDC_temperature_%s.txt',...
  datestr(handles.StartRecording_Time_datenum,handles.TmpDateStrFormat));
handles.TempFileName = fullfile(handles.params.TmpOutputDirectory,filestr);
addToStatus(handles,sprintf('Opening %s to write temperature stream',handles.TempFileName));
%FBDC_TempFid = -1;
handles.NTempGrabAttempts = 0;
% if handles.params.DoRecordTemp ~= 0,
%   try
%     FBDC_TempFid = fopen(handles.TempFileName,'w');
%     fprintf('Opened temperature file %s to fid %d\n',handles.TempFileName,FBDC_TempFid);
%   catch ME,
%     addToStatus(handles,{sprintf('Error opening temperature file %s',handles.TempFileName),...
%       getReport(ME,'basic','hyperlinks','off')});
%   end
%   if FBDC_TempFid <= 0,
%     s = sprintf('Could not open temperature file %s',handles.TempFileName);
%     addToStatus(handles,s);
%     uiwait(errordlg(s,'Error opening temperature file'));
%     error(s);
%   end
%   addToStatus(handles,sprintf('Opened temperature file %s for writing',handles.TempFileName));
% end
guidata(hObject,handles);

% number of frames written
handles.FrameCount = 0;

% frame rate
ss = getselectedsource(handles.vid);
tmp = get(ss);
if isfield(ss,'FrameRate'),
  handles.FPS = tmp.FrameRate;
else
  handles.FPS = handles.params.Imaq_FrameRate;
end

if strcmpi(handles.params.Imaq_Adaptor,'gdcam'),
  set(handles.vid.Source,'fmfFileName',handles.FileName);
  set(handles.vid.Source,'LogFlag',1)
elseif strcmpi(handles.params.Imaq_Adaptor,'udcam'),
  set(handles.vid.Source,'ufmfFileName',handles.FileName);
  set(handles.vid.Source,'nFramesTarget',handles.params.RecordTime*handles.params.Imaq_MaxFrameRate);
else
  % open video files for writing
  handles = openVideoFile(handles);
end

% video callbacks
if ~strcmpi(handles.params.Imaq_Adaptor,'udcam'),
  handles.vid.framesacquiredfcn = {@writeFrame,handles.figure_main};
  handles.vid.framesacquiredfcncount = 1;
end

% function called when video recording stops
%if ~strcmpi(handles.params.Imaq_Adaptor,'gdcam'),
%  handles.vid.stopfcn = {@wrapUpVideo,handles.figure_main,handles.params.Imaq_Adaptor,false};
%end

% for computing fps
handles.writeFrame_time = 0;

PreviewParams = getappdata(handles.hImage_Preview,'PreviewParams');
PreviewParams.IsRecording = true;

% create a timer for stopping 
handles.StopTimer = timer('TimerFcn',{@Stop_RecordTimer,handles.vid,handles.figure_main,handles.params.Imaq_Adaptor},...
  'StartDelay',handles.params.RecordTime,...
  'TasksToExecute',1,...
  'Name','FBDC_RecordTimer');

guidata(hObject,handles);

% start recording
if ~strcmpi(handles.params.Imaq_Adaptor,'udcam'),
  start(handles.vid);
else
  % nothing to do
end

% add to status log
addToStatus(handles,{sprintf('Started recording to file %s.',handles.FileName)},...
  handles.StartRecording_Time_datenum);

% set recording status
set(handles.text_Status_Recording,'String','On','BackgroundColor',handles.Status_Recording_bkgdcolor);

%guidata(hObject,handles);

PreviewParams.StartRecording_Time_datenum = handles.StartRecording_Time_datenum;
setappdata(handles.hImage_Preview,'PreviewParams',PreviewParams);

% start timer
start(handles.StopTimer);