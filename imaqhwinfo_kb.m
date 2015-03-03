function out = imaqhwinfo_kb(semaphore_params, adaptor, field)
%IMAQHWINFO Return information on available hardware.
%
%    OUT = IMAQHWINFO returns a structure, OUT, which contains image
%    acquisition hardware information. This information includes the 
%    toolbox version, MATLAB version and names of installed adaptors.
%
%    OUT = IMAQHWINFO(ADAPTORNAME) returns a structure, OUT, which 
%    contains information related to an adaptor, specified by the 
%    string ADAPTORNAME. This information includes adaptor version 
%    and available hardware for the specified adaptor. 
%
%    OUT = IMAQHWINFO(ADAPTORNAME,'FIELD') returns the adaptor information 
%    for the specified field name, FIELD. FIELD can be a single string or a
%    cell array of strings. If FIELD is a cell array, OUT is a 1-by-N 
%    cell array where N is the length of FIELD.
%
%    OUT = IMAQHWINFO(ADAPTORNAME, DEVICEID) returns information for the
%    device identified by the numerical DEVICEID. DEVICEID can be a scalar or
%    a vector. If DEVICEID is a vector, OUT is a 1-by-N structure array where 
%    N is the length of DEVICEID.
%
%    OUT = IMAQHWINFO(OBJ) where OBJ is an image acquisition object, returns  
%    a structure, OUT, containing information such as adaptor, board 
%    information and hardware configuration limits. If OBJ is an array of 
%    device objects then OUT is a 1-by-N cell array of structures where N is
%    the length of OBJ.
%
%    OUT = IMAQHWINFO(OBJ, 'FIELD') returns the hardware information 
%    for the specified field name, FIELD, to OUT. FIELD can be any of 
%    the field names defined in the IMAQHWINFO(OBJ) structure. FIELD can 
%    be a single string or a cell array of strings. If FIELD is a cell 
%    array, OUT is a 1-by-N cell array where N is the length of FIELD.
%
%    Once IMAQHWINFO is called, hardware information is cached by the
%    toolbox. To force the toolbox to search for new hardware that may have
%    been installed while MATLAB was running, use IMAQRESET.
%
%    Example:
%      out1 = imaqhwinfo
%      out2 = imaqhwinfo('matrox');
%
%      obj = videoinput('winvideo', 1);
%      out3 = imaqhwinfo(obj);
%      out4 = imaqhwinfo(obj, 'AdaptorName');
%
%    See also IMAQRESET, IMAQHELP.
%

%    CP 9-01-01
%    Copyright 2001-2007 The MathWorks, Inc.
%    $Revision: 1.1.6.7 $  $Date: 2007/12/17 06:16:39 $

IsCameraRunningFiles = dir(fullfile(semaphore_params.DataDir,'*.mat'));
% sort by date from oldest to newest
if ~isempty(IsCameraRunningFiles),
  [~,order] = sort([IsCameraRunningFiles.datenum]);
  IsCameraRunningFiles = IsCameraRunningFiles(order);
end
NCamerasRunning = length(IsCameraRunningFiles);
AdaptorsRunning = cell(1,NCamerasRunning);
DevsRunning = cell(1,NCamerasRunning);
for i = 1:NCamerasRunning,
  [AdaptorsRunningCurr,DevsRunningCurr] = parseIsCameraRunningFileName(IsCameraRunningFiles(i),semaphore_params);
  if ~isnan(DevsRunningCurr),
    AdaptorsRunning{i} = AdaptorsRunningCurr;
    DevsRunning{i} = DevsRunningCurr;
  end
end

nInputs = nargin;
switch nInputs
  case 0
    error('Usage: imaqhwinfo_kb(semaphore_params,[adaptorname],[fields])');
  case 1
    % Ex. out = imaqhwinfo
    try
      out = imaqmex('imaqhwinfo');
    catch exception
      throw(exception)
    end
  otherwise
    % Ex. out = imaqhwinfo('matrox');
    % Ex. out = imaqhwinfo('matrox', 'AdaptorName');
    %
    % Error check
    if ~ischar(adaptor)
      errID = 'imaq:imaqhwinfo:invalidType';
      error(errID, imaqgate('privateMsgLookup', errID));
    elseif nInputs==3
      % Store as a cell array
      wasChar = false;
      if ischar(field),
        field = {field};
        wasChar = true;
      end
      
      % Check for invalid second input.
      if (~isnumeric(field) && ~iscellstr(field))
        errID = 'imaq:imaqhwinfo:fieldType';
        error(errID, privateMsgLookup(errID));
      elseif (numel(field)~=length(field))
        errID = 'imaq:imaqhwinfo:matrixField';
        error(errID, privateMsgLookup(errID));
      end
    end
    
    % Get hardware information.
    try
      IMAQinfo = imaqmex('imaqhwinfo');
      allAdaptors = lower(IMAQinfo.InstalledAdaptors);
      matchIndex = find(strcmpi(adaptor, allAdaptors));
      if ~isempty(matchIndex)
        sem_match = find(strcmpi(adaptor, AdaptorsRunning));
        if ~isempty(sem_match),
          warning('imaq_kb:CameraRunning','imaqhwinfo_kb: Based on existence of semaphore file %s, a camera with adaptor %s is running. Read adaptor info from semaphore file. If this seems wrong, run "CleanSemaphores"',IsCameraRunningFiles(sem_match(end)).name,adaptor);
          filename = fullfile(semaphore_params.DataDir,...
            IsCameraRunningFiles(sem_match(end)).name);
          tmp = load(filename,'adaptorinfo');
          out = tmp.adaptorinfo;
        else
          out = imaqmex('imaqhwinfo', allAdaptors{matchIndex});
          for i = 1:length(out.DeviceInfo),
            out.DeviceInfo(i).ObjectConstructor = strrep(out.DeviceInfo(i).ObjectConstructor,'videoinput(','videoinput_kb(semaphore_params,');
          end
        end
      else
        out = imaqmex('imaqhwinfo', '');
      end
    catch exception
      throw(exception);
    end
    
    % Return requested fieldname.
    if nInputs==3,
      if iscellstr(field),
        % imaqhwinfo('matrox', 'Foo')
        %
        % Initialize and return field values.
        result = cell(1,length(field));
        allFields = fieldnames(out);
        for i=1:length(field)
          matchIndices = strmatch(lower(field{i}), lower(allFields));
          if any(matchIndices)
            index = matchIndices(1);
            result{i} = out.(allFields{index});
          else
            errID = 'imaq:imaqhwinfo:invalidField';
            error(errID, [privateMsgLookup(errID) field{i} '.']);
          end
        end
        
        % Return as a string if necessary.
        if wasChar,
          out = result{1};
        else
          out = result;
        end
      else
        % imaqhwinfo('matrox', 1)
        allIDs = [out.DeviceIDs{:}];
        for i=1:length(field)
          % Extract information on the requested device.
          index = find(field(i)==allIDs);
          if isempty(index),
            errID = 'imaq:imaqhwinfo:noDeviceID';
            error(errID, privateMsgLookup(errID));
          else
            result(i) = out.DeviceInfo(index); %#ok<AGROW>
          end
        end
        
        % Return our results.
        out = result;
      end
    end
end
