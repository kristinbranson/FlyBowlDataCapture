function metadata = ReadConditionFile(handles)

% TODO: these should not be hardcoded
metadata = struct;

% default values

metadata.SortingTime = -1;
metadata.StarvationTime = -1;
metadata.ExperimentProtocol = '?';
metadata.LineName = 'Unknown';
metadata.Effector = 'Unknown';
metadata.Gender = 'x';
metadata.DaysSinceCross = -1;
metadata.FlipDays = -1;
metadata.FlipUsed = -1;
metadata.RobotID = 'unknown';
metadata.HandlingProtocol = '?';
metadata.CrossHandler = 'unknown';
metadata.SortingHandler = 'unknown';
metadata.StarvationHandler = 'unknown';
metadata.RearingProtocol = '?';
metadata.LabName = 'unknown';
metadata.ScreenReason = handles.ConditionName;

fns_required = fieldnames(metadata);
fns_numeric = fns_required(structfun(@isnumeric,metadata));

% read from conditions file
metadata = ReadParams(handles.ConditionFileName,'params',metadata,'fns_required',fns_required,'fns_numeric',fns_numeric);

metadata.ScreenType = sprintf('non_olympiad_%s_%s',metadata.LabName,handles.ExperimentType);

if metadata.DaysSinceCross < 0,
  metadata.CrossDate = '????????';
else
  cross_datenum = handles.StartRecording_Time_datenum - metadata.DaysSinceCross;
  metadata.CrossDate = datestr(cross_datenum,handles.datetimeformat);
end

if metadata.DaysSinceCross < 0 || metadata.FlipDays < 0,
  metadata.FlipDate = '????????';
else
  flip_datenum = cross_datenum + metadata.FlipDays;
  metadata.FlipDate = datestr(flip_datenum,handles.datetimeformat);
end
