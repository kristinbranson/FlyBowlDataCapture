function handles = SaveMetaData(handles)

% construct name for main metadata file
filestr = sprintf('ExperimentMetadata_%s_Rig%sPlate%sBowl%s_%s.xml',handles.Fly_LineName,...
  handles.Assay_Rig,handles.Assay_Plate,handles.Assay_Bowl,...
  datestr(handles.StartRecording_Time_datenum,30));
handles.MetaDataFileName = fullfile(handles.params.OutputDirectory,filestr);

fid = fopen(handles.MetaDataFileName,'w');
if fid < 0,
  s = sprintf('Could not write to experiment metadata file %s',handles.MetaDataFileName);
  uiwait(errordlg(s,'Error saving metadata'));
  error(s);
end

% write the main metadata file
fprintf(fid,'<?xml version="1.0"?>\n');
fprintf(fid,'<experiment assay="%s" ',handles.params.MetaData_AssayName);
% always same experiment protocol
fprintf(fid,'protocol="%s" ',handles.params.MetaData_ExpProtocols{1});
fprintf(fid,'datetime="%s" ',datestr(handles.StartRecording_Time_datenum,'yyyy-mm-ddTHH:MM:SS'));
fprintf(fid,'experimenter="%s">\n',handles.Assay_Experimenter);
fprintf(fid,'\t<flies line="%s" ',handles.Fly_LineName);
fprintf(fid,'effector="%s" ',handles.params.MetaData_Effector);
% TODO: need to input Cross Date
fprintf(fid,'cross-date="%s" ',handles.PreAssayHandling_DOBEnd);
% count is set to 0 -- won't know this til after tracking
fprintf(fid,'count="0">\n');
% choose rearing protocol based on activity peak time
i = find(strcmp(handles.Rearing_ActivityPeak,handles.Rearing_ActivityPeaks),1);
fprintf(fid,'\t\t<rearing protocol="%s" ',handles.params.MetaData_RearingProtocols{i});
fprintf(fid,'incubator="%s" />\n',handles.Rearing_IncubatorID);
% always handling same protocol
fprintf(fid,'\t\t<handling protocol="%s" ',handles.params.MetaData_HandlingProtocols{1});
fprintf(fid,'handler="%s" />\n',handles.PreAssayHandling_SortingHandler);
fprintf(fid,'\t</flies>\n');
fprintf(fid,'\t<environment temperature="%f" ',handles.MetaData_RoomTemperature);
fprintf(fid,'humidity="%f" />\n',handles.MetaData_RoomHumidity);
fprintf(fid,'\t<note type="behavioral"> %s </note>\n',handles.BehaviorNotes);
fprintf(fid,'\t<note type="technical"> %s </note>\n',handles.TechnicalNotes);
% TODO: no other note right now
fprintf(fid,'\t<note type="other"> </note>\n');
% TODO: no flags right now
%fprintf(fid,'\t<flag type="review" />\n');
%fprintf(fid,'\t<flag type="redo" />\n');
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

