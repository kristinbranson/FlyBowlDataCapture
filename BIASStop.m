function [success,msg] = BIASStop(biasurl,varargin)

success = false;
msg = '';

[disablelogging,disconnect] = myparse(varargin,'disablelogging',true,'disconnect',true);

%% check BIAS state

try
  res = loadjson(urlread([biasurl,'?get-status']));
catch ME,
  msg = getReport(ME,'basic');
  return;
end
if res.success == 0,
  msg = sprintf('Could not get status: %s',res.message);
  return;
end
biasstatus = res.value;

%% stop capture
if biasstatus.capturing > 0,
  res = loadjson(urlread([biasurl,'?stop-capture']));
  if ~res.success,
    msg = sprintf('Error stopping capture: %s',res.message);
    return;
  end
end

%% disable logging
if disablelogging && biasstatus.logging > 0,
  res = loadjson(urlread([biasurl,'?disable-logging']));
  if ~res.success,
    msg = sprintf('Error disabling logging: %s',res.message);
    return;
  end
end  

%% disconnect
if disconnect,
  res = loadjson(urlread([biasurl,'?disconnect']));
  if ~res.success,
    msg = sprintf('Error disconnecting: %s',res.message);
    return;
  end  
end

%% done

success = true;