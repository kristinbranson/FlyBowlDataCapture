function handles = setCamera(handles)

if ~isfield(handles,'DeviceID'), 
  pause(2);
end

if ~isfield(handles,'DeviceID'),
  error('DeviceID not yet set');
end

try
  handles.vid = videoinput(handles.params.Imaq_Adaptor,handles.DeviceID,handles.params.Imaq_VideoFormat);
catch
  s = sprintf('Could not initialize device id %d with format %s and adaptor %s. Try redetecting cameras.',...
    handles.DeviceID,handles.params.Imaq_VideoFormat,handles.params.Imaq_Adaptor);
  uiwait(errordlg(s,'Error initializing device'));
  error(s);
end

% TODO: set properties like shutter speed
% vid_src = getselectedsource(vid);

handles.vidRes = get(handles.vid, 'VideoResolution'); 
handles.nBands = get(handles.vid, 'NumberOfBands'); 
srcparams = get(handles.vid.source);
srcparamnames = fieldnames(srcparams);

% read frame rate from videoinput if possible
if any(strcmpi(srcparamnames,'FrameRate')),
  handles.params.Imaq_FrameRate = str2double(get(handles.vid.source,'FrameRate'));
end

% set shutter period if possible and necessary
if isfield(handles.params,'Imaq_Shutter') && handles.params.Imaq_Shutter > 0 && ...
    any(strcmpi(srcparamnames,'Shutter')),
  set(handles.vid.source,'Shutter',handles.params.Imaq_Shutter);
end

% set gain if possible and necessary
if isfield(handles.params,'Imaq_Gain') && handles.params.Imaq_Gain > 0 && ...
    any(strcmpi(srcparamnames,'Gain')),
  set(handles.vid.source,'Gain',handles.params.Imaq_Gain);
end

% get camera unique ID if available
if any(strcmpi(srcparamnames,'UniqueID')),
  handles.DeviceUniqueID = get(handles.vid.source,'UniqueID');
else
  handles.DeviceUniqueID = '';
end

% maximum number of frames to record
handles.FramesPerTrigger = handles.params.Imaq_FrameRate * handles.params.RecordTime;
set(handles.vid,'FramesPerTrigger',handles.FramesPerTrigger,'Name','FBDC_VideoInput');
tmp = zeros(handles.vidRes(2), handles.vidRes(1), handles.nBands,'uint8');
tmp(1,1,:) = 255;
handles.hImage_Preview = image( tmp , 'Parent', handles.axes_PreviewVideo); 
if handles.nBands == 1,
  colormap(handles.axes_PreviewVideo,gray(256));
end
axis(handles.axes_PreviewVideo,'image');

% Error function
set(handles.vid,'ErrorFcn',@vidError);

% timeout time
set(handles.vid.Source,'FrameTimeOut',20000);

% Set up the update preview window function.
setappdata(handles.hImage_Preview,'UpdatePreviewWindowFcn',@UpdatePreview);
setappdata(handles.hImage_Preview,'LastPreviewUpdateTime',-inf);
PreviewParams = struct;
PreviewParams.PreviewUpdatePeriod = handles.params.PreviewUpdatePeriod/86400;
PreviewParams.pushbutton_Done = handles.pushbutton_Done;
PreviewParams.RecordTimeDays = handles.params.RecordTime/86400;
PreviewParams.StartRecording_Time_datenum = handles.StartRecording_Time_datenum;
PreviewParams.IsRecording = handles.IsRecording;
setappdata(handles.hImage_Preview,'PreviewParams',PreviewParams);

preview(handles.vid, handles.hImage_Preview); 
handles.IsCameraInitialized = true;

% add to status log
handles = addToStatus(handles,{'Video preview started.'});

% set preview status
set(handles.text_Status_Preview,'String','On','BackgroundColor',handles.Status_Preview_bkgdcolor);

% write a semaphore to file saying that we should not call
% imaqhwinfo('dcam')
adaptorinfo = handles.adaptorinfo; %#ok<NASGU>
handles.IsCameraRunningFile = fullfile(handles.DetectCameras_Params.DataDir,...
  sprintf('%s_%s.mat',handles.DetectCameras_Params.IsCameraRunningFileStr,datestr(now,30)));
if ~exist(handles.DetectCameras_Params.DataDir,'file'),
  mkdir(handles.DetectCameras_Params.DataDir);
end
save(handles.IsCameraRunningFile,'adaptorinfo');
global FBDC_IsCameraRunningFiles; 
if isempty(FBDC_IsCameraRunningFiles),
  FBDC_IsCameraRunningFiles = {handles.IsCameraRunningFile};
else
  FBDC_IsCameraRunningFiles{end+1} = handles.IsCameraRunningFile;
end
