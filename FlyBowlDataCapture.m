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

% Last Modified by GUIDE v2.5 04-Aug-2010 06:04:01

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
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% initialize data
handles = FlyBowlDataCapture_InitializeData(handles);

guidata(hObject,handles);

set(handles.figure_main,'Visible','on');
if ~handles.isAutoComplete_edit_Fly_LineName,
  handles.AutoCompleteEdit_Fly_LineName = ...
    AutoCompleteEdit(handles.edit_Fly_LineName,handles.Fly_LineNames,...
    'Callback',get(handles.edit_Fly_LineName,'Callback'));
  set(handles.edit_Fly_LineName,'Callback','');
  handles.isAutoComplete_edit_Fly_LineName = true;
end

% UIWAIT makes FlyBowlDataCapture wait for user response (see UIRESUME)
uiwait(handles.figure_main);


% --- Outputs from this function are returned to the command line.
function varargout = FlyBowlDataCapture_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% save metadata
if handles.FinishedRecording,
  handles = SaveMetaData(handles);
end

% Get default command line output from handles structure
varargout{1} = handles.output;
if isfield(handles,'StopTimer') && isvalid(handles.StopTimer),
  stop(handles.StopTimer);
  delete(handles.StopTimer);
end
if isfield(handles,'vid') && isvalid(handles.vid),
  delete(handles.vid);
end
if isfield(handles,'hImage_Preview') && ishandle(handles.hImage_Preview),
  delete(handles.hImage_Preview);
end

% save figure
handles = RecordConfiguration(handles);
guidata(hObject,handles);

delete(handles.figure_main);

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
newname = get(handles.edit_Fly_LineName,'String');
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
  
else
  
  handles = addToStatus(handles,{sprintf('%s: Invalid line name %s switched back to %s.',...
    datestr(now,handles.secondformat))},...
    newname,handles.Fly_LineName);
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
handles = addToStatus(handles,{sprintf('%s: Shifted fly temperature.',datestr(handles.ShiftFlyTemp_Time_datenum,handles.secondformat))});

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
if handles.IsCameraInitialized,
  set(handles.pushbutton_StartRecording,'Enable','on','BackgroundColor',handles.StartRecording_bkgdcolor);
end

% add to status log
handles = addToStatus(handles,{sprintf('%s: Flies loaded.',datestr(handles.FliesLoaded_Time_datenum,handles.secondformat))});

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
set(handles.menu_DetectCameras,'Enable','off');

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

v = questdlg('Do you really want to quit? All data entered will be lost.','Really quit?','Quit','Cancel','Cancel');
if strcmp(v,'Cancel'),
  return;
end

if isfield(handles,'vid') && isvalid(handles.vid),
  stop(handles.vid);
end
handles = guidata(hObject);
if isfield(handles,'FileName') && exist(handles.FileName,'file'),

  % move video to aborted temporary directory
  handles = guidata(hObject);
  oldfilename = handles.FileName;
  [~,filestr,ext] = fileparts(handles.FileName);
  newfilename = fullfile(handles.params.TmpOutputDirectory,[filestr,ext]);
  if ~strcmp(newfilename,oldfilename),
    [success,msg] = movefile(oldfilename,newfilename);
    if ~success,
      s = sprintf('Could not move file %s to temporary storage %s: %s',oldfilename,newfilename,msg);
      errordlg(s,'Error removing file.');
    end
  end
end

uiresume(handles.figure_main);

function edit_TechnicalNotes_Callback(hObject, eventdata, handles)
% hObject    handle to edit_TechnicalNotes (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_TechnicalNotes as text
%        str2double(get(hObject,'String')) returns contents of edit_TechnicalNotes as a double

handles.TechnicalNotes = get(hObject,'String');
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

% rename video
oldname = handles.FileName;
handles = renameVideoFile(handles);
if ~strcmp(oldname,handles.FileName),
  handles = addToStatus(handles,{sprintf('%s: Renamed %s -> %s.',datestr(now,handles.secondformat),oldname,handles.FileName)});
end

guidata(hObject,handles);

uiresume(handles.figure_main);

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
function menu_File_RefreshLineNames_Callback(hObject, eventdata, handles)
% hObject    handle to menu_File_RefreshLineNames (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function menu_File_SaveSettings_Callback(hObject, eventdata, handles)
% hObject    handle to menu_File_SaveSettings (see GCBO)
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
  
guidata(hObject,handles);


% --- Executes on button press in pushbutton_InitializeCamera.
function pushbutton_InitializeCamera_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_InitializeCamera (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles = setCamera(handles);
set(hObject,'Visible','off');

if handles.FliesLoaded_Time_datenum > 0,
  set(handles.pushbutton_StartRecording,'Enable','on','BackgroundColor',handles.StartRecording_bkgdcolor);
end

guidata(hObject,handles);


% --- Executes when user attempts to close figure_main.
function figure_main_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure_main (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: delete(hObject) closes the figure
if handles.IsRecording,
  pushbutton_Abort_Callback(handles.pushbutton_Abort, eventdata, handles);
else
  uiresume(handles.figure_main);
end


% --------------------------------------------------------------------
function menu_DetectCameras_Callback(hObject, eventdata, handles)
% hObject    handle to menu_DetectCameras (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if isfield(handles,'hImage_Preview') && ishandle(handles.hImage_Preview),
  delete(handles.hImage_Preview);
end
set(handles.pushbutton_InitializeCamera,'Visible','on');
handles = detectCamerasWrapper(handles);
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

if handles.IsRecording,
  pushbutton_Abort_Callback(handles.pushbutton_Abort, eventdata, handles);
else
  uiresume(handles.figure_main);
end
