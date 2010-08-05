function Fly_LineNames = readLineNames(linename_file,doforce)

if ~exist(linename_file,'file') || nargin > 1 && doforce,
  % TODO: read from Sage
end

Fly_LineNames = importdata(linename_file);
