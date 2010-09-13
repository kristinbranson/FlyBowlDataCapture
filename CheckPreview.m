function CheckPreview(obj,event,params)

lastupdate = getappdata(params.hImage_Preview,'LastPreviewUpdateTime');
if isinf(lastupdate), return; end
dt = (now - lastupdate)*86400;
%disp(dt);
if dt > params.MaxPreviewUpdatePeriod,
  handles = guidata(params.figure_main);
  if strcmp(get(handles.vid,'Previewing'),'off'),
    return;
  end
  stoppreview(handles.vid);
  preview(handles.vid,params.hImage_Preview);
end