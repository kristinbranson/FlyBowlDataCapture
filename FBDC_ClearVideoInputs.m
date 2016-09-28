function FBDC_ClearVideoInputs()

if exist('imaqfind') > 0, %#ok<EXIST>
  for tmp = imaqfind('Name','FBDC_VideoInput'),
    delete(tmp{1});
  end
end