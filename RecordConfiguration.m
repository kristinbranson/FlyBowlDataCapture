function handles = RecordConfiguration(handles)

% convert absolute dates to offsets from now
handles.PreAssayHandling_CrossDateOff = floor(handles.now) - handles.PreAssayHandling_CrossDate_datenum;
handles.PreAssayHandling_DOBStartOff = floor(handles.now) - handles.PreAssayHandling_DOBStart_datenum;
handles.PreAssayHandling_DOBEndOff = floor(handles.now) - handles.PreAssayHandling_DOBEnd_datenum;
handles.PreAssayHandling_SortingDateOff = floor(handles.now) - handles.PreAssayHandling_SortingDate_datenum;
handles.PreAssayHandling_StarvationDateOff = floor(handles.now) - handles.PreAssayHandling_StarvationDate_datenum;

%working here

% get current figure position
FigurePosition = get(handles.figure_main,'Position');
if ~isfield(handles,'FigurePositionHistory'),
  handles.FigurePositionHistory = {};
end
for i = length(handles.FigurePositionHistory)+1:handles.GUIi,
  handles.FigurePositionHistory{i} = FigurePosition;
end

fns = {
  'params_file'
  'Assay_Experimenter'
  'Fly_LineName'
  'Rearing_ActivityPeak'
  'Rearing_IncubatorID'
  'PreAssayHandling_CrossDateOff'
  'PreAssayHandling_DOBStartOff'
  'PreAssayHandling_DOBEndOff'
  'PreAssayHandling_SortingDateOff'
  'PreAssayHandling_SortingHour'
  'PreAssayHandling_SortingHandler'
  'PreAssayHandling_StarvationDateOff'
  'PreAssayHandling_StarvationHour'
  'PreAssayHandling_StarvationHandler'
  'Assay_Rig'
  'Assay_Plate'
  'Assay_Bowl'
  'DeviceID'
  'TempProbeID'
  'FigurePositionHistory'
  };

handlefns = fieldnames(handles);
fnsmissing = setdiff(fns,handlefns);
if ~isempty(fnsmissing),
  warning('Missing previous value: %s.\n',fnsmissing{:}); %#ok<WNTAG>
end
fns = setdiff(fns,fnsmissing);
save(handles.rcfile,'-struct','handles',fns{:});