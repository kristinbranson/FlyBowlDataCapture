function handles = getGUIInstance(handles)

if isfield(handles,'GUIi') && ~isnan(handles.GUIi),
  return;
end

if true,

% NEW: use global variables to keep track of which guis are open
  
global FBDC_GUIInstances; %#ok<TLEV>

GUIs = FBDC_GUIInstances;
if isempty(GUIs),
  GUIi = 1;
else
  tmp = true(1:max(GUIs)+1);
  tmp(GUIs) = false;
  GUIi = find(tmp,1,'first');
end
FBDC_GUIInstances(end+1) = GUIi;
handles.GUIi = GUIi;

else
  
% OBSOLETE: use files to keep track of which GUIs are open

GUIs = dir(fullfile(handles.GUIInstanceDir,'*.mat'));
idx = [];
for i = 1:length(GUIs),
  matches = regexp(GUIs(i).name,'.*_(?<instance>[0-9]+).mat$','names');
  if isempty(matches), continue; end
  idx(end+1) = str2double(matches(end).instance); %#ok<AGROW>
end
if isempty(idx),
  GUIi = 1;
else
  for GUIi = 1:max(idx)+1,
    if ~ismember(GUIi,idx),
      break;
    end
  end
end
handles.GUIi = GUIi;
handles.GUIInstanceFileName = fullfile(handles.GUIInstanceDir,sprintf('GUIInstance_%d.mat',GUIi));

global FBDC_GUIInstanceFileName;
if ~isempty(FBDC_GUIInstanceFileName) && exist(FBDC_GUIInstanceFileName,'file'),
  delete(FBDC_GUIInstanceFileName);
end

if ~exist(handles.GUIInstanceDir,'file'),
  mkdir(handles.GUIInstanceDir);
end
GUIi = handles.GUIi;
timestamp = now;
save(handles.GUIInstanceFileName,'GUIi','timestamp');

FBDC_GUIInstanceFileName = handles.GUIInstanceFileName;

end