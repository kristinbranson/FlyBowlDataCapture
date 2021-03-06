function addToStatus(handles,s,datenum)

try

ColsWrap = 90;

if nargin <=1,
  return;
end

if isstruct(handles),
  hObject = handles.edit_Status;
else
  hObject = handles;
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
Status_String = get(hObject,'String');
s = textwrap(handles.edit_Status,s,ColsWrap);
if ~iscell(Status_String),
  Status_String = {Status_String};
end
Status_String(end+1:end+length(s)) = s;
set(handles.edit_Status,'String',Status_String);

% write to log file
success = false;
try
  fid = fopen(handles.LogFileName,'a');
  if fid > 0,
    fprintf(fid,'%s\n',s{:});
    fclose(fid);
    success = true;
  end
catch ME,
  getReport(ME)
end
if ~success,
  fprintf('(Could not write to log file)\n');
  fprintf('%s\n',s{:});
end


% scroll down to bottom
if isfield(handles,'jedit_Status'),
  drawnow;
  handles.jedit_Status.setCaretPosition(handles.jedit_Status.getDocument.getLength);
end

catch ME,
  
  fprintf('Error writing status message:\n');
  try
    fprintf('%s\n',s{:});
  catch
  end
  getReport(ME)
end