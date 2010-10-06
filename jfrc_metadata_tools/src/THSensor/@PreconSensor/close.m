% [success,errormsg] = close(obj)
% [success,errormsg] = obj.close()
%
% This function closes the open SerialPort.
% success is true if closing was successful, false if not. 
% errormsg describes the error that occurred if not successful. 
%
function [success,errormsg] = close(obj)

success = false;
if ~obj.IsOpen,
  errormsg = 'SerialPort is not open.';
  return;
end

try
  fclose(obj.SerialPort);
  delete(obj.SerialPort);
catch ME
  errormsg = getReport(ME,'basic','hyperlinks','off');
  return;
end

success = true;
errormsg = '';
obj.IsOpen = false;