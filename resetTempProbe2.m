function handles = resetTempProbe2(handles)

global TempRecordInfo;

if handles.params.DoRecordTemp == 0,
  return;
end

if isfield(handles,'TempProbe_IsInitialized') && handles.TempProbe_IsInitialized,
  try
        
    stop(handles.TempProbe_timer);
    delete(handles.TempProbe_timer);
    handles.TempProbe_IsInitialized = false;
    if handles.params.CoupleCameraTempProbeStart == 0,
      set(handles.pushbutton_InitializeTempProbe,'Visible','on');
    end
    
    if ~isstruct(TempRecordInfo) || ~isfield(TempRecordInfo,'idslistening'),
      warning('TempRecordInfo is not set.');
      return;
    end
    
    idx = find(handles.GUIi == TempRecordInfo.idslistening);
    if numel(idx) ~= 1,
      warning('Number of times idslistening matches GUIi %d = %d, should be 1.',handles.GUIi,numel(idx));
    end
    TempRecordInfo.idslistening(idx) = [];
        
    if isempty(TempRecordInfo.idslistening),
      addToStatus(handles,'No more GUIs listening to temperature stream, stopping.');
    
      OldTempRecordInfo = TempRecordInfo;
      TempRecordInfo = [];
      
      % close the probe
      ok = calllib('usbtc08','usb_tc08_close_unit',OldTempRecordInfo.tc08_handles);
      if ok == 0,
        last_error=calllib('usbtc08','usb_tc08_get_last_error',OldTempRecordInfo.tc08_handles);
        [errname,errstr] = USBTC08_error_table(last_error);
        warning('Stop(%s): Error %s: %s\n',datestr(now,13),errname,errstr);
      end
      
    else
      
      addToStatus(handles,'Other GUIs are accessing the USB temperature probe, leaving it running.');
      
    end
    
    handles.TempProbe_IsInitialized = false;
    
  catch ME,
    uiwait(warndlg({'Error stopping temperature probe.',getReport(ME)},'Error stopping temperature probe'));
  end
end
