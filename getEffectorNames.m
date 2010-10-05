function [effectorNames,success] = getEffectorNames()

try
  effectors = SAGE.CV('effector').terms();
catch
  success = false;
  effectorNames = {};
  return;
end
effectorNames = {effectors.name};
success = true;