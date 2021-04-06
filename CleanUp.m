function CleanUp()

tmp = findall(0,'type','figure');
if ~isempty(tmp),
  fprintf('Closing %d figures...\n',numel(tmp));
  delete(tmp);
end

CleanSemaphores;
fprintf('Closing all open file handles...\n');
fclose('all');