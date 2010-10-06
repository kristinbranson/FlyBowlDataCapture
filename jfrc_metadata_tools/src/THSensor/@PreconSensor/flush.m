% [success,errormsg] = flush(obj)
% [success,errormsg] = obj.flush()
%
% This function flushes the input stream from the open SerialPort.
% success is true if flushing was successful, false if not. 
% errormsg describes the error that occurred if not successful. 
%
function [success,errormsg] = flush(obj)

success = false;

if ~obj.IsOpen
  errormsg = 'SerialPort not open.';
  return;
end

try
  flushinput(obj.SerialPort);
catch ME
  errormsg = getReport(ME,'basic','hyperlinks','off');
  return;
end

errormsg = '';
success = true;