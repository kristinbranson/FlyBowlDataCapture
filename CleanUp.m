function CleanUp()

tmp = findall(0,'type','figure');
if ~isempty(tmp),
  fprintf('Closing %d figures...\n',numel(tmp));
  delete(tmp);
end

CleanSemaphores;