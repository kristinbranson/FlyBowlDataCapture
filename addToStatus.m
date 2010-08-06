function handles = addToStatus(handles,s)

s = textwrap(handles.edit_Status,s);
handles.Status(end+1:end+length(s)) = s;
set(handles.edit_Status,'String',handles.Status);

% scroll down to bottom
if isfield(handles,'jedit_Status'),
  drawnow;
  handles.jedit_Status.setCaretPosition(handles.jedit_Status.getDocument.getLength);
end