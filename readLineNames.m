function handles = readLineNames(handles,doforce)

handles.Fly_LineNames = {};

if ~exist(handles.linename_file,'file') || (nargin > 1 && doforce),
  if isempty(handles.db),
    errordlg('Not connected to Sage. Cannot query for line names','Error reading line names');
    return
  end
  try
    handles.Fly_LineNames = getLineNames(handles.db);
    fid = fopen(handles.linename_file,'w');
    fprintf(fid,'%s\n',handles.Fly_LineNames{:});
    fclose(fid);
    return;
  catch ME
    errordlg(['Cannot query for line names: ',getReport(ME)],'Error reading line names');
    handles = addToStatus(handles,{'Could not refresh line names from Sage.'});

  end
end

handles.Fly_LineNames = importdata(handles.linename_file);
handles = addToStatus(handles,{'Read line names from file.'});

if isfield(handles.params,'ExtraLineNames'),
  handles.Fly_LineNames = cat(1,handles.Fly_LineNames,handles.params.ExtraLineNames(:));
end
