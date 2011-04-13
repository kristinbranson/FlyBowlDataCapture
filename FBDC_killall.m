function success = FBDC_killall(handles)

success = false;

try
  for i = 1:4,
    fprintf('Trying to kill everything, iteration %d\n',i);
    fprintf('Deleting main figure...\n');
    if isfield(handles,'figure_main') && ishandle(handles.figure_main),
      delete(handles.figure_main);
    end
    fprintf('Deleting all timers...\n');
    delete(timerfindall);
    fprintf('Closing all open files...\n');
    fclose('all');
    fprintf('Deleting all figures...\n');
    delete(findall(0,'type','figure'));
    fprintf('Cleaning semaphores...\n');
    CleanSemaphores;
  end
catch ME,
  fprintf('Error killing everyting:\n');
  getReport(ME)
  return;
end

success = true;