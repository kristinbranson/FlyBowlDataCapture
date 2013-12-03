function FBDC_ClearTimers()

timernames = {'FBDC_RecordTimer','FliesLoaded_Timer','FBDC_USBTC08_Timer','FBDC_CheckPreview_Timer','FBDC_Preview_Timer'};

for j = 1:numel(timernames),
  
  timername = timernames{j};

  tmp = timerfind('Name',timername);
  for i = 1:length(tmp),
    if iscell(tmp),
      delete(tmp{i});
    else
      delete(tmp(i));
    end
  end
  
end