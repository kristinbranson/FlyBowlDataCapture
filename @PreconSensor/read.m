% [temp,humid,success,errormsg] = read(obj,nReadings=1)
% [temp,humid,success,errormsg] = obj.read(nReadings=1)
%
% This function takes nReadings temperature and humidity readings from
% SerialPort. nReadings is 1 by default. 
% temp is an array of size 1 x nReadings containing the temperature
% readings. 
% humid is an array of size 1 x nReadings containing the humidity
% readings. 
% success is true if reading was successful, false if not. 
% errormsg describes the error that occurred if not successful. 
%
function [temp,humid,success,errormsg] = read(obj,nReadings)

maxNTries = 2;
if nargin < 2,
  nReadings = 1;
end

success = false;
temp = nan(1,nReadings);
humid = nan(1,nReadings);

if ~obj.IsOpen,
  errormsg = 'SerialPort is not open.';
  return;
end

try

  if nReadings > 1,
    if ~strcmpi(obj.ReadAsyncMode,'continuous'),
      set(obj.SerialPort,'ReadAsyncMode','continuous');
    end
  end
  
  for i = 1:nReadings,

    for tryi = 1:maxNTries,
    
      s = fgetl(obj.SerialPort);
    
      if ~isempty(s), break; end
    
    end
    
    if isempty(s),
      errormsg = 'No data read from serial port';
      return;
    end
    
    [data,count,errormsg] = sscanf(s,'H %f T %f',2);
    
    if ~isempty(errormsg)
      return;
    end
    
    if count < 2,
      errormsg = 'Could not parse humidity and temperature from data read from serial port.';
      return;
    end
    
    humid(i) = data(1);
    temp(i) = data(2);
    
  end

  if nReadings > 1 && ~strcmpi(obj.ReadAsyncMode,'continuous'),
    set(obj.SerialPort,'ReadAsyncMode',obj.ReadAsyncMode);
  end
  
catch ME
  errormsg = getReport(ME,'basic','hyperlinks','off');
  return;
end

success = true;
errormsg = '';