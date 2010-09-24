classdef PreconSensor < handle
  properties
    IsOpen = false;
    Port = '';
    SerialPort = [];
    BaudRate = 9600;
    DataBits = 8;
    Parity = 'none';
    StopBits = 1;
    FlowControl = 'hardware';
    Terminator = 'CR';
    ReadAsyncMode = 'manual';
  end
  methods
    function obj = PreconSensor(Port)
      % obj = PreconSensor(Port)
      % Creates a PreconSensor instance with port name Port.
      if nargin ~= 1,
        error('Usage: obj = PreconSensor(Port)');
      end
      obj.Port = Port;
    end
    function delete(obj)
      % delete(obj)
      % clear obj
      % Closes the SerialPort if open before deallocating. 
      if obj.IsOpen,
        fprintf('Closing port %s.\n',obj.Port);
        fclose(obj.SerialPort);
        obj.IsOpen = false;
        obj.SerialPort = [];
      end
    end
    function set.Port(obj,value)
      if obj.IsOpen,
        error('Cannot set Port while SerialPort is open');
      end
      obj.Port = value;
    end
    function set.BaudRate(obj,value)
      obj.BaudRate = value;
      if obj.IsOpen,
        set(obj.SerialPort,'BaudRate',value);
      end
    end
    function set.DataBits(obj,value)
      obj.DataBits = value;
      if obj.IsOpen,
        set(obj.SerialPort,'DataBits',value);
      end
    end
    function set.Parity(obj,value)
      obj.Parity = value;
      if obj.IsOpen,
        set(obj.SerialPort,'Parity',value);
      end
    end
    function set.StopBits(obj,value)
      obj.StopBits = value;
      if obj.IsOpen,
        set(obj.SerialPort,'StopBits',value);
      end
    end
    function set.FlowControl(obj,value)
      obj.FlowControl = value;
      if obj.IsOpen,
        set(obj.SerialPort,'FlowControl',value);
      end
    end
    function set.Terminator(obj,value)
      obj.Terminator = value;
      if obj.IsOpen,
        set(obj.SerialPort,'Terminator',value);
      end
    end
    function set.ReadAsyncMode(obj,value)
      obj.ReadAsyncMode = value;
      if obj.IsOpen,
        set(obj.SerialPort,'ReadAsyncMode',value);
      end
    end
    [success,errormsg] = open(obj)
    [success,errormsg] = close(obj)
    [temp,humid,success,errormsg] = read(obj,nReadings)
    [success,errormsg] = flush(obj)
  end
  methods(Static)
    portsAvailable = getAvailableSerialPorts()
  end
end