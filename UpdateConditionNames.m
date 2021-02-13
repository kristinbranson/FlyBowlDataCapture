function handles = UpdateConditionNames(handles)

i = find(strcmp(handles.ExperimentType,handles.ExperimentTypes),1);
handles.IsBarcode = handles.Experiment2IsBarcode(i);

if handles.IsBarcode,

  set([handles.edit_Barcode,handles.pushbutton_ScanBarcode,handles.text_Barcode,handles.menu_Edit_RefreshLineNames],'Visible','on');

  % try to read line names
  conditions = handles.Experiment2Conditions{i};
  metadata = ReadParams(conditions{2},'fns_list',{'LineName'});
  
  doreadlinenames = true;
  if isfield(metadata,'LineName'),
    s = metadata.LineName;
    if numel(s) > 1,
      s = cellfun(@strtrim,s,'Uni',0);
      handles.Fly_LineNames = s(:);
      addToStatus(handles,{'Read line names from condition file.'});
      if isfield(handles.params,'ExtraLineNames'),
        handles.Fly_LineNames = cat(1,handles.Fly_LineNames,handles.params.ExtraLineNames(:));
      end
      handles.Fly_LineNames = unique(handles.Fly_LineNames);
      doreadlinenames = false;
    end
  end
  
  if ~isfield(handles,'FlyBoy_stm'),
    % initialize Fly Boy & SAGE stuff
    handles.FlyBoy_stm = InitializeFlyBoy();
  end
      
  % find SAGE
  if ~isfield(handles,'IsSage'),
    if ~isdeployed,
      handles.IsSage = exist(handles.SAGECodeDir,'file');
      if handles.IsSage,
        try
          addpath(handles.SAGECodeDir);
        catch
          handles.IsSage = false;
        end
      end
    else
      handles.IsSage = exist('SAGE.Line','class');
    end
    if ~handles.IsSage,
      addToStatus(handles,{sprintf('SAGE code directory %s could not be added to the path.',handles.SAGECodeDir)});
    end
  end        
  % read line names
  if doreadlinenames,
    addToStatus(handles,'Reading line names...');
    handles = readLineNames(handles,false);
  end

  if ~isfield(handles,'jhedit_Barcode') && strcmpi(get(handles.figure_main,'Visible'),'on'),
    % barcode edit box
    handles.jhedit_Barcode = findjobj(handles.edit_Barcode);
    % always highlight when focus gained
    set(handles.jhedit_Barcode,'FocusGainedCallback',@HighlightEditText);
  end
    
  handles.ConditionNames = handles.Fly_LineNames;
  handles.ConditionFileNames = repmat(handles.Experiment2Conditions{i}(2,1),[1,numel(handles.Fly_LineNames)]);
  
else
  set([handles.edit_Barcode,handles.pushbutton_ScanBarcode,handles.text_Barcode,handles.menu_Edit_RefreshLineNames],'Visible','off');
  handles.ConditionNames = handles.Experiment2Conditions{i}(1,:);
  handles.ConditionFileNames = handles.Experiment2Conditions{i}(2,:);
end

j = 1;
handles.ConditionName = handles.ConditionNames{j};
handles.ConditionFileName = handles.ConditionFileNames{j};
  
% set possible values, current value, color to shouldchange
set(handles.popupmenu_Condition,'String',handles.ConditionNames,...
  'Value',j,'BackgroundColor',handles.shouldchange_bkgdcolor);
handles.isdefault.ConditionName = true;
  
