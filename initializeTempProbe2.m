function success = initializeTempProbe2(hObject)

success = false;

handles = guidata(hObject);

if handles.params.DoRecordTemp == 0,
  return;
end

handles.TempProbe_NChannelsTotal = 8;
handles.TempProbe_Channels = handles.TempProbeIDs;

% parameters for recording temperatures
handles.TempProbe_Params = ...
  {'NChannelsTotal',handles.TempProbe_NChannelsTotal,...
  'Period',handles.params.TempProbePeriod,...
  'Channels',handles.TempProbe_Channels,...
  'ChannelTypes',handles.params.TempProbeTypes,...
  'Reject60Hz',handles.params.TempProbeReject60Hz};

[success,handles.TempRecorderInfo] = ...
  StartRecordingTemperature(handles.GUIi,...
  handles.TempProbe_Params{:});

if ~success,
  errordlg('Error starting temperature recording');
  return;
end

guidata(hObject,handles);

% set(handles.hLine_Status_Temp,'UserData',now);

handles.TempProbe_timer=timer('ExecutionMode','FixedRate',...
  'Period',handles.params.TempProbePeriod,...
  'TimerFcn',{@TempProbe_GrabTemp2,hObject},...
  'StartDelay',1,...
  'Name',sprintf('FBDC_USBTC08_Timer%d',handles.GUIi),...
  'BusyMode','drop');

addToStatus(handles,'Initialized temperature probe timer');

handles.TempProbe_IsInitialized = true;

guidata(handles.figure_main,handles);

start(handles.TempProbe_timer);

success = true;