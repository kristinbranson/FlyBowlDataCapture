function [success,msg] = StartBIAS(biasparams,deviceid)

success = false;
msg = '';

try
  res = loadjson1(urlread([biasparams.BIASURL,'?get-status']));
  if res.success == 1,
    success = true;
    return
  end
catch %#ok<CTCH>
end

% probably because the GUI is not started yet
fprintf('Launching a new instance of BIAS...\n');
[status,msg1] = dos([biasparams.BIASBinary,'&'],'-echo');
if status ~= 0,
  msg = sprintf('Error starting bias: %s',msg1);
  return;
end

try %#ok<TRYNC>
  res = loadjson1(urlread([biasparams.BIASURL,'?get-status']));
  if res.success == 1,
    success = true;
    return
  end
end