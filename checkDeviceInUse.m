function [isInUse,handles,DeviceIDsLeft] = checkDeviceInUse(handles,newdevid,dowarn)

% check for semaphores
[DeviceIDsUsed,handles] = getIsCameraRunningDevices(handles);
isInUse = ismember(newdevid,DeviceIDsUsed);
DeviceIDsLeft = setdiff(handles.DeviceIDs,DeviceIDsUsed);
if isInUse,
  if dowarn,
    s = {sprintf('Device %d in use by another instance of FlyBowlDataCapture. If this seems incorrect, exit all FlyBowlDataCapture GUIs and run "CleanSemaphores"',newdevid)
      'Device IDs currently available:'
      mat2str(DeviceIDsLeft)};
    uiwait(errordlg(s,'Error selecting device'));
  end
end