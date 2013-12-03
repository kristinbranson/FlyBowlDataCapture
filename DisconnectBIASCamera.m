function [success,msg,handles] = DisconnectBIASCamera(biasparams,deviceid,handles)

success = false;
msg = '';
if nargin < 3,
  handles = struct;
end

try
  res = loadjson(urlread([biasparams.BIASURL,'?get-status']));
catch %#ok<CTCH>
  % camera not connected
  success = true;
  return;
end

if res.success == 0,
  % camera not connected
  success = true;
  return;
end

if res.capturing > 0,
  try
    res1 = loadjson(urlread([biasparams.BIASURL,'?stop-capture']));
    if res1.success == 0,
      msg = 'Could not stop capturing';
      return;
    end
  catch %#ok<CTCH>
    msg = 'Could not stop capturing';
    return;
  end
end

if res.connected > 0,
  try
    res1 = loadjson(urlread([biasparams.BIASURL,'?disconnect']));
    if res1.success == 0,
      msg = 'Could not disconnect camera';
      return;
    end
  catch %#ok<CTCH>
    msg = 'Could not disconnect camera';
    return;
  end
end

success = true;

global FBDC_BIASCAMERASINUSE;
FBDC_BIASCAMERASINUSE = setdiff(FBDC_BIASCAMERASINUSE,deviceid);
handles.IsCameraInitialized = false;