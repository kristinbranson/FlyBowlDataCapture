function varargout = mywaitbar(varargin)

if nargin >= 2 && isnumeric(varargin{2}),
  if ~ishandle(varargin{2}),
    varargin(2) = [];
  end
end

varargout = cell(1,nargout);
[varargout{:}] = waitbar(varargin{:});
