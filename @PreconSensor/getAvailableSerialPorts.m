% portsAvailable = PreconSensor.getAvailableSerialPorts()
%
% This is a static function calls instrhwinfo('serial') and returns an 
% N x 1 cell of the names of the available serial ports. 
% 
function portsAvailable = getAvailableSerialPorts()

tmp = instrhwinfo('serial');
portsAvailable = tmp.AvailableSerialPorts;