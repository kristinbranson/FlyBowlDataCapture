function handles = setEffector(handles,neweffector)

handles.MetaData_Effector = neweffector;
i = find(strcmp(handles.MetaData_Effector,handles.effector_abbrs(:,1)),1);
if ~isempty(i),
  handles.MetaData_EffectorAbbr = handles.effector_abbrs{i,2};
else
  handles.MetaData_EffectorAbbr = neweffector;
end
