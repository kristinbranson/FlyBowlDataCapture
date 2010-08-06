function startLogging(hObject)

handles = guidata(hObject);

handles.StartRecording_Time_datenum = now;

handles = SaveMetaData(handles);

% create a temporary name for the video
filestr = sprintf('FBDC_movie_%s_%d.%s',...
  datestr(handles.StartRecording_Time_datenum,30),...
  randi(9999,1),handles.params.FileType);
handles.FileName = fullfile(handles.params.TmpOutputDirectory,filestr);
handles.IsTmpFileName = true;

% copied from gVision/StartStop.m

% number of frames written
handles.FrameCount = 0;

% frame rate
ss = getselectedsource(handles.vid);
handles.FPS = str2double(get(ss,'FrameRate'));

% open video files for writing
handles = openVideoFile(handles);

% video callbacks
handles.vid.framesacquiredfcn = {@writeFrame,handles.figure_main};
handles.vid.stopfcn = {@wrapUpVideo,handles.figure_main};

handles.vid.framesacquiredfcncount = 1;

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
handles = addToStatus(handles,{sprintf('%s: Started recording to file %s.',...
  datestr(handles.StartRecording_Time_datenum,handles.secondformat),handles.FileName)});

% set recording status
set(handles.text_Status_Recording,'String','On','BackgroundColor',handles.Status_Recording_bkgdcolor);

guidata(hObject,handles);

PreviewParams.StartRecording_Time_datenum = handles.StartRecording_Time_datenum;
setappdata(handles.hImage_Preview,'PreviewParams',PreviewParams);

% start timer
start(handles.StopTimer);