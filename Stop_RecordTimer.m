function Stop_RecordTimer(obj, event, vid, hObject, AdaptorName) %#ok<INUSL>

if strcmpi(AdaptorName,'gdcam'),
  set(vid.Source,'LogFlag',0);
end

stop(vid);
