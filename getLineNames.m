function linenames = getLineNames(db)
        
% query database
query = 'select name from line_vw';
curs = exec(db, query);
if ~isempty(curs.Message)
  errorMsg = ['Could not grab line names: ' curs.Message];
  close(curs)
  error(errorMsg)
end
curs = fetch(curs);

% parse data
if strcmp(curs.Data{1}, 'No Data')
  linenames = {};
else
  linenames = curs.Data(:,1);
end
close(curs)
