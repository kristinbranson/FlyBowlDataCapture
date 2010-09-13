function [AdaptorRunning,DevRunning] = parseIsCameraRunningFileName(IsCameraRunningFile,semaphore_params)

[~,s,ext] = fileparts(IsCameraRunningFile.name);
s = [s,ext];
matches = regexp(s,sprintf('^%s_(?<adaptor>.+)_(?<dev>[0-9]+)\\.mat$',...
  semaphore_params.IsCameraRunningFileStr),'names');
if isempty(matches),
  DevRunning = nan;
  AdaptorRunning = '';
else
  DevRunning = str2double(matches(end).dev);
  AdaptorRunning = matches(end).adaptor;
end
