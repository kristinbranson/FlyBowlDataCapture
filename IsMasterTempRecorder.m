function [ismaster,info,errstring] = IsMasterTempRecorder(varargin)

errstring = '';
info = struct;

% where we will save temperature data
TempRecordDir = '.TempRecordData';
IsMasterFileStr = 'IsMaster';
ChannelFileStr = 'Channel';

% parse parameters

% Total number of channels
NChannelsTotal = 8;
% Time in between temperature readings (seconds)
Period = 1;
% Which channels have temperature probes
Channels = 1:8;
% Thermocouple types
ChannelTypes = {'K'};
% if 1, temperature probe will reject 60 Hz, otherwise will reject 50 Hz
Reject60Hz = 0;

[NChannelsTotal,Period,Channels,ChannelTypes,Reject60Hz,...
  TempRecordDir,IsMasterFileStr,ChannelFileStr] = myparse(varargin,...
  'NChannelsTotal',NChannelsTotal,'Period',Period,...
  'Channels',Channels,'ChannelTypes',ChannelTypes,'Reject60Hz',Reject60Hz,...
  'TempRecordDir',TempRecordDir,'IsMasterFileStr',IsMasterFileStr,...
  'ChannelFileStr',ChannelFileStr); %#ok<ASGLU>

IsMasterFile = fullfile(TempRecordDir,IsMasterFileStr);
ChannelFileNames = cell(1,numel(Channels));
for i = 1:numel(Channels),
  ChannelFileNames{i} = fullfile(TempRecordDir,sprintf('%s_%02d',ChannelFileStr,Channels(i)));
end

if ~exist(IsMasterFile,'file'),
  ismaster = false;
  return;
end

for i = 1:length(Channels),
  if ~exist(ChannelFileNames{i},'file'),
    ismaster = false;
    errstring = sprintf('Is master semaphore file %s exists, but not channel file %s.\n',IsMasterFile,ChannelFileNames{i});
    return;
  end
end

try
  info = load(IsMasterFile);
catch
  errstring = sprintf('Could not load information from IsMasterFile %s',IsMasterFile);
end

ismaster = true;
%info.IsMasterFile = IsMasterFile;
%info.ChannelFileNames = ChannelFileNames;
%info.Channels = Channels;