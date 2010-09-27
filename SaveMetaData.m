function handles = SaveMetaData(handles)

% construct experiment name, directory
handles = setExperimentName(handles);

% open meta data file
fid = fopen(handles.MetaDataFileName,'w');
if fid < 0,
  s = sprintf('Could not write to experiment metadata file %s',handles.MetaDataFileName);
  uiwait(errordlg(s,'Error saving metadata'));
  error(s);
end

% in hours
sorting_time = (handles.StartRecording_Time_datenum - handles.PreAssayHandling_SortingTime_datenum)*24;
starvation_time = (handles.StartRecording_Time_datenum - handles.PreAssayHandling_StarvationTime_datenum)*24;
% in seconds
shift_time = (handles.StartRecording_Time_datenum - handles.ShiftFlyTemp_Time_datenum)*24*60*60;
load_time = (handles.StartRecording_Time_datenum - handles.FliesLoaded_Time_datenum)*24*60*60;

% was the experiment aborted
didabort = ~handles.FinishedRecording;

% write the main metadata file
fprintf(fid,'<?xml version="1.0"?>\n');
fprintf(fid,'<experiment assay="%s" ',handles.params.MetaData_AssayName);
% always same experiment protocol
fprintf(fid,'protocol="%s" ',handles.params.MetaData_ExpProtocols{1});
fprintf(fid,'exp_datetime="%s" ',datestr(handles.StartRecording_Time_datenum,'yyyy-mm-ddTHH:MM:SS'));
fprintf(fid,'aborted="%d" ',didabort);
fprintf(fid,'experimenter="%s" ',handles.Assay_Experimenter);
fprintf(fid,'shiftflytemp_time="%f" ',shift_time);
fprintf(fid,'fliesloaded_time="%f" ',load_time);
fprintf(fid,'>\n');

fprintf(fid,'  <apparatus rig_id="%s" plate_id="%s" bowl_id="%s">\n',handles.Assay_Rig,handles.Assay_Plate,handles.Assay_Bowl);
fprintf(fid,'    <camera adaptor="%s" device_name="%s" format="%s" device_id="%d" unique_id="%s" />\n',...
  handles.params.Imaq_Adaptor,...
  handles.params.Imaq_DeviceName,...
  handles.params.Imaq_VideoFormat,...
  handles.DeviceID,...
  handles.CameraUniqueID);
fprintf(fid,'    <computer id="%s" harddrive_id="%s" output_directory="%s"/>\n',handles.ComputerName,handles.params.HardDriveName,handles.params.OutputDirectory);
fprintf(fid,'    <flies line="%s" ',handles.Fly_LineName);
fprintf(fid,'effector="%s" ',handles.params.MetaData_Effector);
fprintf(fid,'gender="%s" ',handles.params.MetaData_Gender); 
fprintf(fid,'cross_date="%s" ',datestr(handles.PreAssayHandling_CrossDate_datenum,'yyyy-mm-dd'));
fprintf(fid,'hours_starved="%f" ',starvation_time);
% count is set to 0 -- won't know this til after tracking
fprintf(fid,'count="0">\n');

% choose rearing protocol based on incubator ID
i = find(strcmp(handles.Rearing_IncubatorID,handles.Rearing_IncubatorIDs),1);
fprintf(fid,'      <rearing protocol="%s" ',handles.params.MetaData_RearingProtocols{i});
fprintf(fid,'incubator="%s" ',handles.Rearing_IncubatorID);
fprintf(fid,'/>\n');

% always same sorting protocol
fprintf(fid,'      <handling type="sorting" protocol="%s" ',handles.params.MetaData_SortingHandlingProtocols{1});
fprintf(fid,'handler="%s" ',handles.PreAssayHandling_SortingHandler);
fprintf(fid,'time="%f" ',sorting_time);
fprintf(fid,'datetime="%s" ',datestr(handles.PreAssayHandling_SortingTime_datenum,'yyyy-mm-ddTHH:MM:SS'));
fprintf(fid,'/>\n');

% always same starvation protocol
fprintf(fid,'      <handling type="starvation" protocol="%s" ',handles.params.MetaData_StarvationHandlingProtocols{1});
fprintf(fid,'handler="%s" ',handles.PreAssayHandling_StarvationHandler);
fprintf(fid,'datetime="%s" ',datestr(handles.PreAssayHandling_StarvationTime_datenum,'yyyy-mm-ddTHH:MM:SS'));
fprintf(fid,'/>\n');

fprintf(fid,'    </flies>\n');
fprintf(fid,'    <environment temperature="%f" ',handles.MetaData_RoomTemperature);
fprintf(fid,'humidity="%f" />\n',handles.MetaData_RoomHumidity);
fprintf(fid,'    <note type="behavioral">%s</note>\n',handles.BehaviorNotes);
fprintf(fid,'    <note type="technical">%s</note>\n',handles.TechnicalNotes);
% no other note right now
%fprintf(fid,'        <note type="other"> </note>\n');
if ~strcmpi(handles.ReviewFlag,'None'),
  fprintf(fid,'    <flag type="review" reason="%s"/>\n',upper(handles.ReviewFlag));
end
if ~strcmpi(handles.RedoFlag,'None'),
  fprintf(fid,'    <flag type="redo" reason="%s"/>\n',upper(handles.RedoFlag));
end
fprintf(fid,'  </apparatus>\n');
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

