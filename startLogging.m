function startLogging(hObject)

handles = guidata(hObject);

handles.StartRecording_Time_datenum = now;
handles.StartTempRecorded = false;
handles = tryRecordStartTemp(handles);

handles = SaveMetaData(handles);

% create a temporary name for the video
handles.RandomNumber = randi(9999,1);
filestr = sprintf('FBDC_movie_%s_%d.%s',...
  datestr(handles.StartRecording_Time_datenum,30),...
  handles.RandomNumber,handles.params.FileType);
handles.FileName = fullfile(handles.params.TmpOutputDirectory,filestr);
handles.IsTmpFileName = true;

% create a temporary name for the temperature
filestr = sprintf('FBDC_temperature_%s_%d.txt',...
  datestr(handles.StartRecording_Time_datenum,30),...
  handles.RandomNumber);
handles.TempFileName = fullfile(handles.params.TmpOutputDirectory,filestr);
handles.TempFid = -1;
if handles.params.DoRecordTemp ~= 0,
  try
    handles.TempFid = fopen(handles.TempFileName,'w');
  catch
  end
  if handles.TempFid <= 0,
    s = sprintf('Could not open temperature file %s',handles.TempFileName);
    uiwait(errordlg(s,'Error opening temperature file'));
    error(s);
  end
end

% copied from gVision/StartStop.m

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
end


% open video files for writing
handles = openVideoFile(handles);

% video callbacks
handles.vid.framesacquiredfcn = {@writeFrame,handles.figure_main};
handles.vid.framesacquiredfcncount = 1;

% function called when video recording stops
handles.vid.stopfcn = {@wrapUpVideo,handles.figure_main};

% for computing fps
handles.writeFrame_time = 0;

PreviewParams = getappdata(handles.hImage_Preview,'PreviewParams');
PreviewParams.IsRecording = true;

% create a timer for stopping 
handles.StopTimer = timer('TimerFcn',{@Stop_RecordTimer,handles.vid,handles.figure_main},...
  'StartDelay',handles.params.RecordTime,...
  'TasksToExecute',1,...
  'Name','FBDC_RecordTimer');

guidata(hObject,handles);

% start recording
start(handles.vid);

% add to status log
handles = addToStatus(handles,{sprintf('Started recording to file %s.',handles.FileName)},...
  handles.StartRecording_Time_datenum);

% set recording status
set(handles.text_Status_Recording,'String','On','BackgroundColor',handles.Status_Recording_bkgdcolor);

guidata(hObject,handles);

PreviewParams.StartRecording_Time_datenum = handles.StartRecording_Time_datenum;
setappdata(handles.hImage_Preview,'PreviewParams',PreviewParams);

% start timer
start(handles.StopTimer);