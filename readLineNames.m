function Fly_LineNames = readLineNames(linename_file,db,doforce)

Fly_LineNames = {};

if ~exist(linename_file,'file') || (nargin > 2 && doforce),
  if isempty(db),
    errordlg('Not connected to Sage. Cannot query for line names','Error reading line names');
    return
  end
  try
    Fly_LineNames = getLineNames(db);
    fid = fopen(linename_file,'w');
    fprintf(fid,'%s\n',Fly_LineNames{:});
    fclose(fid);
    return;
  catch ME
    errordlg(['Cannot query for line names: ',getReport(ME)],'Error reading line names');
  end
end

Fly_LineNames = importdata(linename_file);
