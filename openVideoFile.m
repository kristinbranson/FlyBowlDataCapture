function handles = openVideoFile(handles)

switch handles.params.FileType,
  case 'avi' %Uncompressed AVIs
    %Single AVI
    handles.logger.aviobj = avifile_sideways(handles.FileName);
    handles.logger.aviobj.Fps = handles.FPS;
    handles.logger.aviobj.compression = 'none';
    handles.logger.aviobj.Colormap=gray(256);
  case 'fmf' %Dickinson Lab "Fly Movie Format"
    %single FMF ROI
    handles.logger.fid = fopen(handles.FileName,'w','ieee-le');
    fwrite(handles.logger.fid,1,'uint32');
    if isfield(handles.params,'Imaq_ROIPosition'),
      sz = handles.params.Imaq_ROIPosition([3,4]);
    else
      sz = handles.vidRes;
    end

    fwrite(handles.logger.fid,sz(1),'uint32');
    fwrite(handles.logger.fid,sz(2),'uint32');
    fwrite(handles.logger.fid,prod(handles.vidRes)+8,'uint64');
    fwrite(handles.logger.fid,0,'uint64');
end
