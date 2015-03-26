function success = startLogging(hObject)

%global FBDC_TempFid;

success = false;

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


if strcmpi(handles.params.Imaq_Adaptor,'bias'),
  hpreview = handles.text_Status_Preview;
else
  hpreview = handles.hImage_Preview;
end

PreviewParams = getappdata(hpreview,'PreviewParams');
PreviewParams.IsRecording = true;

%guidata(hObject,handles);

PreviewParams.StartRecording_Time_datenum = handles.StartRecording_Time_datenum;
setappdata(hpreview,'PreviewParams',PreviewParams);

% set recording status
set(handles.text_Status_Recording,'String','Waiting');

% store record start time in button string
set(handles.pushbutton_StartRecording,'BackgroundColor',handles.grayed_bkgdcolor,...
  'String',sprintf('Rec: %s',datestr(handles.StartRecording_Time_datenum,13)));

global FBDC_DIDHALT;
GUIi = handles.GUIi;
if numel(FBDC_DIDHALT) < GUIi,
  FBDC_DIDHALT(GUIi) = false;
end
if isfield(handles.params,'ExperimentStartDelay') && ...
    handles.params.ExperimentStartDelay > 0,
  
  addToStatus(handles,sprintf('Waiting %f seconds to start experiment...',handles.params.ExperimentStartDelay));
  
  delaystart = tic;
  while toc(delaystart) < handles.params.ExperimentStartDelay > 0,
    pause(0.01);
    if FBDC_DIDHALT(GUIi),
      return;
    end
  end
  
  addToStatus(handles,'Done waiting!');

end

% set recording status
set(handles.text_Status_Recording,'String','On','BackgroundColor',handles.Status_Recording_bkgdcolor);

% number of frames written
handles.FrameCount = 0;

handles.StartedRecordingVideo = true;
guidata(hObject,handles);

if strcmpi(handles.params.Imaq_Adaptor,'bias'),
  
  [success,msg,handles.StartVideoTime_datenum] = BIASStartLogging(handles.vid.BIASURL,handles.FileName,handles);
  if ~success,
    errordlg(sprintf('Error starting logging in BIAS: %s',msg),'Error starting logging in BIAS');
  end
  % TODO: better error handling
  
else
  
handles.StartVideoTime_datenum = now;

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

end

if strcmpi(handles.params.Imaq_Adaptor,'bias') && ...
    isfield(handles,'hLine_Status_FrameRate') && ...
    ishandle(handles.hLine_Status_FrameRate),
  history = get(handles.hLine_Status_FrameRate,'UserData');
  history(:,1) = [];
  history(:,end+1) = [nan,nan];
  set(handles.hLine_Status_FrameRate,'UserData',history);
end

if ~handles.params.doChR,

  % create a timer for stopping
  timername = sprintf('FBDC_RecordTimer%d',handles.GUIi);
  handles.StopTimer = timer('TimerFcn',{@Stop_RecordTimer,handles.vid,handles.figure_main,handles.params.Imaq_Adaptor},...
    'StartDelay',handles.params.RecordTime,...
    'TasksToExecute',1,...
    'Name',timername);
  
end
  
guidata(hObject,handles);

% start recording
if ~ismember(lower(handles.params.Imaq_Adaptor),{'udcam','bias'}),
  start(handles.vid);
else
  % nothing to do
end

% add to status log
addToStatus(handles,{sprintf('Started recording to file %s.',handles.FileName)},...
  handles.StartVideoTime_datenum);

if handles.params.doChR,
  
  expTimeFileID = fopen(handles.StimulusTimingLogFileName,'w');
  fprintf(expTimeFileID,'%.10f,start_camera,%d\n', handles.StartVideoTime_datenum, -1 );
  success = RunStimulusProtocol(handles,expTimeFileID);
  fclose(expTimeFileID);
  
  % close experiment
  stoptime = wrapUpVideo(handles.vid,[],handles.figure_main,handles.params.Imaq_Adaptor,~success);
  
  handles = guidata(hObject);
  
  expTimeFileID = fopen(handles.StimulusTimingLogFileName,'a+');
  fprintf(expTimeFileID,'%.10f,stop_camera,%d\n', stoptime, -1 );
  fclose(expTimeFileID);
  
else

  % start timer
  start(handles.StopTimer);
  
end

success = true;