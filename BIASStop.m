function [success,msg,stoptime] = BIASStop(biasurl,varargin)

success = false;
msg = '';
stoptime = nan;

[disablelogging,disconnect] = myparse(varargin,'disablelogging',true,'disconnect',true);

%% check BIAS state

try
  res = loadjson1(urlread([biasurl,'?get-status']));
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
  stoptime = now;
  res = loadjson1(urlread([biasurl,'?stop-capture']));
  if ~res.success,
    msg = sprintf('Error stopping capture: %s',res.message);
    return;
  end
end

%% disable logging
if disablelogging && biasstatus.logging > 0,
  res = loadjson1(urlread([biasurl,'?disable-logging']));
  if ~res.success,
    msg = sprintf('Error disabling logging: %s',res.message);
    return;
  end
end  

%% disconnect
if disconnect,
  res = loadjson1(urlread([biasurl,'?disconnect']));
  if ~res.success,
    msg = sprintf('Error disconnecting: %s',res.message);
    return;
  end  
end

%% done

success = true;