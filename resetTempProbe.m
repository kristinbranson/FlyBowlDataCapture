function handles = resetTempProbe(handles)

if handles.params.DoRecordTemp == 0,
  return;
end

if isfield(handles,'TempProbe_IsInitialized') && handles.TempProbe_IsInitialized,
  try
    stop(handles.TempProbe_timer);
    delete(handles.TempProbe_timer);
    handles.TempProbe_IsInitialized = false;
    handles.Status_Temp_History(:) = nan;
    set(handles.hLine_Status_Temp,'XData',handles.Status_Temp_History(1,:),...
      'YData',handles.Status_Temp_History(2,:));
    set(handles.pushbutton_InitializeTempProbe,'Visible','on');
  catch ME,
    uiwait(warndlg({'Error stopping temperature probe.',getReport(ME)},'Error stopping temperature probe'));
  end
end
