function [vid,success,msg,warnings] = ConnectToBIAS(biasparams,deviceid,varargin)

[docapture,dodisablelogging,dosetconfig,windowgeometry,cameraname] = myparse(varargin,...
  'docapture',true,'dodisablelogging',false,'dosetconfig',true,...
  'windowgeometry',[],'cameraname','');

%biasbinary,biasconfigfile,...
% biasbase,biasport,cameranumber)

success = false;
msg = '';
warnings = {};
vid = struct;

vid.BIASURL = GetBIASURL(biasparams,deviceid);
biasparams.BIASURL = vid.BIASURL;
vid.BIASParams = biasparams;

%% check camera status

[success1,msg1] = StartBIAS(biasparams,deviceid);
if ~success1,
  msg = sprintf('Error starting BIAS: %s',msg1);
  return;
end

try
  res = loadjson(urlread([vid.BIASURL,'?get-status']));
catch ME,
  msg = getReport(ME,'basic');
  return;
end
if res.success == 0,
  msg = sprintf('Could not get status: %s',res.message);
  return;
end

vid.biasstatus = res.value;

%% set position of the window
if ~isempty(windowgeometry),
  
  screensz = get(0,'ScreenSize');
  windowgeometry_bias = [windowgeometry(1),...
    -windowgeometry(2)-windowgeometry(4)+screensz(4)-25,...
    windowgeometry(3),windowgeometry(4)+25];
  
  res = loadjson(urlread(sprintf('%s?set-window-geometry={"x":"%d","y":"%d","width":"%d","height":"%d"}',...
    vid.BIASURL,windowgeometry_bias)));
  if res.success == 0,
    msg = sprintf('Could not set window geometry: %s',res.message);
    retrun;
  end
  
end

%% set camera name
if ~isempty(cameraname),
  
  res = loadjson(urlread([vid.BIASURL,'?set-camera-name=',cameraname]));
  if res.success == 0,
    msg = sprintf('Could not set camera name: %s',res.message);
    retrun;
  end
  
end

%% connect to camera

if vid.biasstatus.connected == 0,
  res = loadjson(urlread([vid.BIASURL,'?connect']));
  if ~res.success,
    msg = sprintf('Error connecting: %s',res.message);
    return;
  end
else
  warnings{end+1} = 'Camera already connected';
end

%% check that we are not capturing

if vid.biasstatus.capturing == 1,
  warnings{end+1} = 'Already capturing from camera';
  res = loadjson(urlread([vid.BIASURL,'?stop-capture']));
  if ~res.success,
    msg = sprintf('Error stopping capture: %s',res.message);
    return;
  end
end

%% set configuration

if dosetconfig,
  res = loadjson(urlread([vid.BIASURL,'?load-configuration=',biasparams.BIASConfigFile]));
  if ~res.success,
    msg = sprintf('Error setting configuration: %s',res.message);
    return;
  end
end

%% get configuration for error checking

res = loadjson(urlread([vid.BIASURL,'?get-configuration']));
if ~res.success,
  msg = sprintf('Error getting configuration: %s',res.message);
  return;
end
vid.biasconfig = res.value;

%% set logging

if dodisablelogging && vid.biasstatus.logging > 0,
  res = loadjson(urlread([vid.BIASURL,'?disable-logging']));
  if ~res.success,
    msg = sprintf('Error disabling logging: %s',res.message);
    return;
  end
end

%% start capture

if docapture && vid.biasstatus.capturing == 0,
  res = loadjson(urlread([vid.BIASURL,'?start-capture']));
  if ~res.success,
    msg = sprintf('Error starting capture: %s',res.message);
    return;
  end
end  


%% done

success = true;
