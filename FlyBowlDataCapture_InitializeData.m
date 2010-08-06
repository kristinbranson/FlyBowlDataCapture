function handles = FlyBowlDataCapture_InitializeData(handles)

% version
handles.version = '0.1';

% file containing parameters we may want to change some day
handles.params_file = 'FlyBowlDataCaptureParams.txt';

% comment character in params file
comment_char = '#';

% name of rc file
handles.rcfile = '.FlyBowlDataCapture_rc.mat';

% background color if value has not been changed from defaults
handles.isdefault_bkgdcolor = [0,.2,.2];

% background color if value has not been changed from defaults and it
% should be changed per experiment
handles.shouldchange_bkgdcolor = [.6,.2,0];

% background color if value has been changed from defaults
handles.changed_bkgdcolor = 0.314 + zeros(1,3);

% background color for buttons that are not enabled
handles.grayed_bkgdcolor = 0.314 + zeros(1,3);

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
    'PreAssayHandling_DOBStart_Range','PreAssayHandling_DOBEnd_Range',...
    'PreAssayHandling_SortingDate_Range','PreAssayHandling_StarvationDate_Range',...
    'Imaq_ROIPosition','RecordTime','PreviewUpdatePeriod',...
    'MetaData_RoomTemperatureSetPoint','MetaData_RoomHumiditySetPoint',...
    'MaxFrameRatePlot','DoQuerySage'};
  for i = 1:length(numeric_params),
    handles.params.(numeric_params{i}) = str2double(handles.params.(numeric_params{i}));
  end
  
  % some values are not lists
  notlist_params = {'Imaq_Adaptor','Imaq_DeviceName','Imaq_VideoFormat',...
    'FileType','OutputDirectory','TmpOutputDirectory','MetaData_AssayName',...
    'MetaData_Effector','MetaDataFileName','MovieFilePrefix','LogFileName'};
  for i = 1:length(notlist_params),
    handles.params.(notlist_params{i}) = handles.params.(notlist_params{i}){1};
  end
  
catch ME
  uiwait(errordlg({'Error parsing parameter file:',getReport(ME)},'Error reading parameters'));
  rethrow(ME);
end

%% Read previous values

previous_values = struct;
if exist(handles.rcfile,'file'),
  try
    previous_values = load(handles.rcfile);
  catch
  end
end

%% temporary output directory
if isempty(handles.params.TmpOutputDirectory),
  handles.params.TmpOutputDirectory = tempdir;
end

%% Status window
%handles.Status_MaxNLines = 50;
handles.IsTmpLogFile = true;
handles.LogFileName = fullfile(handles.params.TmpOutputDirectory,sprintf('TmpLog_%s.txt',datestr(now,30)));
handles.Status = {};
s = {
  sprintf('FlyBowlDataCapture v. %s',handles.version)
  '--------------------------------------'};
handles = addToStatus(handles,s,-1);
handles = addToStatus(handles,{'GUI initialization finished.'});

%% Experimenter

% whether this has been changed or not
handles.isdefault.Assay_Experimenter = true;

% possible values for experimenter
handles.Assay_Experimenters = handles.params.Assay_Experimenters;

% if experimenter not stored in rc file, choose first experimenter
if ~isfield(previous_values,'Assay_Experimenter') || ...
    ~ismember(previous_values.Assay_Experimenter,handles.Assay_Experimenters),
  previous_values.Assay_Experimenter = handles.Assay_Experimenters{1};
end

% by default, previous experimenter
handles.Assay_Experimenter = previous_values.Assay_Experimenter;

% set possible values, current value, color to default
set(handles.popupmenu_Assay_Experimenter,'String',handles.Assay_Experimenters,...
  'Value',find(strcmp(handles.Assay_Experimenter,handles.Assay_Experimenters),1),...
  'BackgroundColor',handles.isdefault_bkgdcolor);

%% Fly Line

% whether this has been changed or not
handles.isdefault.Fly_LineName = true;

% connect to Sage
if handles.params.DoQuerySage,
  try
    handles.db = connectToSAGE(handles.SageParamsFile);
    handles = addToStatus(handles,{'Connected to Sage.'});
  catch ME
    warndlg(['Could not connect to Sage: ',getReport(ME)],'Could not connect to Sage');
    handles.db = [];
    handles.params.DoQuerySage = false;
    handles = addToStatus(handles,{'Could not connect to Sage. Turning off querying Sage.'});
  end
end

% read the line names cached in handles.linename_file; sort by something?
handles = readLineNames(handles,false);

% if line name not stored in rc file, choose first line name
if ~isfield(previous_values,'Fly_LineName') || ...
    ~ismember(previous_values.Fly_LineName,handles.Fly_LineNames),
  previous_values.Fly_LineName = handles.Fly_LineNames{1};
end

% by default, previous line name
handles.Fly_LineName = previous_values.Fly_LineName;

% set possible values, current value, color to shouldchange
%set(handles.edit_Fly_LineName,'String',handles.Fly_LineNames,...
%  'Value',find(strcmp(handles.Fly_LineName,handles.Fly_LineNames),1),...
%  'BackgroundColor',handles.shouldchange_bkgdcolor);
set(handles.edit_Fly_LineName,'String',handles.Fly_LineName,...
  'BackgroundColor',handles.shouldchange_bkgdcolor);

% we have not created the autofill version yet
handles.isAutoComplete_edit_Fly_LineName = false;

% TODO: make this an edit box that autofills

%% Activity Peak

% whether this has been changed or not
handles.isdefault.Rearing_ActivityPeak = true;

% possible values for ActivityPeaks
handles.Rearing_ActivityPeaks = handles.params.Rearing_ActivityPeaks;

% if ActivityPeak not stored in rc file, choose first ActivityPeak
if ~isfield(previous_values,'Rearing_ActivityPeak') || ...
    ~ismember(previous_values.Rearing_ActivityPeak,handles.Rearing_ActivityPeaks),
  previous_values.Rearing_ActivityPeak = handles.Rearing_ActivityPeaks{1};
end

% by default, previous ActivityPeak
handles.Rearing_ActivityPeak = previous_values.Rearing_ActivityPeak;

% set possible values, current value, color to default
set(handles.popupmenu_Rearing_ActivityPeak,'String',handles.Rearing_ActivityPeaks,...
  'Value',find(strcmp(handles.Rearing_ActivityPeak,handles.Rearing_ActivityPeaks),1),...
  'BackgroundColor',handles.isdefault_bkgdcolor);

%% Incubator ID

% whether this has been changed or not
handles.isdefault.Rearing_IncubatorID = true;

% possible values for IncubatorID
handles.Rearing_IncubatorIDs = handles.params.Rearing_IncubatorIDs;

% if IncubatorID not stored in rc file, choose first IncubatorID
if ~isfield(previous_values,'Rearing_IncubatorID') || ...
    ~ismember(previous_values.Rearing_IncubatorID,handles.Rearing_IncubatorIDs),
  previous_values.Rearing_IncubatorID = handles.Rearing_IncubatorIDs{1};
end

% by default, previous IncubatorID
handles.Rearing_IncubatorID = previous_values.Rearing_IncubatorID;

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
if ~isfield(previous_values,'PreAssayHandling_CrossDateOff') || ...
    previous_values.PreAssayHandling_CrossDateOff > handles.params.PreAssayHandling_CrossDate_Range(2) || ...
    previous_values.PreAssayHandling_CrossDateOff < handles.params.PreAssayHandling_CrossDate_Range(1),
  previous_values.PreAssayHandling_CrossDateOff = handles.params.PreAssayHandling_CrossDate_Range(2);
end

% by default, previous offset
handles.PreAssayHandling_CrossDate_datenum = floor(handles.now) - previous_values.PreAssayHandling_CrossDateOff;
handles.PreAssayHandling_CrossDate = datestr(handles.PreAssayHandling_CrossDate_datenum,handles.dateformat);

% set possible values, current value, color to default
set(handles.popupmenu_PreAssayHandling_CrossDate,'String',handles.PreAssayHandling_CrossDates,...
  'Value',find(strcmp(handles.PreAssayHandling_CrossDate,handles.PreAssayHandling_CrossDates),1),...
  'BackgroundColor',handles.isdefault_bkgdcolor);

%% DOB Start

% whether this has been changed or not
handles.isdefault.PreAssayHandling_DOBStart = true;

% possible values for DOBStart
minv = floor(handles.now) - handles.params.PreAssayHandling_DOBStart_Range(2);
maxv = floor(handles.now) - handles.params.PreAssayHandling_DOBStart_Range(1);
handles.PreAssayHandling_DOBStart_datenums = minv:maxv;
handles.PreAssayHandling_DOBStarts = cellstr(datestr(handles.PreAssayHandling_DOBStart_datenums,handles.dateformat));

% if DOBStart not stored in rc file, choose first date
if ~isfield(previous_values,'PreAssayHandling_DOBStartOff') || ...
    previous_values.PreAssayHandling_DOBStartOff > handles.params.PreAssayHandling_DOBStart_Range(2) || ...
    previous_values.PreAssayHandling_DOBStartOff < handles.params.PreAssayHandling_DOBStart_Range(1),
  previous_values.PreAssayHandling_DOBStartOff = handles.params.PreAssayHandling_DOBStart_Range(2);
end

% by default, previous offset
handles.PreAssayHandling_DOBStart_datenum = floor(handles.now) - previous_values.PreAssayHandling_DOBStartOff;
handles.PreAssayHandling_DOBStart = datestr(handles.PreAssayHandling_DOBStart_datenum,handles.dateformat);

% set possible values, current value, color to default
set(handles.popupmenu_PreAssayHandling_DOBStart,'String',handles.PreAssayHandling_DOBStarts,...
  'Value',find(strcmp(handles.PreAssayHandling_DOBStart,handles.PreAssayHandling_DOBStarts),1),...
  'BackgroundColor',handles.isdefault_bkgdcolor);

%% DOB End

% whether this has been changed or not
handles.isdefault.PreAssayHandling_DOBEnd = true;

% possible values for DOBEnd
minv = floor(handles.now) - handles.params.PreAssayHandling_DOBEnd_Range(2);
maxv = floor(handles.now) - handles.params.PreAssayHandling_DOBEnd_Range(1);
handles.PreAssayHandling_DOBEnd_datenums = minv:maxv;
handles.PreAssayHandling_DOBEnds = cellstr(datestr(handles.PreAssayHandling_DOBEnd_datenums,handles.dateformat));

% if DOBEnd not stored in rc file, choose first date
if ~isfield(previous_values,'PreAssayHandling_DOBEndOff') || ...
    previous_values.PreAssayHandling_DOBEndOff > handles.params.PreAssayHandling_DOBEnd_Range(2) || ...
    previous_values.PreAssayHandling_DOBEndOff < handles.params.PreAssayHandling_DOBEnd_Range(1),
  previous_values.PreAssayHandling_DOBEndOff = handles.params.PreAssayHandling_DOBEnd_Range(2);
end

% by default, previous offset
handles.PreAssayHandling_DOBEnd_datenum = floor(handles.now) - previous_values.PreAssayHandling_DOBEndOff;
handles.PreAssayHandling_DOBEnd = datestr(handles.PreAssayHandling_DOBEnd_datenum,handles.dateformat);

% set possible values, current value, color to default
set(handles.popupmenu_PreAssayHandling_DOBEnd,'String',handles.PreAssayHandling_DOBEnds,...
  'Value',find(strcmp(handles.PreAssayHandling_DOBEnd,handles.PreAssayHandling_DOBEnds),1),...
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
if ~isfield(previous_values,'PreAssayHandling_SortingDateOff') || ...
    previous_values.PreAssayHandling_SortingDateOff > handles.params.PreAssayHandling_SortingDate_Range(2) || ...
    previous_values.PreAssayHandling_SortingDateOff < handles.params.PreAssayHandling_SortingDate_Range(1),
  previous_values.PreAssayHandling_SortingDateOff = handles.params.PreAssayHandling_SortingDate_Range(2);
end

% by default, previous offset
handles.PreAssayHandling_SortingDate_datenum = floor(handles.now) - previous_values.PreAssayHandling_SortingDateOff;
handles.PreAssayHandling_SortingDate = datestr(handles.PreAssayHandling_SortingDate_datenum,handles.dateformat);

% set possible values, current value, color to default
set(handles.popupmenu_PreAssayHandling_SortingDate,'String',handles.PreAssayHandling_SortingDates,...
  'Value',find(strcmp(handles.PreAssayHandling_SortingDate,handles.PreAssayHandling_SortingDates),1),...
  'BackgroundColor',handles.isdefault_bkgdcolor);

%% Sorting Hour

% whether this has been changed or not
handles.isdefault.PreAssayHandling_SortingHour = true;

% if IncubatorID not stored in rc file, choose now
if ~isfield(previous_values,'PreAssayHandling_SortingHour'),
  previous_values.PreAssayHandling_SortingHour = datestr(handles.now,handles.hourformat);
end

% by default, previous IncubatorID
handles.PreAssayHandling_SortingHour = previous_values.PreAssayHandling_SortingHour;

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
if ~isfield(previous_values,'PreAssayHandling_SortingHandler') || ...
    ~ismember(previous_values.PreAssayHandling_SortingHandler,handles.PreAssayHandling_SortingHandlers),
  previous_values.PreAssayHandling_SortingHandler = handles.PreAssayHandling_SortingHandlers{1};
end

% by default, previous SortingHandler
handles.PreAssayHandling_SortingHandler = previous_values.PreAssayHandling_SortingHandler;

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
if ~isfield(previous_values,'PreAssayHandling_StarvationDateOff') || ...
    previous_values.PreAssayHandling_StarvationDateOff > handles.params.PreAssayHandling_StarvationDate_Range(2) || ...
    previous_values.PreAssayHandling_StarvationDateOff < handles.params.PreAssayHandling_StarvationDate_Range(1),
  previous_values.PreAssayHandling_StarvationDateOff = handles.params.PreAssayHandling_StarvationDate_Range(2);
end

% by default, previous offset
handles.PreAssayHandling_StarvationDate_datenum = floor(handles.now) - previous_values.PreAssayHandling_StarvationDateOff;
handles.PreAssayHandling_StarvationDate = datestr(handles.PreAssayHandling_StarvationDate_datenum,handles.dateformat);

% set possible values, current value, color to default
set(handles.popupmenu_PreAssayHandling_StarvationDate,'String',handles.PreAssayHandling_StarvationDates,...
  'Value',find(strcmp(handles.PreAssayHandling_StarvationDate,handles.PreAssayHandling_StarvationDates),1),...
  'BackgroundColor',handles.isdefault_bkgdcolor);

%% Starvation Hour

% whether this has been changed or not
handles.isdefault.PreAssayHandling_StarvationHour = true;

% if IncubatorID not stored in rc file, choose now
if ~isfield(previous_values,'PreAssayHandling_StarvationHour'),
  previous_values.PreAssayHandling_StarvationHour = datestr(handles.now,handles.hourformat);
end

% by default, previous IncubatorID
handles.PreAssayHandling_StarvationHour = previous_values.PreAssayHandling_StarvationHour;

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
if ~isfield(previous_values,'PreAssayHandling_StarvationHandler') || ...
    ~ismember(previous_values.PreAssayHandling_StarvationHandler,handles.PreAssayHandling_StarvationHandlers),
  previous_values.PreAssayHandling_StarvationHandler = handles.PreAssayHandling_StarvationHandlers{1};
end

% by default, previous StarvationHandler
handles.PreAssayHandling_StarvationHandler = previous_values.PreAssayHandling_StarvationHandler;

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
if ~isfield(previous_values,'Assay_Rig') || ...
    ~ismember(previous_values.Assay_Rig,handles.Assay_Rigs),
  previous_values.Assay_Rig = handles.Assay_Rigs{1};
end

% by default, previous StarvationHandler
handles.Assay_Rig = previous_values.Assay_Rig;

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
if ~isfield(previous_values,'Assay_Plate') || ...
    ~ismember(previous_values.Assay_Plate,handles.Assay_Plates),
  previous_values.Assay_Plate = handles.Assay_Plates{1};
end

% by default, previous StarvationHandler
handles.Assay_Plate = previous_values.Assay_Plate;

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
if ~isfield(previous_values,'Assay_Bowl') || ...
    ~ismember(previous_values.Assay_Bowl,handles.Assay_Bowls),
  previous_values.Assay_Bowl = handles.Assay_Bowls{1};
end

% by default, previous StarvationHandler
handles.Assay_Bowl = previous_values.Assay_Bowl;

% set possible values, current value, color to default
set(handles.popupmenu_Assay_Bowl,'String',handles.Assay_Bowls,...
  'Value',find(strcmp(handles.Assay_Bowl,handles.Assay_Bowls),1),...
  'BackgroundColor',handles.isdefault_bkgdcolor);

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
if ~isfield(previous_values,'DeviceID'),
  previous_values.DeviceID = [];
end
% by default, previous DeviceID
handles.DeviceID = previous_values.DeviceID;

handles = detectCamerasWrapper(handles);

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

% TODO: for now, this is set statically
handles.MetaData_RoomTemperature = handles.params.MetaData_RoomTemperatureSetPoint;
% TODO: for now, this is set statically
handles.MetaData_RoomHumidity = handles.params.MetaData_RoomHumiditySetPoint;

%% Plot frame rate

handles.Status_FrameRate_MaxNFramesPlot = 100;
handles.Status_FrameRate_History = nan(1,handles.Status_FrameRate_MaxNFramesPlot);
handles.hLine_Status_FrameRate = plot(handles.axes_Status_FrameRate,...
  1:handles.Status_FrameRate_MaxNFramesPlot,handles.Status_FrameRate_History,'color',[0,1,0]);
set(handles.axes_Status_FrameRate,'Color',[0,0,0],...
  'XColor','w','YColor','w',...
  'XLim',[1,handles.Status_FrameRate_MaxNFramesPlot],...
  'YLim',[0,handles.params.MaxFrameRatePlot]);

%% Preview axes

set(handles.axes_PreviewVideo,'xtick',[],'ytick',[]);