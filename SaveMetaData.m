function handles = SaveMetaData(handles)

% construct experiment name, directory
handles = setExperimentName(handles);

% open meta data file
fid = fopen(handles.MetaDataFileName,'w');
if fid < 0,
  s = sprintf('Could not write to experiment metadata file %s',handles.MetaDataFileName);
  uiwait(errordlg(s,'Error saving metadata'));
  error(s); %#ok<SPERR>
end

% in hours
sorting_time = (handles.StartRecording_Time_datenum - handles.PreAssayHandling_SortingTime_datenum)*24;
starvation_time = (handles.StartRecording_Time_datenum - handles.PreAssayHandling_StarvationTime_datenum)*24;
% in seconds
shift_time = (handles.StartRecording_Time_datenum - handles.ShiftFlyTemp_Time_datenum)*24*60*60;
load_time = (handles.StartRecording_Time_datenum - handles.FliesLoaded_Time_datenum)*24*60*60;

% write the main metadata file
fprintf(fid,'<?xml version="1.0"?>\n');
% name of assay
fprintf(fid,'<experiment assay="%s" ',handles.params.MetaData_AssayName);
% start datetime
fprintf(fid,'exp_datetime="%s" ',datestr(handles.StartRecording_Time_datenum,'yyyy-mm-ddTHH:MM:SS'));
% name of experimenter
fprintf(fid,'experimenter="%s" ',handles.Assay_Experimenter);
% always same experiment protocol
fprintf(fid,'protocol="%s" ',handles.params.MetaData_ExpProtocols{1});
fprintf(fid,'>\n');

% session container
fprintf(fid,'  <session id="1">\n');

% unique id for this apparatus, composed of all the parts
apparatusUniqueName = sprintf('Rig%s__Plate%s__Lid%s__Bowl%s__Camera%s__Computer%s__HardDrive%s',...
  handles.Assay_Rig,handles.Assay_Plate,handles.Assay_Lid,handles.Assay_Bowl,...
  handles.CameraUniqueID,handles.ComputerName,handles.params.HardDriveName);
% apparatus full id and parts
fprintf(fid,'    <apparatus id="%s" environmental_chamber="%s" rig="%s" plate="%s" top_plate="%s" bowl="%s" camera="%s" computer="%s" harddrive="%s"/>\n',...
  apparatusUniqueName,...
  handles.Assay_Room,handles.Assay_Rig,handles.Assay_Plate,handles.Assay_Lid,handles.Assay_Bowl,...
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
fprintf(fid,'cross_date="%s" ',datestr(handles.PreAssayHandling_CrossDate_datenum,'yyyy-mm-dd'));
% hours starved
fprintf(fid,'hours_starved="%f" ',starvation_time);
% count is set to 0 -- won't know this til after tracking
fprintf(fid,'count="0">\n');
% TODO: genotype
fprintf(fid,'      <genotype>%s &amp; w+;;%s</genotype>\n',handles.Fly_LineName,handles.params.MetaData_Effector);

% choose rearing protocol based on incubator ID
i = find(strcmp(handles.Rearing_IncubatorID,handles.Rearing_IncubatorIDs),1);
fprintf(fid,'      <rearing protocol="%s" ',handles.params.MetaData_RearingProtocols{i});
fprintf(fid,'incubator="%s" ',handles.Rearing_IncubatorID);
fprintf(fid,'/>\n');

% always same handling protocol
fprintf(fid,'      <handling protocol="%s" ',handles.params.MetaData_HandlingProtocols{1});
% person who sorted flies
fprintf(fid,'handler_sorting="%s" ',handles.PreAssayHandling_SortingHandler);
% time since sorting, in hours
fprintf(fid,'hours_sorted="%f" ',sorting_time);
% absolute datetime the flies were sorted at
fprintf(fid,'datetime_sorting="%s" ',datestr(handles.PreAssayHandling_SortingTime_datenum,'yyyy-mm-ddTHH:MM:SS'));
% person who moved flies to starvation material
fprintf(fid,'handler_starvation="%s" ',handles.PreAssayHandling_StarvationHandler);
% absolute datetime the flies were moved to starvation material
fprintf(fid,'datetime_starvation="%s" ',datestr(handles.PreAssayHandling_StarvationTime_datenum,'yyyy-mm-ddTHH:MM:SS'));
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
fprintf(fid,'  <note_behavioral>%s</note_behavioral>\n',BehaviorNotes);
% deal with multi-line notes
if iscell(handles.TechnicalNotes),
  TechnicalNotes = handles.TechnicalNotes;
else
  TechnicalNotes = cellstr(handles.TechnicalNotes);
end
TechnicalNotes = sprintf('%s\\n',TechnicalNotes{:});
TechnicalNotes = TechnicalNotes(1:end-2);
fprintf(fid,'  <note_technical>%s</note_technical>\n',TechnicalNotes);
% flags entered
fprintf(fid,'  <flag_review>%s</flag_review>\n',handles.ReviewFlag);
fprintf(fid,'  <flag_redo>%s</flag_redo>\n',handles.RedoFlag);
fprintf(fid,'  <flag_aborted>%d</flag_aborted>\n',handles.didabort);

fprintf(fid,'</experiment>\n');

fclose(fid);

% meta data does not need to be saved now
handles.MetaDataNeedsSave = false;
set(handles.pushbutton_SaveMetaData,'BackgroundColor',handles.grayed_bkgdcolor);

% write to log file
addToStatus(handles,{sprintf('Saved MetaData to file %s.',...
    handles.MetaDataFileName)});

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

