function handles = RecordConfiguration(handles)

hwaitbar = waitbar(0,'Recording configuration');

if exist(handles.rcfile,'file'),
  rc = load(handles.rcfile);
else
  rc = struct;
end
GUIi = handles.GUIi;

waitbar(.1,hwaitbar,'Loaded rc file');

% convert absolute dates to offsets from now
handles.PreAssayHandling_CrossDateOff = floor(handles.now) - handles.PreAssayHandling_CrossDate_datenum;
handles.PreAssayHandling_SortingDateOff = floor(handles.now) - handles.PreAssayHandling_SortingDate_datenum;
handles.PreAssayHandling_StarvationDateOff = floor(handles.now) - handles.PreAssayHandling_StarvationDate_datenum;

% get current figure position
handles.FigurePosition = get(handles.figure_main,'Position');

waitbar(.2,hwaitbar,'Computed offsets, figure position');

fns = {'params_file',...
  'Assay_Experimenter',...
  'Fly_LineName',...
  'Rearing_IncubatorID',...
  'PreAssayHandling_CrossDateOff',...
  'PreAssayHandling_SortingDateOff',...
  'PreAssayHandling_SortingHour',...
  'PreAssayHandling_SortingHandler',...
  'PreAssayHandling_StarvationDateOff',...
  'PreAssayHandling_StarvationHour',...
  'PreAssayHandling_StarvationHandler',...
  'Assay_Room',...
  'Assay_Rig',...
  'Assay_Plate',...
  'Assay_Lid',...
  'Assay_Bowl',...
  'DeviceID',...
  'TempProbeID',...
  'FigurePosition',...
  'linename_file',...
  };

for i = 1:length(fns),
  fn = fns{i};
  waitbar(.2,hwaitbar,sprintf('%d: %s',i,fn));

  if ~isfield(handles,fn),
    continue;
  end
  if ismember(fn,handles.GUIInstance_prev),
    if ~isfield(rc,fn) || numel(rc.(fn)) < GUIi,
      if ~isfield(rc,fn),
        n1 = 1;
      else
        n1 = numel(rc.(fn))+1;
      end
      rc.(fn)(n1:GUIi) = repmat({handles.(fn)},[1,GUIi-n1+1]);
    else
      rc.(fn){GUIi} = handles.(fn);
    end
  else
    rc.(fn) = handles.(fn);
  end
  %uiwait(warndlg(['fns: ',sprintf('%s, ',fns{:})]));
  
end

waitbar(.3,hwaitbar,'Put values in struct');

fnsmissing = setdiff(fns,fieldnames(rc));
if ~isempty(fnsmissing),
  warning('Missing previous value: %s.\n',fnsmissing{:}); %#ok<WNTAG>
end
fns = setdiff(fns,fnsmissing);

waitbar(.4,hwaitbar,sprintf('Checked for missing values, trying to save to %s',handles.rcfile));

save(handles.rcfile,'-struct','rc',fns{:});

delete(hwaitbar);