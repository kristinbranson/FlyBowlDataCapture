% data=loadjson1(fname,opt)
% or
% data=loadjson1(fname,'param1',value1,'param2',value2,...)
%
% same as loadjson, except does not return a cell array
function res = loadjson1(varargin)

res = loadjson(varargin{:});
if ~isempty(res) && iscell(res),
  res = res{1};
end