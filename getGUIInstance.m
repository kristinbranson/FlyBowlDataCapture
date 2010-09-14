function handles = getGUIInstance(handles)

if isfield(handles,'GUIi') && ~isnan(handles.GUIi),
  return;
end

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
save(handles.GUIInstanceFileName,'-struct','handles','RandomNumber','GUIi','now');

FBDC_GUIInstanceFileName = handles.GUIInstanceFileName;