function [success,msg] = CheckBIASState(biasurl,varargin)

success = false;
msg = '';

[biasstatus,leftovers] = myparse_nocheck(varargin,'biasstatus',[]);

%% get status

if isempty(biasstatus),
  try
    res = BIASCommand([biasurl,'?get-status']);
  catch ME,
    msg = getReport(ME,'basic');
    return;
  end
  if res.success == 0,
    msg = sprintf('Could not get status: %s',res.message);
  return;
  end
  
  biasstatus = res.value;
end

%% check

for i = 1:2:numel(leftovers)-1,
  fn = leftovers{i};
  val = leftovers{i+1};
  if ~isfield(biasstatus,fn),
    msg = sprintf('No field %s in BIAS status',fn);
    return;
  end
  if val ~= biasstatus.(fn),
    msg = sprintf('Wrong value %d for %s, wanted %d',biasstatus.(fn),fn,val);
    return;
  end
end

%% all checks succeeded

success = true;
