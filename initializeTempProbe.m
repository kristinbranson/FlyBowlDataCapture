function success = initializeTempProbe(hObject)

success = false;

handles = guidata(hObject);

if handles.params.DoRecordTemp == 0,
  return;
end

handles.TempProbe_NChannelsTotal = 8;
handles.TempProbe_Channels = handles.TempProbeIDs;

% parameters for recording temperatures
handles.TempProbe_Params = ...
  {'TempRecordDir','.TempRecordData',...
  'IsMasterFileStr','IsMaster.mat',...
  'ChannelFileStr','Channel',...
  'NChannelsTotal',handles.TempProbe_NChannelsTotal,...
  'Period',handles.params.TempProbePeriod,...
  'Channels',handles.TempProbe_Channels,...
  'ChannelTypes',handles.params.TempProbeTypes,...
  'Reject60Hz',handles.params.TempProbeReject60Hz};

% check for master temperature recorder, create if necessary
[handles,success1] = GetMasterTempRecorderInfo(handles);
if ~success1,
  addToStatus(handles,'Unable to start temperature recording.');
  guidata(hObject,handles);
  return;
end

i = find(handles.TempProbeID == handles.TempProbe_MasterInfo.Channels,1);
handles.TempProbe_ChannelFileName = handles.TempProbe_MasterInfo.ChannelFileNames{i};

guidata(hObject,handles);

handles.TempProbe_timer=timer('ExecutionMode','FixedRate',...
  'Period',handles.params.TempProbePeriod,...
  'TimerFcn',{@TempProbe_GrabTemp,hObject},...
  'StartDelay',1,...
  'Name','FBDC_USBTC08_Timer');

addToStatus(handles,'Initialized temperature probe timer');

handles.TempProbe_IsInitialized = true;

guidata(handles.figure_main,handles);

start(handles.TempProbe_timer);

success = true;