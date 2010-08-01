function handles = setCamera(handles)

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
% maximum number of frames to record
handles.FramesPerTrigger = str2double(get(handles.vid.source,'FrameRate')) * handles.params.RecordTime;
set(handles.vid,'FramesPerTrigger',handles.FramesPerTrigger,'Name','FBDC_VideoInput');
handles.hImage_Preview = image( zeros(handles.vidRes(2), handles.vidRes(1), handles.nBands) , 'Parent', handles.axes_PreviewVideo); 
axis(handles.axes_PreviewVideo,'image');

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
handles = addToStatus(handles,{sprintf('%s: Video preview started.',datestr(now,handles.secondformat))});

% set preview status
set(handles.text_Status_Preview,'String','On','BackgroundColor',handles.Status_Preview_bkgdcolor);