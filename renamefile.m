% [success,msg] = renamefile(inname,outname)
%
% Matlab's movefile copies the file then deletes the original. This calls
% the move DOS command. 
%
% Comparison in speed:
% tmp1.bin and tmpa.bin are identical files of size 10^9 bytes.
% tic; movefile('tmp1.bin','tmp2.bin'); toc
% Elapsed time is 20.075737 seconds.
% tic; renamefile('tmpa.bin','tmpb.bin'); toc
% Elapsed time is 0.105161 seconds.
%
function [success,msg] = renamefile(inname,outname)

success = false;

if ~ispc,
  msg = 'renamefile should only be used in Windows';
  return;
end

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
  
[flag,msg] = dos(sprintf('move %s %s',inname,outname));
success = ~flag;