function handles = FlyBowlDataCapture_InitializeData(handles)

% version
handles.version = '0.1';

% for unique names
handles.RandomNumber = randi(9999,1);

% comment character in params file
comment_char = '#';

% background color if value has not been changed from defaults
handles.isdefault_bkgdcolor = [0,.2,.2];

% background color if value has not been changed from defaults and it
% should be changed per experiment
handles.shouldchange_bkgdcolor = [.6,.2,0];

% background color if value has been changed from defaults
handles.changed_bkgdcolor = 0.314 + zeros(1,3);

% background color for buttons that are not enabled
handles.grayed_bkgdcolor = 0.314 + zeros(1,3);

% colors for status box text
handles.status_colors = [0,1,0;0,0,1];

% list of fly lines read frame Sage
handles.linename_file = 'SageLineNames.txt';

% name of Sage parameters file
handles.SageParamsFile = 'SAGEReadParams.txt';

% now
handles.now = now;

% format for date
handles.dateformat = 2;

% format for hour
handles.hourformat = 15;

% format for second
handles.secondformat = 13;

% earliest time that someone should be working
handles.minhour = rem(datenum('06:00'),1);
handles.maxhour = rem(datenum('23:00'),1);

handles.SAGECodeDir = '../SAGE/MATLABInterface/Trunk';
handles.JCtraxCodeDir = '../JCtrax';

% add JCtrax to path
miscdir = fullfile(handles.JCtraxCodeDir,'misc');
if ~exist(miscdir,'file')
  error('Directory %s required',miscdir);
end
addpath(miscdir);
filehandlingdir = fullfile(handles.JCtraxCodeDir,'filehandling');
if ~exist(filehandlingdir,'file')
  error('Directory %s required',filehandlingdir);
end
addpath(miscdir);


%% delete existing imaqs and timers

tmp = timerfind('Name','FBDC_RecordTimer');
for i = 1:length(tmp),
  if iscell(tmp),
    delete(tmp{i});
  else
    delete(tmp(i));
  end
end
for tmp = imaqfind('Name','FBDC_VideoInput'),
  delete(tmp{1});
end

%% reset experiment name

handles.ExperimentName = '';
handles.ExperimentDirectory = '';

%% parse parameter file

% open the parameter file
fid = fopen(handles.params_file,'r');
if fid < 0,
  s = sprintf('Could not read in parameters file %s',handles.params_file);
  uiwait(errordlg(s,'Error reading parameters'));
  error(s);
end

handles.params = struct;
try
  % read each line
  while true,
    s = fgetl(fid);
    if ~ischar(s), break; end
    
    % remove extra white space
    s = strtrim(s);
    
    % skip comments
    if isempty(s) || s(1) == comment_char,
      continue;
    end
    
    % split at ,
    v = regexp(s,',','split');
    
    % first value is the parameter name, rest are parameter values
    handles.params.(v{1}) = v(2:end);
  end
  fclose(fid);
  
  % some values are numbers
  numeric_params = {'PreAssayHandling_CrossDate_Range',...
    'PreAssayHandling_SortingDate_Range','PreAssayHandling_StarvationDate_Range',...
    'Imaq_ROIPosition','NFlies','RecordTime','PreviewUpdatePeriod',...
    'MetaData_RoomTemperatureSetPoint','MetaData_RoomHumiditySetPoint',...
    'FrameRatePlotYLim','TempPlotYLim','DoQuerySage','Imaq_FrameRate',...
    'Imaq_Shutter','Imaq_Gain','Imaq_Brightness','TempProbePeriod','TempProbeChannels',...
    'TempProbeReject60Hz','DoRecordTemp','NPreconSamples','gdcamPreviewFrameInterval',...
    'Imaq_MaxFrameRate','UFMFPrintStats','UFMFStatStreamPrintFreq',...
    'UFMFStatComputeFrameErrorFreq','UFMFStatPrintTimings',...
    'UFMFMaxFracFgCompress','UFMFMaxBGNFrames','UFMFBGUpdatePeriod',...
    'UFMFBGKeyFramePeriod','UFMFMaxBoxLength','UFMFBackSubThresh',...
    'UFMFNFramesInit','UFMFBGKeyFramePeriodInit','ColormapPreview'};
  for i = 1:length(numeric_params),
    if isfield(handles.params,numeric_params{i}),
      handles.params.(numeric_params{i}) = str2double(handles.params.(numeric_params{i}));
    else
      fprintf('Parameter %s not set in parameter file.\n',numeric_params{i});
    end
  end
  
  % some values are not lists
  notlist_params = {'Imaq_Adaptor','Imaq_DeviceName','Imaq_VideoFormat',...
    'FileType','MetaData_AssayName',...
    'MetaData_Effector','MetaData_Gender','MetaDataFileName','MovieFilePrefix','LogFileName',...
    'UFMFLogFileName','UFMFStatFileName','PreconSensorSerialPort'};
  for i = 1:length(notlist_params),
    fn = notlist_params{i};
    if ischar(handles.params.(fn){1}),
      tmp = handles.params.(fn){1};
      for j = 2:length(handles.params.(fn)),
        tmp = [tmp,',',handles.params.(fn){j}]; %#ok<AGROW>
      end
      handles.params.(fn) = tmp;
    else
      handles.params.(fn) = cat(2,handles.params.(fn){:});
    end
  end
  
  % parameters that are selected by GUI instance
  GUIInstance_params = {'OutputDirectory','TmpOutputDirectory','HardDriveName'};
  for i = 1:length(GUIInstance_params),
    fn = GUIInstance_params{i};
    j = mod(handles.GUIi-1,length(handles.params.(fn)))+1;
    handles.params.(fn) = handles.params.(fn){j};
  end

catch ME
  uiwait(errordlg({'Error parsing parameter file:',getReport(ME)},'Error reading parameters'));
  rethrow(ME);
end
  
%% temporary output directory
if isempty(handles.params.TmpOutputDirectory),
  handles.params.TmpOutputDirectory = tempdir;
end

%% movie file name

handles.params.MovieFileStr = sprintf('%s.%s',handles.params.MovieFilePrefix,handles.params.FileType);

%% computer name
[~,handles.ComputerName] = system('hostname');
handles.ComputerName = strtrim(handles.ComputerName);

%% Status window
%handles.Status_MaxNLines = 50;
handles.IsTmpLogFile = true;
handles.LogFileName = fullfile(handles.params.TmpOutputDirectory,sprintf('TmpLog_%s.txt',datestr(now,30)));
set(handles.edit_Status,'String',{});
j = mod(handles.GUIi-1,size(handles.status_colors,1))+1;
handles.status_color = handles.status_colors(j,:);
set(handles.edit_Status,'ForegroundColor',handles.status_color);
s = {
  sprintf('FlyBowlDataCapture v. %s',handles.version)
  '--------------------------------------'};
addToStatus(handles,s,-1);
addToStatus(handles,{sprintf('GUI instance %d, writing to %s, random number %d.',handles.GUIi,handles.params.OutputDirectory,handles.RandomNumber)});
%% Experimenter

% whether this has been changed or not
handles.isdefault.Assay_Experimenter = true;

% possible values for experimenter
handles.Assay_Experimenters = handles.params.Assay_Experimenters;

% if experimenter not stored in rc file, choose first experimenter
if ~isfield(handles.previous_values,'Assay_Experimenter') || ...
    ~ismember(handles.previous_values.Assay_Experimenter,handles.Assay_Experimenters),
  handles.previous_values.Assay_Experimenter = handles.Assay_Experimenters{1};
end

% by default, previous experimenter
handles.Assay_Experimenter = handles.previous_values.Assay_Experimenter;

% set possible values, current value, color to default
set(handles.popupmenu_Assay_Experimenter,'String',handles.Assay_Experimenters,...
  'Value',find(strcmp(handles.Assay_Experimenter,handles.Assay_Experimenters),1),...
  'BackgroundColor',handles.isdefault_bkgdcolor);

%% Fly Line

% whether this has been changed or not
handles.isdefault.Fly_LineName = true;
handles.IsSage = exist(handles.SAGECodeDir,'file');
if handles.IsSage,
  try
    addpath(handles.SAGECodeDir);
  catch
    handles.IsSage = false;
  end
end
if ~handles.IsSage,
  addToStatus(handles,{sprintf('SAGE code directory %s could not be added to the path.',handles.SAGECodeDir)});
end
handles = readLineNames(handles,false);

% if line name not stored in rc file, choose first line name
if ~isfield(handles.previous_values,'Fly_LineName') || ...
    ~ismember(handles.previous_values.Fly_LineName,handles.Fly_LineNames),
  handles.previous_values.Fly_LineName = handles.Fly_LineNames{1};
end

% by default, previous line name
handles.Fly_LineName = handles.previous_values.Fly_LineName;

% set possible values, current value, color to shouldchange
%set(handles.edit_Fly_LineName,'String',handles.Fly_LineNames,...
%  'Value',find(strcmp(handles.Fly_LineName,handles.Fly_LineNames),1),...
%  'BackgroundColor',handles.shouldchange_bkgdcolor);
set(handles.edit_Fly_LineName,'String',handles.Fly_LineName,...
  'BackgroundColor',handles.shouldchange_bkgdcolor);

% we have not created the autofill version yet
handles.isAutoComplete_edit_Fly_LineName = false;

%% Incubator ID

% whether this has been changed or not
handles.isdefault.Rearing_IncubatorID = true;

% possible values for IncubatorID
handles.Rearing_IncubatorIDs = handles.params.Rearing_IncubatorIDs;

% if IncubatorID not stored in rc file, choose first IncubatorID
if ~isfield(handles.previous_values,'Rearing_IncubatorID') || ...
    ~ismember(handles.previous_values.Rearing_IncubatorID,handles.Rearing_IncubatorIDs),
  handles.previous_values.Rearing_IncubatorID = handles.Rearing_IncubatorIDs{1};
end

% by default, previous IncubatorID
handles.Rearing_IncubatorID = handles.previous_values.Rearing_IncubatorID;

% set possible values, current value, color to default
set(handles.popupmenu_Rearing_IncubatorID,'String',handles.Rearing_IncubatorIDs,...
  'Value',find(strcmp(handles.Rearing_IncubatorID,handles.Rearing_IncubatorIDs),1),...
  'BackgroundColor',handles.isdefault_bkgdcolor);

%% Cross Date

% whether this has been changed or not
handles.isdefault.PreAssayHandling_CrossDate = true;

% possible values for CrossDate
minv = floor(handles.now) - handles.params.PreAssayHandling_CrossDate_Range(2);
maxv = floor(handles.now) - handles.params.PreAssayHandling_CrossDate_Range(1);
handles.PreAssayHandling_CrossDate_datenums = minv:maxv;
handles.PreAssayHandling_CrossDates = cellstr(datestr(handles.PreAssayHandling_CrossDate_datenums,handles.dateformat));

% if CrossDate not stored in rc file, choose first date
if ~isfield(handles.previous_values,'PreAssayHandling_CrossDateOff') || ...
    handles.previous_values.PreAssayHandling_CrossDateOff > handles.params.PreAssayHandling_CrossDate_Range(2) || ...
    handles.previous_values.PreAssayHandling_CrossDateOff < handles.params.PreAssayHandling_CrossDate_Range(1),
  handles.previous_values.PreAssayHandling_CrossDateOff = handles.params.PreAssayHandling_CrossDate_Range(2);
end

% by default, previous offset
handles.PreAssayHandling_CrossDate_datenum = floor(handles.now) - handles.previous_values.PreAssayHandling_CrossDateOff;
handles.PreAssayHandling_CrossDate = datestr(handles.PreAssayHandling_CrossDate_datenum,handles.dateformat);

% set possible values, current value, color to default
set(handles.popupmenu_PreAssayHandling_CrossDate,'String',handles.PreAssayHandling_CrossDates,...
  'Value',find(strcmp(handles.PreAssayHandling_CrossDate,handles.PreAssayHandling_CrossDates),1),...
  'BackgroundColor',handles.isdefault_bkgdcolor);

%% Sorting Date

% whether this has been changed or not
handles.isdefault.PreAssayHandling_SortingDate = true;

% possible values for SortingDate
minv = floor(handles.now) - handles.params.PreAssayHandling_SortingDate_Range(2);
maxv = floor(handles.now) - handles.params.PreAssayHandling_SortingDate_Range(1);
handles.PreAssayHandling_SortingDate_datenums = minv:maxv;
handles.PreAssayHandling_SortingDates = cellstr(datestr(handles.PreAssayHandling_SortingDate_datenums,handles.dateformat));

% if SortingDate not stored in rc file, choose first date
if ~isfield(handles.previous_values,'PreAssayHandling_SortingDateOff') || ...
    handles.previous_values.PreAssayHandling_SortingDateOff > handles.params.PreAssayHandling_SortingDate_Range(2) || ...
    handles.previous_values.PreAssayHandling_SortingDateOff < handles.params.PreAssayHandling_SortingDate_Range(1),
  handles.previous_values.PreAssayHandling_SortingDateOff = handles.params.PreAssayHandling_SortingDate_Range(2);
end

% by default, previous offset
handles.PreAssayHandling_SortingDate_datenum = floor(handles.now) - handles.previous_values.PreAssayHandling_SortingDateOff;
handles.PreAssayHandling_SortingDate = datestr(handles.PreAssayHandling_SortingDate_datenum,handles.dateformat);

% set possible values, current value, color to default
set(handles.popupmenu_PreAssayHandling_SortingDate,'String',handles.PreAssayHandling_SortingDates,...
  'Value',find(strcmp(handles.PreAssayHandling_SortingDate,handles.PreAssayHandling_SortingDates),1),...
  'BackgroundColor',handles.isdefault_bkgdcolor);

%% Sorting Hour

% whether this has been changed or not
handles.isdefault.PreAssayHandling_SortingHour = true;

% if IncubatorID not stored in rc file, choose now
if ~isfield(handles.previous_values,'PreAssayHandling_SortingHour'),
  handles.previous_values.PreAssayHandling_SortingHour = datestr(handles.now,handles.hourformat);
end

% by default, previous IncubatorID
handles.PreAssayHandling_SortingHour = handles.previous_values.PreAssayHandling_SortingHour;

% set possible values, current value, color to default
set(handles.edit_PreAssayHandling_SortingHour,'String',handles.PreAssayHandling_SortingHour,...
  'BackgroundColor',handles.isdefault_bkgdcolor);

handles.PreAssayHandling_SortingHour_datenum = rem(datenum(handles.PreAssayHandling_SortingHour),1);
handles.PreAssayHandling_SortingTime_datenum = handles.PreAssayHandling_SortingDate_datenum + ...
  handles.PreAssayHandling_SortingHour_datenum;

%% Sorting Handler

% whether this has been changed or not
handles.isdefault.PreAssayHandling_SortingHandler = true;

% possible values for SortingHandler
handles.PreAssayHandling_SortingHandlers = handles.params.PreAssayHandling_SortingHandlers;

% if SortingHandler not stored in rc file, choose first SortingHandler
if ~isfield(handles.previous_values,'PreAssayHandling_SortingHandler') || ...
    ~ismember(handles.previous_values.PreAssayHandling_SortingHandler,handles.PreAssayHandling_SortingHandlers),
  handles.previous_values.PreAssayHandling_SortingHandler = handles.PreAssayHandling_SortingHandlers{1};
end

% by default, previous SortingHandler
handles.PreAssayHandling_SortingHandler = handles.previous_values.PreAssayHandling_SortingHandler;

% set possible values, current value, color to default
set(handles.popupmenu_PreAssayHandling_SortingHandler,'String',handles.PreAssayHandling_SortingHandlers,...
  'Value',find(strcmp(handles.PreAssayHandling_SortingHandler,handles.PreAssayHandling_SortingHandlers),1),...
  'BackgroundColor',handles.isdefault_bkgdcolor);

%% Starvation Date

% whether this has been changed or not
handles.isdefault.PreAssayHandling_StarvationDate = true;

% possible values for StarvationDate
minv = floor(handles.now) - handles.params.PreAssayHandling_StarvationDate_Range(2);
maxv = floor(handles.now) - handles.params.PreAssayHandling_StarvationDate_Range(1);
handles.PreAssayHandling_StarvationDate_datenums = minv:maxv;
handles.PreAssayHandling_StarvationDates = cellstr(datestr(handles.PreAssayHandling_StarvationDate_datenums,handles.dateformat));

% if StarvationDate not stored in rc file, choose first date
if ~isfield(handles.previous_values,'PreAssayHandling_StarvationDateOff') || ...
    handles.previous_values.PreAssayHandling_StarvationDateOff > handles.params.PreAssayHandling_StarvationDate_Range(2) || ...
    handles.previous_values.PreAssayHandling_StarvationDateOff < handles.params.PreAssayHandling_StarvationDate_Range(1),
  handles.previous_values.PreAssayHandling_StarvationDateOff = handles.params.PreAssayHandling_StarvationDate_Range(2);
end

% by default, previous offset
handles.PreAssayHandling_StarvationDate_datenum = floor(handles.now) - handles.previous_values.PreAssayHandling_StarvationDateOff;
handles.PreAssayHandling_StarvationDate = datestr(handles.PreAssayHandling_StarvationDate_datenum,handles.dateformat);

% set possible values, current value, color to default
set(handles.popupmenu_PreAssayHandling_StarvationDate,'String',handles.PreAssayHandling_StarvationDates,...
  'Value',find(strcmp(handles.PreAssayHandling_StarvationDate,handles.PreAssayHandling_StarvationDates),1),...
  'BackgroundColor',handles.isdefault_bkgdcolor);

%% Starvation Hour

% whether this has been changed or not
handles.isdefault.PreAssayHandling_StarvationHour = true;

% if IncubatorID not stored in rc file, choose now
if ~isfield(handles.previous_values,'PreAssayHandling_StarvationHour'),
  handles.previous_values.PreAssayHandling_StarvationHour = datestr(handles.now,handles.hourformat);
end

% by default, previous IncubatorID
handles.PreAssayHandling_StarvationHour = handles.previous_values.PreAssayHandling_StarvationHour;

% set possible values, current value, color to default
set(handles.edit_PreAssayHandling_StarvationHour,'String',handles.PreAssayHandling_StarvationHour,...
  'BackgroundColor',handles.isdefault_bkgdcolor);

handles.PreAssayHandling_StarvationHour_datenum = rem(datenum(handles.PreAssayHandling_StarvationHour),1);
handles.PreAssayHandling_StarvationTime_datenum = handles.PreAssayHandling_StarvationDate_datenum + ...
  handles.PreAssayHandling_StarvationHour_datenum;

%% Starvation Handler

% whether this has been changed or not
handles.isdefault.PreAssayHandling_StarvationHandler = true;

% possible values for StarvationHandler
handles.PreAssayHandling_StarvationHandlers = handles.params.PreAssayHandling_StarvationHandlers;

% if StarvationHandler not stored in rc file, choose first StarvationHandler
if ~isfield(handles.previous_values,'PreAssayHandling_StarvationHandler') || ...
    ~ismember(handles.previous_values.PreAssayHandling_StarvationHandler,handles.PreAssayHandling_StarvationHandlers),
  handles.previous_values.PreAssayHandling_StarvationHandler = handles.PreAssayHandling_StarvationHandlers{1};
end

% by default, previous StarvationHandler
handles.PreAssayHandling_StarvationHandler = handles.previous_values.PreAssayHandling_StarvationHandler;

% set possible values, current value, color to default
set(handles.popupmenu_PreAssayHandling_StarvationHandler,'String',handles.PreAssayHandling_StarvationHandlers,...
  'Value',find(strcmp(handles.PreAssayHandling_StarvationHandler,handles.PreAssayHandling_StarvationHandlers),1),...
  'BackgroundColor',handles.isdefault_bkgdcolor);

%% Rig

% whether this has been changed or not
handles.isdefault.Assay_Rig = true;

% possible values for StarvationHandler
handles.Assay_Rigs = handles.params.Assay_Rigs;

% if StarvationHandler not stored in rc file, choose first StarvationHandler
if ~isfield(handles.previous_values,'Assay_Rig') || ...
    ~ismember(handles.previous_values.Assay_Rig,handles.Assay_Rigs),
  handles.previous_values.Assay_Rig = handles.Assay_Rigs{1};
end

% by default, previous StarvationHandler
handles.Assay_Rig = handles.previous_values.Assay_Rig;

% set possible values, current value, color to default
set(handles.popupmenu_Assay_Rig,'String',handles.Assay_Rigs,...
  'Value',find(strcmp(handles.Assay_Rig,handles.Assay_Rigs),1),...
  'BackgroundColor',handles.isdefault_bkgdcolor);

%% Plate

% whether this has been changed or not
handles.isdefault.Assay_Plate = true;

% possible values for StarvationHandler
handles.Assay_Plates = handles.params.Assay_Plates;

% if StarvationHandler not stored in rc file, choose first StarvationHandler
if ~isfield(handles.previous_values,'Assay_Plate') || ...
    ~ismember(handles.previous_values.Assay_Plate,handles.Assay_Plates),
  handles.previous_values.Assay_Plate = handles.Assay_Plates{1};
end

% by default, previous StarvationHandler
handles.Assay_Plate = handles.previous_values.Assay_Plate;

% set possible values, current value, color to default
set(handles.popupmenu_Assay_Plate,'String',handles.Assay_Plates,...
  'Value',find(strcmp(handles.Assay_Plate,handles.Assay_Plates),1),...
  'BackgroundColor',handles.isdefault_bkgdcolor);

%% Bowl

% whether this has been changed or not
handles.isdefault.Assay_Bowl = true;

% possible values for StarvationHandler
handles.Assay_Bowls = handles.params.Assay_Bowls;

% if StarvationHandler not stored in rc file, choose first StarvationHandler
if ~isfield(handles.previous_values,'Assay_Bowl') || ...
    ~ismember(handles.previous_values.Assay_Bowl,handles.Assay_Bowls),
  handles.previous_values.Assay_Bowl = handles.Assay_Bowls{1};
end

% by default, previous StarvationHandler
handles.Assay_Bowl = handles.previous_values.Assay_Bowl;

% set possible values, current value, color to default
set(handles.popupmenu_Assay_Bowl,'String',handles.Assay_Bowls,...
  'Value',find(strcmp(handles.Assay_Bowl,handles.Assay_Bowls),1),...
  'BackgroundColor',handles.isdefault_bkgdcolor);

%% Number of dead flies

handles.NDeadFlies_str = cellstr(num2str((0:handles.params.NFlies)'));
handles.NDeadFlies = 0;
set(handles.popupmenu_NDeadFlies,'String',handles.NDeadFlies_str,...
  'Value',handles.NDeadFlies+1);

%% Redo Flag

% whether this has been changed or not
handles.isdefault.RedoFlag = true;

% possible values for RedoFlag
handles.RedoFlags = handles.params.RedoFlags;

handles.RedoFlag = 'None';

% set possible values, current value, color to default
set(handles.popupmenu_RedoFlag,'String',handles.RedoFlags,...
  'Value',find(strcmp(handles.RedoFlag,handles.RedoFlags),1),...
  'BackgroundColor',handles.isdefault_bkgdcolor);

%% Review Flag

% whether this has been changed or not
handles.isdefault.ReviewFlag = true;

% possible values for ReviewFlag
handles.ReviewFlags = handles.params.ReviewFlags;

handles.ReviewFlag = 'None';

% set possible values, current value, color to default
set(handles.popupmenu_ReviewFlag,'String',handles.ReviewFlags,...
  'Value',find(strcmp(handles.ReviewFlag,handles.ReviewFlags),1),...
  'BackgroundColor',handles.isdefault_bkgdcolor);


%% Technical Notes

handles.TechnicalNotes = 'None';
set(handles.edit_TechnicalNotes,'String',handles.TechnicalNotes);

%% Behavioral Notes

handles.BehaviorNotes = 'None';
set(handles.edit_BehaviorNotes,'String',handles.BehaviorNotes);

%% Detect Cameras

% if DeviceID not stored in rc file, choose first DeviceID
if ~isfield(handles.previous_values,'DeviceID'),
  handles.previous_values.DeviceID = [];
end
% by default, previous DeviceID
handles.DeviceID = handles.previous_values.DeviceID;
handles.CameraUniqueID = '';

handles = detectCamerasWrapper(handles);

%% Temperature Probe

handles.TempProbeIDs = handles.params.TempProbeChannels;

% if TempProbeID not stored in rc file or invalid, choose first valid
% channel
if ~isfield(handles.previous_values,'TempProbeID') || ...
    ~ismember(handles.previous_values.TempProbeID,handles.TempProbeIDs),
  handles.previous_values.TempProbeID = handles.TempProbeIDs(1);
end
% by default, previous TempProbeID
handles.TempProbeID = handles.previous_values.TempProbeID;

set(handles.popupmenu_TempProbeID,'String',cellstr(num2str(handles.TempProbeIDs(:))),...
  'value',find(handles.TempProbeID==handles.TempProbeIDs,1));

handles.TempProbe_IsInitialized = false;

if handles.params.DoRecordTemp == 0,
  set(handles.popupmenu_TempProbeID,'Enable','off');
end

%% Shift Fly Temp
handles.ShiftFlyTemp_Time_datenum = -1;
handles.ShiftFlyTemp_bkgdcolor = [.153,.227,.373];
set(handles.pushbutton_ShiftFlyTemp,'BackgroundColor',handles.ShiftFlyTemp_bkgdcolor,...
  'String','Shift Fly Temp','Enable','on');

%% Flies Loaded
handles.FliesLoaded_Time_datenum = -1;
handles.FliesLoaded_bkgdcolor = [.349,.2,.329];
set(handles.pushbutton_FliesLoaded,'BackgroundColor',handles.grayed_bkgdcolor,...
  'String','Flies Loaded','Enable','off');

%% Start Recording
handles.StartRecording_Time_datenum = -1;
handles.IsRecording = false;
handles.FinishedRecording = false;
handles.StartRecording_bkgdcolor = [.071,.212,.141];
set(handles.pushbutton_StartRecording,'BackgroundColor',handles.grayed_bkgdcolor,...
  'String','Start Recording','Enable','off');

%% Initialize Camera

handles.InitializeCamera_bkgdcolor = [.071,.212,.141];
set(handles.pushbutton_InitializeCamera,'BackgroundColor',handles.InitializeCamera_bkgdcolor,...
  'String','Initialize Camera','Visible','on');

% if no device found, then not enabled
if isempty(handles.DeviceID),
  set(handles.pushbutton_InitializeCamera,'Enable','off');
else
  set(handles.pushbutton_InitializeCamera,'Enable','on');
end

%% Initialize Temperature Probe

handles.InitializeTempProbe_bkgdcolor = [.071,.212,.141];
set(handles.pushbutton_InitializeTempProbe,'BackgroundColor',handles.InitializeTempProbe_bkgdcolor,...
  'String','Init Temp Probe','Visible','on');
if (handles.params.DoRecordTemp == 0) || isempty(handles.TempProbeIDs),
  set(handles.pushbutton_InitializeTempProbe,'Enable','off','String','No Temp Probe');
else
  set(handles.pushbutton_InitializeTempProbe,'Enable','on');
end

%% Abort
handles.Abort_bkgdcolor = [.4,0,0];
set(handles.pushbutton_Abort,'BackgroundColor',handles.Abort_bkgdcolor,...
  'String','Abort','Enable','on');

%% Done
handles.Done_bkgdcolor = [.404,.231,.012];
set(handles.pushbutton_Done,'BackgroundColor',handles.grayed_bkgdcolor,...
  'String','Done','Enable','off');

%% Save MetaData

% meta data needs to be saved still
handles.MetaDataNeedsSave = true;
handles.SaveMetaData_bkgdcolor = [0,.35,.35];
set(handles.pushbutton_SaveMetaData,'BackgroundColor',handles.SaveMetaData_bkgdcolor,...
  'String','Save MetaData','Enable','on');


%% Preview Status

handles.Status_Preview_bkgdcolor = [.4,0,0];
set(handles.text_Status_Preview,'String','Off',...
  'BackgroundColor',handles.grayed_bkgdcolor);

%% Recording Status
handles.Status_Recording_bkgdcolor = [.4,0,0];
set(handles.text_Status_Recording,'String','Off',...
  'BackgroundColor',handles.grayed_bkgdcolor);

%% Frames Written Status

set(handles.text_Status_FramesWritten,'String',num2str(0),...
  'BackgroundColor',handles.grayed_bkgdcolor);

%% Frame Rate

set(handles.text_Status_FrameRate,'String','N/A',...
  'BackgroundColor',handles.grayed_bkgdcolor);

%% Temperature and humidity

handles.MetaData_RoomTemperature = nan;
handles.MetaData_RoomHumidity = nan;

%% Plot frame rate

handles.Status_FrameRate_MaxNFramesPlot = 100;
handles.Status_FrameRate_MaxSecondsPlot = handles.Status_FrameRate_MaxNFramesPlot / ...
  handles.params.Imaq_FrameRate;
handles.Status_FrameRate_History = nan(2,handles.Status_FrameRate_MaxNFramesPlot);
handles.hLine_Status_FrameRate = plot(handles.axes_Status_FrameRate,...
  handles.Status_FrameRate_History(1,:)-handles.Status_FrameRate_History(1,end),...
  handles.Status_FrameRate_History(2,:),'.-','color',[0,1,0]);
set(handles.hLine_Status_FrameRate,'UserData',handles.Status_FrameRate_History);
hylabel = ylabel(handles.axes_Status_FrameRate,'fps');
set(hylabel,'Units','pixels');
pos = get(hylabel,'Position');
pos(1) = pos(1)+10;
set(hylabel,'Position',pos);
xlabel(handles.axes_Status_FrameRate,'Seconds ago');
set(handles.axes_Status_FrameRate,'Color',[0,0,0],...
  'XColor','w','YColor','w',...
  'XLim',[-handles.Status_FrameRate_MaxSecondsPlot,0],...
  'YLim',handles.params.FrameRatePlotYLim);

%% Plot temperature

handles.Status_Temp_MaxSamplesPlot = 100;
handles.Status_Temp_MaxSecondsPlot = handles.Status_Temp_MaxSamplesPlot * ...
  handles.params.TempProbePeriod;

handles.Status_Temp_History = nan(2,handles.Status_Temp_MaxSamplesPlot);
handles.hLine_Status_Temp = plot(handles.axes_Status_Temp,handles.Status_Temp_History(1,:),...
  handles.Status_Temp_History(2,:),'.-','color',[0,1,0]);
hylabel = ylabel(handles.axes_Status_Temp,'Temp (C)');
set(hylabel,'Units','pixels');
pos = get(hylabel,'Position');
pos(1) = pos(1)+10;
set(hylabel,'Position',pos);
xlabel(handles.axes_Status_Temp,'Seconds ago');
set(handles.axes_Status_Temp,'Color',[0,0,0],...
  'XColor','w','YColor','w',...
  'XLim',[-handles.Status_Temp_MaxSecondsPlot,0],...
  'YLim',handles.params.TempPlotYLim);

%% Preview axes

set(handles.axes_PreviewVideo,'xtick',[],'ytick',[]);

%% computeQuickStats parameters

handles.ComputeQuickStatsParams = {...
  'UFMFDiagnosticsFileStr',handles.params.UFMFStatFileName,...
  'MovieFileStr',handles.params.MovieFileStr,...
  'FigHandle',100,...
  'GUIInstance',handles.GUIi,...
  'parent',handles.figure_main...
  'SaveFileStr','QuickStats.png',...
  'SaveDataStr','QuickStats.txt'...
  };

%% Initialization complete
handles.GUIInitialization_Time_datenum = now;
handles.GUIIsInitialized = true;
addToStatus(handles,{'GUI initialization finished.'},handles.GUIInitialization_Time_datenum);
