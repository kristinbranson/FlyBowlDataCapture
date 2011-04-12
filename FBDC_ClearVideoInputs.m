function FBDC_ClearVideoInputs()

for tmp = imaqfind('Name','FBDC_VideoInput'),
  delete(tmp{1});
end
