function [success,msg,starttime] = BIASStartLogging(biasurl,moviefilename,handles)

starttime = nan;

success = false;
msg = '';

%% get status
try
  res = BIASCommand([biasurl,'?get-status']);
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
    
  if nargin >= 3,
    warnmsg = 'THIS SHOULD NOT HAPPEN! Camera not connected when starting logging! Trying to reconnect, but this could fail!';
    warning(warnmsg);
    addToStatus(handles,warnmsg);

    try
      [handles.vid,success1,msg2,warnings2] = ConnectToBIAS(handles.BIASParams,handles.DeviceID);
      res = BIASCommand([biasurl,'?get-status']);
      if res.success == 0,
        msg = sprintf('Could not get status: %s',res.message);
        return;
      end
      biasstatus = res.value;
      
    catch ME,
      warnmsg = sprintf('Tried to reconnect to BIAS but failed:\n%s',getReport(ME));
      warning(warnmsg);
      addToStatus(handles,warning);
    end
    if ~success1,
      warnmsg = sprintf('Tried to reconnect to BIAS but failed:\n%s',msg2);
      warning(warnmsg);
      addToStatus(handles,warning);
    end
  end
end
if ~success1,
  msg = sprintf('BIAS GUI not in correct state: %s',msg1);
  return;
end

%% stop capture
if biasstatus.capturing > 0,
  res = BIASCommand([biasurl,'?stop-capture']);
  if ~res.success,
    msg = sprintf('Error stopping capture: %s',res.message);
    return;
  end
end

%% set movie file name

res = BIASCommand([biasurl,'?set-video-file=',moviefilename]);
if ~res.success,
  msg = sprintf('Error setting video file name: %s',res.message);
  return;
end

%% start logging
res = BIASCommand([biasurl,'?enable-logging']);
if ~res.success,
  msg = sprintf('Error enabling logging: %s',res.message);
  return;
end

%% start capture

starttime = now;
res = BIASCommand([biasurl,'?start-capture']);
if ~res.success,
  msg = sprintf('Error starting capture: %s',res.message);
  return;
end

success = true;
