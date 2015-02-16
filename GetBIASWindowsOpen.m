function biases = GetBIASWindowsOpen(biasparams)

biases = [];
for cameranumber = 1:max(biasparams.BIASCameraNumbers),
  biasurl = GetBIASURL(biasparams,cameranumber);
  try %#ok<TRYNC>
    res = loadjson1(urlread([biasurl,'?get-status']));
    if res.success == 1,
      biases(end+1) = cameranumber; %#ok<AGROW>
    end
  end
end