function test_autocomplete()

handles = struct;
handles.figure_main = 1;
handles.choices = {'GMR_24F07','GMR_25F08'};
w = 200;
h = 30;
maxheight = 5;

figure(handles.figure_main);
clf;
delete(get(1,'Children'));
set(handles.figure_main,'Units','Pixels');
figpos = get(handles.figure_main,'Position');
c = figpos(3)/2;
m = figpos(4)/2;
pos = [c-w/2,m-h/2,w,h];
%pos2 = pos;
%pos2(2) = m - 2*h - h/2;
handles.hedit = uicontrol('Style','edit','Parent',handles.figure_main,'Units','Pixels','Position',pos,'FontSize',12,'String','InitialString','HorizontalAlignment','Left');
%handles.hpopup = uicontrol('Style','popupmenu','Parent',handles.figure_main,'Units','Pixels','Position',pos2,'FontSize',12,'String',{'aa','bbb','ccccc'});
handles.hauto = AutoCompleteEdit(handles.hedit,handles.choices,'maxheight',maxheight,'Callback',@EditCallbackFcn);
%set(handles.hedit,'Callback',@EditCallbackFcn);

guidata(handles.figure_main,handles);

function EditCallbackFcn(hObject,event)

s = get(hObject,'String');
fprintf('Edit callback -> %s\n',s);
