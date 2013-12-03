function [success,msg] = StartBIAS(biasparams,deviceid)

success = false;
msg = '';

try
  res = loadjson(urlread([biasparams.BIASURL,'?get-status']));
  if res.success == 1,
    success = true;
    return
  end
catch %#ok<CTCH>
end

% find BIAS windows open
biasesopen = GetBIASWindowsOpen(biasparams);
biasestoopen = setdiff(1:deviceid,biasesopen);
if isempty(biasestoopen),
  msg = sprintf('Could not determine how many times to call BIAS, bias windows already open = %s, camera number to open = %d',...
    mat2str(biasesopen),deviceid);
end

for i = 1:numel(biasestoopen),

  % probably because the GUI is not started yet
  fprintf('Launching a new instance of BIAS...\n');
  [status,msg1] = dos([biasparams.BIASBinary,'&'],'-echo');
  if status ~= 0,
    msg = sprintf('Error starting bias: %s',msg1);
    return;
  end

  res = loadjson(urlread([biasparams.BIASURL,'?get-status']));
  if res.success == 1,
    success = true;
    return
  end
end