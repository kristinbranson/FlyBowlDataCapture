function fixRCFile(ninstances)

params = load('.FlyBowlDataCapture_rc.mat');
fns = fieldnames(params);
for i = 1:numel(fns),
  fn = fns{i};
  if iscell(params.(fn)) && numel(params.(fn)) > ninstances,
    params.(fn) = params.(fn)(1:ninstances);
  end
end

save('.FlyBowlDataCapture_rc.mat','-struct','params');