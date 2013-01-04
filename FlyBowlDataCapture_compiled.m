try
  FlyBowlDataCapture;
catch ME
  uiwait(errordlg(getReport(msg),'Error running FBDCCond'));
end