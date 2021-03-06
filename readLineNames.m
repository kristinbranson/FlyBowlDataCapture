function handles = readLineNames(handles,doforce)

handles.Fly_LineNames = {};

if ~exist(handles.linename_file,'file') || (nargin > 1 && doforce),
  if ~handles.IsSage,
    errordlg('Not connected to Sage. Cannot query for line names','Error reading line names');
    return
  end
  try
    handles.Fly_LineNames = getLineNames(handles);
    fid = fopen(handles.linename_file,'w');
    if fid < 0,
      error('Cannot open file %s for writing',handles.linename_file);
    end
    fprintf(fid,'%s\n',handles.Fly_LineNames{:});
    fclose(fid);
    addToStatus(handles,{sprintf('%d line names successfully read from SAGE.',length(handles.Fly_LineNames))});
    return;
  catch ME
    errordlg(['Cannot query for line names: ',getReport(ME)],'Error reading line names');
    addToStatus(handles,{'Could not refresh line names from Sage.'});

  end
end

fid = fopen(handles.linename_file,'r');
if fid < 0,
  error('Could not open file %s for reading',handles.linename_file);
end
handles.Fly_LineNames = {};
while true,
  l = fgetl(fid);
  if ~ischar(l),
    break;
  end
  l = strtrim(l);
  if isempty(l),
    continue;
  end
  handles.Fly_LineNames{end+1} = l;
end
fclose(fid);
handles.Fly_LineNames = handles.Fly_LineNames(:);
%handles.Fly_LineNames = importdata(handles.linename_file);
addToStatus(handles,{'Read line names from file.'});

if isfield(handles.params,'ExtraLineNames'),
  handles.Fly_LineNames = cat(1,handles.Fly_LineNames,handles.params.ExtraLineNames(:));
end
handles.Fly_LineNames = unique(handles.Fly_LineNames);
