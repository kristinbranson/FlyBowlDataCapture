function success = AddToLogFile(LogFileName,varargin)

success = false;

fid = fopen(LogFileName,'a');
if fid < 0,
  return;
end

fprintf(fid,varargin{:});

fclose(fid);

success = true;