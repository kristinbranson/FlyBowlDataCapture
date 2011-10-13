function [handles,success] = SaveMetaData(handles)

success = true;

% construct experiment name, directory
[handles,success1] = setExperimentName(handles);
if ~success1,
  addToStatus(handles,'Failed to set experiment name. Aborting SaveMetaData.');
  success = false;
end

% back up metadata file if it exists
if exist(handles.MetaDataFileName,'file'),
  bakfilename = [handles.MetaDataFileName,'.bak'];
  addToStatus(handles,sprintf('Copying metadata file to backup %s',bakfilename));
  [success1,msg] = copyfile(handles.MetaDataFileName,bakfilename);
  if ~success1,
    warndlg(msg,'Error backing up metadatafile, aborting SaveMetaData','modal');
    success = false;
    return;
  end
end
  
% open meta data file
fid = fopen(handles.MetaDataFileName,'w');
if fid < 0,
  s = sprintf('Could not write to experiment metadata file %s',handles.MetaDataFileName);
  uiwait(errordlg(s,'Error saving metadata'));
  error(s); %#ok<SPERR>
end

% in hours
sorting_time = (handles.StartRecording_Time_datenum - handles.PreAssayHandling_SortingTime_datenum)*24;
% unknown sorting time
if isnan(sorting_time),
  sorting_time = -1;
elseif sorting_time < 0,
  addToStatus(handles,'Hours sorted is negative. Storing as unknown.');
  warndlg('Hours sorted is negative. Storing as unknown','Metadata Warning');
  sorting_time = -1;
end
starvation_time = (handles.StartRecording_Time_datenum - handles.PreAssayHandling_StarvationTime_datenum)*24;
% unknown starvation time
if isnan(starvation_time),
  starvation_time = -1;
elseif starvation_time < 0,
  addToStatus(handles,'Hours starved is negative. Storing as 0.');
  starvation_time = 0;
end

% in seconds
shift_time = (handles.StartRecording_Time_datenum - handles.ShiftFlyTemp_Time_datenum)*24*60*60;
load_time = (handles.StartRecording_Time_datenum - handles.FliesLoaded_Time_datenum)*24*60*60;

% write the main metadata file
fprintf(fid,'<?xml version="1.0"?>\n');
% name of assay
fprintf(fid,'<experiment assay="%s" ',handles.params.MetaData_AssayName);
% start datetime
fprintf(fid,'exp_datetime="%s" ',datestr(handles.StartRecording_Time_datenum,handles.datetimeformat));
% name of experimenter
fprintf(fid,'experimenter="%s" ',handles.Assay_Experimenter);
% always same experiment protocol
fprintf(fid,'protocol="%s" ',handles.params.MetaData_ExpProtocols{1});
% screen type
if isfield(handles.params,'ScreenType'),
  ScreenType = handles.params.ScreenType;
else
  ScreenType = 'primary';
end
fprintf(fid,'screen_type="%s" ',ScreenType);
% screen reason
if isfield(handles.params,'ScreenReason'),
  ScreenReason = handles.params.ScreenReason;
else
  ScreenReason = 'standard';
end
% set to control if it is a control fly
if isfield(handles.params,'ControlLineNames'),
  if ismember(handles.Fly_LineName,handles.params.ControlLineNames),
    ScreenReason = 'control';
  end
end
fprintf(fid,'screen_reason="%s" ',ScreenReason);
% data capture code version
fprintf(fid,'data_capture_version="%s" ',handles.version);

fprintf(fid,'>\n');

% session container
fprintf(fid,'  <session id="1">\n');

% unique id for this apparatus, composed of all the parts
apparatusUniqueName = sprintf('Rig%s__Plate%s__Lid%s__Bowl%s__Camera%s__Computer%s__HardDrive%s',...
  handles.Assay_Rig,handles.Assay_Plate,handles.Assay_Lid,handles.Assay_Bowl,...
  handles.CameraUniqueID,handles.ComputerName,handles.params.HardDriveName);
% apparatus full id and parts
fprintf(fid,'    <apparatus apparatus_id="%s" room="%s" rig="%s" plate="%s" top_plate="%s" visual_surround="%s" bowl="%s" camera="%s" computer="%s" harddrive="%s"/>\n',...
  apparatusUniqueName,...
  handles.Assay_Room,handles.Assay_Rig,handles.Assay_Plate,handles.Assay_Lid,handles.Assay_VisualSurround,handles.Assay_Bowl,...
  handles.CameraUniqueID,...
  handles.ComputerName,...
  handles.params.HardDriveName);
% line name
fprintf(fid,'    <flies line="%s" ',handles.Fly_LineName);
% effector
fprintf(fid,'effector="%s" ',handles.params.MetaData_Effector);
% gender
fprintf(fid,'gender="%s" ',handles.params.MetaData_Gender); 
% cross date
fprintf(fid,'cross_date="%s" ',datestr(handles.PreAssayHandling_CrossDate_datenum,handles.datetimeformat));
% flip_date
if ~isfield(handles.params,'flip_days'),
  warning('flipdays not input. Not storing flip_date.');
else
  flip_datenum = handles.PreAssayHandling_CrossDate_datenum + handles.params.flip_days;
  handles.flip_date = datestr(flip_datenum,handles.datetimeformat);
  fprintf(fid,'flip_date="%s" ',handles.flip_date);
end

% hours starved
fprintf(fid,'hours_starved="%f" ',starvation_time);
% barcode
fprintf(fid,'cross_barcode="%d" ',handles.barcode);
% flip
fprintf(fid,'flip_used="%d" ',handles.params.PreAssayHandling_FlipUsed);
% wish list
fprintf(fid,'wish_list="%d" ',handles.WishList);
% robot stock copy. set this to unknown for now
fprintf(fid,'robot_stock_copy="%s" ',handles.RobotID);
% count is set to 0 -- won't know this til after tracking
fprintf(fid,'num_flies="0">\n');

% no longer recording genotype
%fprintf(fid,'      <genotype>%s &amp; w+;;%s</genotype>\n',handles.Fly_LineName,handles.params.MetaData_Effector);
%fprintf(fid,'      <genotype>%s__%s</genotype>\n',handles.Fly_LineName,handles.params.MetaData_Effector);

% choose rearing protocol based on incubator ID
i = find(strcmp(handles.Rearing_IncubatorID,handles.Rearing_IncubatorIDs),1);
fprintf(fid,'      <rearing rearing_protocol="%s" ',handles.params.MetaData_RearingProtocols{i});
fprintf(fid,'rearing_incubator="%s" ',handles.Rearing_IncubatorID);
fprintf(fid,'/>\n');

% always same handling protocol
fprintf(fid,'      <handling handling_protocol="%s" ',handles.params.MetaData_HandlingProtocols{1});
% person who crossed flies
fprintf(fid,'handler_cross="%s" ',handles.PreAssayHandling_CrossHandler);
% person who sorted flies
fprintf(fid,'handler_sorting="%s" ',handles.PreAssayHandling_SortingHandler);
% time since sorting, in hours
fprintf(fid,'hours_sorted="%f" ',sorting_time);
% absolute datetime the flies were sorted at
% handle missing sorting time
if isnan(handles.PreAssayHandling_SortingTime_datenum),
  s = [datestr(handles.PreAssayHandling_SortingDate_datenum,'yyyymmdd'),'T999999'];
else
  s = datestr(handles.PreAssayHandling_SortingTime_datenum,'yyyymmddTHHMMSS');
end
fprintf(fid,'datetime_sorting="%s" ',s);
% person who moved flies to starvation material
fprintf(fid,'handler_starvation="%s" ',handles.PreAssayHandling_StarvationHandler);
% absolute datetime the flies were moved to starvation material
% handle missing starvation time
if isnan(handles.PreAssayHandling_SortingTime_datenum),
  s = [datestr(handles.PreAssayHandling_StarvationDate_datenum,'yyyymmdd'),'T999999'];
else
  s = datestr(handles.PreAssayHandling_StarvationTime_datenum,'yyyymmddTHHMMSS');
end
fprintf(fid,'datetime_starvation="%s" ',s);
% seconds between bringing vials into hot temperature environment and
% experiment start
fprintf(fid,'seconds_shiftflytemp="%f" ',shift_time);
% seconds between loading flies into arena and experiment start
fprintf(fid,'seconds_fliesloaded="%f" ',load_time);
% number of observed dead flies
fprintf(fid,'num_flies_dead="%d" ',handles.NDeadFlies);
% number of observed damaged flies
fprintf(fid,'num_flies_damaged="%d" ',handles.NDamagedFlies);
fprintf(fid,'/>\n');
fprintf(fid,'    </flies>\n');
fprintf(fid,'  </session>\n');
% temperature and humidity measured from precon sensor
fprintf(fid,'  <environment temperature="%f" ',handles.MetaData_RoomTemperature);
fprintf(fid,'humidity="%f" />\n',handles.MetaData_RoomHumidity);
% notes entered
% deal with multi-line notes
if iscell(handles.BehaviorNotes),
  BehaviorNotes = handles.BehaviorNotes;
else
  BehaviorNotes = cellstr(handles.BehaviorNotes);
end
BehaviorNotes = sprintf('%s\\n',BehaviorNotes{:});
BehaviorNotes = BehaviorNotes(1:end-2);
fprintf(fid,'  <notes_behavioral>%s</notes_behavioral>\n',BehaviorNotes);
% deal with multi-line notes
if iscell(handles.TechnicalNotes),
  TechnicalNotes = handles.TechnicalNotes;
else
  TechnicalNotes = cellstr(handles.TechnicalNotes);
end
TechnicalNotes = sprintf('%s\\n',TechnicalNotes{:});
TechnicalNotes = TechnicalNotes(1:end-2);
fprintf(fid,'  <notes_technical>%s</notes_technical>\n',TechnicalNotes);
fprintf(fid,'  <notes_keyword></notes_keyword>\n');
% flags entered
fprintf(fid,'  <flag_review>%d</flag_review>\n',strcmpi(handles.Flag,'Review'));
fprintf(fid,'  <flag_redo>%d</flag_redo>\n',strcmpi(handles.Flag,'Redo'));
fprintf(fid,'  <flag_aborted>%d</flag_aborted>\n',handles.didabort);
fprintf(fid,'  <flag_legacy>0</flag_legacy>\n');

fprintf(fid,'</experiment>\n');

fclose(fid);

% meta data does not need to be saved now
if success,
  handles.MetaDataNeedsSave = false;
  set(handles.pushbutton_SaveMetaData,'BackgroundColor',handles.grayed_bkgdcolor);
  % write to log file
  addToStatus(handles,{sprintf('Saved MetaData to file %s.',...
    handles.MetaDataFileName)});
else
  addToStatus(handles,'Some errors encountered saving metadata to file');
end


% % write the extra metadata file
% filestr = sprintf('ExtraMetadata_%s_Rig%sPlate%sBowl%s_%s.xml',handles.Fly_LineName,...
%   handles.Assay_Rig,handles.Assay_Plate,handles.Assay_Bowl,...
%   datestr(handles.StartRecording_Time_datenum,30));
% handles.ExtraMetaDataFileName = fullfile(handles.params.OutputDirectory,filestr);
% fid = fopen(handles.ExtraMetaDataFileName,'w');
% if fid < 0,
%   s = sprintf('Could not write to extra metadata file %s',handles.ExtraMetaDataFileName);
%   uiwait(errordlg(s,'Error saving extra metadata'));
%   error(s);
% end

