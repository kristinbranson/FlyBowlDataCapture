function handles = RecordConfiguration(handles)

if exist(handles.rcfile,'file'),
  rc = load(handles.rcfile);
else
  rc = struct;
end
GUIi = handles.GUIi;

% convert absolute dates to offsets from now
handles.PreAssayHandling_CrossDateOff = floor(handles.now) - handles.PreAssayHandling_CrossDate_datenum;
handles.PreAssayHandling_DOBStartOff = floor(handles.now) - handles.PreAssayHandling_DOBStart_datenum;
handles.PreAssayHandling_DOBEndOff = floor(handles.now) - handles.PreAssayHandling_DOBEnd_datenum;
handles.PreAssayHandling_SortingDateOff = floor(handles.now) - handles.PreAssayHandling_SortingDate_datenum;
handles.PreAssayHandling_StarvationDateOff = floor(handles.now) - handles.PreAssayHandling_StarvationDate_datenum;

% get current figure position
handles.FigurePosition = get(handles.figure_main,'Position');

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
  'FigurePosition'
  };
for i = 1:length(fns),
  fn = fns{i};
  if ~isfield(handles,fn),
    continue;
  end
  if ismember(fn,handles.GUIInstance_prev),
    if ~isfield(rc,fn),
      rc.(fn) = {};
    end
    if ~iscell(rc.(fn)),
      rc.(fn) = {rc.(fn)};
    end
    for j = length(rc.(fn))+1:GUIi,
      rc.(fn){i} = handles.(fn);
    end
  else
    rc.(fn) = handles.(fn);
  end
  
end

fnsmissing = setdiff(fns,fieldnames(rc));
if ~isempty(fnsmissing),
  warning('Missing previous value: %s.\n',fnsmissing{:}); %#ok<WNTAG>
end
fns = setdiff(fns,fnsmissing);
save(handles.rcfile,'-struct','handles',fns{:});