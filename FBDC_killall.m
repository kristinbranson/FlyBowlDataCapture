function success = FBDC_killall(handles)

success = false;

try
  for i = 1:4,
    if isfield(handles,'figure_main') && ishandle(handles.figure_main),
      delete(handles.figure_main);
    end
    delete(timerfindall);
    fclose('all');
    delete(findall(0,'type','figure'));
    CleanSemaphores;
  end
catch ME,
  fprintf('Error killing everyting:\n');
  getReport(ME)
  return;
end

success = true;