function varargout = basicMetaDataDlg(varargin)
% BASICMETADATADLG M-file for basicMetaDataDlg.fig
%      BASICMETADATADLG, by itself, creates a new BASICMETADATADLG or raises the existing
%      singleton*.
%
%      H = BASICMETADATADLG returns the handle to a new BASICMETADATADLG or the handle to
%      the existing singleton*.
%
%      BASICMETADATADLG('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in BASICMETADATADLG.M with the given input arguments.
%
%      BASICMETADATADLG('Property','Value',...) creates a new BASICMETADATADLG or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before basicMetaDataDlg_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to basicMetaDataDlg_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help basicMetaDataDlg

% Last Modified by GUIDE v2.5 03-Oct-2010 17:00:29

% Begin initialization code - DO NOT EDIT
gui_Singleton = 0;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @basicMetaDataDlg_OpeningFcn, ...
                   'gui_OutputFcn',  @basicMetaDataDlg_OutputFcn, ...
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


% --- Executes just before basicMetaDataDlg is made visible.
function basicMetaDataDlg_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to basicMetaDataDlg (see VARARGIN)

% Choose default command line output for basicMetaDataDlg
handles.output = hObject;

if isempty(varargin)
    error('basicMetaDataDlg requires at least one input argument, defaultsTree');
end

% Set optional argument mode if it is not given.
if length(varargin) < 2
    mode = 'basic';
else
    mode = varargin{2};
end
defaultsTree = varargin{1};

% added by KB: store the mode in handles
handles.mode = mode;

% Create JIDE property grid and add it to figure. 
% Note, the 'HandleVisilbility' of the figure must be set to 'on' for this 
% to work properly. For this example I set it to 'on' in guide.
handles.pgrid = PropertyGrid(handles.dialogFigure,'Position', [0 0.1 1 0.9]);
handles.pgrid.setDefaultsTree(defaultsTree,mode);
handles.defaultsTree = defaultsTree;
% modified by KB: store pgrid in handles

% Setup temperature and humidity event listener
handles.THListener = THListener(hObject,handles);

% added by KB:
% keep y-positions of the bottom line of the GUI constant through resizing
% positions of the buttons at the bottom for resizing
% set(handles.dialogFigure,'Units','pixels');
% handles.figPos = get(handles.dialogFigure,'Position');
% handles.fnsResize = {'temperatureText','humidityText','pushbutton_Propagate'};
% for i = 1:length(handles.fnsResize),
%   fn = handles.fnsResize{i};
%   set(handles.(fn),'Units','Pixels');
%   pos = get(handles.(fn),'Position');
%   handles.posResize.(fn) = [pos(1)/handles.figPos(3),pos(2),pos(3)/handles.figPos(3),pos(4)];
% end

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes basicMetaDataDlg wait for user response (see UIRESUME)
%uiwait(handles.dialogFigure);


% --- Outputs from this function are returned to the command line.
function varargout = basicMetaDataDlg_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes when user attempts to close dialogFigure.
function dialogFigure_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to dialogFigure (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Check to see if tree has all required manual entry values
exitFlag = true;
if handles.defaultsTree.hasValuesNeeded('manual') == false
    % Create message showing values still required.
    msg = sprintf('Values required:\n\n');
    valuesNeeded = handles.defaultsTree.getValuesNeeded('manual');
    for i = 1:length(valuesNeeded)
        displayString = cleanPathString(valuesNeeded{i});
        msg = sprintf('%s%s\n',msg, displayString);
    end
    % Create dialog displaying values still required and asking if use want
    % to quit
    msg = sprintf('Not all required values have been entered\n\n%s',msg);
    msg = sprintf('%s\nDo you really want to quit?',msg);
    answer = questdlg(msg,'Exit', 'yes', 'no', 'no');
    switch lower(answer)
        case 'yes'
            exitFlag = true;
        otherwise
            exitFlag = false;
    end
end

% Set temperature and humidity values in xml defaults Tree
try
  % modified by KB: add check for H and T fields
  if isfield(handles,'H'),
    setHumidityValue(handles.defaultsTree,handles.H);
  end
  if isfield(handles,'T'),
    setTemperatureValue(handles.defaultsTree,handles.T);
  end
catch ME
    errmsg = sprintf('unable to set value: %s', ME.message);
    errordlg(errmsg, 'Missing attribute');
end

% Hint: delete(hObject) closes the figure
if exitFlag == true
    delete(hObject);
end

function outPathString = cleanPathString(inPathString)
% Cleans up path strings for displaying them in dialogs. Basically just
% remove the .content part of the path string if it refers to a content
% node.
if length(inPathString) > length('content')
    endString = inPathString(end-length('content')+1:end);
    if strcmpi(endString,'content')
        outPathString = inPathString(1:end-length('content')-1);
    else
        outPathString = inPathString;
    end
else
    outPathString = inPathString;
end

function setNodeValueByName(defaultsTree,name,value)
% Sets the value of the first occurrence of a node with name=name in defaults 
% tree handles.defaultsTree,  given value.
pathString = getPathStringByNodeName(defaultsTree,name);
try
    defaultsTree.setValueByPathString(pathString,num2str(value));
catch ME
    errmsg = sprintf('error setting value of node %s: %s',pathString,ME.message);
    errordlg(errmsg,'Set value error');
end

function setTemperatureValue(defaultsTree, value)
% Sets the value of the first occurance of a node with name='temperature'
% in the defaults tree to the given value.
setNodeValueByName(defaultsTree,'temperature',value);

function setHumidityValue(defaultsTree, value)
% Sets the value of the first occurance of a node with name='humidity' in the
% defaults tree to the given value
setNodeValueByName(defaultsTree, 'humidity', value);

function pathString = getPathStringByNodeName(defaultsTree,name)
% Returns the path string, of unique names from the root node, to first leaf
% node with name=name in the given defaults tree.
rootNode = defaultsTree.root;
leaves = rootNode.getLeaves();
test = false;
for i = 1:length(leaves)
   leaf = leaves(i);
   if strcmpi(leaf.name,name)
       test = true;
       break;
   end
end
if test == false
    error('missing attribute, %s, unable to find node', name);
end
pathString = leaf.getPathString();

% % --- Executes when dialogFigure is resized.
% function dialogFigure_ResizeFcn(hObject, eventdata, handles)
% % hObject    handle to dialogFigure (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    structure with handles and user data (see GUIDATA)
% 
% if ~isfield(handles,'dialogFigure') || ~isfield(handles,'fnsResize') || ...
%     ~isfield(handles,'posResize'),
%   return;
% end
% newFigPos = get(handles.dialogFigure,'Position');
% for i = 1:length(handles.fnsResize),
%   fn = handles.fnsResize{i};
%   if ~isfield(handles,fn) || ~isfield(handles.posResize,fn),
%     continue;
%   end
%   pos = handles.posResize.(fn);
%   newpos = [pos(1)*newFigPos(3),pos(2),pos(3)*newFigPos(3),pos(4)];
%   set(handles.(fn),'Position',newpos);
% end

% recursiveCopy(n1,n2,mode,pgrid)
%
% Copy values from defaultsTree node n1 to n2 recursively. 
% Only viewable and writable properties are copied. 
% Properties are copied in such a way that the property grid will reflect
% these changes. 
%
% added by KB
function recursiveCopy(n1,n2,mode,pgrid)
  
if strcmp(n1.getPathString(),n2.getPathString())
  return;
end
if n1.isLeaf() && strcmpi(n1.getAppearString(mode),'true'),
  n2.value = n1.value;
  pgrid.setValueByPathString(n2.getPathString(),n1.value);
elseif n1.isContentNode(),
  childNode1 = n1.children(1);
  childNode2 = n2.children(1);
  % Assign value and pass through validator
  childNode2.value = childNode1.value;
  pgrid.setValueByPathString(n2.getPathString(),childNode1.value);
else
  chil1 = n1.children();
  chil2 = n2.children();
  for i = 1:length(chil1),
    recursiveCopy(chil1(i),chil2(i),mode,pgrid);
  end
end

% --- Executes on button press in pushbutton_Propagate.
%
% Copies values from the selected session or session field to all following
% sessions recursively. 
%
% added by KB
function pushbutton_Propagate_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_Propagate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

sessions = handles.defaultsTree.getChildrenByName('session');
if isempty(sessions), return; end

% get selected property
selected = handles.pgrid.getSelectedProperty();
if isempty(selected)
  warndlg('To propagate, select a session or a field of a session. That session or field will then be copied to all following sessions.','Propagate: Nothing selected');
  return;
end

% find session within selected property
[tokens,starts,ends] = regexp(selected,'session_(?<sessioni>[0-9]+)','tokens','start','end');
sessioni = [];
prefix = '';
suffix = '';
for i = 1:length(starts),
  if ~(starts(i) == 1 || selected(starts(i)-1) == '.'),
    continue;
  end
  if ~(ends(i) == length(selected) || selected(ends(i)+1) == '.'),
    continue;
  end
  sessioni = str2double(tokens{i});
  prefix = selected(1:starts(i)-1);
  suffix = selected(ends(i)+1:end);
  break;
end

if isempty(sessioni),
  warndlg('To propagate, select a session or a field of a session. That session or field will then be copied to all following sessions.','Propagate: session or session field not selected');
  return;
end

pathString1 = sprintf('%ssession_%d%s',prefix,sessioni,suffix);
n1 = handles.defaultsTree.getNodeByPathString(pathString1);

for i = sessioni+1:length(sessions),
  pathString2 = sprintf('%ssession_%d%s',prefix,i,suffix);
  n2 = handles.defaultsTree.getNodeByPathString(pathString2);
  recursiveCopy(n1,n2,handles.mode,handles.pgrid);
end

set(handles.pushbutton_Save,'Enable','on');

% pushbutton_Save_Callback(hObject, eventdata, handles)
%
% handle save callbacks. 
% asks user for filename if filename has not yet been set. 
% otherwise saves to previously selected filename. 
%
% added by KB
%
% --- Executes on button press in pushbutton_Save.
function pushbutton_Save_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_Save (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% make sure that if saveMetaDataFileName is set, that the directory exists
if isfield(handles,'saveMetaDataFileName'),
  pathstr = fileparts(handles.saveMetaDataFileName);
  if ~isempty(pathstr) && ~exist(pathstr,'file'),
    warning('Save directory %s does not exist',pathstr); %#ok<WNTAG>
    handles.saveMetaDataFileName = '';
  end
end

% if saveMetaDataFileName not set, then choose
if ~isfield(handles,'saveMetaDataFileName') || isempty(handles.saveMetaDataFileName),
  saveDialogName = 'Save metadata to XML file';
  [fileName, pathName, ~] =  uiputfile('metadata_test_write.xml', saveDialogName);
  if fileName == 0,
    return;
  end
  handles.saveMetaDataFileName = fullfile(pathName,fileName);
  handles.pgrid.setPropertyChangeCallback(@(varargin) set(handles.pushbutton_Save,'Enable','on'));
end

guidata(hObject,handles);

% save
metaDataTree = createXMLMetaData(handles.defaultsTree);
metaDataTree.write(handles.saveMetaDataFileName);
set(handles.pushbutton_Save,'Enable','off');
