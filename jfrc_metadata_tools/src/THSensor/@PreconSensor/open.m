% [success,errormsg] = open(obj)
% [success,errormsg] = obj.open()
%
% This function opens the port specified in obj.Port. 
% success is true if opening was successful, false if not. 
% errormsg describes the error that occurred if not successful. 
%
function [success,errormsg] = open(obj)

success = false;
if obj.IsOpen,
  errormsg = 'SerialPort is already open.';
  return;
end

obj.SerialPort = [];
try
  obj.SerialPort = serial(obj.Port,...
    'BaudRate',obj.BaudRate,...
    'DataBits',obj.DataBits,...
    'Parity',obj.Parity,...
    'StopBits',obj.StopBits,...
    'FlowControl',obj.FlowControl,...
    'Terminator',obj.Terminator,...
    'ReadAsyncMode',obj.ReadAsyncMode);
  fopen(obj.SerialPort);
  obj.SerialPort.DataTerminalReady = 'On';
  fgetl(obj.SerialPort);
catch ME
  errormsg = getReport(ME,'basic','hyperlinks','off');
  return;
end
  
obj.IsOpen = true;
success = true;
errormsg = '';