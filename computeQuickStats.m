function [out,success,errmsg,warnings] = computeQuickStats(expdir,varargin)

success = false;
out = struct;
warnings = {};

% name of diagnostics file within experiment directory
UFMFDiagnosticsFileStr = 'ufmf_diagnostics.txt';
% name of video
MovieFileStr = 'movie.ufmf';
% streams to plot
UFMFStreamFns = {'bytes','nForegroundPx','nPxWritten','nFramesBuffered','nFramesDropped',...
  'meanPixelError','maxPixelError','maxFilterError'};
% number of subplot columns
UFMFStream_nc = 4;
% for auto-setting axis limits
UFMFStreamXLimExtra = .01;
UFMFStreamYLimExtra = .05;
% average, std of statistics
UFMFStreamMu = struct;
UFMFStreamSig = struct;
SigColor = [.75,.75,.75];
MuColor = [.25,.25,.25];
DataColor = [.7,0,0];

% summaries to show
UFMFSummaryFns = {'nFrames','nFramesDroppedTotal','nFramesUncompressed','nUpdateBackgroundCalls','nWriteKeyFrameCalls','ImageWidth','ImageHeight'};
UFMFSummaryStatFns = {'FPS','CompressionRate','NForegroundPx','NPxWritten','MeanPixelError','MaxPixelError','MaxFilterError'};

% bkgd scan lines to plot
NBkgdScanLines = 4;
% number of bins for histogramming background intensities
NBkgdBins = 25;

BackSubNFramesSample = 10;
BackSubThreshLow = 10;
BackSubThreshHigh = 20;
BackSubMinCCArea = 5;

[GUIi,fig,FigPos,...
  UFMFDiagnosticsFileStr,MovieFileStr,...
  UFMFStreamFns,UFMFStreamMu,UFMFStreamSig,...
  UFMFStream_nc,UFMFStreamYLim,UFMFStreamXLim,...
  parent,SigColor,MuColor,DataColor,...
  UFMFSummaryFns,UFMFSummaryStatFns,...
  NBkgdScanLines,NBkgdBins,...
  BackSubNFramesSample,BackSubThreshLow,BackSubThreshHigh,BackSubMinCCArea] = ...
  myparse(varargin,...
  'GUIInstance',1,...
  'FigHandle',nan,...
  'FigPos',[],...
  'UFMFDiagnosticsFileStr',UFMFDiagnosticsFileStr,...
  'MovieFileStr',MovieFileStr,...
  'UFMFStreamFns',UFMFStreamFns,...
  'UFMFStreamMu',UFMFStreamMu,...
  'UFMFStreamSig',UFMFStreamSig,...
  'UFMFStream_nc',UFMFStream_nc,...
  'UFMFStreamYLim',struct,...
  'UFMFStreamXLim',[],...
  'parent',nan,...
  'SigColor',SigColor,...
  'MuColor',MuColor,...
  'DataColor',DataColor,...
  'UFMFSummaryFns',UFMFSummaryFns,...
  'UFMFSummaryStatFns',UFMFSummaryStatFns,...
  'NBkgdScanLines',NBkgdScanLines,...
  'NBkgdBins',NBkgdBins,...
  'BackSubNFramesSample',BackSubNFramesSample,...
  'BackSubThreshLow',BackSubThreshLow,...
  'BackSubThreshHigh',BackSubThreshHigh,...
  'BackSubMinCCArea',BackSubMinCCArea);

%% Figure positions

if ishandle(parent),
  ParentPos = get(parent,'Position');
else
  ParentPos = get(0,'ScreenSize');
end

% we set the figure to be inset from the parent by the following amounts
OutBorderTop = 100;
OutBorderLeft = 100;
OutBorderBottom = 50;
OutBorderRight = 50;

% we set axes to be inset from the figure by the following amounts
FigBorderLeft = 10;
FigBorderRight = 10;
FigBorderTop = 20;
FigBorderBottom = 10;

% amount of space required for x, y labels, tick labels
YLabelSpace = 25;
YTickSpace = 25;
XLabelSpace = 20;
XTickSpace = 20;

% amount of space to skip between everything
BorderX = 5;
BorderY = 5;

% width of the table
TableWidth = 550;
% height of a row of the table
TableRowHeight = 19;

% fraction of figure the table can take
MaxTableHeightFrac = .6;
MaxTableWidthFrac = .5;

% fraction of width the background axes should take
BkgdAxesWidthFrac = .225;

% fraction of width the intensity histogram should take
HistWidthFrac = .225;

%% Read files

% read UFMF diagnostics file
UFMFDiagnosticsFileName = fullfile(expdir,UFMFDiagnosticsFileStr);
[UFMFStats,success1,errmsg] = readUFMFDiagnostics(UFMFDiagnosticsFileName);
out.UFMFStats = UFMFStats;
if ~success1,
  return;
end

if ~isfield(UFMFStats,'stream'),
  errmsg = 'Stream not read from UFMF diagnostics file';
  return;
end
if ~isfield(UFMFStats.stream,'timestamp'),
  errmsg = 'timestamp field of UFMF stream not found';
  return;
end
if ~isfield(UFMFStats,'summary'),
  errmsg = 'Summary stats not read from UFMF diagnostics file';
  return;
end

% open video file
MovieFile = fullfile(expdir,MovieFileStr);
[readframe,nframes,fid,headerinfo] = get_readframe_fcn(MovieFile);
if nframes ~= UFMFStats.summary.nFrames,
  warnings{end+1} = sprintf('Number of frames read from movie (%d) does not equal number of frames recorded in UFMF Stats (%d)',nframes,UFMFStats.summary.nFrames);
end
UFMFStats.summary.ImageHeight = headerinfo.max_height;
UFMFStats.summary.ImageWidth = headerinfo.max_width;

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

%% do a little bit of background subtraction, connected components

framessample = unique(round(linspace(1,nframes,BackSubNFramesSample)));
BackSubNFramesSample = length(framessample);
areas = [];
nccs = zeros(1,BackSubNFramesSample);
for i = 1:BackSubNFramesSample,
  im = double(readframe(framessample(i)));
  diffim = abs(im-bkgdim);
  isForeLow = diffim >= BackSubThreshLow;
  cc = bwconncomp(isForeLow);
  for j = 1:cc.NumObjects,
    areacurr = length(cc.PixelIdxList(j));
    if areacurr > BackSubMinCCArea && ...
        max(diffim(cc.PixelIdxList)) >= BackSubThreshHigh,
      nccs(i) = nccs(i)+1;
      areas(end+1) = areacurr; %#ok<AGROW>
    end
  end
end

BackSubStats.meanNConnectedComponents = mean(nccs);
BackSubStats.minNConnectedComponents = min(nccs);
BackSubStats.maxNConnectedComponents = max(nccs);
BackSubStats.stdNConnectedComponents = std(nccs,1);
BackSubStats.meanBlobArea = median(areas);
BackSubStats.minBlobArea = min(areas);
BackSubStats.maxBlobArea = max(areas);
BackSubStats.stdBlobArea = median(abs(areas-BackSubStats.meanBlobArea));

out.BackSubStats = BackSubStats;

BackSubStatFns = {'NConnectedComponents','BlobArea'};

%% done with the movie file

fclose(fid);

%% Statistics table: collect data
% make a table for now
% in the future, maybe show where these stats are relative to normal data

badidx = ~ismember(UFMFSummaryFns,fieldnames(UFMFStats.summary));
if any(badidx),
  warnings{end+1} = cat(2,'UFMF Summary Stats missing: ',sprintf('%s ',UFMFSummaryFns{badidx}));
end
UFMFSummaryFns(badidx) = [];
badidx = false(1,length(UFMFSummaryStatFns));
for i = 1:length(UFMFSummaryStatFns),
  meanfn = ['mean',UFMFSummaryStatFns{i}];
  if ~isfield(UFMFStats.summary,meanfn),
    badidx(i) = true;
  end
end
if any(badidx),
  warnings{end+1} = cat(2,'UFMF Summary Mean Stats missing: ',sprintf('%s ',UFMFSummaryStatFns{badidx}));
end
UFMFSummaryStatFns(badidx) = [];
badidx = false(1,length(BackSubStatFns));
for i = 1:length(BackSubStatFns),
  meanfn = ['mean',BackSubStatFns{i}];
  if ~isfield(BackSubStats,meanfn),
    badidx(i) = true;
  end
end
if any(badidx),
  warnings{end+1} = cat(2,'BackSub Stats missing: ',BackSubStatFns{badidx});
end
BackSubStatFns(badidx) = [];

nTableFns = length(UFMFSummaryFns) + length(UFMFSummaryStatFns) + length(BackSubStatFns);

data = cell(nTableFns,3);
rowheaders = cat(1,UFMFSummaryFns(:),UFMFSummaryStatFns(:),BackSubStatFns(:));
colheaders = {'Mean','Std','Min','Max'};
for i = 1:length(UFMFSummaryFns),
  fn = UFMFSummaryFns{i};
  data{i,1} = UFMFStats.summary.(fn);
end
off = length(UFMFSummaryFns);
for i = 1:length(UFMFSummaryStatFns),
  j = off + i;
  fn = UFMFSummaryStatFns{i};
  meanfn = ['mean',fn];
  if isfield(UFMFStats.summary,meanfn),
    data{j,1} = UFMFStats.summary.(meanfn);
  end
  stdfn = ['std',fn];
  if isfield(UFMFStats.summary,stdfn),
    data{j,2} = UFMFStats.summary.(stdfn);
  end
  minfn = ['min',fn];
  if isfield(UFMFStats.summary,minfn),
    data{j,3} = UFMFStats.summary.(minfn);
  end
  maxfn = ['max',fn];
  if isfield(UFMFStats.summary,maxfn),
    data{j,4} = UFMFStats.summary.(maxfn);
  end

end
off = off+length(UFMFSummaryStatFns);
for i = 1:length(BackSubStatFns),
  j = off + i;
  fn = BackSubStatFns{i};
  meanfn = ['mean',fn];
  if isfield(BackSubStats,meanfn),
    data{j,1} = BackSubStats.(meanfn);
  end
  stdfn = ['std',fn];
  if isfield(BackSubStats,stdfn),
    data{j,2} = BackSubStats.(stdfn);
  end
  minfn = ['min',fn];
  if isfield(BackSubStats,minfn),
    data{j,3} = BackSubStats.(minfn);
  end
  maxfn = ['max',fn];
  if isfield(BackSubStats,maxfn),
    data{j,4} = BackSubStats.(maxfn);
  end

end

%% layout figure

if ~ishandle(fig),
  if isnumeric(fig) && round(fig) == fig,
    figure(fig);
  else
    fig = figure;
  end
else
  figure(fig);
  clf;
end
out.fig = fig;

% set size of figure
if isempty(FigPos),
  l = ParentPos(1)+OutBorderLeft;
  FigWidth = ParentPos(3)-OutBorderLeft-OutBorderRight;
  b = ParentPos(2)+OutBorderBottom;
  FigHeight = ParentPos(4)-OutBorderBottom-OutBorderTop;
  FigPos = [l,b,FigWidth,FigHeight];
else
  FigWidth = FigPos(3);
  FigHeight = FigPos(4);
end
FigWidthFree = FigWidth - FigBorderLeft - FigBorderRight;
FigHeightFree = FigHeight - FigBorderTop - FigBorderBottom;
set(fig,'Units','Pixels','Position',FigPos,'Name',sprintf('Summary Stats %d',GUIi),'ToolBar','figure');

% table for statistics
TableHeight = min(TableRowHeight*(nTableFns+1),FigHeightFree*MaxTableHeightFrac);
TableWidth = min(TableWidth,FigWidthFree*MaxTableWidthFrac);
TableLeft = FigBorderLeft;
TableRight = TableLeft + TableWidth;
TableTop = FigHeight-FigBorderTop;
TableBottom = TableTop - TableHeight;
TablePos = [TableLeft,TableBottom,TableWidth,TableHeight];

% axes for UFMF stream data
nUFMFStreamFns = length(UFMFStreamFns);
UFMFStream_nr = ceil(nUFMFStreamFns/UFMFStream_nc);
StreamAxHeight = (TableHeight-XLabelSpace-XTickSpace-BorderY*(UFMFStream_nr-1))/UFMFStream_nr;
StreamAxWidth = (FigWidthFree - TableWidth) / UFMFStream_nc - (BorderX+YLabelSpace+YTickSpace);

l = TableRight + BorderX + YLabelSpace + YTickSpace;
StreamAx = nan(UFMFStream_nr,UFMFStream_nc);
for c = 1:UFMFStream_nc,
  t = TableTop;
  for r = 1:UFMFStream_nr,
    StreamAx(r,c) = axes('Parent',fig,'Units','Pixels','Position',[l,t-StreamAxHeight,StreamAxWidth,StreamAxHeight]);
    t = t - (StreamAxHeight + BorderY);
  end
  l = l + (BorderX + YLabelSpace + YTickSpace + StreamAxWidth);
end
StreamAx = StreamAx(:);
if UFMFStream_nc*UFMFStream_nr > nUFMFStreamFns,
  delete(StreamAx(nUFMFStreamFns+1:end));
  StreamAx = StreamAx(1:nUFMFStreamFns);
end
  
% axes for background model
BkgdAxesHeight = FigHeightFree - TableHeight - BorderY - XLabelSpace;
BkgdAxesWidth = FigWidthFree * BkgdAxesWidthFrac - BorderX/2;
BkgdAxesLeft = FigBorderLeft;
BkgdAxesBottom = FigBorderBottom + XLabelSpace;
BkgdAx = nan(1,2);
BkgdAx(1) = axes('Parent',fig,'Units','Pixels','Position',[BkgdAxesLeft,BkgdAxesBottom,BkgdAxesWidth,BkgdAxesHeight]);
BkgdAxesLeft = BkgdAxesLeft + BkgdAxesWidth + BorderX;
BkgdAx(2) = axes('Parent',fig,'Units','Pixels','Position',[BkgdAxesLeft,BkgdAxesBottom,BkgdAxesWidth,BkgdAxesHeight]);
BkgdAxesRight = BkgdAxesLeft + BkgdAxesWidth;

% axis for intensity histogram
HistHeight = BkgdAxesHeight - XTickSpace;
HistWidth = FigWidthFree*HistWidthFrac - BorderX - YLabelSpace - YTickSpace;
HistLeft = BkgdAxesRight + BorderX + YLabelSpace + YTickSpace;
HistBottom = FigBorderBottom + XLabelSpace + XTickSpace;
HistRight = HistLeft + HistWidth;
HistAx = axes('Parent',fig,'Units','Pixels','Position',[HistLeft,HistBottom,HistWidth,HistHeight]);

% axes for scan line intensities
ScanHeight = (HistHeight - ((NBkgdScanLines-1)*BorderY))/NBkgdScanLines;
ScanWidth = FigWidthFree - HistRight - BorderX - YLabelSpace;
ScanLeft = HistRight + BorderX + YLabelSpace;
ScanBottom = HistBottom;

ScanAx = nan(1,NBkgdScanLines);
for i = 1:NBkgdScanLines,
  ScanAx(i) = axes('Parent',fig,'Units','Pixels','Position',[ScanLeft,ScanBottom,ScanWidth,ScanHeight]);
  ScanBottom = ScanBottom + ScanHeight + BorderY;
end

%% plot the table

uitable(fig,'Units','Pixels','Position',TablePos,...
  'Data',data,'ColumnName',colheaders,'RowName',rowheaders,...
  'FontUnits','Pixels','FontSize',10.6667);


%% UFMF Diagnostics Stream plots

isbot = false(UFMFStream_nr,UFMFStream_nc);
isbot(end,:) = true;
x = UFMFStats.stream.timestamp(:)';
x = x - x(1);
if isempty(UFMFStreamXLim),
  UFMFStreamXLim = [-UFMFStreamXLimExtra*x(end),x(end)*(1+UFMFStreamXLimExtra)];
end
for i = 1:nUFMFStreamFns,
  fn = UFMFStreamFns{i};
  
  % plot standard deviation
  if isfield(UFMFStreamSig,fn) && isfield(UFMFStreamMu,fn),
    y = UFMFStreamMu.(fn)(:)';
    dy = UFMFStreamSig.(fn)(:)';
    patch(StreamAx(i),[x,fliplr(x)],[y+dy,fliplr(y-dy)],SigColor,'LineStyle','none');
    hold(StreamAx(i),'on');
  end
  if isfield(UFMFStreamMu,fn),
    plot(StreamAx(i),x,UFMFStreamMu.(fn)(:)','-','Color',MuColor);
    hold(StreamAx(i),'on');
  end
  
  y = UFMFStats.stream.(fn);
  plot(StreamAx(i),x,y,'.-','Color',DataColor);
  if ~isfield(UFMFStreamYLim,fn),
    miny = min(y);
    maxy = max(y);
    dy = (maxy - miny)*UFMFStreamYLimExtra;
    if dy == 0,
      dy = 1;
    end
    UFMFStreamYLim.(fn) = [miny-dy,maxy+dy];
  end
  axis(StreamAx(i),[UFMFStreamXLim,UFMFStreamYLim.(fn)]);
  if isbot(i),
    xlabel(StreamAx(i),'Time (s)');    
  else
    set(StreamAx(i),'xticklabel',{});
  end
  ylabel(StreamAx(i),fn);  
end
linkaxes(StreamAx,'x');

%% Show background model

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

% intensity histogram
edges = linspace(0,255,NBkgdBins+1);
ctrs = (edges(1:end-1)+edges(2:end))/2;
counts = hist(bkgdim(:),ctrs);
frac = counts / numel(bkgdim);
plot(HistAx,ctrs,frac,'.-','Color',DataColor);
axis(HistAx,[edges(1),edges(end),0,1]);
xlabel(HistAx,'Pixel intensity histogram');

% plot some scan lines through the center of the image at different
% orientations
x0 = (headerinfo.nc+1)/2;
y0 = (headerinfo.nc+1)/2;
r = min(headerinfo.nr,headerinfo.nc)/2;
theta = linspace(0,pi,NBkgdScanLines+1);
theta = theta(1:end-1);
off = -r+1:r-1;
hold(BkgdAx(1),'on');
for i = 1:NBkgdScanLines,
  s = sprintf('%d',round(theta(i)*180/pi));
  plot(BkgdAx(1),x0+cos(theta(i))*[-r,r],y0+sin(theta(i))*[-r,r],'-','Color',DataColor);
  text(x0+cos(theta(i))*r,y0+sin(theta(i))*r,s,'parent',BkgdAx(1),'Color',DataColor);
  x = round(x0 + cos(theta(i))*off);
  y = round(y0 + sin(theta(i))*off);  
  z = bkgdim(sub2ind([headerinfo.nr,headerinfo.nc],y,x));
  plot(ScanAx(i),off,z,'-','Color',DataColor);
  axis(ScanAx(i),[-r,r,-5,260]);
  set(ScanAx(i),'xticklabel',{},'yticklabel',{},'ytick',[0,122.5,255],'ticklength',[.005,.005]);
  ylabel(ScanAx(i),s);
end
xlabel(ScanAx(1),'Bkgd scan lines');

linkaxes(ScanAx);
