function ExperimentName = getExperimentName(handles)

if handles.StartRecording_Time_datenum <= 0,
  timestampstr = sprintf('notstarted_%s',datestr(handles.GUIInitialization_Time_datenum,30));
else
  timestampstr = datestr(handles.StartRecording_Time_datenum,30);
end

if isfield(handles.params,'ExperimentNameComponents'),

  ExperimentName = eval(handles.params.ExperimentNameComponents);
  
else

  ExperimentName = sprintf('%s_%s_Rig%sBowl%s_%s',...
    handles.ExperimentType,...
    handles.ConditionName,...
    handles.Assay_Rig,handles.Assay_Bowl,...
    timestampstr);

end