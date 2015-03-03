function Stop_RecordTimer(obj, event, vid, hObject, AdaptorName) %#ok<INUSL>

% last parameter: we did not abort
wrapUpVideo(vid,event,hObject,AdaptorName,false);
