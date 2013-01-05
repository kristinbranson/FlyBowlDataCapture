try
  FlyBowlDataCapture;
catch ME
  uiwait(errordlg(getReport(ME),'Error running FBDCCond'));
end