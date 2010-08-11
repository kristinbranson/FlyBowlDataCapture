function success = initializeTempProbe(hObject)

global FBDC_tc08_handle;
success = false;

handles = guidata(hObject);

handles.TempProbe_NChannelsTotal = 8;
handles.TempProbe_Channels = handles.TempProbeIDs;

% load the TC08 dll library
if ~libisloaded('usbtc08'),
  loadlibrary('usbtc08.dll', 'usbtc08.h');
end

% open device
handles.TempProbe_tc08_handle=calllib('usbtc08','usb_tc08_open_unit');
FBDC_tc08_handle = handles.TempProbe_tc08_handle;
if handles.TempProbe_tc08_handle == 0,
  % if no devices remain, try closing a unit to see if it is open somewhere
  % else
  try
    ok=calllib('usbtc08','usb_tc08_close_unit',1);
    if ok,
      handles.TempProbe_tc08_handle=calllib('usbtc08','usb_tc08_open_unit');
    end
  catch
  end
end

if handles.TempProbe_tc08_handle<=0
  last_error=calllib('usbtc08','usb_tc08_get_last_error',0);
  if handles.TempProbe_tc08_handle == 0,
    handles = addToStatus(handles,{'Error calling usb_tc08_open_unit:','No more units were found.'});
  else
    [errname,errstr] = error_table(last_error);
    handles = addToStatus(handles,{sprintf('Error %s calling usb_tc08_open_unit. Unit failed to open:',errname),errstr});
  end
  ok=calllib('usbtc08','usb_tc08_close_unit',handles.TempProbe_tc08_handle); 
  return;
else
  handles = addToStatus(handles,'Connected to TC-08 temperature probe.');
end

% set the USB TC-08 to reject either 50 or 60 Hz
ok=calllib('usbtc08','usb_tc08_set_mains',handles.TempProbe_tc08_handle,int16(handles.params.TempProbeReject60Hz));
if ok==0
  last_error=calllib('usbtc08','usb_tc08_get_last_error',handles.TempProbe_tc08_handle);
  [errname,errstr] = error_table(last_error);
  handles = addToStatus(handles,{sprintf('Error %s calling usb_tc08_set_mains(reject_60_hz=%d):',errname,handles.params.TempProbeReject60Hz),errstr});
  ok=calllib('usbtc08','usb_tc08_close_unit',handles.TempProbe_tc08_handle); 
  return;
end

% Specifies what type of thermocouple is connected to this
% channel. Set to one of the following characters: 'B', 'E', 'J',
% 'K', 'N', 'R', 'S', 'T.' Use a space in quotes to disable the
% channel. Voltage readings can be obtained by passing 'X' as
% the character.
handles.TempProbe_ChannelIsSet = false(1,handles.TempProbe_NChannelsTotal);
for i = 1:handles.TempProbe_NChannelsTotal,
  j = find(i == handles.TempProbe_Channels,1);
  if ~isempty(j),
    handles.TempProbe_ChannelIsSet(i)=calllib('usbtc08','usb_tc08_set_channel', handles.TempProbe_tc08_handle,int16(i),int8(handles.params.TempProbeTypes{j}(1)));
    if handles.TempProbe_ChannelIsSet(i) == 0,
      last_error=calllib('usbtc08','usb_tc08_get_last_error',handles.TempProbe_tc08_handle);
      [errname,errstr] = error_table(last_error);
      handles = addToStatus(handles,{sprintf('Error %s calling usb_tc08_set_channel(%d,%s):',errname,i,handles.params.TempProbeTypes{j}),errstr});
    end
  else
    handles.TempProbe_ChannelIsSet(i)=calllib('usbtc08','usb_tc08_set_channel', handles.TempProbe_tc08_handle,int16(i),int8(' '));
  end
end

% get code for specifying temperature units
handles.TempProbe_UnitsCode = temp_units_code('centigrade');

% allocate pointers for storing temp and overflow
handles.TempProbe_BufferLength = 10;
temp = zeros(1,handles.TempProbe_BufferLength);
overflow = int16(0);
times_ms = int32(zeros(1,handles.TempProbe_BufferLength));
handles.TempProbe_tempp = libpointer('singlePtr',temp);
handles.TempProbe_overflowp = libpointer('int16Ptr',overflow);
handles.TempProbe_times_msp = libpointer('int32Ptr',times_ms);
handles.TempProbe_fill_missing = 0;

handles.TempProbe_timer=timer('ExecutionMode','FixedRate','Period',handles.params.TempProbePeriod,...
  'TimerFcn',@timer_function,'StartDelay',1,...
  'ErrorFcn',@tc08_stop,'Name','FBDC_USBTC08_Timer','StopFcn',@tc08_stop);

handles.TempProbe_IsInitialized = true;

guidata(handles.figure_main,handles);

calllib('usbtc08','usb_tc08_run',handles.TempProbe_tc08_handle,...
  handles.params.TempProbePeriod*1000);

start(handles.TempProbe_timer);

success = true;

  function tc08_stop(varargin)
    
    ok=calllib('usbtc08','usb_tc08_close_unit',handles.TempProbe_tc08_handle);
    if ok==0
      last_error=calllib('usbtc08','usb_tc08_get_last_error',handles.TempProbe_tc08_handle);
      [errname,errstr] = error_table(last_error);
      handles = guidata(handles.figure_main);
      handles = addToStatus(handles,sprintf('Error %s calling usb_tc08_close_unit:\n%s\n',errname,errstr));
      guidata(handles.figure_main,handles);
    else
      handles = guidata(handles.figure_main);
      handles = addToStatus(handles,'Stopped collecting temperature data.');
      guidata(handles.figure_main,handles);
    end

  end

  function timer_function(obj,event) %#ok<INUSD>
    
    nreadings = calllib('usbtc08','usb_tc08_get_temp',...
      handles.TempProbe_tc08_handle,...
      handles.TempProbe_tempp,...
      handles.TempProbe_times_msp,...
      int32(handles.TempProbe_BufferLength),...
      handles.TempProbe_overflowp,...
      int16(handles.TempProbeID),...
      int16(handles.TempProbe_UnitsCode),...
      int16(handles.TempProbe_fill_missing));
    if nreadings < 0,
      last_error=calllib('usbtc08','usb_tc08_get_last_error',handles.TempProbe_tc08_handle);
      [errname,errstr] = error_table(last_error);
      handles = guidata(handles.figure_main);
      handles = addToStatus(handles,{sprintf('Error %s calling usb_tc08_get_single:',errname),errstr});
      guidata(handles.figure_main,handles);
      return;
    end
    if nreadings == 0,
      return;
    end
    tempcurr = get(handles.TempProbe_tempp,'Value');
    times_mscurr = get(handles.TempProbe_times_msp,'Value');
    overflowcurr = get(handles.TempProbe_overflowp,'Value');
    tempcurr = tempcurr(1:nreadings);
    times_mscurr = times_mscurr(1:nreadings);
    if overflowcurr ~= 0,
      tempcurr(:) = nan;
    end
    handles = guidata(handles.figure_main);
    handles.Status_Temp_History(:,1:nreadings) = [];
    handles.Status_Temp_History(:,end+1:end+nreadings) = [double(times_mscurr)/1000;double(tempcurr)];
    if overflowcurr ~= 0,
      handles = addToStatus(handles,sprintf('Temp probe channel %d overflowed\n', handles.TempProbeID));
    end
    if handles.IsRecording,
      if ~handles.StartTempRecorded,
        handles = tryRecordStartTemp(handles);
      end
      for ii = 1:nreadings,
        fprintf(handles.TempFid,'%f,%f\n',double(times_mscurr)/1000,double(tempcurr(ii)));
      end
    end
    guidata(handles.figure_main,handles);
    set(handles.hLine_Status_Temp,'XData',handles.Status_Temp_History(1,:)-handles.Status_Temp_History(1,end),...
      'YData',handles.Status_Temp_History(2,:));
    drawnow;
  end

  function [name,str] = error_table(n)
    
    switch n,
      case 0,
        name = 'USBTC08_ERROR_OK';
        str = 'No error occurred.';
      case 1,
        name = 'USBTC08_ERROR_OS_NOT_SUPPORTED';
        str = 'The driver supports Windows XP SP2 and Vista.';
      case 2
        name = 'USBTC08_ERROR_NO_CHANNELS_SET';
        str = 'A call to usb_tc08_set_channel is required.';
      case 3
        name = 'USBTC08_ERROR_INVALID_PARAMETER';
        str = 'One or more of the function arguments were invalid.';
      case 4
        name = 'USBTC08_ERROR_VARIANT_NOT_SUPPORTED';
        str = 'The hardware version is not supported. Download the latest driver.';
      case 5
        name = 'USBTC08_ERROR_INCORRECT_MODE';
        str = 'An incompatible mix of legacy and non-legacy functions wascalled (or usb_tc08_get_single was called while in streaming mode.)';
      case 6
        name = 'USBTC08_ERROR_ENUMERATION_INCOMPLETE';
        str = 'usb_tc08_open_unit_async was called again while a background enumeration was already in progress.';
      otherwise
        name = sprintf('Unknown error %d',n);
        str = '';
    end
    
  end

  function temp_units = temp_units_code(temp_units_str)
    
    switch upper(temp_units_str),
      case 'CENTIGRADE',
        temp_units = 0;
      case 'FAHRENHEIT',
        temp_units = 1;
      case 'KELVIN',
        temp_units = 2;
      case 'RANKINE',
        temp_units = 3;
    end
  end

end