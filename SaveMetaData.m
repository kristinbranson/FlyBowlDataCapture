function handles = SaveMetaData(handles)

% construct experiment name, directory
handles = setExperimentName(handles);

% construct name for main metadata file
handles.MetaDataFileName = fullfile(handles.ExperimentDirectory,handles.params.MetaDataFileName);

% open meta data file
fid = fopen(handles.MetaDataFileName,'w');
if fid < 0,
  s = sprintf('Could not write to experiment metadata file %s',handles.MetaDataFileName);
  uiwait(errordlg(s,'Error saving metadata'));
  error(s);
end

% in days
minage = floor(handles.StartRecording_Time_datenum - handles.PreAssayHandling_DOBEnd_datenum - 1); % -1 is for late in the day births
maxage = ceil(handles.StartRecording_Time_datenum - handles.PreAssayHandling_DOBStart_datenum);
% in hours
sorting_time = (handles.StartRecording_Time_datenum - handles.PreAssayHandling_SortingTime_datenum)*24;
starvation_time = (handles.StartRecording_Time_datenum - handles.PreAssayHandling_StarvationTime_datenum)*24;
% in seconds
shift_time = (handles.StartRecording_Time_datenum - handles.ShiftFlyTemp_Time_datenum)*24*60*60;
load_time = (handles.StartRecording_Time_datenum - handles.FliesLoaded_Time_datenum)*24*60*60;

% write the main metadata file
fprintf(fid,'<?xml version="1.0"?>\n');
fprintf(fid,'<experiment assay="%s" ',handles.params.MetaData_AssayName);
% always same experiment protocol
fprintf(fid,'protocol="%s" ',handles.params.MetaData_ExpProtocols{1});
fprintf(fid,'datetime="%s" ',datestr(handles.StartRecording_Time_datenum,'yyyy-mm-ddTHH:MM:SS'));
fprintf(fid,'experimenter="%s" ',handles.Assay_Experimenter);
fprintf(fid,'shiftflytemp_time="%f" ',shift_time);
fprintf(fid,'fliesloaded_time="%f" ',load_time);
fprintf(fid,'>\n');

fprintf(fid,'  <apparatus type="rig" id="%s">\n',handles.Assay_Rig);
fprintf(fid,'    <apparatus type="plate" id="%s">\n',handles.Assay_Plate);
fprintf(fid,'      <apparatus type="bowl" id="%s">\n',handles.Assay_Bowl);

fprintf(fid,'        <flies line="%s" ',handles.Fly_LineName);
fprintf(fid,'effector="%s" ',handles.params.MetaData_Effector);
fprintf(fid,'cross-date="%s" ',datestr(handles.PreAssayHandling_CrossDate_datenum,'yyyy-mm-dd'));
fprintf(fid,'age="%f,%f" ',minage,maxage);
% count is set to 0 -- won't know this til after tracking
fprintf(fid,'count="0">\n');

% choose rearing protocol based on activity peak time
i = find(strcmp(handles.Rearing_ActivityPeak,handles.Rearing_ActivityPeaks),1);
fprintf(fid,'          <rearing_protocol="%s" ',handles.params.MetaData_RearingProtocols{i});
fprintf(fid,'incubator="%s" ',handles.Rearing_IncubatorID);
% i = find(strcmp(handles.Rearing_ActivityPeak,handles.Rearing_ActivityPeaks),1);
% fprintf(fid,'lightson="%s" ',handles.params.Rearing_LightsOns{i});
% fprintf(fid,'lightsoff="%s" ',handles.params.Rearing_LightsOffs{i});
fprintf(fid,'/>\n');

% always same sorting protocol
fprintf(fid,'          <handling_protocol="%s" ',handles.params.MetaData_SortingHandlingProtocols{1});
fprintf(fid,'type="sorting" ');
fprintf(fid,'handler="%s" ',handles.PreAssayHandling_SortingHandler);
fprintf(fid,'time="%f" ',sorting_time);
fprintf(fid,'/>\n');

% always same starvation protocol
fprintf(fid,'          <handling_protocol="%s" ',handles.params.MetaData_StarvationHandlingProtocols{1});
fprintf(fid,'type="starvation" ');
fprintf(fid,'handler="%s" ',handles.PreAssayHandling_StarvationHandler);
fprintf(fid,'time="%f" ',starvation_time);
fprintf(fid,'/>\n');

fprintf(fid,'        </flies>\n');
fprintf(fid,'        <environment temperature="%f" ',handles.MetaData_RoomTemperature);
fprintf(fid,'humidity="%f" />\n',handles.MetaData_RoomHumidity);
tmp = strtrim(handles.BehaviorNotes);
if ~isempty(tmp) && ~strcmpi(tmp,'None'),
  fprintf(fid,'        <note type="behavioral"> %s </note>\n',handles.BehaviorNotes);
end
tmp = strtrim(handles.TechnicalNotes);
if ~isempty(tmp) && ~strcmpi(tmp,'None'),
  fprintf(fid,'        <note type="technical"> %s </note>\n',handles.TechnicalNotes);
end
% no other note right now
%fprintf(fid,'        <note type="other"> </note>\n');
if ~strcmpi(handles.ReviewFlag,'None'),
  fprintf(fid,'        <flag type="review" reason="%s"/>\n',upper(handles.ReviewFlag));
end
if ~strcmpi(handles.RedoFlag,'None'),
  fprintf(fid,'        <flag type="redo" reason="%s"/>\n',upper(handles.RedoFlag));
end
fprintf(fid,'      </apparatus>\n');
fprintf(fid,'    </apparatus>\n');
fprintf(fid,'  </apparatus>\n');
fprintf(fid,'</experiment>\n');

fclose(fid);

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

