function handles = setCamera(handles)

set(handles.figure_main,'Pointer','watch');

% for temporary names
handles.SetCamera_Time_datenum = now;

if ~isfield(handles,'DeviceID'), 
  pause(2);
end

if ~isfield(handles,'DeviceID'),
  s = sprintf('DeviceID not yet set');
  errordlg(s);
  error(s); %#ok<SPERR>
end

% check if this device is in use now
[isInUse,handles] = checkDeviceInUse(handles,handles.DeviceID,true);
if isInUse,
  set(handles.figure_main,'Pointer','arrow');
  return;
end

if strcmpi(handles.params.Imaq_Adaptor,'bias'),
  
  % set position
  pos = get(handles.figure_main,'Position');
  biaspos = [pos(1)+pos(3),pos(2),pos(3:4)];
  
  j = mod(handles.GUIi-1,size(handles.status_colors,1))+1;
  cameraname = sprintf('GUI%d(%s)',handles.GUIi,handles.status_color_names{j});

  [handles.vid,success,msg,warnings] = ConnectToBIAS(handles.BIASParams,handles.DeviceID,...
    'windowgeometry',biaspos,...
    'cameraname',cameraname);
  if ~success,
    errordlg(sprintf('Error connecting to camera: %s',msg));
    error(msg);
  end
  warning(sprintf('%s\n',warnings{:})); %#ok<SPWRN>
  
  handles.params.Imaq_DeviceName = regexprep(handles.vid.biasconfig.camera.model,'[^a-zA-Z0-9]','');
  handles.params.Imaq_VideoFormat = 'F7';
  handles.CameraUniqueID = handles.vid.biasconfig.camera.guid;
  
  handles.DeviceName = sprintf('Adaptor_%s___Name_%s___Format_%s___DeviceID_%d___UniqueID_%s',...
    handles.params.Imaq_Adaptor,...
    handles.params.Imaq_DeviceName,...
    handles.params.Imaq_VideoFormat,...
    handles.DeviceID,...
    handles.CameraUniqueID);
  
  addToStatus(handles,{sprintf('DeviceName = %s',handles.DeviceName)});

  % TODO: UFMF Log file not yet implemented
  
  % TODO: set preview callback, equivalent to this:
  % setappdata(handles.hImage_Preview,'UpdatePreviewWindowFcn',@UpdatePreview);
  % setappdata(handles.hImage_Preview,'LastPreviewUpdateTime',-inf);
  % %setappdata(handles.hImage_Preview,'NoChangeInTimestamp',0);
  PreviewParams = struct;
  PreviewParams.AdaptorName = handles.params.Imaq_Adaptor;
  PreviewParams.PreviewUpdatePeriod = handles.params.PreviewUpdatePeriod/86400;
  PreviewParams.pushbutton_Done = handles.pushbutton_Done;
  PreviewParams.RecordTimeDays = handles.params.RecordTime/86400;
  PreviewParams.StartRecording_Time_datenum = handles.StartRecording_Time_datenum;
  PreviewParams.IsRecording = handles.IsRecording;
  PreviewParams.text_Status_Recording = handles.text_Status_Recording;
  PreviewParams.text_Status_FrameRate = handles.text_Status_FrameRate;
  PreviewParams.text_Status_FramesWritten = handles.text_Status_FramesWritten;
  PreviewParams.hLine_Status_FrameRate = handles.hLine_Status_FrameRate;
  %PreviewParams.axes_PreviewVideo = handles.axes_PreviewVideo;
  PreviewParams.BIASParams = handles.vid.BIASParams;
  PreviewParams.grayed_bkgdcolor = handles.grayed_bkgdcolor;
  PreviewParams.Status_Recording_bkgdcolor = handles.Status_Recording_bkgdcolor;
  PreviewParams.GUIi = handles.GUIi;
  % PreviewParams.ColormapPreview = handles.params.ColormapPreview;
  % PreviewParams.DoRotatePreviewImage = handles.params.DoRotatePreviewImage;
  %
  setappdata(handles.text_Status_Preview,'PreviewParams',PreviewParams);
  setappdata(handles.text_Status_Preview,'LastPreviewUpdateTime',-inf);
  %
  % preview(handles.vid, handles.hImage_Preview);
  timername = sprintf('FBDC_Preview_Timer%d',handles.GUIi);
  handles.PreviewTimer = timer('ExecutionMode','FixedRate',...
    'Period',1,...
    'TimerFcn',{@UpdatePreview,handles.text_Status_Preview},...
    'StartDelay',1,...
    'Name',timername);
  start(handles.PreviewTimer);

  
  global FBDC_BIASCAMERASRUNNING; %#ok<TLEV>
  FBDC_BIASCAMERASRUNNING(end+1) = handles.DeviceID;
  
  handles.IsCameraInitialized = true;
  
  % add to status log
  addToStatus(handles,{'Video preview started.'});
  
  % set preview status
  set(handles.text_Status_Preview,'String','On','BackgroundColor',handles.Status_Preview_bkgdcolor);

else
  
  try
    %handles.vid = videoinput_kb(handles.DetectCameras_Params,handles.params.Imaq_Adaptor,handles.DeviceID,handles.params.Imaq_VideoFormat);
    %fprintf('Trying to call videoinput(%s,%d,%s)\n',handles.params.Imaq_Adaptor,handles.DeviceID,handles.params.Imaq_VideoFormat);
    handles.vid = videoinput(handles.params.Imaq_Adaptor,handles.DeviceID,handles.params.Imaq_VideoFormat);
  catch ME,
    s = sprintf('Could not initialize device id %d with format %s and adaptor %s. Try redetecting cameras.',...
      handles.DeviceID,handles.params.Imaq_VideoFormat,handles.params.Imaq_Adaptor);
    uiwait(errordlg(s,'Error initializing device'));
    error([s,'\n',getReport(ME)]);
  end
  
  handles.vidRes = get(handles.vid, 'VideoResolution');
  handles.nBands = get(handles.vid, 'NumberOfBands');
  srcparams = get(handles.vid.source);
  srcparamnames = fieldnames(srcparams);
  
  % get name for device
  if(any(strcmpi(srcparamnames,'UniqueID'))),
    handles.CameraUniqueID = get(handles.vid.source,'UniqueID');
  else
    handles.CameraUniqueID = sprintf('%d',handles.DeviceID);
  end
  
  handles.DeviceName = sprintf('Adaptor_%s___Name_%s___Format_%s___DeviceID_%d___UniqueID_%s',...
    handles.params.Imaq_Adaptor,...
    handles.params.Imaq_DeviceName,...
    handles.params.Imaq_VideoFormat,...
    handles.DeviceID,...
    handles.CameraUniqueID);
  
  addToStatus(handles,{sprintf('DeviceName = %s',handles.DeviceName)});

  % read frame rate from videoinput if possible
  if any(strcmpi(srcparamnames,'FrameRate')),
    handles.params.Imaq_FrameRate = str2double(get(handles.vid.source,'FrameRate'));
  end

  % set shutter period if possible and necessary
  if isfield(handles.params,'Imaq_Shutter') && handles.params.Imaq_Shutter > 0 && ...
      any(strcmpi(srcparamnames,'Shutter')),
    set(handles.vid.source,'Shutter',handles.params.Imaq_Shutter);
  end
  
  % set shutter period if possible and necessary
  if isfield(handles.params,'Imaq_Brightness') && handles.params.Imaq_Brightness > 0 && ...
      any(strcmpi(srcparamnames,'Brightness')),
    set(handles.vid.source,'Brightness',handles.params.Imaq_Brightness);
  end
  
  % set previewFrameInterval if gdcam
  if strcmpi(handles.params.Imaq_Adaptor,'gdcam'),
    set(handles.vid.source,'previewFrameInterval',handles.params.gdcamPreviewFrameInterval);
  end
  
  % set ROI if necessary
  if isfield(handles.params,'Imaq_ROIPosition'),
    set(handles.vid,'ROIPosition',handles.params.Imaq_ROIPosition);
  end
  if strcmpi(handles.params.Imaq_Adaptor,'udcam'),
    
    % create a temporary name for the log file
    filestr = sprintf('FBDC_UFMF_Log_%s.txt',...
      datestr(handles.SetCamera_Time_datenum,handles.TmpDateStrFormat));
    handles.TmpUFMFLogFileName = fullfile(handles.params.TmpOutputDirectory,filestr);
    
    % create a temporary name for the diagnostics file
    filestr = sprintf('FBDC_UFMF_Diagnostics_%s.txt',...
      datestr(handles.SetCamera_Time_datenum,handles.TmpDateStrFormat));
    handles.TmpUFMFStatFileName = fullfile(handles.params.TmpOutputDirectory,filestr);
    
    if isfield(handles.params,'UFMFMaxFracFgCompress'),
      set(handles.vid.Source,'maxFracFgCompress',handles.params.UFMFMaxFracFgCompress);
    end
    if isfield(handles.params,'UFMFMaxBGNFrames'),
      set(handles.vid.Source,'maxBGNFrames',handles.params.UFMFMaxBGNFrames);
    end
    if isfield(handles.params,'UFMFBGUpdatePeriod'),
      set(handles.vid.Source,'BGUpdatePeriod',handles.params.UFMFBGUpdatePeriod);
    end
    if isfield(handles.params,'UFMFBGKeyFramePeriod'),
      set(handles.vid.Source,'BGKeyFramePeriod',handles.params.UFMFBGKeyFramePeriod);
    end
    if isfield(handles.params,'UFMFMaxBoxLength'),
      set(handles.vid.Source,'boxLength',handles.params.UFMFMaxBoxLength);
    end
    if isfield(handles.params,'UFMFBackSubThresh'),
      set(handles.vid.Source,'backSubThresh',handles.params.UFMFBackSubThresh);
    end
    if isfield(handles.params,'UFMFNFramesInit'),
      set(handles.vid.Source,'nFramesInit',handles.params.UFMFNFramesInit);
    end
    if isfield(handles.params,'UFMFLogFileName'),
      set(handles.vid.Source,'debugFileName',handles.TmpUFMFLogFileName);
      fprintf('Set log file to %s\n',handles.TmpUFMFLogFileName);
    end
    if isfield(handles.params,'UFMFStatFileName'),
      set(handles.vid.Source,'statFileName',handles.TmpUFMFStatFileName);
    end
    if isfield(handles.params,'UFMFPrintStats'),
      set(handles.vid.Source,'printStats',handles.params.UFMFPrintStats);
    end
    if isfield(handles.params,'UFMFStatStreamPrintFreq'),
      set(handles.vid.Source,'statStreamPrintFreq',handles.params.UFMFStatStreamPrintFreq);
    end
    if isfield(handles.params,'UFMFStatComputeFrameErrorFreq'),
      set(handles.vid.Source,'statComputeFrameErrorFreq',handles.params.UFMFStatComputeFrameErrorFreq);
    end
    if isfield(handles.params,'UFMFStatPrintTimings'),
      set(handles.vid.Source,'statPrintTimings',handles.params.UFMFStatPrintTimings);
    end
    if isfield(handles.params,'UFMFBGKeyFramePeriodInit'),
      v = get(handles.vid.Source,'bgKeyFramePeriodInit');
      l = min(length(v),length(handles.params.UFMFBGKeyFramePeriodInit));
      v(:) = 0;
      v(1:l) = handles.params.UFMFBGKeyFramePeriodInit(1:l);
      set(handles.vid.Source,'bgKeyFramePeriodInit',v);
    end
    
    try
      udcam_version = get(handles.vid.Source,'version');
    catch %#ok<CTCH>
      udcam_version = '????';
    end
    addToStatus(handles,sprintf('UDCAM version %s',udcam_version));
  end

  %   % get camera unique ID if available
  %   if any(strcmpi(srcparamnames,'UniqueID')),
  %     handles.DeviceUniqueID = get(handles.vid.source,'UniqueID');
  %   else
  %     handles.DeviceUniqueID = '';
  %   end
  
  % maximum number of frames to record
  handles.FramesPerTrigger = handles.params.Imaq_MaxFrameRate * handles.params.RecordTime;
  set(handles.vid,'FramesPerTrigger',handles.FramesPerTrigger,'Name','FBDC_VideoInput');
  if isfield(handles.params,'Imaq_ROIPosition'),
    sz = handles.params.Imaq_ROIPosition([4,3]);
  else
    sz = handles.vidRes([2,1]);
  end
  tmp = zeros(sz(1), sz(2), handles.nBands,'uint8');
  tmp(1,1,:) = 255;
  handles.hImage_Preview = image( tmp , 'Parent', handles.axes_PreviewVideo);
  if handles.nBands == 1,
    colormap(handles.axes_PreviewVideo,gray(256));
  end
  axis(handles.axes_PreviewVideo,'image');

  RotatePreviewImage(handles);

  % Error function
  set(handles.vid,'ErrorFcn',@vidError);

  % Set up the update preview window function.
  setappdata(handles.hImage_Preview,'UpdatePreviewWindowFcn',@UpdatePreview);
  setappdata(handles.hImage_Preview,'LastPreviewUpdateTime',-inf);
  %setappdata(handles.hImage_Preview,'NoChangeInTimestamp',0);
  PreviewParams = struct;
  PreviewParams.AdaptorName = handles.params.Imaq_Adaptor;
  PreviewParams.PreviewUpdatePeriod = handles.params.PreviewUpdatePeriod/86400;
  PreviewParams.pushbutton_Done = handles.pushbutton_Done;
  PreviewParams.RecordTimeDays = handles.params.RecordTime/86400;
  PreviewParams.StartRecording_Time_datenum = handles.StartRecording_Time_datenum;
  PreviewParams.IsRecording = handles.IsRecording;
  PreviewParams.text_Status_FrameRate = handles.text_Status_FrameRate;
  PreviewParams.text_Status_FramesWritten = handles.text_Status_FramesWritten;
  PreviewParams.hLine_Status_FrameRate = handles.hLine_Status_FrameRate;
  PreviewParams.axes_PreviewVideo = handles.axes_PreviewVideo;
  PreviewParams.ColormapPreview = handles.params.ColormapPreview;
  PreviewParams.DoRotatePreviewImage = handles.params.DoRotatePreviewImage;
  
  setappdata(handles.hImage_Preview,'PreviewParams',PreviewParams);

  preview(handles.vid, handles.hImage_Preview);

  % gain needs to be set after preview for some reason?
  % set gain if possible and necessary
  if isfield(handles.params,'Imaq_Gain') && handles.params.Imaq_Gain > 0 && ...
      any(strcmpi(srcparamnames,'Gain')),
    set(handles.vid.source,'Gain',handles.params.Imaq_Gain);
  end

  handles.IsCameraInitialized = true;

  % set up timer to check if preview is not being updated
  CheckPreviewParams.hImage_Preview = handles.hImage_Preview;
  CheckPreviewParams.MaxPreviewUpdatePeriod = 3;
  CheckPreviewParams.figure_main = handles.figure_main;
  CheckPreviewParams.GUIi = handles.GUIi;
  timername = sprintf('FBDC_CheckPreview_Timer%d',handles.GUIi);
  handles.CheckPreviewTimer = timer('ExecutionMode','FixedRate',...
    'Period',1,...
    'TimerFcn',{@CheckPreview,CheckPreviewParams},...
    'StartDelay',1,...
    'Name',timername);
  start(handles.CheckPreviewTimer);
  
  % add to status log
  addToStatus(handles,{'Video preview started.'});
  
  % set preview status
  set(handles.text_Status_Preview,'String','On','BackgroundColor',handles.Status_Preview_bkgdcolor);
  
  % write a semaphore to file saying that we should not call
  % imaqhwinfo('dcam')
  adaptorinfo = handles.adaptorinfo; %#ok<NASGU>
  handles.IsCameraRunningFile = fullfile(handles.DetectCameras_Params.DataDir,...
    sprintf('%s_%s_%d.mat',handles.DetectCameras_Params.IsCameraRunningFileStr,handles.params.Imaq_Adaptor,handles.DeviceID));
  if ~exist(handles.DetectCameras_Params.DataDir,'file'),
    mkdir(handles.DetectCameras_Params.DataDir);
  end
  save(handles.IsCameraRunningFile,'adaptorinfo');
  global FBDC_IsCameraRunningFiles; %#ok<TLEV>
  if isempty(FBDC_IsCameraRunningFiles),
    FBDC_IsCameraRunningFiles = {handles.IsCameraRunningFile};
  else
    FBDC_IsCameraRunningFiles{end+1} = handles.IsCameraRunningFile;
  end

end

set(handles.figure_main,'Pointer','arrow');
