function ExperimentName = getExperimentName(handles)

if handles.StartRecording_Time_datenum <= 0,
  timestampstr = sprintf('notstarted_%s',datestr(handles.GUIInitialization_Time_datenum,30));
else
  timestampstr = datestr(handles.StartRecording_Time_datenum,30);
end

ExperimentName = sprintf('%s_%s_%s',...
  handles.ExperimentType,...
  handles.ConditionName,...
  timestampstr);
