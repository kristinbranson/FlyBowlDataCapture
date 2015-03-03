function test_pico(varargin)

nchannels = 8;
[active,ch_type_str,reject_60_hz,sample_period,temp_units_str,maxnsamples] = ...
  myparse(varargin,...
  'active',[],'ch_type_str',{},'reject_60_hz',0,...
  'sample_period',1000,'temp_units_str','centigrade',...
  'maxnsamples',10);
if isempty(ch_type_str) && isempty(active),
  ch_type_str = repmat({'K'},[1,nchannels]);
  active = ones(1,nchannels);
elseif isempty(active),
  nchannels = length(ch_type_str);
  active = ~strcmp(ch_type_str,' ');
elseif isempty(ch_type_str),
  nchannels = length(active);
  ch_type_str = repmat(' ',[1,nchannels]);
  ch_type_str(active~=0) = 'K';
  ch_type_str = num2cell(ch_type_str);
else
  nchannels = length(ch_type_str);
  if nchannels ~= length(active),
    error('Lengths of ch_type_str and active must match');
  end
end

% load the TC08 dll library
if ~libisloaded('usbtc08'),
  loadlibrary('usbtc08.dll', 'usbtc08.h');
end

% open device
tc08_handle=calllib('usbtc08','usb_tc08_open_unit');
if tc08_handle<=0
  last_error=calllib('usbtc08','usb_tc08_get_last_error',0);
  if tc08_handle == 0,
    fprintf('Error calling usb_tc08_open_unit:\n');
    fprintf('No more units were found.\n');
  else
    [errname,errstr] = error_table(last_error);
    fprintf('Error %s calling usb_tc08_open_unit. Unit failed to open:\n%s\n',errname,errstr);
  end
  ok=calllib('usbtc08','usb_tc08_close_unit',tc08_handle); 
  return;
else
  fprintf('TC-08 connected\n')
end

out = nan(1,nchannels);

% set the USB TC-08 to reject either 50 or 60 Hz
ok=calllib('usbtc08','usb_tc08_set_mains',tc08_handle,int16(reject_60_hz));
if ok==0
  last_error=calllib('usbtc08','usb_tc08_get_last_error',tc08_handle);
  [errname,errstr] = error_table(last_error);
  fprintf('Error %s calling usb_tc08_set_mains(reject_60_hz=%d):\n%s\n',reject_60_hz,errname,errstr);
  ok=calllib('usbtc08','usb_tc08_close_unit',tc08_handle); 
  return;
end

% Specifies what type of thermocouple is connected to this
% channel. Set to one of the following characters: 'B', 'E', 'J',
% 'K', 'N', 'R', 'S', 'T.' Use a space in quotes to disable the
% channel. Voltage readings can be obtained by passing 'X' as
% the character.
for i = 1:nchannels,
  if active(i)==0
    out(i)=calllib('usbtc08','usb_tc08_set_channel', tc08_handle,int16(i),int8(' '));
  else
    out(i)=calllib('usbtc08','usb_tc08_set_channel', tc08_handle,int16(i),int8(ch_type_str{i}));
  end
  if out(i)==0
    last_error=calllib('usbtc08','usb_tc08_get_last_error',tc08_handle);
    [errname,errstr] = error_table(last_error);
    fprintf('Error %s calling usb_tc08_set_channel(%d,%s):\n%s\n',i,ch_type_str{i},errname,errstr);
    ok=calllib('usbtc08','usb_tc08_close_unit',tc08_handle); 
  end
end
if ~any(out),
  fprintf('Did not successfully initialize any channel, returning.\n');
  return;
end

% the minimum sampling interval (or fastest millisecond interval)
% that the unit can achieve in its current configuration.
minimum_interval=calllib('usbtc08','usb_tc08_get_minimum_interval_ms',tc08_handle);
if minimum_interval <= 0,
  last_error=calllib('usbtc08','usb_tc08_get_last_error',0);
  [errname,errstr] = error_table(last_error);
  fprintf('Error %s calling usb_tc08_get_minimum_interval_ms:\n%s\n',errname,errstr);
end
if isempty(sample_period),
  sample_period = minimum_interval + 600;
else
  sample_period = max(sample_period,minimum_interval+600);
end

% get code for specifying temperature units
temp_units = temp_units_code(temp_units_str);

% % get device info
% deviceinfo = repmat(int8(' '),[1,512]);
% deviceinfo(end+1) = 0;
% deviceinfop = libpointer('voidPtr',deviceinfo);
% ok=calllib('usbtc08','usb_tc08_get_formatted_info',tc08_handle,deviceinfop,int16(512));
% deviceinfo = get(deviceinfop,'Value');
% fprintf('Device info:\n%s\n',deviceinfo);
% clear deviceinfop;

% create a figure
hfig = figure(1); %#ok<NASGU>
clf;
hold on;
hax = gca;
set(hax,'color','k');
colors = zeros(nchannels+1,3);
colors([true,active~=0],:) = jet(nnz(active)+1);
hplot = nan(1,nchannels+1);
for i = 1:nchannels+1,
  hplot(i) = plot(hax,nan,nan,'.-','color',colors(i,:));
end

% allocate pointers for storing temp and overflow
temp = nan(1,nchannels+1);
overflow = 0;
tempp = libpointer('singlePtr',temp);
overflowp = libpointer('int16Ptr',overflow);

% period for timer in seconds
timer_period=sample_period/1000;
T=timer('ExecutionMode','FixedRate','Period',timer_period,'TimerFcn',@timer_function,...
  'StartDelay',0,'ErrorFcn',@tc08_stop,'Name','USBTC0_Timer','StopFcn',@tc08_stop,...
  'TasksToExecute',maxnsamples);

start(T);

  function tc08_stop(varargin)
    
    ok=calllib('usbtc08','usb_tc08_close_unit',tc08_handle);
    if ok==0
      last_error=calllib('usbtc08','usb_tc08_get_last_error',tc08_handle);
      [errname,errstr] = error_table(last_error);
      fprintf('Error %s calling usb_tc08_close_unit:\n%s\n',errname,errstr);
    else
      fprintf('Stopped collecting data.\n');
    end

  end

  function timer_function(varargin)
    
    [ok,tempcurr,time,overflowarray] = get_single();
    if ok,
      x = get(hplot(1),'xdata');
      x(end+1) = time;
      for ii = 1:nchannels+1,
        if overflowarray(ii),
          fprintf('Channel %d overflowed\n', ii);
          set(hplot(ii),'xdata',x,'ydata',cat(2,get(hplot(ii),'ydata'),nan));
        else
          set(hplot(ii),'xdata',x,'ydata',cat(2,get(hplot(ii),'ydata'),tempcurr(ii)))
        end
      end
    end
  end

  function [ok,tempcurr,time,overflowarray] = get_single()
    
    % read from temperature probe
    ok=calllib('usbtc08','usb_tc08_get_single',tc08_handle,tempp,overflowp,int16(temp_units));
    tempcurr = nan(1,nchannels+1);
    overflowarray = false(1,nchannels+1);
    
    if ok == 0,
      last_error=calllib('usbtc08','usb_tc08_get_last_error',tc08_handle);
      [errname,errstr] = error_table(last_error);
      fprintf('Error %s calling usb_tc08_get_single:\n%s\n',errname,errstr);
      return;
    else
      tempcurr=get(tempp,'Value');
      overflowcurr=uint16(get(overflowp,'Value'));
      for ii = 1:nchannels+1,
        overflowarray(ii) = bitand(overflowcurr,bitshift(1,ii));
      end
      time=now;
    end
    
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