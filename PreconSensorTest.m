% test script

% close all open ports
OpenPorts = instrfindall('Status','Open');
for i = 1:length(OpenPorts),
  fprintf('Before testing, closing port:\n');
  disp(OpenPorts(i));
  fclose(OpenPorts(i));
end

% find all serial ports available
PortsAvailable = PreconSensor.getAvailableSerialPorts();

% choose the first one
Port = PortsAvailable{1};
fprintf('Using Port %s\n',Port);

% initialize
psobj = PreconSensor(Port); 

% open the serial port
[success,errormsg] = psobj.open();

% read in some data
[temp,humid,success,errormsg] = psobj.read();
fprintf('Temperature = %f, humidity = %f\n',temp,humid);

% read in more data and take an average
[temp,humid,success,errormsg] = psobj.read(5);
fprintf('Average temperature = %f, humidity = %f\n',mean(temp),mean(humid));

% now read in a stream
fprintf('Reading a stream of temperature and humidity data...\n');
psobj.ReadAsyncMode = 'continuous';
[success,errormsg] = psobj.flush();
[temp,humid,success,errormsg] = psobj.read(50);
clf;
subplot(2,1,1);
plot(temp,'.-');
title('Temperature');
subplot(2,1,2);
plot(humid,'.-');
title('Humidity');
psobj.ReadAsyncMode = 'manual';

% close the port
[success,errormsg] = psobj.close();
