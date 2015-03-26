function res = BIASCommand(s,statusfn,maxntries)

res = [];

isstatusfn = nargin >= 2 && ~isempty(statusfn);
if nargin < 3 || isempty(maxntries),
  maxntries = 3;
end

for tryi = 1:maxntries,
  try
    res = loadjson1(urlread(s));
    return;
  catch ME,
    if tryi < maxntries,
      warnmsg = {sprintf('ERROR COMMUNICATING WITH BIAS on try %d.',tryi),...
        sprintf('Command: %s',s),...
        getReport(ME,'basic')};
      if isstatusfn,
        statusfn(warnmsg);
      end
      warning('%s\n',warnmsg{:});
    else
      throw(ME);
    end   
  end
end   
