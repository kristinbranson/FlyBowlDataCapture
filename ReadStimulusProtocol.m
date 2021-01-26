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

% old code for old protocol files

% res.expData = indata;
% res.stepNum= indata(:,1);
% res.intensity = indata(:,2);
% res.pulseWidthSP = round(indata(:,3));
% res.pulsePeriodSP = round(indata(:,4));
% res.pulseNum = round(indata(:,5));
% res.offTime = round(indata(:,6));
% res.delayTime = round(indata(:,7));
% 
% if size(indata,2)==9
%   res.iteration = indata(:,8);
%   res.duration = indata(:,9);
% else
%   res.iteration = zeros(size(indata,1),1);
%   res.duration = indata(:,8);
% end

% new code copied from Jin's flyBowl_RGB.m and modified
res.stepNum = indata(:,1);
res.duration = indata(:,2);
res.delayTime = indata(:,3);
%red light
res.Rintensity = indata(:,4);
res.RpulseWidth = indata(:,5);
res.RpulsePeriod = indata(:,6);
res.RpulseNum = indata(:,7);
res.RoffTime = indata(:,8);
res.Riteration = indata(:,9);
%green light
res.Gintensity = indata(:,10);
res.GpulseWidth = indata(:,11);
res.GpulsePeriod = indata(:,12);
res.GpulseNum = indata(:,13);
res.GoffTime = indata(:,14);
res.Giteration = indata(:,15);
%blue light
res.Bintensity = indata(:,16);
res.BpulseWidth = indata(:,17);
res.BpulsePeriod = indata(:,18);
res.BpulseNum = indata(:,19);
res.BoffTime = indata(:,20);
res.Biteration = indata(:,21);

res.ProtocolData = indata;
res.ProtocolHeader = intext(1,:);

% KB 20210125 not sure if we should continue to have these checks or if
% e.g. units have changed here
% if any(res.pulseWidthSP > MAXPULSEWIDTH),
%   errmsg = 'The value of pulse width should be equal or less than 30 seconds.';
%   return;
% end
% 
% if any(res.pulsePeriodSP > MAXPULSEPERIOD),
%   errmsg = 'The value of pulse period should be equal or less than 30 Seconds.';
%   return;
% end
%             
% if any(res.pulsePeriodSP < res.pulseWidthSP),
%   errmsg = 'The value of pulse period should be equal or larger than pulse width.';
%   return;
% end

if ~all(res.stepNum' == 1:numel(res.stepNum)),
  warning('Protocol step should be 1:%d, actual numbers read will be ignored.',numel(res.stepNum));
end

success = true;
