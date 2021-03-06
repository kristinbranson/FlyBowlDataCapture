% hauto = AutoCompleteEdit(hObject,choices,...)
% 
% Modifies input edit box hObject to be an auto-complete edit box with
% valid input choices. Only valid input choices are accepted for the edit
% box string. Strings not in the choices list will be reset. The possible
% autofills are chosen based on the part of the string in the edit box
% before the cursor. 
%
% Inputs:
% hObject: Handle to edit box.
% choices: Cell of strings representing valid choices for the edit box. 
%
% Optional inputs:
% 'maxheight': Maximum height of the popped up listbox, as a multiple of
% the height of the edit box. 
% 'Callback': Function that executes whenever the string for the edit box
% is finally set. 
% 
% Output:
% hauto: Struct with handles to various useful things.
%
% Other use:
% warnings = AutoCompleteEdit(hauto,choices)
% Resets the valid choices for an AutoCompleteEdit box to input choices.
% hauto should be the output from the original AutoCompleteEdit call.
% warnings is a string containing any warning messages generated. 
%
function hauto = AutoCompleteEdit(hObject,choices,varargin)

if isstruct(hObject),
  % note that this inputs hauto and returns warning string
  hauto = ResetChoices(hObject,choices);
  return;
end

hauto = struct;

[hauto.maxheight,hauto.Callback] =...
  myparse(varargin,'maxheight',5,...
  'Callback','');
hauto.maxheight = min(hauto.maxheight,length(choices));
hauto.DEBUG = false;

hauto.Parent = hObject;
hauto.hjava = findjobj(hObject);

% position of listbox: directly below, of the same size, but with height
% maxheight times the edit box height
editpos = get(hObject,'Position');
w = editpos(3);
hauto.y0 = editpos(2);
hauto.height0 = editpos(4);
h = hauto.height0*hauto.maxheight;
hauto.listboxpos = [editpos(1),hauto.y0-h,w,h];

hauto.listbox = uicontrol('Style','listbox','String',choices,'Visible','on',...
  'Position',hauto.listboxpos,'FontName',get(hObject,'FontName'),...
  'FontUnits',get(hObject,'FontUnits'),...
  'FontSize',get(hObject,'FontSize'));
setappdata(hauto.listbox,'AllChoices',choices);
hauto.hjava_listbox = findjobj(hauto.listbox);
set(hauto.listbox,'Visible','off');

set(hauto.hjava,'FocusGainedCallback',@(h,event) FocusGainedAutoCompleteEdit(h,event,hauto));
set(hauto.hjava,'KeyPressedCallback',@(h,event) KeyPressedAutoCompleteEdit(h,event,hauto));
set(hauto.hjava,'FocusLostCallback',@(h,event) FocusLostAutoCompleteEdit(h,event,hauto));
set(hauto.hjava,'MousePressedCallback',@(h,event) MousePressedAutoCompleteEdit(h,event,hauto));
set(hauto.listbox,'Callback',@(h,event) ListBoxCallback(h,event,hauto));
set(hauto.hjava_listbox,'FocusLostCallback',@(h,event) FocusLostListbox(h,event,hauto));

function warnings = ResetChoices(hauto,choices)

if hauto.DEBUG,
  fprintf('Reset choices called.\n');
end
warnings = '';
oldvisible = get(hauto.listbox,'Visible');

% Get old choice
oldstring = get(hauto.Parent,'String');

% Make sure old choice is a member of new choices
newvalue = find(strcmpi(oldstring,choices),1);
if isempty(newvalue),
  warnings = 'Original value no longer valid choice.';
  newvalue = 1;
end
newstring = choices{newvalue};
set(hauto.Parent,'String',newstring);

% update listbox
set(hauto.listbox,'String',choices,'Value',newvalue);
setappdata(hauto.listbox,'AllChoices',choices);
drawnow;
matchStringChoices(hauto);
set(hauto.listbox,'Visible',oldvisible);

function MousePressedAutoCompleteEdit(hObject,event,hauto) %#ok<*INUSL>

if hauto.DEBUG,
  fprintf('MousePressedAutoCompleteEdit called,\nevent = ');
  disp(event); fprintf('\n');
end

matchStringChoices(hauto);
set(hauto.listbox,'Visible','on');

function FocusGainedAutoCompleteEdit(hObject,event,hauto)

if hauto.DEBUG,
  fprintf('FocusGainedAutoCompleteEdit called,\nevent = ');
  disp(event); fprintf('\n');
end

%matchStringChoices(hauto);
set(hauto.listbox,'Visible','on');

function FocusLostListbox(hObject,event,hauto) 

if hauto.DEBUG,
  fprintf('FocusLostListbox called,\nevent = ');
  disp(event); fprintf('\n');
end

set(hObject,'Visible','off');

function FocusLostAutoCompleteEdit(hObject,event,hauto)

if hauto.DEBUG,
  fprintf('FocusLostAutoCompleteEdit called,\nevent = ');
  disp(event); fprintf('\n');
end

if ~ishandle(hauto.listbox),
  return;
end

if strcmpi(get(hauto.listbox,'Visible'),'on'),
  CurrentObject = get(get(hauto.Parent,'parent'),'CurrentObject');
  if ismember(CurrentObject,[hauto.listbox,hauto.Parent])
    return;
  else
    if hauto.DEBUG,
      fprintf('CurrentObject = %f:\n',get(get(hauto.Parent,'parent'),'CurrentObject'));
      disp(get(get(get(hauto.Parent,'parent'),'CurrentObject')));
    end
  end
end

if ~isempty(event) && strcmpi(get(event,'Cause'),'TRAVERSAL_FORWARD'),
  v = get(hauto.listbox,'Value');
  ss = get(hauto.listbox,'String');
  s = ss{v};
  set(hauto.listbox,'Visible','off');
  set(hauto.Parent,'String',s);
  eventdata.String = s;
else
  eventdata.String = get(hauto.Parent,'String');
end

set(hauto.listbox,'Visible','off');
if ~isempty(hauto.Callback),
  if iscell(hauto.Callback),
    feval(hauto.Callback{1},hauto.Parent,eventdata,hauto.Callback{2:end});
  else
    feval(hauto.Callback,hauto.Parent,eventdata);
  end
end

function KeyPressedAutoCompleteEdit(hObject,event,hauto)

if hauto.DEBUG,
  fprintf('KeyPressedAutoCompleteEdit called,\nevent = ');
  disp(event); fprintf('\n');
end

KeyCode = get(event,'KeyCode');
if KeyCode == 40, % down
  value = get(hauto.listbox,'Value');
  s = get(hauto.listbox,'String');
  if value < length(s),
    set(hauto.listbox,'Value',value+1);
  end
elseif KeyCode == 38, % up
  value = get(hauto.listbox,'Value');
  if value > 1,
    set(hauto.listbox,'Value',value-1);
  end
elseif KeyCode == 10 || KeyCode == 9, % enter or tab
  ListBoxCallback(hauto.listbox,[],hauto);
elseif KeyCode == 16, % shift
else 
  matchStringChoices(hauto);
end

function matchStringChoices(hauto)

caretpos = get(hauto.hjava,'CaretPosition');
string = get(hauto.hjava,'Text');
string1 = string(1:caretpos);

if hauto.DEBUG,
  fprintf('matchStringChoices called: %s <caret> %s\n',string1,string(caretpos+1:end));
end


choices = getappdata(hauto.listbox,'AllChoices');
%string2 = string(caretpos+1:end);

% match with choices
if isempty(string1),
  matchi = false(size(choices));
else
  matchi = strncmpi(choices,string1,length(string1));
end

% keep at previous value if possible
oldlistboxvalue = get(hauto.listbox,'Value');
oldlistboxstring = get(hauto.listbox,'String');
oldlistboxs = oldlistboxstring{oldlistboxvalue};

if ~any(matchi),
  % if no matches set string to be all choices
  matchi(:) = true;
end
  
value = find(strcmpi(oldlistboxs,choices(matchi)),1);
if isempty(value),
  value = 1;
end

h = hauto.height0*min(hauto.maxheight,nnz(matchi));
listboxpos = hauto.listboxpos;
listboxpos(2) = hauto.y0-h;
listboxpos(4) = h;

set(hauto.listbox,'String',choices(matchi),'Value',value,'Visible','on','Position',listboxpos);

function ListBoxCallback(hObject,event,hauto)

if hauto.DEBUG,
  fprintf('ListBoxCallback called,\nevent = ');
  disp(event); fprintf('\n');
end

v = get(hauto.listbox,'Value');
ss = get(hauto.listbox,'String');
s = ss{v};
set(hauto.Parent,'String',s);
drawnow;
set(hauto.hjava,'SelectionStart',0,'SelectionEnd',length(s));
matchStringChoices(hauto);
set(hauto.listbox,'Visible','off');

eventdata.String = s;
if ~isempty(hauto.Callback),
  if iscell(hauto.Callback),
    feval(hauto.Callback{1},hauto.Parent,eventdata,hauto.Callback{2:end});
  else
    feval(hauto.Callback,hauto.Parent,eventdata);
  end
end