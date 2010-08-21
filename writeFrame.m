function writeFrame(obj,event,hObject) %#ok<INUSL>

% copied from gVision/StartStop.m:writeFullROI

% get a frame
[frame,time,metadata] = getdata(obj,1); %#ok<NASGU>
%fprintf('Writing frame %d at time %f\n',metadata.FrameNumber,time);

handles = guidata(hObject);

if strcmpi(handles.params.Imaq_Adaptor,'gdcam'),
  
  nFramesLogged = get(handles.vid.Source,'nFramesLogged');
  nFramesCurr = nFramesLogged - handles.FrameCount;
  handles.FrameCount = nFramesLogged;
  handles.writeFrame_EmpiricalFPS = nFramesCurr/(time-handles.writeFrame_time);
  
  if nFramesLogged == get(handles.vid.Source,'nFramesTarget')
    stop(handles.vid);
  end
  
else

  if isempty(fopen(handles.logger.fid)),
    fprintf('File is closed, not writing\n');
    return;
  end
  
  % write frame to file
  try
    switch handles.params.FileType
      case 'avi'
        f.colormap = [];
        f.cdata = frame;
        handles.logger.aviobj = addframe(handles.logger.aviobj,f);
      case 'fmf'
        % deal with color by converting to gray scale
        % TODO: fix!
        if size(frame,3) > 1,
          frame = rgb2gray(frame);
        end
        fwrite(handles.logger.fid,time,'double');
        fwrite(handles.logger.fid,frame(:),'uint8');
    end
  catch ME
    if strcmp(handles.params.FileType,'fmf') && ...
        isempty(fopen(handles.logger.fid)),
      fprintf('File is closed, not writing\n');
      addToStatus(handles,{'Warning: writeFrame called after writing finished. Disabling FramesAcquiredFcn.'});
    else
      addToStatus(handles,sprintf('Error writing frame %d.',handles.FrameCount+1));
      getReport(ME)
    end
    handles.vid.framesacquiredfcn = '';
    return;
  end  
  
  % increment frame count
  handles.FrameCount = handles.FrameCount + 1;
  
  handles.writeFrame_EmpiricalFPS = 1/(time-handles.writeFrame_time);
  
end

handles.writeFrame_time = time;
  
set(handles.text_Status_Recording,'String',sprintf('%.1f s',handles.writeFrame_time));
set(handles.text_Status_FramesWritten,'String',sprintf('%d',handles.FrameCount));
set(handles.text_Status_FrameRate,'String',sprintf('%.2f Hz',handles.writeFrame_EmpiricalFPS));
handles.Status_FrameRate_History(:,1) = [];
handles.Status_FrameRate_History(:,end+1) = [time,handles.writeFrame_EmpiricalFPS];
set(handles.hLine_Status_FrameRate,...
  'Xdata',handles.Status_FrameRate_History(1,:)-handles.Status_FrameRate_History(1,end),...
  'Ydata',handles.Status_FrameRate_History(2,:));


guidata(hObject,handles);
  
  