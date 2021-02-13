function HighlightEditText(hObject,eventdata)

s = get(hObject,'Text');
set(hObject,'SelectionStart', 0);
set(hObject,'SelectionEnd', length(s)); 