function handles = FindAllExperimentConditions(handles)

if ~exist(handles.params.ConditionDirectory,'dir'),
  s = sprintf('Experiment condition directory %s does not exist',handles.ConditionDirectory);
  errordlg(s);
  error(s);
end

conditionfiles = dir(fullfile(handles.params.ConditionDirectory,'*__*.csv'));
if isempty(conditionfiles),
  s = sprintf('Experiment condition directory %s contains no condition definition files',handles.params.ConditionDirectory);
  errordlg(s);
  error(s);
end
conditionfiles = {conditionfiles.name};

% parse the condition files
handles.ExperimentTypes = {};
handles.Experiment2Conditions = {};
for i = 1:numel(conditionfiles),
  m = regexp(conditionfiles{i},'^(?<experiment>.+)__(?<condition>.+)\.csv$','names','once');
  if isempty(m),
    continue;
  end
  j = find(strcmp(m.experiment,handles.ExperimentTypes),1);
  if isempty(j),
    handles.ExperimentTypes{end+1} = m.experiment;
    handles.Experiment2Conditions{end+1} = {m.condition;fullfile(handles.params.ConditionDirectory,conditionfiles{i})};
  else
    handles.Experiment2Conditions{j}(:,end+1) = {m.condition;fullfile(handles.params.ConditionDirectory,conditionfiles{i})};
  end
end
