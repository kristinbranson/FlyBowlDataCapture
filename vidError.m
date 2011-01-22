function vidError(obj, event)

keyboard;

% Define error identifiers.
errID = 'imaq:imaqcallback:invalidSyntax';
errID2 = 'imaq:imaqcallback:zeroInputs';

switch nargin
    case 0
        error(errID2, imaqgate('privateMsgLookup', errID2));
    case 1
        error(errID, imaqgate('privateMsgLookup', errID));
    case 2
        if ~isa(obj, 'imaqdevice') || ~isa(event, 'struct')
            error(errID, imaqgate('privateMsgLookup', errID));
        end   
        if ~(isfield(event, 'Type') && isfield(event, 'Data'))
            error(errID, imaqgate('privateMsgLookup', errID));
        end
end

% Determine the type of event.
EventType = event.Type;

% Determine the time of the error event.
EventData = event.Data;
EventDataTime = EventData.AbsTime;

% Create a display indicating the type of event, the time of the event and
% the name of the object.
name = get(obj, 'Name');
s = sprintf('%s event occurred at %s for video input object: %s.\n', ...
  EventType, datestr(EventDataTime,13), name);
errordlg(s,'Video Error');

% Display the error string.
if strcmpi(EventType, 'error')
    fprintf('%s\n', EventData.Message);
end