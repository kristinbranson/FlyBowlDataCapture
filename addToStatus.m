function handles = addToStatus(handles,s,datenum)

if nargin <=1,
  return;
end

if ~iscell(s),
  s = {s};
end

% add to status edit box
if nargin <= 2,
  datenum = now;
end
if datenum > 0,
  s{1} = sprintf('%s: %s',datestr(datenum,handles.secondformat),s{1});
end
s = textwrap(handles.edit_Status,s);
handles.Status(end+1:end+length(s)) = s;
set(handles.edit_Status,'String',handles.Status);

% write to log file
fid = fopen(handles.LogFileName,'a');
fprintf(fid,'%s\n',s{:});
fclose(fid);

% scroll down to bottom
if isfield(handles,'jedit_Status'),
  drawnow;
  handles.jedit_Status.setCaretPosition(handles.jedit_Status.getDocument.getLength);
end