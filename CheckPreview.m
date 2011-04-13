function CheckPreview(obj,event,params)

% stop if we've halted
global FBDC_DIDHALT;
if ~isempty(FBDC_DIDHALT) && FBDC_DIDHALT,
  try
    if strcmpi(get(obj,'Running'),'on'),
      stop(obj);
    end
  catch ME
    getReport(ME)
  end
end

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