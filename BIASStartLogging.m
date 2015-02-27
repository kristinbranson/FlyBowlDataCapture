function [success,msg,starttime] = BIASStartLogging(biasurl,moviefilename)

success = false;
msg = '';

%% get status
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

%% check BIAS state

[success1,msg1] = CheckBIASState(biasurl,'biasstatus',biasstatus,...
  'connected',1,'logging',0);
if ~success1,
  msg = sprintf('BIAS GUI not in correct state: %s',msg1);
  return;
end

%% stop capture
if biasstatus.capturing > 0,
  res = loadjson1(urlread([biasurl,'?stop-capture']));
  if ~res.success,
    msg = sprintf('Error stopping capture: %s',res.message);
    return;
  end
end

%% set movie file name

res = loadjson1(urlread([biasurl,'?set-video-file=',moviefilename]));
if ~res.success,
  msg = sprintf('Error setting video file name: %s',res.message);
  return;
end

%% start logging
res = loadjson1(urlread([biasurl,'?enable-logging']));
if ~res.success,
  msg = sprintf('Error enabling logging: %s',res.message);
  return;
end

%% start capture

starttime = now;
res = loadjson1(urlread([biasurl,'?start-capture']));
if ~res.success,
  msg = sprintf('Error starting capture: %s',res.message);
  return;
end

success = true;
