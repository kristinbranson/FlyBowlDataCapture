function params = ReadParams(filename,varargin)

[params,fns_required,fns_numeric] = ...
  myparse(varargin,'params',struct,...
  'fns_required',{},...
  'fns_numeric',{});

comment_char = '#';

fid = fopen(filename,'r');
if fid < 0,
  s = sprintf('Could not read in parameters file %s',filename);
  uiwait(errordlg(s,'Error reading parameters'));
  error(s);
end

% read each line
fns_read = {};
while true,
  s = fgetl(fid);
  if ~ischar(s), break; end
    
  % remove extra white space
  s = strtrim(s);
    
  % skip comments
  if isempty(s) || s(1) == comment_char,
    continue;
  end
    
  % split at ,
  i = find(s==',',1);
  if isempty(i),
    warning('Skipping line %s, no comma',s);
    continue;
  end
  v = {s(1:i-1),s(i+1:end)};
    
  % first value is the parameter name, rest are parameter values
  if ismember(v{1},fns_numeric),
    params.(v{1}) = str2double(v{2});
  else
    params.(v{1}) = v{2};
  end
  fns_read{end+1} = v{1}; %#ok<AGROW>
end

fclose(fid);

fns_missing = setdiff(fns_required,fns_read);
if ~isempty(fns_missing),
  warning(['The following parameters were not read, and the default values will be used: ',sprintf('%s ',fns_missing{:})]);
end