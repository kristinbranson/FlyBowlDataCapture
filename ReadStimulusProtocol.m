function [success,res,errmsg] = ReadStimulusProtocol(params,res)

MAXPULSEWIDTH = 30000;
MAXPULSEPERIOD = 30000;

success = false;
errmsg = '';
if nargin < 2,
  res = struct;
end

[~,~,protocolExt] = fileparts(params.ChR_expProtocolFile);

switch protocolExt
  case {'.csv'}
    [intext, indata] = csvread_with_headers(params.ChR_expProtocolFile);
  case {'.xls', '.xlsx'}
    [indata,intext,~] = xlsread(params.ChR_expProtocolFile);
  otherwise
    errmsg = sprintf('Unknown protocol file type %s.',protocolExt);
    return
end

%fclose(fid);
res.expData = indata;
res.stepNum= indata(:,1);
res.intensity = indata(:,2);
res.pulseWidthSP = round(indata(:,3));
res.pulsePeriodSP = round(indata(:,4));
res.pulseNum = round(indata(:,5));
res.offTime = round(indata(:,6));
res.delayTime = round(indata(:,7));

if size(indata,2)==9
  res.iteration = indata(:,8);
  res.duration = indata(:,9);
else
  res.iteration = zeros(size(indata,1),1);
  res.duration = indata(:,8);
end

res.ProtocolData = indata;
res.ProtocolHeader = intext(1,:);

if any(res.pulseWidthSP > MAXPULSEWIDTH),
  errmsg = 'The value of pulse width should be equal or less than 30 seconds.';
  return;
end

if any(res.pulsePeriodSP > MAXPULSEPERIOD),
  errmsg = 'The value of pulse period should be equal or less than 30 Seconds.';
  return;
end
            
if any(res.pulsePeriodSP < res.pulseWidthSP),
  errmsg = 'The value of pulse period should be equal or larger than pulse width.';
  return;
end

if ~all(res.stepNum' == 1:numel(res.stepNum)),
  warning('Protocol step should be 1:%d, actual numbers read will be ignored.',numel(res.stepNum));
end

success = true;
