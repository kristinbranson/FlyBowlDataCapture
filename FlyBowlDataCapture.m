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

% Last Modified by GUIDE v2.5 15-Aug-2010 15:26:15

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
function FlyBowlDataCapture_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to FlyBowlDataCapture (see VARARGIN)

% Choose default command line output for FlyBowlDataCapture

handles.DEBUG = false;
handles.IsProcessingError = false;
guidata(hObject,handles);

try
  
handles.output = hObject;

% file containing parameters we may want to change some day
handles.params_file = 'FlyBowlDataCaptureParams.txt';
[filestr,pathstr] = uigetfile('*.txt','Choose Parameter File',handles.params_file);
if ~ischar(filestr) || isempty(filestr),
  uiresume(handles.figure_main);
  return;
end
handles.params_file = fullfile(pathstr,filestr);
if ~exist(handles.params_file),
  error('File %s does not exist',handles.params_file);
end

% initialize data
handles = FlyBowlDataCapture_InitializeData(handles);

if isempty(which('findjobj')) && exist('findjobj','dir'),
  addpath('findjobj');
end

% make the line name edit box autocomplete -- must be visible
set(handles.figure_main,'Visible','on');
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

guidata(hObject,handles);

% UIWAIT makes FlyBowlDataCapture wait for user response (see UIRESUME)
uiwait(handles.figure_main);

catch ME,
  
  if handles.DEBUG,
    getReport(ME)
    rethrow ME;
  else
    s = {'Error during data capture:',getReport(ME)};
    if exist('handles','var') && isstruct(handles) && ...
        isfield(handles,'LogFileName') && ischar(handles.LogFileName),
      s{end+1} = ['Log file location: ',handles.LogFileName];
    end
    s{end+1} = 'Please create a Jira ticket with this information.';
    uiwait(msgbox(s,'Error During Data Capture'));
    handles.IsProcessingError = true;
    guidata(hObject,handles);
  end
end

% --- Outputs from this function are returned to the command line.
function varargout = FlyBowlDataCapture_OutputFcn(hObject, eventdata, handles) 
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
function popupmenu_Assay_Experimenter_Callback(hObject, eventdata, handles)
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
function popupmenu_Assay_Experimenter_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu_Assay_Experimenter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in edit_Fly_LineName.
function edit_Fly_LineName_Callback(hObject, eventdata, handles)
% hObject    handle to edit_Fly_LineName (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns edit_Fly_LineName contents as cell array
%        contents{get(hObject,'Value')} returns selected item from edit_Fly_LineName

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
    nmatches = sum(char(handles.Fly_LineNames(i))==newname,2,'double');
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
  
  handles = addToStatus(handles,{sprintf('Invalid line name %s switched back to %s.',...
    newname,handles.Fly_LineName)});
  set(handles.edit_Fly_LineName,'BackgroundColor',handles.shouldchange_bkgdcolor);

end

guidata(hObject,handles);

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


% --- Executes on selection change in popupmenu_Rearing_ActivityPeak.
function popupmenu_Rearing_ActivityPeak_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu_Rearing_ActivityPeak (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu_Rearing_ActivityPeak contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu_Rearing_ActivityPeak

% grab value
v = get(handles.popupmenu_Rearing_ActivityPeak,'Value');
handles.Rearing_ActivityPeak = handles.Rearing_ActivityPeaks{v};

% no longer default
handles.isdefault.Rearing_ActivityPeak = false;

% set color
set(handles.popupmenu_Rearing_ActivityPeak,'BackgroundColor',handles.changed_bkgdcolor);

handles = ChangedMetaData(handles);

guidata(hObject,handles);

% --- Executes during object creation, after setting all properties.
function popupmenu_Rearing_ActivityPeak_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu_Rearing_ActivityPeak (see GCBO)
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


% --- Executes on selection change in popupmenu_PreAssayHandling_DOBStart.
function popupmenu_PreAssayHandling_DOBStart_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu_PreAssayHandling_DOBStart (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu_PreAssayHandling_DOBStart contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu_PreAssayHandling_DOBStart

% grab value
v = get(handles.popupmenu_PreAssayHandling_DOBStart,'Value');
handles.PreAssayHandling_DOBStart = handles.PreAssayHandling_DOBStarts{v};
handles.PreAssayHandling_DOBStart_datenum = datenum(handles.PreAssayHandling_DOBStart);

% no longer default
handles.isdefault.PreAssayHandling_DOBStart = false;

% DOBEnd should be >= DOBStart
if handles.PreAssayHandling_DOBEnd_datenum < handles.PreAssayHandling_DOBStart_datenum,

  if handles.isdefault.PreAssayHandling_DOBEnd,
  % set DOBEnd to be more than DOBStart if we haven't modified DOBEnd yet
    handles.PreAssayHandling_DOBEnd_datenum = handles.PreAssayHandling_DOBStart_datenum;
    handles.PreAssayHandling_DOBEnd = handles.PreAssayHandling_DOBStart;
    set(handles.popupmenu_PreAssayHandling_DOBEnd,'Value',...
      find(strcmp(handles.PreAssayHandling_DOBEnd,handles.PreAssayHandling_DOBEnds),1));
  end

end

% highlight ordering errors
handles = CheckOrderingErrors(handles);
  
handles = ChangedMetaData(handles);

guidata(hObject,handles);

function handles = CheckOrderingErrors(handles)

handles.isOrderingError = false(1,5);

% is CrossDate > DOBStart?
if handles.PreAssayHandling_CrossDate_datenum > handles.PreAssayHandling_DOBStart_datenum,
  handles.isOrderingError(1:2) = true;
end

% is DOBStart > DOBEnd?
if handles.PreAssayHandling_DOBStart_datenum > handles.PreAssayHandling_DOBEnd_datenum,
  handles.isOrderingError(2:3) = true;
end
% is DOBEnd > SortingTime?
if handles.PreAssayHandling_DOBEnd_datenum > handles.PreAssayHandling_SortingTime_datenum,
  handles.isOrderingError(3:4) = true;
end
% is SortingTime > StarvationTime?
if handles.PreAssayHandling_SortingTime_datenum > handles.PreAssayHandling_StarvationTime_datenum,
  handles.isOrderingError(4:5) = true;
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
  set(handles.popupmenu_PreAssayHandling_DOBStart,'BackgroundColor',handles.shouldchange_bkgdcolor);
else  
  % no ordering error, set color to either isdefault or changed color
  if handles.isdefault.PreAssayHandling_DOBStart,
    set(handles.popupmenu_PreAssayHandling_DOBStart,'BackgroundColor',handles.isdefault_bkgdcolor);
  else
    set(handles.popupmenu_PreAssayHandling_DOBStart,'BackgroundColor',handles.changed_bkgdcolor);
  end
end

if handles.isOrderingError(3),
  set(handles.popupmenu_PreAssayHandling_DOBEnd,'BackgroundColor',handles.shouldchange_bkgdcolor);
else
  if handles.isdefault.PreAssayHandling_DOBEnd,
    set(handles.popupmenu_PreAssayHandling_DOBEnd,'BackgroundColor',handles.isdefault_bkgdcolor);
  else
    set(handles.popupmenu_PreAssayHandling_DOBEnd,'BackgroundColor',handles.changed_bkgdcolor);
  end
end

if handles.isOrderingError(4),
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

if handles.isOrderingError(5),
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

% --- Executes during object creation, after setting all properties.
function popupmenu_PreAssayHandling_DOBStart_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu_PreAssayHandling_DOBStart (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenu_PreAssayHandling_DOBEnd.
function popupmenu_PreAssayHandling_DOBEnd_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu_PreAssayHandling_DOBEnd (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu_PreAssayHandling_DOBEnd contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu_PreAssayHandling_DOBEnd

% grab value
v = get(handles.popupmenu_PreAssayHandling_DOBEnd,'Value');
handles.PreAssayHandling_DOBEnd = handles.PreAssayHandling_DOBEnds{v};
handles.PreAssayHandling_DOBEnd_datenum = datenum(handles.PreAssayHandling_DOBEnd);

% no longer default
handles.isdefault.PreAssayHandling_DOBEnd = false;

% DOBEnd should be >= DOBStart
if handles.PreAssayHandling_DOBEnd_datenum < handles.PreAssayHandling_DOBStart_datenum,

  if handles.isdefault.PreAssayHandling_DOBStart,
  % set DOBStart to be DOBEnd if we haven't modified DOBStart yet
    handles.PreAssayHandling_DOBStart_datenum = handles.PreAssayHandling_DOBEnd_datenum;
    handles.PreAssayHandling_DOBStart = handles.PreAssayHandling_DOBEnd;
    set(handles.popupmenu_PreAssayHandling_DOBStart,'Value',...
      find(strcmp(handles.PreAssayHandling_DOBStart,handles.PreAssayHandling_DOBStarts),1));
  end
  
end

% highlight ordering errors
handles = CheckOrderingErrors(handles);

handles = ChangedMetaData(handles);

guidata(hObject,handles);

% --- Executes during object creation, after setting all properties.
function popupmenu_PreAssayHandling_DOBEnd_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu_PreAssayHandling_DOBEnd (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
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
handles.PreAssayHandling_SortingHour_datenum = rem(datenum(s),1);

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
handles = addToStatus(handles,{'Shifted fly temperature.'},handles.ShiftFlyTemp_Time_datenum);

handles = ChangedMetaData(handles);

guidata(hObject,handles);

% --- Executes on button press in pushbutton_FliesLoaded.
function pushbutton_FliesLoaded_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_FliesLoaded (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% store time flies were loaded
handles.FliesLoaded_Time_datenum = now;
% also write to button string
set(hObject,'BackgroundColor',handles.grayed_bkgdcolor,...
  'String',sprintf('Load: %s',datestr(handles.FliesLoaded_Time_datenum,13)));

% enable recording if camera is initialized
if handles.IsCameraInitialized && handles.TempProbe_IsInitialized,
  set(handles.pushbutton_StartRecording,'Enable','on','BackgroundColor',handles.StartRecording_bkgdcolor);
end

% add to status log
handles = addToStatus(handles,{'Flies loaded.'},handles.FliesLoaded_Time_datenum);

handles = ChangedMetaData(handles);

guidata(hObject,handles);

% --- Executes on button press in pushbutton_StartRecording.
function pushbutton_StartRecording_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_StartRecording (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

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

handles = DisableGUI(handles);

% rename video
oldname = handles.FileName;
handles = renameVideoFile(handles);
if ~strcmp(oldname,handles.FileName),
  handles = addToStatus(handles,{sprintf('Renamed %s -> %s.',oldname,handles.FileName)});
end

handles = resetTempProbe(handles);

guidata(hObject,handles);

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

if handles.FliesLoaded_Time_datenum > 0 && handles.TempProbe_IsInitialized,
  set(handles.pushbutton_StartRecording,'Enable','on','BackgroundColor',handles.StartRecording_bkgdcolor);
end

guidata(hObject,handles);


% --- Executes when user attempts to close figure_main.
function figure_main_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure_main (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: delete(hObject) closes the figure
[handles,didcancel] = CloseExperiment(handles);
if didcancel,
  return;
end
guidata(hObject,handles);
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


% --- Executes on selection change in popupmenu_RedoFlag.
function popupmenu_RedoFlag_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu_RedoFlag (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu_RedoFlag contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu_RedoFlag
handles.RedoFlag = handles.RedoFlags{get(hObject,'Value')};

% no longer default
handles.isdefault.RedoFlag = false;

% set color
set(handles.popupmenu_RedoFlag,'BackgroundColor',handles.changed_bkgdcolor);

handles = ChangedMetaData(handles);

guidata(hObject,handles);

% --- Executes during object creation, after setting all properties.
function popupmenu_RedoFlag_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu_RedoFlag (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenu_ReviewFlag.
function popupmenu_ReviewFlag_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu_ReviewFlag (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu_ReviewFlag contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu_ReviewFlag

handles.ReviewFlag = handles.ReviewFlags{get(hObject,'Value')};

% no longer default
handles.isdefault.ReviewFlag = false;

% set color
set(handles.popupmenu_ReviewFlag,'BackgroundColor',handles.changed_bkgdcolor);

handles = ChangedMetaData(handles);

guidata(hObject,handles);

% --- Executes during object creation, after setting all properties.
function popupmenu_ReviewFlag_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu_ReviewFlag (see GCBO)
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

[handles,didcancel] = CloseExperiment(handles);
if didcancel,
  return;
end

guidata(hObject,handles);

uiresume(handles.figure_main);

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
  handles = CloseExperiment(handles);
end

guidata(hObject,handles);

handles = EnableGUI(handles);

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

guidata(hObject,handles);

function [handles,didcancel] = CloseExperiment(handles)

hObject = handles.figure_main;
didcancel = false;

% if not done recording, then make sure user wants to stop prematurely
if ~handles.FinishedRecording && handles.GUIIsInitialized,
  v = questdlg('Do you really want to close the current experiment?','Really close?','Close','Cancel','Cancel');
  if strcmp(v,'Cancel'),
    didcancel = true;
    return;
  end
  handles = addToStatus(handles,{'Capture aborted.'});
end

% recording stopped in the middle
if handles.IsRecording,
  handles = addToStatus(handles,sprintf('Video recording canceled after %f seconds',(now-handles.StartRecording_Time_datenum)*86400));
end

% stop logging
if handles.IsRecording && isfield(handles,'vid') && isvalid(handles.vid),
  guidata(hObject,handles);
  stop(handles.vid);
  handles = guidata(hObject);
end

% save metadata
if handles.MetaDataNeedsSave,
  answer = questdlg('Save MetaData before closing?','Save MetaData?','Yes','No','Yes');
  if strcmpi(answer,'Yes'),
    handles = SaveMetaData(handles);
  end
end
handles.MetaDataNeedsSave = false;

% stop experiment timer
if isfield(handles,'StopTimer') && isvalid(handles.StopTimer),
  stop(handles.StopTimer);
  delete(handles.StopTimer);
end

% delete vid object
if isfield(handles,'vid') && isvalid(handles.vid),
  delete(handles.vid);
end

% delete preview image
if isfield(handles,'hImage_Preview') && ishandle(handles.hImage_Preview),
  delete(handles.hImage_Preview);
end

% delete temp recorder timer
handles = resetTempProbe(handles);

% save figure
handles = RecordConfiguration(handles);

function handles = EnableGUI(handles)

chil = findobj(handles.figure_main,'type','uicontrol');
handles.menus_disable = [handles.menu_Edit,handles.menu_File_SaveMetaData,handles.menu_File_Close];
chil = [chil;handles.menus_disable'];
for i = 1:length(chil),
  if ishandle(chil(i)),
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
