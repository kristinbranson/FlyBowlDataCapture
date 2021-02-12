function varargout = FBDC_advanced(varargin)
% FBDC_ADVANCED MATLAB code for FBDC_advanced.fig
%      FBDC_ADVANCED, by itself, creates a new FBDC_ADVANCED or raises the existing
%      singleton*.
%
%      H = FBDC_ADVANCED returns the handle to a new FBDC_ADVANCED or the handle to
%      the existing singleton*.
%
%      FBDC_ADVANCED('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in FBDC_ADVANCED.M with the given input arguments.
%
%      FBDC_ADVANCED('Property','Value',...) creates a new FBDC_ADVANCED or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before FBDC_advanced_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to FBDC_advanced_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help FBDC_advanced

% Last Modified by GUIDE v2.5 12-Feb-2021 13:41:58

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @FBDC_advanced_OpeningFcn, ...
                   'gui_OutputFcn',  @FBDC_advanced_OutputFcn, ...
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


% --- Executes just before FBDC_advanced is made visible.
function FBDC_advanced_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to FBDC_advanced (see VARARGIN)

handles.mainfig = varargin{1};

main = guidata(handles.mainfig);

% set possible values, current value, color to default
set(handles.popupmenu_Assay_Rig,'String',main.Assay_Rigs,...
  'Value',find(strcmp(main.Assay_Rig,main.Assay_Rigs),1),...
  'BackgroundColor',main.isdefault_bkgdcolor);

if ~main.isdefault.Assay_Rig,
  set(handles.popupmenu_Assay_Rig,'BackgroundColor',main.changed_bkgdcolor);
end

% set possible values, current value, color to default
set(handles.popupmenu_Assay_Lid,'String',main.Assay_Lids,...
  'Value',find(strcmp(main.Assay_Lid,main.Assay_Lids),1),...
  'BackgroundColor',main.isdefault_bkgdcolor);
if ~main.isdefault.Assay_Lid,
  set(handles.popupmenu_Assay_Lid,'BackgroundColor',main.changed_bkgdcolor);
end

% set possible values, current value, color to default
set(handles.popupmenu_Assay_VisualSurround,'String',main.Assay_VisualSurrounds,...
  'Value',find(strcmp(main.Assay_VisualSurround,main.Assay_VisualSurrounds),1),...
  'BackgroundColor',main.isdefault_bkgdcolor);
if ~main.isdefault.Assay_VisualSurround,
  set(handles.popupmenu_Assay_VisualSurround,'BackgroundColor',main.changed_bkgdcolor);
end

% set possible values, current value, color to default
set(handles.popupmenu_Assay_Bowl,'String',main.Assay_Bowls,...
  'Value',find(strcmp(main.Assay_Bowl,main.Assay_Bowls),1),...
  'BackgroundColor',main.isdefault_bkgdcolor);
if ~main.isdefault.Assay_Bowl,
  set(handles.popupmenu_Assay_Bowl,'BackgroundColor',main.changed_bkgdcolor);
end

set(handles.popupmenu_TempProbeID,'String',cellstr(num2str(main.TempProbeIDs(:))),...
  'value',find(main.TempProbeID==main.TempProbeIDs,1));
if main.params.DoRecordTemp == 0,
  set(handles.popupmenu_TempProbeID,'Enable','off');
end

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes FBDC_advanced wait for user response (see UIRESUME)
uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = FBDC_advanced_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure

% --- Executes on button press in pushbutton_Done.
function pushbutton_Done_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_Done (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
delete(handles.figure1);

% --- Executes on selection change in popupmenu_Assay_Bowl.
function popupmenu_Assay_Bowl_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu_Assay_Bowl (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu_Assay_Bowl contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu_Assay_Bowl


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


% --- Executes on selection change in popupmenu_Assay_VisualSurround.
function popupmenu_Assay_VisualSurround_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu_Assay_VisualSurround (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu_Assay_VisualSurround contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu_Assay_VisualSurround


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


% --- Executes on selection change in popupmenu_Assay_Rig.
function popupmenu_Assay_Rig_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu_Assay_Rig (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu_Assay_Rig contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu_Assay_Rig

main = guidata(handles.mainfig);

% grab value
v = get(handles.popupmenu_Assay_Rig,'Value');
main.Assay_Rig = main.Assay_Rigs{v};

% no longer default
main.isdefault.Assay_Rig = false;

% set color
set(handles.popupmenu_Assay_Rig,'BackgroundColor',main.changed_bkgdcolor);

main = FlyBowlDataCapture('ChangedMetaData',main);

% rotate preview image if nec
FlyBowlDataCapture('RotatePreviewImage',main);

guidata(handles.mainfig,main);

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

% --- Executes on selection change in popupmenu_Assay_Lid.
function popupmenu_Assay_Lid_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu_Assay_Lid (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu_Assay_Lid contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu_Assay_Lid

main = guidata(handles.mainfig);

% grab value
v = get(handles.popupmenu_Assay_Lid,'Value');
main.Assay_Lid = main.Assay_Lids{v};

% no longer default
main.isdefault.Assay_Lid = false;

% set color
set(handles.popupmenu_Assay_Lid,'BackgroundColor',main.changed_bkgdcolor);

main = FlyBowlDataCapture('ChangedMetaData',main);
guidata(handles.mainfig,main);

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


% --- Executes on selection change in popupmenu_TempProbeID.
function popupmenu_TempProbeID_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu_TempProbeID (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu_TempProbeID contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu_TempProbeID
main = guidata(handles.mainfig);
main.TempProbeID = main.TempProbeIDs(get(hObject,'Value'));
guidata(handles.mainfig,main);

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
