function RotatePreviewImage(handles)

% determine whether to rotate the image
if ~isfield(handles,'axes_PreviewVideo') || ~ishandle(handles.axes_PreviewVideo),
  return;
end
tmpidx = strcmp(handles.params.DoRotatePreviewImage(:,1),handles.Assay_Rig) & ...
  strcmp(handles.params.DoRotatePreviewImage(:,2),handles.Assay_Bowl);
if isempty(tmpidx),
  DoRotate = false;
else
  DoRotate = handles.params.DoRotatePreviewImage{tmpidx,3};
end
if DoRotate,
  set(handles.axes_PreviewVideo,'XDir','reverse','YDir','normal');
else
  set(handles.axes_PreviewVideo,'XDir','normal','YDir','reverse');
end