function Fly_LineNames = readLineNames(linename_file)

if ~exist(linename_file,'file'),
  % TODO: read from Sage
end

Fly_LineNames = importdata(linename_file);
