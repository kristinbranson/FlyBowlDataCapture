function biases = GetBIASWindowsOpen(biasparams)

biases = [];
for cameranumber = 1:max(biasparams.BIASCameraNumbers),
  biasurl = GetBIASURL(biasparams,cameranumber);
  try %#ok<TRYNC>
    res = BIASCommand(([biasurl,'?get-status']),[],1);
    if res.success == 1,
      biases(end+1) = cameranumber; %#ok<AGROW>
    end
  end
end