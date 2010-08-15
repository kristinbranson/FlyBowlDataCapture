function varargout = MasterTempRecordGUI(varargin)
% MASTERTEMPRECORDGUI M-file for MasterTempRecordGUI.fig
%      MASTERTEMPRECORDGUI, by itself, creates a new MASTERTEMPRECORDGUI or raises the existing
%      singleton*.
%
%      H = MASTERTEMPRECORDGUI returns the handle to a new MASTERTEMPRECORDGUI or the handle to
%      the existing singleton*.
%
%      MASTERTEMPRECORDGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in MASTERTEMPRECORDGUI.M with the given input arguments.
%
%      MASTERTEMPRECORDGUI('Property','Value',...) creates a new MASTERTEMPRECORDGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before MasterTempRecordGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to MasterTempRecordGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help MasterTempRecordGUI

% Last Modified by GUIDE v2.5 15-Aug-2010 15:04:48

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @MasterTempRecordGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @MasterTempRecordGUI_OutputFcn, ...
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


% --- Executes just before MasterTempRecordGUI is made visible.
function MasterTempRecordGUI_OpeningFcn(hObject, eventdata, handles, varargin) %#ok<*INUSL>
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to MasterTempRecordGUI (see VARARGIN)

% Choose default command line output for MasterTempRecordGUI
handles.output = hObject;
handles.info = varargin{1};

% Set update period
set(handles.edit_Period,'String',num2str(handles.info.Period));

% Set channels
set(handles.listbox_Channels,...
  'String',cellstr(num2str(handles.info.Channels(:))),...
  'Value',1);
% Channel types
set(handles.listbox_ChannelTypes,...
  'String',handles.info.ChannelTypes,...
  'Value',1);
% Channel file names
set(handles.listbox_ChannelFileNames,...
  'String',handles.info.ChannelFileNames,...
  'Value',1);

% Directory
set(handles.edit_TempRecordDir,'String',handles.info.TempRecordDir);

% IsMaster File
set(handles.edit_IsMasterFile,'String',handles.info.IsMasterFile);

% make listboxes match
handles.Channel_listboxes = [handles.listbox_Channels,handles.listbox_ChannelTypes,handles.listbox_ChannelFileNames];

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes MasterTempRecordGUI wait for user response (see UIRESUME)
% uiwait(handles.figure_main);


% --- Outputs from this function are returned to the command line.
function varargout = MasterTempRecordGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;



function edit_TempRecordDir_Callback(hObject, eventdata, handles) %#ok<*INUSD,*DEFNU>
% hObject    handle to edit_TempRecordDir (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_TempRecordDir as text
%        str2double(get(hObject,'String')) returns contents of edit_TempRecordDir as a double


% --- Executes during object creation, after setting all properties.
function edit_TempRecordDir_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_TempRecordDir (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_IsMasterFile_Callback(hObject, eventdata, handles)
% hObject    handle to edit_IsMasterFile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_IsMasterFile as text
%        str2double(get(hObject,'String')) returns contents of edit_IsMasterFile as a double


% --- Executes during object creation, after setting all properties.
function edit_IsMasterFile_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_IsMasterFile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in listbox_ChannelFileNames.
function listbox_ChannelFileNames_Callback(hObject, eventdata, handles)
% hObject    handle to listbox_ChannelFileNames (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns listbox_ChannelFileNames contents as cell array
%        contents{get(hObject,'Value')} returns selected item from listbox_ChannelFileNames
v = get(hObject,'Value');
set(setdiff(handles.Channel_listboxes,hObject),'Value',v);

% --- Executes during object creation, after setting all properties.
function listbox_ChannelFileNames_CreateFcn(hObject, eventdata, handles)
% hObject    handle to listbox_ChannelFileNames (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_Period_Callback(hObject, eventdata, handles)
% hObject    handle to edit_Period (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_Period as text
%        str2double(get(hObject,'String')) returns contents of edit_Period as a double


% --- Executes during object creation, after setting all properties.
function edit_Period_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_Period (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in listbox_Channels.
function listbox_Channels_Callback(hObject, eventdata, handles)
% hObject    handle to listbox_Channels (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns listbox_Channels contents as cell array
%        contents{get(hObject,'Value')} returns selected item from listbox_Channels
v = get(hObject,'Value');
set(setdiff(handles.Channel_listboxes,hObject),'Value',v);

% --- Executes during object creation, after setting all properties.
function listbox_Channels_CreateFcn(hObject, eventdata, handles)
% hObject    handle to listbox_Channels (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in listbox_ChannelTypes.
function listbox_ChannelTypes_Callback(hObject, eventdata, handles)
% hObject    handle to listbox_ChannelTypes (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns listbox_ChannelTypes contents as cell array
%        contents{get(hObject,'Value')} returns selected item from listbox_ChannelTypes
v = get(hObject,'Value');
set(setdiff(handles.Channel_listboxes,hObject),'Value',v);

% --- Executes during object creation, after setting all properties.
function listbox_ChannelTypes_CreateFcn(hObject, eventdata, handles)
% hObject    handle to listbox_ChannelTypes (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton_Stop.
function pushbutton_Stop_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_Stop (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

button = questdlg(['Really stop the Master Temperature Recorder? ',...
  'All running instances of FlyBowlDataCapture may be relying on ',...
  'this recording. Are you sure you want to stop?'],...
  'Really stop???','Yes','No','No');
if strcmp(button,'Yes'),
  fprintf('Stopping Temperature Recording\n');
  try
    stop(handles.info.MasterTempRecord_timer);
  catch ME,
    fprintf('Error stopping temperature recorder.\n');
    getReport(ME)
  end
  if ishandle(handles.figure_main),
    delete(handles.figure_main);
  end
end

% --- Executes when user attempts to close figure_main.
function figure_main_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure_main (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: delete(hObject) closes the figure
