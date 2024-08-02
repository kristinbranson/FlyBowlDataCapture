% code modified from FBDC Quickstats code - Kristin Branson
% change to YOUR movie
% MovieFile = '/groups/branson/home/robiea/Projects_data/FlyBowl_Opto/TestData/NewOptoBowls/20191204T151156_rig1_flyBowl3__SS47478_20XUASCsChrimsonattp18_protocol_OL0077_testing_long_fortesting/movie.ufmf';

% addpath /groups/branson/home/robiea/Code_versioned/Jdetect_github/Jdetect/filehandling
% addpath /groups/branson/home/robiea/Code_versioned/Jdetect_github/Jdetect/misc

% MovieFile = '/groups/branson/home/robiea/Downloads/movie_cam_0_date_2020_08_07_time_14_02_16_v001.ufmf';
reflineval = 215;
MovieFile = 'C:\Users\bransonk\Videos\bias_video_v013.ufmf'
% MovieFile = 'C:\Users\bransonk\Videos\BLUeveness_v002.ufmf'
% MovieFile = 'E:\debug_data\locomotionGtACR1_emptySplit24m_Unknown_RigB_20210310T174924\movie.ufmf'
[moviepath,moviename] = fileparts(MovieFile);


savefilename = fullfile(moviepath,[moviename,'_background']);
[readframe,nframes,fid,headerinfo] = get_readframe_fcn(MovieFile);
% change to path for QuickStats data download 
% load /groups/branson/home/robiea/Code_versioned/FlyBowlDataCapture/QuickStats_Stats_20110914T022555.mat;

parent = nan;
fig = nan;
FigPos = [];


SigColor = [.75,.75,.75];
MuColor = [.25,.25,.25];
DataColor = [.7,0,0];
NBkgdBins = 25;

% IntensityHistMu = [];
% IntensityHistSig = [];
% ScanLineMu = [];
% ScanLineSig = [];
NBkgdScanLines = 4;
ScanLineYLim = [-5,260];
% ScanLineYLim = [-5,260];



h = figure('Position', [50,5,1000,1000]);

% 
% axes for background model

BkgdAx(1) = axes('Parent',h,'Units','Pixels','Position',[25,525,400,400],'FontUnits','pixels','Fontsize',9);

BkgdAx(2) = axes('Parent',h,'Units','Pixels','Position',[525,525,400,400],'FontUnits','pixels','Fontsize',9);

HistAx = axes('Parent',h,'Units','Pixels','Position',[25,125,400,200],'FontUnits','pixels','Fontsize',9);


ScanAx = nan(1,NBkgdScanLines);
ScanBottom = 25;
ScanHeight = 90;
BorderY = 10;
for i = 1:NBkgdScanLines,
  ScanAx(i) = axes('Parent',h,'Units','Pixels','Position',[525,ScanBottom,400,100],'FontUnits','pixels','Fontsize',9);
  ScanBottom = ScanBottom + ScanHeight + BorderY;
end


%% Compute background model
% 
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

% background intensity histogram
edges = linspace(0,255,NBkgdBins+1);
ctrs = (edges(1:end-1)+edges(2:end))/2;
counts = hist(bkgdim(:),ctrs);
frac = counts / numel(bkgdim);
% standard deviation
% if length(IntensityHistSig) == NBkgdBins && length(IntensityHistMu) == NBkgdBins,
%   y = IntensityHistMu;
%   dy = IntensityHistSig;
%   patch([ctrs,fliplr(ctrs)],[y+dy,fliplr(y-dy)],SigColor,'LineStyle','none','parent',HistAx);
%   hold(HistAx,'on');
% end
% % mean
% if length(IntensityHistMu) == NBkgdBins,
%   plot(HistAx,ctrs,IntensityHistMu,'-','Color',MuColor);
%   hold(HistAx,'on');
% end
plot(HistAx,ctrs,frac,'.-','Color',DataColor);
axis(HistAx,[edges(1),edges(end),0,1]);
xlabel(HistAx,'Pixel intensity histogram');
ylabel(HistAx,'Fraction of pixels');

%% backgrounds

% grayscale bkgd
image(repmat(bkgdim/255,[1,1,3]),'parent',BkgdAx(1));
axis(BkgdAx(1),'image');
set(BkgdAx(1),'xtick',[],'ytick',[]);
xlabel(BkgdAx(1),'Background');

% jet bkgd
imagesc(bkgdim,'parent',BkgdAx(2),[0,255]);
axis(BkgdAx(2),'image');
xlabel(BkgdAx(2),'Background, jet');
colormap(BkgdAx(2),'jet');
set(BkgdAx(2),'xtick',[],'ytick',[]);



%% scan lines
%% plot some scan lines through the center of the image at different
% orientations

y0 = [ ((headerinfo.nc+1)/4)*3, ((headerinfo.nc+1)/4)*1, ((headerinfo.nc+1)/4)*2, ((headerinfo.nc+1)/4)*2 ];
    
x0 = [ ((headerinfo.nc+1)/4)*2, ((headerinfo.nc+1)/4)*2, ((headerinfo.nc+1)/4)*3, ((headerinfo.nc+1)/4)*1 ]; 
r = min(headerinfo.nr,headerinfo.nc)/2;

theta = [0,0,pi/2,pi/2];
off = -r+1:r-1;
refline = ones(1,length(off))*reflineval;
hold(BkgdAx(1),'on');
out.BkgdScanLine.theta = theta;
out.BkgdScanLine.intensities = cell(NBkgdScanLines,1);
s = {'2 to 1','3 to 0','3 to 2', '0 to 1'}
for i = 1:NBkgdScanLines,
 % s = sprintf('%d',round(theta(i)*180/pi));
  % draw a line on the background
  plot(BkgdAx(1),x0(i)+cos(theta(i))*[-r,r],y0(i)+sin(theta(i))*[-r,r],'-','Color',DataColor);
  text(x0(i)+cos(theta(i))*r,y0(i)+sin(theta(i))*r,s{i},'parent',BkgdAx(1),'Color',DataColor);
  
  % sample
  x = round(x0(i) + cos(theta(i))*off);
  y = round(y0(i) + sin(theta(i))*off);  
  z = bkgdim(sub2ind([headerinfo.nr,headerinfo.nc],y,x));
  
  out.BkgdScanLine.intensities{i} = z;
  
%   % standard deviation
%   if size(ScanLineSig,1) >= i && size(ScanLineMu,1) >= i,
%     y = ScanLineMu(i,:);
%     dy = ScanLineSig(i,:);
%     patch([off,fliplr(off)],[y+dy,fliplr(y-dy)],SigColor,'LineStyle','none','parent',ScanAx(i));
%     hold(ScanAx(i),'on');
%   end
  % mean
%   if size(ScanLineMu,1) >= i,
%     plot(ScanAx(i),off,ScanLineMu(i,:),'-','Color',MuColor);
%     hold(ScanAx(i),'on');
%   end
  plot(ScanAx(i),off,refline,'-','Color','b');
  hold(ScanAx(i),'on');
  % plot actual data
  plot(ScanAx(i),off,z,'-','Color',DataColor);
  axis(ScanAx(i),[-r,r,ScanLineYLim]);
  
  set(ScanAx(i),'xticklabel',{},'yticklabel',{},'ytick',[0,122.5,255],'ticklength',[.005,.005]);
  ylabel(ScanAx(i),s{i});
end
xlabel(ScanAx(1),'Bkgd scan line intensities');

linkaxes(ScanAx);


%% save figure 

saveas(h, savefilename,'jpg')
