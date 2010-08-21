function [success,msg] = renamefile(inname,outname)

success = false;
msg = '';

if ~exist(inname,'file'),
  msg = 'No matching files were found.';
  return;
end
if strcmp(inname,outname),
  msg = 'Cannot copy or move a file or directory onto itself.';
  return;
end
pathstr = fileparts(outname);
if ~isempty(pathstr) && ~exist(pathstr,'file')
  msg = 'The system cannot find the path specified.';
  return;
end
  
flag = dos(sprintf('rename %s %s',inname,outname));
success = ~flag;