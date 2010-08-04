function hauto = AutoCompleteEdit(hObject,choices,varargin)

hauto = struct;

[hauto.maxheight,hauto.Callback] =...
  myparse(varargin,'maxheight',5,...
  'Callback','');
hauto.maxheight = min(hauto.maxheight,length(choices));

hauto.Parent = hObject;
hauto.Choices = choices;
hauto.hjava = findjobj(hObject);

% position of listbox: directly below, of the same size, but with height
% maxheight times the edit box height
editpos = get(hObject,'Position');
w = editpos(3);
hauto.y0 = editpos(2);
hauto.height0 = editpos(4);
h = hauto.height0*hauto.maxheight;
hauto.listboxpos = [editpos(1),hauto.y0-h,w,h];

hauto.listbox = uicontrol('Style','listbox','String',choices,'Visible','off',...
  'Position',hauto.listboxpos,'FontName',get(hObject,'FontName'),...
  'FontUnits',get(hObject,'FontUnits'),...
  'FontSize',get(hObject,'FontSize'));

setappdata(hObject,'AutoCompleteHandle',hauto);

set(hauto.hjava,'FocusGainedCallback',@(h,event) FocusGainedAutoCompleteEdit(h,event,hauto));
set(hauto.hjava,'KeyPressedCallback',@(h,event) KeyPressedAutoCompleteEdit(h,event,hauto));
set(hauto.hjava,'FocusLostCallback',@(h,event) FocusLostAutoCompleteEdit(h,event,hauto));
set(hauto.hjava,'MousePressedCallback',@(h,event) MousePressedAutoCompleteEdit(h,event,hauto));
set(hauto.listbox,'Callback',@(h,event) ListBoxCallback(h,event,hauto));

function MousePressedAutoCompleteEdit(hObject,event,hauto) %#ok<*INUSL>

matchStringChoices(hauto);
set(hauto.listbox,'Visible','on');

function FocusGainedAutoCompleteEdit(hObject,event,hauto)

%matchStringChoices(hauto);
set(hauto.listbox,'Visible','on');

function FocusLostAutoCompleteEdit(hObject,event,hauto)

if ~isempty(event) && strcmpi(get(event,'Cause'),'TRAVERSAL_FORWARD'),
  v = get(hauto.listbox,'Value');
  ss = get(hauto.listbox,'String');
  s = ss{v};
  set(hauto.listbox,'Visible','off');
  set(hauto.Parent,'String',s);
end
  
set(hauto.listbox,'Visible','off');
if ~isempty(hauto.Callback),
  if iscell(hauto.Callback),
    feval(hauto.Callback{1},hauto.Parent,event,hauto.Callback{2:end});
  else
    feval(hauto.Callback,hauto.Parent,event);
  end
end

function KeyPressedAutoCompleteEdit(hObject,event,hauto)

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
elseif KeyCode == 10, % enter
  ListBoxCallback(hauto.listbox,[],hauto);
else 
  matchStringChoices(hauto);
end

function matchStringChoices(hauto)

caretpos = get(hauto.hjava,'CaretPosition');
string = get(hauto.hjava,'Text');
string1 = string(1:caretpos);
%string2 = string(caretpos+1:end);

% match with choices
if isempty(string1),
  matchi = false(size(hauto.Choices));
else
  matchi = strncmpi(hauto.Choices,string1,length(string1));
end

% keep at previous value if possible
oldlistboxvalue = get(hauto.listbox,'Value');
oldlistboxstring = get(hauto.listbox,'String');
oldlistboxs = oldlistboxstring{oldlistboxvalue};

if ~any(matchi),
  % if no matches set string to be all choices
  matchi(:) = true;
end
  
value = find(strcmpi(oldlistboxs,hauto.Choices(matchi)),1);
if isempty(value),
  value = 1;
end

h = hauto.height0*min(hauto.maxheight,nnz(matchi));
listboxpos = hauto.listboxpos;
listboxpos(2) = hauto.y0-h;
listboxpos(4) = h;

set(hauto.listbox,'String',hauto.Choices(matchi),'Value',value,'Visible','on','Position',listboxpos);

function ListBoxCallback(hObject,event,hauto)

v = get(hauto.listbox,'Value');
ss = get(hauto.listbox,'String');
s = ss{v};
set(hauto.Parent,'String',s);
drawnow;
set(hauto.hjava,'SelectionStart',0,'SelectionEnd',length(s));
matchStringChoices(hauto);
set(hauto.listbox,'Visible','off');