function handles = UpdateConditionNames(handles)

i = find(strcmp(handles.ExperimentType,handles.ExperimentTypes),1);

if isfield(handles,'IsBarcode'),
  oldIsBarcode = handles.IsBarcode;
else
  oldIsBarcode = false;
end
handles.IsBarcode = handles.Experiment2IsBarcode(i);

if handles.IsBarcode,

  set([handles.edit_Barcode,handles.pushbutton_ScanBarcode,handles.text_Barcode,handles.menu_Edit_RefreshLineNames],'Visible','on');
  
  if ~oldIsBarcode,
    
    if ~isfield(handles,'FlyBoy_stm'),
      
      % initialize Fly Boy & SAGE stuff
      handles.FlyBoy_stm = InitializeFlyBoy();
      
      % find SAGE
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
      
      % read line names
      addToStatus(handles,'Reading line names...');
      handles = readLineNames(handles,false);
      
    end

    if ~isfield(handles,'jhedit_Barcode') && strcmpi(get(handles.figure_main,'Visible'),'on'),
      % barcode edit box
      handles.jhedit_Barcode = findjobj(handles.edit_Barcode);
      % always highlight when focus gained
      set(handles.jhedit_Barcode,'FocusGainedCallback',@HighlightEditText);
    end
    
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
  
