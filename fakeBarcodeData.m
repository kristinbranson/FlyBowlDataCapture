function barcodeData = fakeBarcodeData(handles,recordtime)

if nargin < 2,
  recordtime = now;
end

barcodeData = struct;
barcodeData.Date_Crossed = datestr(round(recordtime-mean(handles.params.PreAssayHandling_CrossDate_Range)),handles.datetimeformat);
date = floor(recordtime-mean(handles.params.PreAssayHandling_SortingDate_Range));
hr = mean(handles.params.PreAssayHandling_SortingHour_Range)/24;
barcodeData.Sorting_DateTime = datestr(date+hr,handles.datetimeformat);
date = floor(recordtime-mean(handles.params.PreAssayHandling_StarvationDate_Range));
hr = mean(handles.params.PreAssayHandling_StarvationHour_Range)/24;
barcodeData.Starvation_DateTime = datestr(date+hr,handles.datetimeformat);
barcodeData.Set_Number = 123;
barcodeData.Handler_Sorting = 'sorter';
barcodeData.Handler_Starvation = 'starver';
barcodeData.Handler_Cross = 'crosser';
if isfield(handles,'Fly_LineNames') && ~isempty(handles.Fly_LineNames),
  if iscell(handles.Fly_LineNames),
    barcodeData.Line_Name = handles.Fly_LineNames{1};
  else
    barcodeData.Line_Name = handles.Fly_LineNames;
  end
else  
  barcodeData.Line_Name = 'GMR_SS00123';
end
barcodeData.Effector = 'TestEffector';
barcodeData.RobotID = 'robot';