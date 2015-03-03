function s = ParseComputerSpecificParam(s,handles)

m = regexp(s,',','split');
if numel(m) > 1,
  for i = 1:numel(m),
    j = find(m{i} == ':');
    if isempty(j), continue; end
    if strcmpi(handles.ComputerName,m{i}(1:j-1)),
      s = m{i}(j+1:end);
      break;
    end
  end
end