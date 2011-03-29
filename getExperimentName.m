function ExperimentName = getExperimentName(handles)

effector_abbrs = {'UAS_dTrpA1_2_0002','TrpA'};
i = find(strcmp(handles.params.MetaData_Effector,effector_abbrs(:,1)),1);
if ~isempty(i),
  effector = effector_abbrs{i,2};
else
  effector = handles.params.MetaData_Effector;
end


if handles.StartRecording_Time_datenum <= 0,
  timestampstr = sprintf('notstarted_%s',datestr(handles.GUIInitialization_Time_datenum,30));
else
  timestampstr = datestr(handles.StartRecording_Time_datenum,30);
end

ExperimentName = sprintf('%s_%s_Rig%sPlate%sBowl%s_%s',...
  handles.Fly_LineName,...
  effector,...
  handles.Assay_Rig,handles.Assay_Plate,handles.Assay_Bowl,...
  timestampstr);
