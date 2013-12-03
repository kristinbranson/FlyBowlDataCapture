function biasurl = GetBIASURL(biasparams,deviceid)

biasurl = sprintf('%s:%d/',biasparams.BIASURLBase,...
  biasparams.BIASServerPortBegin+deviceid*biasparams.BIASServerPortStep);