function MasterTempRecord_GrabTemp(obj,event,tc08_handle,Channels,ChannelFileNames,StartRunTimeStamp) %#ok<INUSL>

% read temp in celcius
UnitsCode = 0; 
% max number of temps to grab at once -- this should be big enough to get
% all values in the buffer
BufferLength = 10; 
% whether to replace missing values with last known value
FillMissing = 0; 

persistent temps_p;
persistent overflow_p;
persistent times_ms_p;

% allocate pointers for storing temp and overflow
if isempty(temps_p),
  temps = zeros(1,BufferLength);
  times_ms = int32(zeros(1,BufferLength));
  overflow = int16(0);
  temps_p = libpointer('singlePtr',temps);
  times_ms_p = libpointer('int32Ptr',times_ms);
  overflow_p = libpointer('int16Ptr',overflow);
end  

% loop through channels
for i = 1:length(Channels),
  channel = Channels(i);
  
  % times coming from temperature probe don't seem accurate
  timestamp = now; 
  
  % get readings from driver buffer
  nreadings = calllib('usbtc08','usb_tc08_get_temp',...
    tc08_handle,...
    temps_p,...
    times_ms_p,...
    int32(BufferLength),...
    overflow_p,...
    int16(channel),...
    int16(UnitsCode),...
    int16(FillMissing));
  
  % check for error
  if nreadings < 0,
    last_error=calllib('usbtc08','usb_tc08_get_last_error',tc08_handle);
    [errname,errstr] = error_table(last_error);
    fprintf('Error %s calling usb_tc08_get_single: %s',errname,errstr);
    continue;
  end
  
  % no readings available
  if nreadings == 0,
    continue;
  end
  
  % get values from pointers
  temps_v = get(temps_p,'Value');
  %times_ms_v = get(times_ms_p,'Value');
  overflow_v = get(overflow_p,'Value');
  
  % we want the last value
  temp_v = temps_v(nreadings);
  %time_ms_v = double(times_ms_v(nreadings));
  %timestamp = StartRunTimeStamp + (time_ms_v / 1000 / 86400);
  
  % write to file
  fid = fopen(ChannelFileNames{i},'w');
  if fid <= 0,
    fprintf('Could not open file %s for writing temperature data for channel %d\n',ChannelFileNames{i},Channel);
    continue;
  end
  fprintf(fid,'%f %f %d',timestamp,temp_v,overflow_v);
  fclose(fid);
  
  % debug
  %fprintf('Channel %d: timestamp = %s, temp = %f, nreadings = %d, callback at time %s\n',channel,datestr(timestamp,13),temp_v,nreadings,datestr(event.Data.time,13));
  
end

% ok = calllib('usbtc08','usb_tc08_get_single',...
%   int16(tc08_handle),...
%   temp_p,...
%   overflow_flags_p,...
%   int16(UnitsCode));
% 
% if ok == 0,
%   last_error=calllib('usbtc08','usb_tc08_get_last_error',tc08_handle);
%   [errname,errstr] = USBTC08_error_table(last_error);
%   fprintf('GrabTemp(%s): Error %s: %s',datestr(timestamp,13),errname,errstr);
%   return;
% end
% 
% temp = temp_p.Value;
% overflow_flags = uint16(overflow_flags_p.Value);
% for i = 1:length(Channels),
%   channel = Channels(i);
%   overflow_flag = bitand(overflow_flags,bitshift(1,channel));
%   fid = fopen(ChannelFileNames{i},'w');
%   fprintf(fid,'%f %f %d',timestamp,temp(channel),overflow_flag);
%   fclose(fid);
%   fprintf('Channel %d: timestamp = %s, temp = %f\n',channel,datestr(timestamp,13),temp(i));
% end