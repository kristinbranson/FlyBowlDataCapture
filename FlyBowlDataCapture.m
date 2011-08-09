function varargout = FlyBowlDataCapture(varargin)
% FLYBOWLDATACAPTURE M-file for FlyBowlDataCapture.fig
%      FLYBOWLDATACAPTURE, by itself, creates a new FLYBOWLDATACAPTURE or raises the existing
%      singleton*.
%
%      H = FLYBOWLDATACAPTURE returns the handle to a new FLYBOWLDATACAPTURE or the handle tc
%      the existing singleton*.
%
%      FLYBOWLDATACAPTURE('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in FLYBOWLDATACAPTURE.M with the given input arguments.
%
%      FLYBOWLDATACAPTURE('Property','Value',...) creates a new FLYBOWLDATACAPTURE or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before FlyBowlDataCapture_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to FlyBowlDataCapture_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help FlyBowlDataCapture

% Last Modified by GUIDE v2.5 09-Aug-2011 17:33:26

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @FlyBowlDataCapture_OpeningFcn, ...
                   'gui_OutputFcn',  @FlyBowlDataCapture_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before FlyBowlDataCapture is made visible.
function FlyBowlDataCapture_OpeningFcn(hObject, eventdata, handles, varargin) %#ok<*INUSL>
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to FlyBowlDataCapture (see VARARGIN)

% Choose default command line output for FlyBowlDataCapture

% make sure that we can close if we really really want to
%global FBDC_NTRIESCLOSE;
%FBDC_NTRIESCLOSE = 0;

global FBDC_DIDHALT;
FBDC_DIDHALT = false;

handles.DEBUG = false;
handles.IsProcessingError = false;
guidata(hObject,handles);

try
  
handles.output = hObject;

% name of rc file
handles.rcfile = '.FlyBowlDataCapture_rc.mat';

% get GUI instance
handles.GUIInstanceDir = '.GUIInstances';
handles = getGUIInstance(handles);

handles = LoadPreviousValues(handles);

if isfield(handles.previous_values,'params_file'),
  handles.params_file = handles.previous_values.params_file;
else
  handles.params_file = 'FlyBowlDataCaptureParams.txt';
end

[filestr,pathstr] = uigetfile('*.txt','Choose Parameter File',handles.params_file);
if ~ischar(filestr) || isempty(filestr),
  if isfield(handles,'GUIInstanceFileName') && ...
      exist(handles.GUIInstanceFileName,'file'),
    delete(handles.GUIInstanceFileName);
  end
  uiresume(handles.figure_main);
  return;
end
handles.params_file = fullfile(pathstr,filestr);
if ~exist(handles.params_file,'file'),
  s = sprintf('File %s does not exist',handles.params_file);
  errordlg(s,'Error loading config parameters');
  error(s);
end

% Figure position

if isfield(handles.previous_values,'FigurePosition'),
  handles.FigurePosition = get(handles.figure_main,'Position');
  handles.FigurePosition(1:2) = handles.previous_values.FigurePosition(1:2);

  % make sure that this fits on the screen
  ScreenSize = get(0,'ScreenSize');
  handles.FigurePosition(1) = max(1,handles.FigurePosition(1));
  handles.FigurePosition(2) = max(1,handles.FigurePosition(2));
  top = handles.FigurePosition(2)+handles.FigurePosition(4);
  if top > ScreenSize(4)-50,
    top = ScreenSize(4)-50;
    handles.FigurePosition(2) = top-handles.FigurePosition(4);
  end
  right = handles.FigurePosition(1)+handles.FigurePosition(3);
  if right > ScreenSize(3),
    right = ScreenSize(3);
    handles.FigurePosition(1) = max(1,right-handles.FigurePosition(3));
  end
  
  set(handles.figure_main,'Units','Pixels','Position',handles.FigurePosition);
end

% initialize data
handles = FlyBowlDataCapture_InitializeData(handles);

if isempty(which('findjobj')) && exist('findjobj','dir'),
  addpath('findjobj');
end

% make the line name edit box autocomplete -- must be visible
set(handles.figure_main,'Visible','on');
hwait = waitbar(0,'Please wait. Initializing GUI...');

if ~handles.isAutoComplete_edit_Fly_LineName,
  handles.AutoCompleteEdit_Fly_LineName = ...
    AutoCompleteEdit(handles.edit_Fly_LineName,handles.Fly_LineNames,...
    'Callback',get(handles.edit_Fly_LineName,'Callback'));
  set(handles.edit_Fly_LineName,'Callback','');
  handles.isAutoComplete_edit_Fly_LineName = true;
end

% get a reference to the underlying java component for the log
handles.jhedit_Status = findjobj(handles.edit_Status);
handles.jedit_Status = handles.jhedit_Status.getComponent(0).getComponent(0);

% barcode edit box
handles.jhedit_Barcode = findjobj(handles.edit_Barcode);
% always highlight when focus gained
set(handles.jhedit_Barcode,'FocusGainedCallback',@HighlightEditText);

guidata(hObject,handles);

hwait = waitbar(1);
if ishandle(hwait),
  delete(hwait);
end

% UIWAIT makes FlyBowlDataCapture wait for user response (see UIRESUME)
uiwait(handles.figure_main);

catch ME,
  
  if handles.DEBUG,
    getReport(ME)
    rethrow(ME);
  else
    s = {'Error during data capture:',getReport(ME)};
    if exist('handles','var') && isstruct(handles) && ...
        isfield(handles,'LogFileName') && ischar(handles.LogFileName),
      s{end+1} = ['Log file location: ',handles.LogFileName];
    end
    s{end+1} = 'Please create a Jira ticket with this information.';
    uiwait(myerrordlg(s,'Error During Data Capture'));
    handles.IsProcessingError = true;
    guidata(hObject,handles);
  end
  
  if exist('hwait','var') && ishandle(hwait),
    delete(hwait);
  end
  
end

function handles = LoadPreviousValues(handles)

% Read previous values
handles.previous_values = struct;
handles.GUIInstance_prev = {
  'Assay_Rig'
  'Assay_Plate'
  'Assay_Lid'
  'Assay_VisualSurround'
  'Assay_Bowl'
  'DeviceID'
  'TempProbeID'
  'FigurePosition'
  };
if exist(handles.rcfile,'file'),
  try
    handles.previous_values = load(handles.rcfile);

    for i = 1:length(handles.GUIInstance_prev),
      fn = handles.GUIInstance_prev{i};
      if ~isfield(handles.previous_values,fn) || ischar(handles.previous_values.(fn)),
        continue;
      end
      j = mod(handles.GUIi-1,length(handles.previous_values.(fn)))+1;
      handles.previous_values.(fn) = handles.previous_values.(fn){j};
    end
  catch
  end
end


% --- Outputs from this function are returned to the command line.
function FlyBowlDataCapture_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

try

guidata(hObject,handles);

delete(handles.figure_main);

catch ME
  s = sprintf('Error while closing GUI: %s\n',getReport(ME));
  uiwait(errordlg(s,'Error while closing GUI'));
  if exist('handles','var') && isfield(handles,'figure_main') && ...
      ishandle(handles.figure_main),
    delete(handles.figure_main);
  end
end

% --- Executes on selection change in popupmenu_Assay_Experimenter.
function popupmenu_Assay_Experimenter_Callback(hObject, eventdata, handles) %#ok<*DEFNU>
% hObject    handle to popupmenu_Assay_Experimenter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu_Assay_Experimenter contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu_Assay_Experimenter

% grab value
v = get(handles.popupmenu_Assay_Experimenter,'Value');
handles.Assay_Experimenter = handles.Assay_Experimenters{v};

% no longer default
handles.isdefault.Assay_Experimenter = false;

% set color
set(handles.popupmenu_Assay_Experimenter,'BackgroundColor',handles.changed_bkgdcolor);

handles = ChangedMetaData(handles);

guidata(hObject,handles);

% --- Executes during object creation, after setting all properties.
function popupmenu_Assay_Experimenter_CreateFcn(hObject, eventdata, handles) %#ok<*INUSD>
% hObject    handle to popupmenu_Assay_Experimenter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function [handles,success] = setLineName(handles,newname)

success = false;
hObject = handles.edit_Fly_LineName;
oldname = get(hObject,'String');
eventdata.String = newname;
set(hObject,'String',newname);
try
  edit_Fly_LineName_Callback(hObject, eventdata, handles);
  handles = guidata(hObject);
  success = strcmp(newname,get(hObject,'String'));
  CheckBarcodeConsistency(handles);
  if ~success,
    warndlg(sprintf('Line name %s not in list of allowed line names',newname),'Error setting line name','modal');    
  end
catch ME,
  warndlg(getReport(ME),'Error setting line name','modal');
  set(hObject,'String',oldname);
  return;
end


% --- Executes on selection change in edit_Fly_LineName.
function edit_Fly_LineName_Callback(hObject, eventdata, handles)
% hObject    handle to edit_Fly_LineName (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns edit_Fly_LineName contents as cell array
%        contents{get(hObject,'Value')} returns selected item from edit_Fly_LineName

%fprintf('edit_Fly_LineName called, event = ');
%disp(eventdata)

% grab value
drawnow;
if isfield(eventdata,'String'),
  newname = eventdata.String;
else
  newname = get(handles.edit_Fly_LineName,'String');
end
i = find(strcmpi(newname,handles.Fly_LineNames));
isvalid = ~isempty(i);
if ~isvalid,
  % doesn't match a valid name? then revert
  set(handles.edit_Fly_LineName,'String',handles.Fly_LineName);
else
  % multiple matches, check for case sensitivity
  if length(i) > 1,
    % how many letters are exactly shared
    nmatches = sum(char(handles.Fly_LineNames(i))==repmat(newname,[length(i),1]),2,'double');
    % choose the maximum number of exact matches
    [~,i1] = max(nmatches);
    i = i(i1);
  end
  % replace with correct capitalization if nec
  if ~strcmp(newname,handles.Fly_LineNames{i}),
    newname = handles.Fly_LineNames{i};
    set(handles.edit_Fly_LineName,'String',handles.Fly_LineNames{i});
  end
end

if isvalid,

  handles.Fly_LineName = newname;
  
  % no longer default
  handles.isdefault.Fly_LineName = false;

  % set color
  set(handles.edit_Fly_LineName,'BackgroundColor',handles.changed_bkgdcolor);
  
  handles = ChangedMetaData(handles);
  
else
  
  addToStatus(handles,{sprintf('Invalid line name %s switched back to %s.',...
    newname,handles.Fly_LineName)});
  %fprintf('Invalid line name %s switched back to %s.',...
  %  newname,handles.Fly_LineName);
  set(handles.edit_Fly_LineName,'BackgroundColor',handles.shouldchange_bkgdcolor);

end

guidata(hObject,handles);

CheckBarcodeConsistency(handles);

% --- Executes during object creation, after setting all properties.
function edit_Fly_LineName_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_Fly_LineName (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on selection change in popupmenu_Rearing_IncubatorID.
function popupmenu_Rearing_IncubatorID_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu_Rearing_IncubatorID (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu_Rearing_IncubatorID contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu_Rearing_IncubatorID

% grab value
v = get(handles.popupmenu_Rearing_IncubatorID,'Value');
handles.Rearing_IncubatorID = handles.Rearing_IncubatorIDs{v};

% no longer default
handles.isdefault.Rearing_IncubatorID = false;

% set color
set(handles.popupmenu_Rearing_IncubatorID,'BackgroundColor',handles.changed_bkgdcolor);

handles = ChangedMetaData(handles);

guidata(hObject,handles);

% --- Executes during object creation, after setting all properties.
function popupmenu_Rearing_IncubatorID_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu_Rearing_IncubatorID (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function handles = CheckOrderingErrors(handles)

handles.isOrderingError = false(1,3);

% is CrossDate > SortingTime?
if handles.PreAssayHandling_CrossDate_datenum > handles.PreAssayHandling_SortingTime_datenum,
  handles.isOrderingError(1:2) = true;
end
% is SortingTime > StarvationTime?
if handles.PreAssayHandling_SortingTime_datenum > handles.PreAssayHandling_StarvationTime_datenum,
  handles.isOrderingError(2:3) = true;
end

% set background colors
if handles.isOrderingError(1),
  set(handles.popupmenu_PreAssayHandling_CrossDate,'BackgroundColor',handles.shouldchange_bkgdcolor);
else  
  % no ordering error, set color to either isdefault or changed color
  if handles.isdefault.PreAssayHandling_CrossDate,
    set(handles.popupmenu_PreAssayHandling_CrossDate,'BackgroundColor',handles.isdefault_bkgdcolor);
  else
    set(handles.popupmenu_PreAssayHandling_CrossDate,'BackgroundColor',handles.changed_bkgdcolor);
  end
end

if handles.isOrderingError(2),
  set(handles.popupmenu_PreAssayHandling_SortingDate,'BackgroundColor',handles.shouldchange_bkgdcolor);
  set(handles.edit_PreAssayHandling_SortingHour,'BackgroundColor',handles.shouldchange_bkgdcolor);
else
  if handles.isdefault.PreAssayHandling_SortingDate,
    set(handles.popupmenu_PreAssayHandling_SortingDate,'BackgroundColor',handles.isdefault_bkgdcolor);
  else
    set(handles.popupmenu_PreAssayHandling_SortingDate,'BackgroundColor',handles.changed_bkgdcolor);
  end
  if handles.isdefault.PreAssayHandling_SortingHour,
    set(handles.edit_PreAssayHandling_SortingHour,'BackgroundColor',handles.isdefault_bkgdcolor);
  else
    set(handles.edit_PreAssayHandling_SortingHour,'BackgroundColor',handles.changed_bkgdcolor);
  end
end

if handles.isOrderingError(3),
  set(handles.popupmenu_PreAssayHandling_StarvationDate,'BackgroundColor',handles.shouldchange_bkgdcolor);
  set(handles.edit_PreAssayHandling_StarvationHour,'BackgroundColor',handles.shouldchange_bkgdcolor);
else
  if handles.isdefault.PreAssayHandling_StarvationDate,
    set(handles.popupmenu_PreAssayHandling_StarvationDate,'BackgroundColor',handles.isdefault_bkgdcolor);
  else
    set(handles.popupmenu_PreAssayHandling_StarvationDate,'BackgroundColor',handles.changed_bkgdcolor);
  end
  if handles.isdefault.PreAssayHandling_StarvationHour,
    set(handles.edit_PreAssayHandling_StarvationHour,'BackgroundColor',handles.isdefault_bkgdcolor);
  else
    set(handles.edit_PreAssayHandling_StarvationHour,'BackgroundColor',handles.changed_bkgdcolor);
  end
end

% --- Executes on selection change in popupmenu_PreAssayHandling_SortingDate.
function popupmenu_PreAssayHandling_SortingDate_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu_PreAssayHandling_SortingDate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu_PreAssayHandling_SortingDate contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu_PreAssayHandling_SortingDate

% grab value
v = get(handles.popupmenu_PreAssayHandling_SortingDate,'Value');
handles.PreAssayHandling_SortingDate = handles.PreAssayHandling_SortingDates{v};
% store datenum
handles.PreAssayHandling_SortingDate_datenum = floor(datenum(handles.PreAssayHandling_SortingDate));
% and time datenum
handles.PreAssayHandling_SortingTime_datenum = ...
  handles.PreAssayHandling_SortingDate_datenum + ...
  handles.PreAssayHandling_SortingHour_datenum;

% no longer default
handles.isdefault.PreAssayHandling_SortingDate = false;

% highlight ordering errors
handles = CheckOrderingErrors(handles);

handles = ChangedMetaData(handles);

guidata(hObject,handles);

% --- Executes during object creation, after setting all properties.
function popupmenu_PreAssayHandling_SortingDate_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu_PreAssayHandling_SortingDate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_PreAssayHandling_SortingHour_Callback(hObject, eventdata, handles)
% hObject    handle to edit_PreAssayHandling_SortingHour (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_PreAssayHandling_SortingHour as text
%        str2double(get(hObject,'String')) returns contents of edit_PreAssayHandling_SortingHour as a double

% grab value
s = get(handles.edit_PreAssayHandling_SortingHour,'String');

% make sure this is a valid time string
s = strtrim(s);
m = regexp(s,'^\d\d:\d\d$','match');
if isempty(m),
  set(handles.edit_PreAssayHandling_SortingHour,'String',handles.PreAssayHandling_SortingHour,...
    'BackgroundColor',handles.shouldchange_bkgdcolor);
  return;
end
  
handles.PreAssayHandling_SortingHour = s;
% unknown sorting hour
if strcmpi(s,'99:99'),
  handles.PreAssayHandling_SortingHour_datenum = nan;
else
  handles.PreAssayHandling_SortingHour_datenum = rem(datenum(s),1);
end

handles.PreAssayHandling_SortingTime_datenum = ...
  handles.PreAssayHandling_SortingDate_datenum + ...
  handles.PreAssayHandling_SortingHour_datenum;

% no longer default
handles.isdefault.PreAssayHandling_SortingHour = false;

% make sure date order is legal
handles = CheckOrderingErrors(handles);

handles = ChangedMetaData(handles);

guidata(hObject,handles);

% --- Executes during object creation, after setting all properties.
function edit_PreAssayHandling_SortingHour_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_PreAssayHandling_SortingHour (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenu_PreAssayHandling_SortingHandler.
function popupmenu_PreAssayHandling_SortingHandler_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu_PreAssayHandling_SortingHandler (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu_PreAssayHandling_SortingHandler contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu_PreAssayHandling_SortingHandler

% grab value
v = get(handles.popupmenu_PreAssayHandling_SortingHandler,'Value');
handles.PreAssayHandling_SortingHandler = handles.PreAssayHandling_SortingHandlers{v};

% no longer default
handles.isdefault.PreAssayHandling_SortingHandler = false;

% set color
set(handles.popupmenu_PreAssayHandling_SortingHandler,'BackgroundColor',handles.changed_bkgdcolor);

handles = ChangedMetaData(handles);

guidata(hObject,handles);

% --- Executes during object creation, after setting all properties.
function popupmenu_PreAssayHandling_SortingHandler_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu_PreAssayHandling_SortingHandler (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenu_PreAssayHandling_StarvationDate.
function popupmenu_PreAssayHandling_StarvationDate_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu_PreAssayHandling_StarvationDate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu_PreAssayHandling_StarvationDate contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu_PreAssayHandling_StarvationDate

% grab value
v = get(handles.popupmenu_PreAssayHandling_StarvationDate,'Value');
% store datenum
handles.PreAssayHandling_StarvationDate = handles.PreAssayHandling_StarvationDates{v};
handles.PreAssayHandling_StarvationDate_datenum = floor(datenum(handles.PreAssayHandling_StarvationDate));
% and time datenum
handles.PreAssayHandling_StarvationTime_datenum = ...
  handles.PreAssayHandling_StarvationDate_datenum + ...
  handles.PreAssayHandling_StarvationHour_datenum;

% no longer default
handles.isdefault.PreAssayHandling_StarvationDate = false;

% highlight ordering errors
handles = CheckOrderingErrors(handles);

handles = ChangedMetaData(handles);

guidata(hObject,handles);

% --- Executes during object creation, after setting all properties.
function popupmenu_PreAssayHandling_StarvationDate_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu_PreAssayHandling_StarvationDate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_PreAssayHandling_StarvationHour_Callback(hObject, eventdata, handles)
% hObject    handle to edit_PreAssayHandling_StarvationHour (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_PreAssayHandling_StarvationHour as text
%        str2double(get(hObject,'String')) returns contents of edit_PreAssayHandling_StarvationHour as a double

% grab value
s = get(handles.edit_PreAssayHandling_StarvationHour,'String');

% make sure this is a valid time string
s = strtrim(s);
m = regexp(s,'^\d\d:\d\d$','match');
if isempty(m),
  set(handles.edit_PreAssayHandling_StarvationHour,'String',handles.PreAssayHandling_StarvationHour,...
    'BackgroundColor',handles.shouldchange_bkgdcolor);
  return;
end

% store hour
handles.PreAssayHandling_StarvationHour = s;
% and hour datenum
handles.PreAssayHandling_StarvationHour_datenum = rem(datenum(s),1);

% and time datenum
handles.PreAssayHandling_StarvationTime_datenum = ...
  handles.PreAssayHandling_StarvationDate_datenum + ...
  handles.PreAssayHandling_StarvationHour_datenum;

% no longer default
handles.isdefault.PreAssayHandling_StarvationHour = false;

% highlight ordering errors
handles = CheckOrderingErrors(handles);

handles = ChangedMetaData(handles);

guidata(hObject,handles);

% --- Executes during object creation, after setting all properties.
function edit_PreAssayHandling_StarvationHour_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_PreAssayHandling_StarvationHour (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenu_Assay_Rig.
function popupmenu_Assay_Rig_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu_Assay_Rig (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu_Assay_Rig contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu_Assay_Rig

% grab value
v = get(handles.popupmenu_Assay_Rig,'Value');
handles.Assay_Rig = handles.Assay_Rigs{v};

% no longer default
handles.isdefault.Assay_Rig = false;

% set color
set(handles.popupmenu_Assay_Rig,'BackgroundColor',handles.changed_bkgdcolor);

handles = ChangedMetaData(handles);

% rotate preview image if nec
RotatePreviewImage(handles);

guidata(hObject,handles);


% --- Executes during object creation, after setting all properties.
function popupmenu_Assay_Rig_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu_Assay_Rig (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenu_Assay_Plate.
function popupmenu_Assay_Plate_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu_Assay_Plate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu_Assay_Plate contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu_Assay_Plate

% grab value
v = get(handles.popupmenu_Assay_Plate,'Value');
handles.Assay_Plate = handles.Assay_Plates{v};

% no longer default
handles.isdefault.Assay_Plate = false;

% set color
set(handles.popupmenu_Assay_Plate,'BackgroundColor',handles.changed_bkgdcolor);

handles = ChangedMetaData(handles);

guidata(hObject,handles);


% --- Executes during object creation, after setting all properties.
function popupmenu_Assay_Plate_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu_Assay_Plate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenu_Assay_Bowl.
function popupmenu_Assay_Bowl_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu_Assay_Bowl (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu_Assay_Bowl contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu_Assay_Bowl

% grab value
v = get(handles.popupmenu_Assay_Bowl,'Value');
handles.Assay_Bowl = handles.Assay_Bowls{v};

% no longer default
handles.isdefault.Assay_Bowl = false;

% set color
set(handles.popupmenu_Assay_Bowl,'BackgroundColor',handles.changed_bkgdcolor);

handles = ChangedMetaData(handles);

% rotate preview image if nec
RotatePreviewImage(handles);

guidata(hObject,handles);


% --- Executes during object creation, after setting all properties.
function popupmenu_Assay_Bowl_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu_Assay_Bowl (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on button press in pushbutton_ShiftFlyTemp.
function pushbutton_ShiftFlyTemp_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_ShiftFlyTemp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% store time that flies were shifted
handles.ShiftFlyTemp_Time_datenum = now;

% put in button string
set(hObject,'BackgroundColor',handles.grayed_bkgdcolor,...
  'String',sprintf('Temp: %s',datestr(handles.ShiftFlyTemp_Time_datenum,13)));

% if we've already stored fly loading time, reset this
handles.FliesLoaded_Time_datenum = -1;
set(handles.pushbutton_FliesLoaded,'BackgroundColor',handles.FliesLoaded_bkgdcolor,...
  'String','Flies Loaded','Enable','on');

% we haven't set fly loading time, so disable startrecording button
set(handles.pushbutton_StartRecording,'Enable','off','BackgroundColor',handles.grayed_bkgdcolor);

% add to status log
addToStatus(handles,{'Shifted fly temperature.'},handles.ShiftFlyTemp_Time_datenum);

handles = ChangedMetaData(handles);

guidata(hObject,handles);

% --- Executes on button press in pushbutton_FliesLoaded.
function pushbutton_FliesLoaded_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_FliesLoaded (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% store time flies were loaded
handles.FliesLoaded_Time_datenum = now;

% start a timer so that we know how long it's been since flies were loaded
FliesLoaded_Timer_Params = ...
 struct('FliesLoaded_Time_datenum',handles.FliesLoaded_Time_datenum,...
 'pushbutton_FliesLoaded',handles.pushbutton_FliesLoaded,...
 'pushbutton_StartRecording',handles.pushbutton_StartRecording,...
 'MinFliesLoadedTime',handles.params.MinFliesLoadedTime,...
 'MaxFliesLoadedTime',handles.params.MaxFliesLoadedTime);

handles.FliesLoaded_Timer = timer('Period',1,...
  'ExecutionMode','fixedRate',...
  'Name','FliesLoaded_Timer','tag','FliesLoaded_Timer',...
  'TimerFcn',{@FliesLoaded_Timer_Callback,FliesLoaded_Timer_Params},...
  'StopFcn',{@FliesLoaded_Timer_Stop,FliesLoaded_Timer_Params},...
  'BusyMode','drop');

% also write to button string
set(hObject,'BackgroundColor',handles.grayed_bkgdcolor,...
  'String',sprintf('Load: %ds ago',0));

% enable recording if camera is initialized
if handles.IsCameraInitialized && (handles.TempProbe_IsInitialized || (handles.params.DoRecordTemp == 0)),
  set(handles.pushbutton_StartRecording,'Enable','on','BackgroundColor',handles.StartRecording_bkgdcolor);
end

% add to status log
addToStatus(handles,{'Flies loaded.'},handles.FliesLoaded_Time_datenum);

handles = ChangedMetaData(handles);

start(handles.FliesLoaded_Timer);

guidata(hObject,handles);

function FliesLoaded_Timer_Stop(obj,event,params)

% time since flies loaded, in seconds
dt = (now - params.FliesLoaded_Time_datenum)*86400;
if ishandle(params.pushbutton_FliesLoaded),
  set(params.pushbutton_FliesLoaded,'String',sprintf('Load Time: %.2f',dt));
end
if ishandle(params.pushbutton_StartRecording),
  set(params.pushbutton_StartRecording,'String','Start Recording');
end

function FliesLoaded_Timer_Callback(obj,event,params)

% stop if we've halted
global FBDC_DIDHALT;
if ~isempty(FBDC_DIDHALT) && FBDC_DIDHALT,
  try
    if strcmpi(get(obj,'Running'),'on'),
      stop(obj);
    end
  catch ME
    getReport(ME)
  end
end

% time since flies loaded, in seconds
dt = (now - params.FliesLoaded_Time_datenum)*86400;
rounddt = round(dt);
if dt < params.MinFliesLoadedTime,
  set(params.pushbutton_StartRecording,...
    'String',sprintf('Record (%ds early)',params.MinFliesLoadedTime-rounddt));
elseif dt > params.MaxFliesLoadedTime,
  set(params.pushbutton_StartRecording,...
    'String',sprintf('Record (%ds late)',rounddt-params.MaxFliesLoadedTime));
else
  set(params.pushbutton_StartRecording,...
    'String','Start Recording');
end
set(params.pushbutton_FliesLoaded,'String',sprintf('Load: %ds ago',rounddt));

function handles = RemoveFliesLoadedTimer(handles)

% stop, delete the fliesloaded timer
if isfield(handles,'FliesLoaded_Timer') && ...
    isvalid(handles.FliesLoaded_Timer),
  if strcmpi(get(handles.FliesLoaded_Timer,'Running'),'on'),
    stop(handles.FliesLoaded_Timer);
  end
  delete(handles.FliesLoaded_Timer);
  handles = rmfield(handles,'FliesLoaded_Timer');
end


% --- Executes on button press in pushbutton_StartRecording.
function pushbutton_StartRecording_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_StartRecording (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles = RemoveFliesLoadedTimer(handles);

% store isrecording flag
handles.IsRecording = true;

% disable other time buttons
set(handles.pushbutton_FliesLoaded,'Enable','off');
set(handles.pushbutton_ShiftFlyTemp,'Enable','off');

% disable start recording button
set(handles.pushbutton_StartRecording,'Enable','off','BackgroundColor',handles.grayed_bkgdcolor);

% disable changing camera
set(handles.popupmenu_DeviceID,'Enable','off');
set(handles.menu_Edit_DetectCameras,'Enable','off');

% disable File menus
set(handles.menu_File_New,'Enable','off');
set(handles.menu_File_Close,'Enable','off');
set(handles.menu_Quit,'Enable','off');

guidata(hObject,handles);

% start recording
startLogging(handles.figure_main);

handles = guidata(hObject);

% store record start time in button string
set(hObject,'BackgroundColor',handles.grayed_bkgdcolor,...
  'String',sprintf('Rec: %s',datestr(handles.StartRecording_Time_datenum,13)));


% --- Executes on button press in pushbutton_Abort.
function pushbutton_Abort_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_Abort (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

[handles,didcancel] = CloseExperiment(handles);
if didcancel,
  return;
end
handles = DisableGUI(handles);
guidata(hObject,handles);

function edit_TechnicalNotes_Callback(hObject, eventdata, handles)
% hObject    handle to edit_TechnicalNotes (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_TechnicalNotes as text
%        str2double(get(hObject,'String')) returns contents of edit_TechnicalNotes as a double

handles.TechnicalNotes = get(hObject,'String');

handles = ChangedMetaData(handles);

guidata(hObject,handles);

% --- Executes during object creation, after setting all properties.
function edit_TechnicalNotes_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_TechnicalNotes (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_BehaviorNotes_Callback(hObject, eventdata, handles)
% hObject    handle to edit_BehaviorNotes (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_BehaviorNotes as text
%        str2double(get(hObject,'String')) returns contents of edit_BehaviorNotes as a double

handles.BehaviorNotes = get(hObject,'String');

handles = ChangedMetaData(handles);

guidata(hObject,handles);

% --- Executes during object creation, after setting all properties.
function edit_BehaviorNotes_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_BehaviorNotes (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenu_PreAssayHandling_StarvationHandler.
function popupmenu_PreAssayHandling_StarvationHandler_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu_PreAssayHandling_StarvationHandler (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu_PreAssayHandling_StarvationHandler contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu_PreAssayHandling_StarvationHandler

% grab value
v = get(handles.popupmenu_PreAssayHandling_StarvationHandler,'Value');
handles.PreAssayHandling_StarvationHandler = handles.PreAssayHandling_StarvationHandlers{v};

% no longer default
handles.isdefault.PreAssayHandling_StarvationHandler = false;

% set color
set(handles.popupmenu_PreAssayHandling_StarvationHandler,'BackgroundColor',handles.changed_bkgdcolor);

handles = ChangedMetaData(handles);

guidata(hObject,handles);

% --- Executes during object creation, after setting all properties.
function popupmenu_PreAssayHandling_StarvationHandler_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu_PreAssayHandling_StarvationHandler (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton_Done.
function pushbutton_Done_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_Done (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% check if barcode is entered
if handles.params.CheckBarcode && handles.barcode < 0,
  res = questdlg('Barcode not entered. Continue closing experiment?','Bad Barcode','Yes','No','Cancel','Cancel');
  if ~strcmp(res,'Yes'),
    return;
  end  
end

handles = DisableGUI(handles);

CloseQuickStatsFigures(handles);
pause(1);

% rename video
oldname = handles.FileName;
handles = renameVideoFile(handles);
if ~strcmp(oldname,handles.FileName),
  addToStatus(handles,{sprintf('Renamed %s -> %s.',oldname,handles.FileName)});
end

handles = resetTempProbe(handles);
handles = unsetCamera(handles);

% save metadata
if handles.MetaDataNeedsSave,
  answer = questdlg('Save MetaData before closing?','Save MetaData?','Yes','No','Yes');
  if strcmpi(answer,'Yes'),
    handles = SaveMetaData(handles);
  end
end
handles.MetaDataNeedsSave = false;

successfilename = fullfile(handles.ExperimentDirectory,'SUCCESS');
try
  fid = fopen(successfilename,'w');
  fprintf(fid,datestr(now,30));
  fclose(fid);
catch ME
  addToStatus(handles,{'Could not create success file',getReport(ME,'basic','hyperlinks','off')});
end

% record configuration
handles = RecordConfiguration(handles);

guidata(hObject,handles);

function CloseQuickStatsFigures(handles)

% delete quick stats figure
if isfield(handles,'QuickStats'),
  if isfield(handles.QuickStats,'fig') && ishandle(handles.QuickStats.fig),
    delete(handles.QuickStats.fig);
  end
  if isfield(handles.QuickStats,'showufmf_handle') && ishandle(handles.QuickStats.showufmf_handle),
    delete(handles.QuickStats.showufmf_handle);
  end
end

% --- Executes on key press with focus on popupmenu_Assay_Experimenter and none of its controls.
function popupmenu_Assay_Experimenter_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu_Assay_Experimenter (see GCBO)
% eventdata  structure with the following fields (see UICONTROL)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function menu_File_Callback(hObject, eventdata, handles)
% hObject    handle to menu_File (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function menu_Edit_RefreshLineNames_Callback(hObject, eventdata, handles)
% hObject    handle to menu_Edit_RefreshLineNames (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles = readLineNames(handles,handles.params.DoQuerySage);

% check to see if the current line name is valid
if ~ismember(handles.Fly_LineName,handles.Fly_LineNames),
  uiwait(errordlg(sprintf('Line name %s not in line name list, resetting line name to %s\n',handles.Fly_LineName,handles.Fly_LineNames{1})));
  handles.Fly_LineName = handles.Fly_LineNames{1};
end
set(handles.edit_Fly_LineName,'String',handles.Fly_LineName);
drawnow;
AutoCompleteEdit(handles.AutoCompleteEdit_Fly_LineName,handles.Fly_LineNames);
drawnow;

handles = ChangedMetaData(handles);

guidata(hObject,handles);

% --------------------------------------------------------------------
function menu_Edit_SaveConfig_Callback(hObject, eventdata, handles)
% hObject    handle to menu_Edit_SaveConfig (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles = RecordConfiguration(handles);
guidata(hObject,handles);

% --- Executes on button press in popupmenu_DeviceID.
function popupmenu_DeviceID_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu_DeviceID (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

newdevid = handles.DeviceIDs(get(hObject,'Value'));

if newdevid ~= handles.DeviceID,

  % check if this camera is currently in use
  [isInUse,handles] = checkDeviceInUse(handles,newdevid,true);
  if isInUse,
    set(hObject,'Value',find(handles.DeviceID==handles.DeviceIDs,1));
    guidata(hObject,handles);
    return;
  end
  
  % if we've already initialized the camera, uninitialize
  handles = clearVideoInput(handles);
  
  % store new device ID
  handles.DeviceID = newdevid;
  
end
% set color
set(handles.popupmenu_DeviceID,'BackgroundColor',handles.changed_bkgdcolor);
  
handles = ChangedMetaData(handles);

guidata(hObject,handles);


% --- Executes on button press in pushbutton_InitializeCamera.
function pushbutton_InitializeCamera_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_InitializeCamera (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles = setCamera(handles);
set(hObject,'Visible','off');

if handles.FliesLoaded_Time_datenum > 0 && (handles.TempProbe_IsInitialized || (handles.params.DoRecordTemp == 0)),
  set(handles.pushbutton_StartRecording,'Enable','on','BackgroundColor',handles.StartRecording_bkgdcolor);
end

guidata(hObject,handles);


% --- Executes when user attempts to close figure_main.
function figure_main_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure_main (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% global FBDC_NTRIESCLOSE;
% if isempty(FBDC_NTRIESCLOSE),
%   FBDC_NTRIESCLOSE = 0;
% end
% FBDC_NTRIESCLOSE = FBDC_NTRIESCLOSE + 1;
% 
% if FBDC_NTRIESCLOSE > 1,
%   res = questdlg('Force quit? We will try to hard-kill EVERYTHING.','Force quit?');
%   if strcmpi(res,'yes'),
%     FBDC_killall();
%   else
%     FBDC_NTRIESCLOSE = 0;
%   end
% end

% Hint: delete(hObject) closes the figure
[handles,didcancel] = CloseExperiment(handles,true);

hwaitbar = waitbar(0,'Closing GUI');

s = 'Closed experiment';
if exist('hwaitbar','var') && ishandle(hwaitbar),
  waitbar(.3,hwaitbar,s);
else
  hwaitbar = waitbar(.3,s);
end
if didcancel,
  if exist('hwaitbar','var') && ishandle(hwaitbar),
    delete(hwaitbar);
  end
  %FBDC_NTRIESCLOSE = 0;
  return;
end

if isfield(handles,'GUIInstanceFileName') && ...
    exist(handles.GUIInstanceFileName,'file'),
  delete(handles.GUIInstanceFileName);
  s = 'Deleted GUI semaphore';
  if exist('hwaitbar','var') && ishandle(hwaitbar),
    waitbar(.6,hwaitbar,s);
  else
    hwaitbar = waitbar(.6,s);
  end
end
guidata(hObject,handles);

if exist('hwaitbar','var') && ishandle(hwaitbar),
  delete(hwaitbar);
end

%clear FBDC_NTRIESCLOSE;
uiresume(handles.figure_main);

% --------------------------------------------------------------------
function menu_Edit_DetectCameras_Callback(hObject, eventdata, handles)
% hObject    handle to menu_Edit_DetectCameras (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if isfield(handles,'hImage_Preview') && ishandle(handles.hImage_Preview),
  delete(handles.hImage_Preview);
end
set(handles.pushbutton_InitializeCamera,'Visible','on');
handles = detectCamerasWrapper(handles);

handles = ChangedMetaData(handles);

guidata(hObject,handles);

function [handles,success] = setCrossDate(handles,newdatestr)

success = false;
hObject = handles.popupmenu_PreAssayHandling_CrossDate;
v = find(strcmp(newdatestr,handles.PreAssayHandling_CrossDates),1);
if isempty(v),
  warndlg(sprintf('Cross date %s not allowed',newdatestr),'Error setting cross date');
  CheckBarcodeConsistency(handles);
  return;
end
set(hObject,'Value',v);
popupmenu_PreAssayHandling_CrossDate_Callback(hObject, [], handles);
handles = guidata(hObject);
success = true;

% --- Executes on selection change in popupmenu_PreAssayHandling_CrossDate.
function popupmenu_PreAssayHandling_CrossDate_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu_PreAssayHandling_CrossDate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu_PreAssayHandling_CrossDate contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu_PreAssayHandling_CrossDate

% grab value
v = get(handles.popupmenu_PreAssayHandling_CrossDate,'Value');
handles.PreAssayHandling_CrossDate = handles.PreAssayHandling_CrossDates{v};
% store datenum
handles.PreAssayHandling_CrossDate_datenum = datenum(handles.PreAssayHandling_CrossDate);

% no longer default
handles.isdefault.PreAssayHandling_CrossDate = false;

% highlight ordering errors
handles = CheckOrderingErrors(handles);

handles = ChangedMetaData(handles);

guidata(hObject,handles);

CheckBarcodeConsistency(handles);

% --- Executes during object creation, after setting all properties.
function popupmenu_PreAssayHandling_CrossDate_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu_PreAssayHandling_CrossDate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenu_Flag.
function popupmenu_Flag_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu_Flag (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu_Flag contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu_Flag
handles.Flag = handles.Flags{get(hObject,'Value')};

% no longer default
handles.isdefault.Flag = false;

% set color
set(handles.popupmenu_Flag,'BackgroundColor',handles.changed_bkgdcolor);

handles = ChangedMetaData(handles);

guidata(hObject,handles);

% --- Executes during object creation, after setting all properties.
function popupmenu_Flag_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu_Flag (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes during object creation, after setting all properties.
function figure_main_CreateFcn(hObject, eventdata, handles)
% hObject    handle to figure_main (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


% --------------------------------------------------------------------
function menu_Quit_Callback(hObject, eventdata, handles)
% hObject    handle to menu_Quit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

figure_main_CloseRequestFcn(hObject, eventdata, handles)
% 
% [handles,didcancel] = CloseExperiment(handles);
% if didcancel,
%   return;
% end
% if isfield(handles,'GUIInstanceFileName') && ...
%     exist(handles.GUIInstanceFileName,'file'),
%   delete(handles.GUIInstanceFileName);
% end
% 
% guidata(hObject,handles);
% 
% uiresume(handles.figure_main);

% --- Executes on button press in pushbutton_SaveMetaData.
function pushbutton_SaveMetaData_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_SaveMetaData (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles = SaveMetaData(handles);

guidata(hObject,handles);


% --------------------------------------------------------------------
function menu_File_SaveMetaData_Callback(hObject, eventdata, handles)
% hObject    handle to menu_File_SaveMetaData (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles = SaveMetaData(handles);

guidata(hObject,handles);


% --------------------------------------------------------------------
function menu_Edit_Callback(hObject, eventdata, handles)
% hObject    handle to menu_Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function menu_File_New_Callback(hObject, eventdata, handles)
% hObject    handle to menu_File_New (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if handles.GUIIsInitialized,
  [handles,didcancel] = CloseExperiment(handles);
  if didcancel,
    return;
  end
end
CloseQuickStatsFigures(handles);

guidata(hObject,handles);

handles = EnableGUI(handles);

% reload previous values
handles = LoadPreviousValues(handles);

% initialize data
handles = FlyBowlDataCapture_InitializeData(handles);

% reset line name choices
AutoCompleteEdit(handles.AutoCompleteEdit_Fly_LineName,handles.Fly_LineNames);

guidata(hObject,handles);


% --------------------------------------------------------------------
function menu_File_Close_Callback(hObject, eventdata, handles)
% hObject    handle to menu_File_Close (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

[handles,didcancel] = CloseExperiment(handles);
if didcancel,
  return;
end
handles = DisableGUI(handles);
CloseQuickStatsFigures(handles);
% record configuration
handles = RecordConfiguration(handles);

guidata(hObject,handles);

function [handles,didcancel] = CloseExperiment(handles,isclosefig)

if nargin < 2,
  isclosefig = false;
end

if isclosefig,
  % store that we are trying to close
  global FBDC_DIDHALT;
  FBDC_DIDHALT = true;
end

hObject = handles.figure_main;
didabort = false;
didcancel = false;


% if not done recording, then make sure user wants to stop prematurely
if ~handles.FinishedRecording && handles.GUIIsInitialized,
  v = questdlg('Do you really want to close the current experiment?','Really close?','Close','Cancel','Cancel');
  if strcmp(v,'Cancel'),
    didcancel = true;
    return;
  end
  addToStatus(handles,{'Experiment aborted.'});
  didabort = true;
end

hwaitbar = waitbar(.1,'Closing experiment');

% remove flies loaded timer
handles = RemoveFliesLoadedTimer(handles);

% recording stopped in the middle
if handles.IsRecording,
  addToStatus(handles,sprintf('Video recording canceled after %f seconds',(now-handles.StartRecording_Time_datenum)*86400));
end

% stop logging
if handles.IsRecording && isfield(handles,'vid') && isvalid(handles.vid),
  guidata(hObject,handles);
  % last parameter: we did abort
  wrapUpVideo(handles.vid,'',hObject,handles.params.Imaq_Adaptor,true);
  %stop(handles.vid);
  handles = guidata(hObject);
end

s = 'Logging stopped';
if exist('hwaitbar','var') && ishandle(hwaitbar),
  waitbar(.2,hwaitbar,s);
else
  hwaitbar = waitbar(.2,s);
end

% check if barcode is entered
if ~didabort && handles.GUIIsInitialized && ...
    handles.params.CheckBarcode && handles.barcode < 0,
  res = questdlg('Barcode not entered. Continue closing experiment?','Bad barcode','Yes','No','Cancel','Cancel');
  if ~strcmp(res,'Yes'),
    if exist('hwaitbar','var') && ishandle(hwaitbar),
      delete(hwaitbar);
    end
    didcancel = true;
    return;
  end  
end

% save metadata
if handles.MetaDataNeedsSave,
  answer = questdlg('Save MetaData before closing?','Save MetaData?','Yes','No','Yes');
  if strcmpi(answer,'Yes'),
    handles = SaveMetaData(handles);
  end
end
handles.MetaDataNeedsSave = false;

s = 'Saved metadata';
if exist('hwaitbar','var') && ishandle(hwaitbar),
  waitbar(.3,hwaitbar,s);
else
  hwaitbar = waitbar(.3,s);
end


% create a file if there is an experiment directory
if isfield(handles,'ExperimentDirectory') && exist(handles.ExperimentDirectory,'file') && didabort,
  abortfilename = fullfile(handles.ExperimentDirectory,'ABORTED');
  try
    fid = fopen(abortfilename,'w');
    fprintf(fid,datestr(now,30));
    fclose(fid);
  catch
    addToStatus(handles,'Could not create abort file');
  end
  s = 'Created ABORT file';
  if exist('hwaitbar','var') && ishandle(hwaitbar),
    waitbar(.4,hwaitbar,s);
  else
    hwaitbar = waitbar(.4,s);
  end

end

% stop experiment timer
if isfield(handles,'StopTimer') && isvalid(handles.StopTimer),
  stop(handles.StopTimer);
  delete(handles.StopTimer);
end

s = 'Stopped experiment timer';
if exist('hwaitbar','var') && ishandle(hwaitbar),
  waitbar(.5,hwaitbar,s);
else
  hwaitbar = waitbar(.5,s);
end


% delete vid object
handles = clearVideoInput(handles);
if isfield(handles,'vid') && isvalid(handles.vid),
  delete(handles.vid);
end

s = 'Destroyed vid object';
if exist('hwaitbar','var') && ishandle(hwaitbar),
  waitbar(.6,hwaitbar,s);
else
  hwaitbar = waitbar(.6,s);
end

% delete preview image
if isfield(handles,'hImage_Preview') && ishandle(handles.hImage_Preview),
  delete(handles.hImage_Preview);
end


s = 'Deleted preview image';
if exist('hwaitbar','var') && ishandle(hwaitbar),
  waitbar(.7,hwaitbar,s);
else
  hwaitbar = waitbar(.7,s);
end

% delete temp recorder timer
handles = resetTempProbe(handles);

s = 'Reset temperature probe';
if exist('hwaitbar','var') && ishandle(hwaitbar),
  waitbar(.8,hwaitbar,s);
else
  hwaitbar = waitbar(.8,s);
end

% save config
handles = RecordConfiguration(handles);


s = 'Recorded configuration';
if exist('hwaitbar','var') && ishandle(hwaitbar),
  waitbar(.9,hwaitbar,s);
else
  hwaitbar = waitbar(.9,s);
end

% enable disabled menus
set(handles.menu_File_New,'Enable','on');
set(handles.menu_File_Close,'Enable','on');
set(handles.menu_Quit,'Enable','on');


s = 'Enabled menus';
if exist('hwaitbar','var') && ishandle(hwaitbar),
  waitbar(.95,hwaitbar,s);
else
  hwaitbar = waitbar(.95,s);
end

if exist('hwaitbar','var') && ishandle(hwaitbar),
  delete(hwaitbar);
end

guidata(hObject,handles);

function handles = EnableGUI(handles)

chil = findobj(handles.figure_main,'type','uicontrol');
handles.menus_disable = [handles.menu_Edit,handles.menu_File_SaveMetaData,handles.menu_File_Close];
chil = [chil;handles.menus_disable'];
for i = 1:length(chil),
  if ishandle(chil(i)) && ~strcmpi(get(chil(i),'Enable'),'on') && ...
      (handles.IsAdvancedMode || ~ismember(chil(i),handles.advanced_controls)),
    try
      set(chil(i),'Enable','on');
    catch
    end
  end
end

function handles = DisableGUI(handles)

chil = findobj(handles.figure_main,'type','uicontrol');
handles.menus_disable = [handles.menu_Edit,handles.menu_File_SaveMetaData,handles.menu_File_Close];
chil = [chil;handles.menus_disable'];
for i = 1:length(chil),
  if ishandle(chil(i)),
    try
      set(chil(i),'Enable','off');
    catch
    end
  end
end

handles.GUIIsInitialized = false;


% --- Executes on selection change in popupmenu_TempProbeID.
function popupmenu_TempProbeID_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu_TempProbeID (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu_TempProbeID contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu_TempProbeID
handles.TempProbeID = handles.TempProbeIDs(get(hObject,'Value'));
guidata(hObject,handles);

% --- Executes during object creation, after setting all properties.
function popupmenu_TempProbeID_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu_TempProbeID (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenu_NDeadFlies.
function popupmenu_NDeadFlies_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu_NDeadFlies (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu_NDeadFlies contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu_NDeadFlies
handles.NDeadFlies = get(hObject,'Value')-1;
guidata(hObject,handles);

% --- Executes during object creation, after setting all properties.
function popupmenu_NDeadFlies_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu_NDeadFlies (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton_InitializeTempProbe.
function pushbutton_InitializeTempProbe_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_InitializeTempProbe (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if handles.params.DoRecordTemp == 0,
  return;
end
success = initializeTempProbe(hObject);
if success,
  set(hObject,'Visible','off');
  set(handles.popupmenu_TempProbeID,'Enable','off');
  if handles.FliesLoaded_Time_datenum > 0 && handles.IsCameraInitialized,
    set(handles.pushbutton_StartRecording,'Enable','on','BackgroundColor',handles.StartRecording_bkgdcolor);
  end
else
  uiwait(warndlg('Unable to initialize temperature probe. Perhaps it is open in another program?','Error Initializing Temp Probe'));
end


% % --- Executes on selection change in popupmenu_Assay_Room.
% function popupmenu_Assay_Room_Callback(hObject, eventdata, handles)
% % hObject    handle to popupmenu_Assay_Room (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    structure with handles and user data (see GUIDATA)
% 
% % Hints: contents = cellstr(get(hObject,'String')) returns popupmenu_Assay_Room contents as cell array
% %        contents{get(hObject,'Value')} returns selected item from popupmenu_Assay_Room
% 
% % grab value
% v = get(handles.popupmenu_Assay_Room,'Value');
% handles.Assay_Room = handles.Assay_Rooms{v};
% 
% % no longer default
% handles.isdefault.Assay_Room = false;
% 
% % set color
% set(handles.popupmenu_Assay_Room,'BackgroundColor',handles.changed_bkgdcolor);
% 
% handles = ChangedMetaData(handles);
% 
% guidata(hObject,handles);

% --- Executes during object creation, after setting all properties.
% function popupmenu_Assay_Room_CreateFcn(hObject, eventdata, handles)
% % hObject    handle to popupmenu_Assay_Room (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    empty - handles not created until after all CreateFcns called
% 
% % Hint: popupmenu controls usually have a white background on Windows.
% %       See ISPC and COMPUTER.
% if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
%     set(hObject,'BackgroundColor','white');
% end


% --------------------------------------------------------------------
function menu_Clean_Callback(hObject, eventdata, handles)
% hObject    handle to menu_Clean (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function menu_Clean_Semaphores_Callback(hObject, eventdata, handles)
% hObject    handle to menu_Clean_Semaphores (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

button = questdlg('Are you sure you want to clean semaphores? This may mess up any open GUIs.','Clean Semaphores?','Yes','Cancel','Cancel');
if strcmp(button,'Yes'),
  CleanSemaphores();
end

% --------------------------------------------------------------------
function menu_Clean_Local_Sempahores_Callback(hObject, eventdata, handles)
% hObject    handle to menu_Clean_Local_Sempahores (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

button = questdlg('Are you sure you want to clean local semaphores? This may mess up this GUI.','Clean Local Semaphores?','Yes','Cancel','Cancel');
if strcmp(button,'Yes'),
  CleanLocalSemaphores;
end

% --------------------------------------------------------------------
function menu_FixRCFile_Callback(hObject, eventdata, handles)
% hObject    handle to menu_FixRCFile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

fixRCFile(2);


% --- Executes on selection change in popupmenu_Assay_Lid.
function popupmenu_Assay_Lid_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu_Assay_Lid (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu_Assay_Lid contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu_Assay_Lid

% grab value
v = get(handles.popupmenu_Assay_Lid,'Value');
handles.Assay_Lid = handles.Assay_Lids{v};

% no longer default
handles.isdefault.Assay_Lid = false;

% set color
set(handles.popupmenu_Assay_Lid,'BackgroundColor',handles.changed_bkgdcolor);

handles = ChangedMetaData(handles);

guidata(hObject,handles);

% --- Executes during object creation, after setting all properties.
function popupmenu_Assay_Lid_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu_Assay_Lid (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --------------------------------------------------------------------
function menu_Edit_ChangeLineNameFile_Callback(hObject, eventdata, handles)
% hObject    handle to menu_Edit_ChangeLineNameFile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

[filestr,pathstr] = uigetfile('*.txt','Choose Line Name File');
handles.linename_file = fullfile(pathstr,filestr);

handles = readLineNames(handles,false);

% if current line name not in new list, choose first line name
if ~ismember(handles.Fly_LineName,handles.Fly_LineNames),
  handles.Fly_LineName = handles.Fly_LineNames{1};
end

% set possible values, current value, color to shouldchange
%set(handles.edit_Fly_LineName,'String',handles.Fly_LineNames,...
%  'Value',find(strcmp(handles.Fly_LineName,handles.Fly_LineNames),1),...
%  'BackgroundColor',handles.shouldchange_bkgdcolor);
AutoCompleteEdit(handles.AutoCompleteEdit_Fly_LineName,handles.Fly_LineNames);
set(handles.edit_Fly_LineName,'String',handles.Fly_LineName,...
  'BackgroundColor',handles.shouldchange_bkgdcolor);
guidata(hObject,handles);


% --- Executes on selection change in popupmenu_NDamagedFlies.
function popupmenu_NDamagedFlies_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu_NDamagedFlies (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu_NDamagedFlies contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu_NDamagedFlies
handles.NDamagedFlies = get(hObject,'Value')-1;
guidata(hObject,handles);

% --- Executes during object creation, after setting all properties.
function popupmenu_NDamagedFlies_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu_NDamagedFlies (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenu_PreAssayHandling_CrossHandler.
function popupmenu_PreAssayHandling_CrossHandler_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu_PreAssayHandling_CrossHandler (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu_PreAssayHandling_CrossHandler contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu_PreAssayHandling_CrossHandler

% grab value
v = get(handles.popupmenu_PreAssayHandling_CrossHandler,'Value');
handles.PreAssayHandling_CrossHandler = handles.PreAssayHandling_CrossHandlers{v};

% no longer default
handles.isdefault.PreAssayHandling_CrossHandler = false;

% set color
set(handles.popupmenu_PreAssayHandling_CrossHandler,'BackgroundColor',handles.changed_bkgdcolor);

handles = ChangedMetaData(handles);

guidata(hObject,handles);

% --- Executes during object creation, after setting all properties.
function popupmenu_PreAssayHandling_CrossHandler_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu_PreAssayHandling_CrossHandler (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_Barcode_Callback(hObject, eventdata, handles)
% hObject    handle to edit_Barcode (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_Barcode as text
%        str2double(get(hObject,'String')) returns contents of edit_Barcode as a double

% Get scan string and convert it to a number for querying the database
scanStr = get(handles.edit_Barcode,'String');
scanNum = str2double(scanStr);
handles.barcode = scanNum;

% Check that scanned result is a number
if isnan(scanNum),
  errMsg = sprintf('Scan Error: unable to convert scanned result, %s, to number', scanStr);
  h = errordlg(errMsg);
  uiwait(h);
  return;
end

% if querying disabled
if isfield(handles.params,'DoSyncBarcode') && handles.params.DoSyncBarcode == 0,
  guidata(hObject,handles);
  return;
end
% Query database for barcode
try
  scanValue = FlyFQuery(scanNum);
catch ME
  errMsg = sprintf('Scan Error: %s', ME.message);
  h = errordlg(errMsg);
  uiwait(h);
  return;
end

% save metadata read from barcode
handles.barcodeData = struct('Fly_LineName',scanValue.Line_Name,...
  'CrossDate',datestr(datenum(scanValue.Date_Crossed),handles.dateformat),...
  'WishList',str2double(scanValue.Set_Number));

% line name
handles = setLineName(handles,handles.barcodeData.Fly_LineName);

% cross date
handles = setCrossDate(handles,handles.barcodeData.CrossDate);

% set number
handles = setWishList(handles,handles.barcodeData.WishList);

% Highlight text
set(handles.jhedit_Barcode,'SelectionStart', 0);
set(handles.jhedit_Barcode,'SelectionEnd', length(scanStr)); 

% Update handles structure
guidata(hObject, handles);

function CheckBarcodeConsistency(handles,fields)

% no barcode data yet? then set color to require change
if ~isfield(handles,'barcodeData'),
  set(handles.edit_Barcode,'BackgroundColor',handles.shouldchange_bkgdcolor);
  return;
end

if nargin < 2,
  fields = fieldnames(handles.barcodeData);
end

% set background color that we have changed
set(handles.edit_Barcode,'BackgroundColor',handles.changed_bkgdcolor);

% check line name
if ismember('Fly_LineName',fields) && ...
    ~strcmp(handles.barcodeData.Fly_LineName,handles.Fly_LineName),
  % set background color to indicate an error
  set(handles.edit_Barcode,'BackgroundColor',handles.shouldchange_bkgdcolor);
  set(handles.edit_Fly_LineName,'BackgroundColor',handles.shouldchange_bkgdcolor);
end

% check cross date
if ismember('CrossDate',fields) && ...
    ~strcmp(handles.barcodeData.CrossDate,handles.PreAssayHandling_CrossDate),
  % set background color to indicate an error
  set(handles.edit_Barcode,'BackgroundColor',handles.shouldchange_bkgdcolor);
  set(handles.popupmenu_PreAssayHandling_CrossDate,'BackgroundColor',handles.shouldchange_bkgdcolor);
end

% check set number
if ismember('WishList',fields) && ...
    handles.barcodeData.WishList ~= handles.WishList,
  % set background color to indicate an error
  set(handles.edit_Barcode,'BackgroundColor',handles.shouldchange_bkgdcolor);
  set(handles.popupmenu_WishList,'BackgroundColor',handles.shouldchange_bkgdcolor);
end

% --- Executes during object creation, after setting all properties.
function edit_Barcode_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_Barcode (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton_ScanBarcode.
function pushbutton_ScanBarcode_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_ScanBarcode (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.jhedit_Barcode.requestFocus;
%set(handles.figure_main,'CurrentObject',);
% Highlight text
s = get(handles.edit_Barcode,'String');
set(handles.jhedit_Barcode,'SelectionStart', 0);
set(handles.jhedit_Barcode,'SelectionEnd', length(s)); 


% --------------------------------------------------------------------
function menu_Edit_ScanBarcode_Callback(hObject, eventdata, handles)
% hObject    handle to menu_Edit_ScanBarcode (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% this menu is used just for the shortcut
pushbutton_ScanBarcode_Callback(handles.pushbutton_ScanBarcode, eventdata, handles);

function HighlightEditText(hObject,eventdata)

s = get(hObject,'Text');
set(hObject,'SelectionStart', 0);
set(hObject,'SelectionEnd', length(s)); 

function [handles,success] = setWishList(handles,newwishlist)

success = false;

hObject = handles.popupmenu_WishList;
eventdata = [];

oldv = get(hObject,'Value');
v = find(newwishlist == handles.WishLists,1);
if isempty(v),
  return;
end
try
  set(hObject,'Value',v);
  popupmenu_WishList_Callback(hObject,eventdata,handles);
  handles = guidata(hObject);
  CheckBarcodeConsistency(handles);
catch ME,
  warndlg(getReport(ME),'Error setting wish list','modal');
  set(hObject,'Value',oldv);
  return;
end
success = true;

% --- Executes on selection change in popupmenu_WishList.
function popupmenu_WishList_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu_WishList (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu_WishList contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu_WishList

% grab value
v = get(hObject,'Value');
handles.WishList = handles.WishLists(v);

% no longer default
handles.isdefault.WishList = false;

% set color
set(handles.popupmenu_WishList,'BackgroundColor',handles.changed_bkgdcolor);

handles = ChangedMetaData(handles);

guidata(hObject,handles);

CheckBarcodeConsistency(handles);

% --- Executes during object creation, after setting all properties.
function popupmenu_WishList_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu_WishList (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes during object deletion, before destroying properties.
function pushbutton_Abort_DeleteFcn(hObject, eventdata, handles)
% hObject    handle to pushbutton_Abort (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes during object deletion, before destroying properties.
function pushbutton_Done_DeleteFcn(hObject, eventdata, handles)
% hObject    handle to pushbutton_Done (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function menu_advanced_mode_Callback(hObject, eventdata, handles)
% hObject    handle to menu_advanced_mode (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

v = get(hObject,'Checked');
if strcmp(v,'on'),
  handles.IsAdvancedMode = false;
  set(handles.advanced_controls,'Enable','off');
  set(hObject,'Checked','off');
else
  handles.IsAdvancedMode = true;
  set(handles.advanced_controls,'Enable','on');
  set(hObject,'Checked','on');
end  
guidata(hObject,handles);

% --------------------------------------------------------------------
function menu_HardEnableButtons_Callback(hObject, eventdata, handles)
% hObject    handle to menu_HardEnableButtons (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

h = [handles.pushbutton_ShiftFlyTemp,handles.pushbutton_FliesLoaded,handles.pushbutton_StartRecording];
set(h,'Enable','on');


% --- Executes on selection change in popupmenu_Assay_VisualSurround.
function popupmenu_Assay_VisualSurround_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu_Assay_VisualSurround (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu_Assay_VisualSurround contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu_Assay_VisualSurround

% grab value
v = get(handles.popupmenu_Assay_VisualSurround,'Value');
handles.Assay_VisualSurround = handles.Assay_VisualSurrounds{v};

% no longer default
handles.isdefault.Assay_VisualSurround = false;

% set color
set(handles.popupmenu_Assay_VisualSurround,'BackgroundColor',handles.changed_bkgdcolor);

handles = ChangedMetaData(handles);

guidata(hObject,handles);

% --- Executes during object creation, after setting all properties.
function popupmenu_Assay_VisualSurround_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu_Assay_VisualSurround (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
