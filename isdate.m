function res = isdate(s,dateformat)

try
  if nargin < 2,
    n = datenum(s);
  else
    n = datenum(s,dateformat);
  end
  res = true;
catch
  res = false;
end