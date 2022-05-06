% change to YOUR movie
MovieFile = '/groups/branson/home/robiea/Projects_data/FlyBowl_Opto/TestData/NewOptoBowls/20191204T151156_rig1_flyBowl3__SS47478_20XUASCsChrimsonattp18_protocol_OL0077_testing_long_fortesting/movie.ufmf';
[readframe,nframes,fid,headerinfo] = get_readframe_fcn(MovieFile);
% change to path for QuickStats data download 
load /groups/branson/home/robiea/Code_versioned/FlyBowlDataCapture/QuickStats_Stats_20110914T022555.mat;

SigColor = [.75,.75,.75];
MuColor = [.25,.25,.25];
DataColor = [.7,0,0];
NBkgdBins = 25;
figure;
HistAx = axes;

%% Compute background model

% take the median of all background frames
nsampleframes = 10;
if headerinfo.nmeans > 1,
  if headerinfo.nmeans-1 > nsampleframes,
    sampleframes = unique(round(linspace(2,headerinfo.nmeans,nsampleframes)));
  else
    sampleframes = 2:headerinfo.nmeans;
  end
  [meanims,headerinfo] = ufmf_read_mean(headerinfo,'meani',sampleframes);
  meanims = double(meanims);
  bkgdim = mean(meanims,4);
else
  sampleframes = unique(round(linspace(1,headerinfo.nframes,nsampleframes)));
  meanims = repmat(double(readframe(1)),[1,1,1,nsampleframes]);
  for i = 2:nsampleframes,
    meanims(:,:,:,i) = double(readframe(sampleframes(i)));
  end
  bkgdim = median(meanims,4);
end
im = double(readframe(1));
% WARNING: THIS WON'T WORK WITH COLOR IMAGES
if ndims(bkgdim) == ndims(im) && ~all(size(bkgdim) == size(im)),
  bkgdim = bkgdim';
end

%% background intensity histogram
edges = linspace(0,255,NBkgdBins+1);
ctrs = (edges(1:end-1)+edges(2:end))/2;
counts = hist(bkgdim(:),ctrs);
frac = counts / numel(bkgdim);
% standard deviation
if length(IntensityHistSig) == NBkgdBins && length(IntensityHistMu) == NBkgdBins,
  y = IntensityHistMu;
  dy = IntensityHistSig;
  patch([ctrs,fliplr(ctrs)],[y+dy,fliplr(y-dy)],SigColor,'LineStyle','none','parent',HistAx);
  hold(HistAx,'on');
end
% mean
if length(IntensityHistMu) == NBkgdBins,
  plot(HistAx,ctrs,IntensityHistMu,'-','Color',MuColor);
  hold(HistAx,'on');
end
plot(HistAx,ctrs,frac,'.-','Color',DataColor);
axis(HistAx,[edges(1),edges(end),0,1]);
xlabel(HistAx,'Pixel intensity histogram');
ylabel(HistAx,'Fraction of pixels');
