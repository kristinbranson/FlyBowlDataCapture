function s = any2string(v)

if ischar(v),
  s = v;
elseif isnumeric(v),
  s = num2str(v);
elseif iscell(v),
  s = '{ ';
  for i = 1:length(v),
    s = [s,any2string(v{i})]; %#ok<AGROW>
  end
  s = [s,'}'];
else
  s = ['[[',class(v),']]'];
end
      
