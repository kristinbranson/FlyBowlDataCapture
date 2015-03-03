function [linenames,success] = getLineNames(handles)

success = true;

try
  labs = SAGE.labs();
catch
  addToStatus(handles,'Could not connect to SAGE. Make sure you are connected to the Janelia network');
  success = false;
  return;
end

linenames = {};
for i = 1:length(labs),
  labname = labs(i).name;
  linenames0 = SAGE.Lab(labname).lines();
  for j = 1:length(linenames0),
    linenames{end+1} = linenames0(j).name; %#ok<AGROW>
  end
end
