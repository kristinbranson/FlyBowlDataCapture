function handles = addToStatus(handles,s)

s = textwrap(handles.edit_Status,s);
handles.Status(end+1:end+length(s)) = s;
if length(handles.Status) > handles.Status_MaxNLines,
  handles.Status = handles.Status(end-handles.Status_MaxNLines+1:end);
end
set(handles.edit_Status,'String',handles.Status);
