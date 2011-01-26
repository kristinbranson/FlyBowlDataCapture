function [out,success,errmsg,warnings] = computeQuickStats(expdir,varargin)

success = false;
out = struct;
warnings = {};

% name of diagnostics file within experiment directory
UFMFDiagnosticsFileStr = 'ufmf_diagnostics.txt';
% name of video
MovieFileStr = 'movie.ufmf';
% name of temperature stream
TemperatureFileStr = 'temperature.txt';
% name of metadata file
MetaDataFileStr = 'Metadata.xml';
% streams to plot
UFMFStreamFns = {'bytes','nForegroundPx','nPxWritten','nFramesBuffered','nFramesDropped','FPS',...
  'meanPixelError','maxPixelError','maxFilterError','Temperature'};
% number of subplot columns
UFMFStream_nc = 5;
% for auto-setting axis limits
UFMFStreamXLimExtra = .01;
UFMFStreamYLimExtra = .05;
ScanLineYLim = [-5,260];
% average, std of statistics
UFMFStreamMu = struct;
UFMFStreamSig = struct;
UFMFSummaryMu = struct;
UFMFSummarySig = struct;
UFMFSummaryNStd = 3;

IntensityHistMu = [];
IntensityHistSig = [];
ScanLineMu = [];
ScanLineSig = [];
SigColor = [.75,.75,.75];
MuColor = [.25,.25,.25];
DataColor = [.7,0,0];
TableBackgroundColor = [1,1,1];
TableWarningColor = [1,.2,.2];

% name of file to export figure to 
SaveFileStr = '';
% name of file to export quick stats to
SaveDataStr = '';

% summaries to show
UFMFSummaryFns = {'nFrames','nFramesDroppedTotal','nFramesUncompressed','nUpdateBackgroundCalls','nWriteKeyFrameCalls','ImageWidth','ImageHeight','nTemperatureReadings','RoomTemperature','RoomHumidity'};
UFMFSummaryStatFns = {'FPS','CompressionRate','NForegroundPx','NPxWritten','MeanPixelError','MaxPixelError','MaxFilterError'};

% bkgd scan lines to plot
NBkgdScanLines = 4;
% number of bins for histogramming background intensities
NBkgdBins = 25;

BackSubNFramesSample = 10;
BackSubThreshLow = 10;
BackSubThreshHigh = 20;
BackSubMinCCArea = 5;
BackSubCloseRadius = 2;

[GUIi,fig,FigPos,...
  UFMFDiagnosticsFileStr,MovieFileStr,TemperatureFileStr,MetaDataFileStr,...
  UFMFStreamFns,UFMFStreamMu,UFMFStreamSig,...
  UFMFStream_nc,UFMFStreamYLim,UFMFStreamXLim,...
  parent,SigColor,MuColor,DataColor,...
  UFMFSummaryFns,UFMFSummaryStatFns,...
  UFMFSummaryMu,UFMFSummarySig,UFMFSummary_NStd,...
  NBkgdScanLines,ScanLineMu,ScanLineSig,...
  NBkgdBins,IntensityHistMu,IntensityHistSig,...
  BackSubNFramesSample,BackSubThreshLow,BackSubThreshHigh,BackSubMinCCArea,...
  SaveFileStr,SaveDataStr,...
  ScanLineYLim] = ...
  myparse(varargin,...
  'GUIInstance',1,...
  'FigHandle',nan,...
  'FigPos',[],...
  'UFMFDiagnosticsFileStr',UFMFDiagnosticsFileStr,...
  'MovieFileStr',MovieFileStr,...
  'TemperatureFileStr',TemperatureFileStr,...
  'MetaDataFileStr',MetaDataFileStr,...
  'UFMFStreamFns',UFMFStreamFns,...
  'UFMFStreamMu',UFMFStreamMu,...
  'UFMFStreamSig',UFMFStreamSig,...
  'UFMFStream_nc',UFMFStream_nc,...
  'UFMFStreamYLim',struct('FPS',[0,50]),...
  'UFMFStreamXLim',[],...
  'parent',nan,...
  'SigColor',SigColor,...
  'MuColor',MuColor,...
  'DataColor',DataColor,...
  'UFMFSummaryFns',UFMFSummaryFns,...
  'UFMFSummaryStatFns',UFMFSummaryStatFns,...
  'UFMFSummaryMu',UFMFSummaryMu,...
  'UFMFSummarySig',UFMFSummarySig,...
  'UFMFSummaryNstd',UFMFSummaryNStd,...
  'NBkgdScanLines',NBkgdScanLines,...
  'ScanLineMu',ScanLineMu,...
  'ScanLineSig',ScanLineSig,...
  'NBkgdBins',NBkgdBins,...
  'IntensityHistMu',IntensityHistMu,...
  'IntensityHistSig',IntensityHistSig,...
  'BackSubNFramesSample',BackSubNFramesSample,...
  'BackSubThreshLow',BackSubThreshLow,...
  'BackSubThreshHigh',BackSubThreshHigh,...
  'BackSubMinCCArea',BackSubMinCCArea,...
  'SaveFileStr',SaveFileStr,...
  'SaveDataStr',SaveDataStr,...
  'ScanLineYLim',ScanLineYLim); 

%% Figure positions

if ishandle(parent),
  ParentPos = get(parent,'Position');
else
  ParentPos = get(0,'ScreenSize');
end

% we set the figure to be inset from the parent by the following amounts
OutBorderTop = 50;
OutBorderLeft = 25;
OutBorderBottom = 50;
OutBorderRight = 25;

% we set axes to be inset from the figure by the following amounts
FigBorderLeft = 10;
FigBorderRight = 10;
FigBorderTop = 20;
FigBorderBottom = 10;

% amount of space required for x, y labels, tick labels
YLabelSpace = 15;
YTickSpace = 15;
XLabelSpace = 10;
XTickSpace = 10;

% amount of space to skip between everything
BorderX = 10;
BorderY = 10;

% for computing width, height of table
MinTableColumnWidth = 75;
TableRowLabelWidth = 250;
TableRowHeight = 20;

% fraction of figure the table can take
MaxTableHeightFrac = .3;

% fraction of height the stream axes should take in total
StreamHeightFrac = .37;

% fraction of width the background axes should take
BkgdAxesWidthFrac = .225;

% fraction of width the intensity histogram should take
HistWidthFrac = .225;

% showufmf figure
ShowUFMFBorderTop = 50;
ShowUFMFBorderLeft = 50;
ShowUFMFBorderBottom = 50;
ShowUFMFBorderRight = 50;

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

[UFMFStats,success1,errmsg] = readUFMFDiagnostics(UFMFDiagnosticsFileName);
out.UFMFStats = UFMFStats;
if ~success1,
  return;
end

UFMFStats.summary.ImageHeight = headerinfo.max_height;
UFMFStats.summary.ImageWidth = headerinfo.max_width;


% read temperature stream
TemperatureFileName = fullfile(expdir,TemperatureFileStr);
data = [];
if ~exist(TemperatureFileName,'file'),
  warnings{end+1} = sprintf('Temperature stream file %s does not exist',TemperatureFileName);
else
  try
    data = importdata(TemperatureFileName,',');
  catch ME,
    warnings{end+1} = sprintf('Error importing temperature stream: %s',getReport(ME,'basic','hyperlinks','off'));
  end
end
if isempty(data),
  tempTimestamp = [];
  temp = [];
elseif size(data,2) < 2,
  warnings{end+1} = 'Temperature data could not be read';
  tempTimestamp = [];
  temp = [];
else
  tempTimestamp = data(:,1);
  temp = data(:,2);
end

% read room temperature, humidity from metadata
RoomTemperature = nan;
RoomHumidity = nan;
MetaDataFileName = fullfile(expdir,MetaDataFileStr);
if exist(MetaDataFileName,'file'),
  metafid = fopen(MetaDataFileName,'r');
  while true,
    s = fgetl(metafid);
    if ~ischar(s),
      break;
    end
    tmp = regexpi(s,'.*<\s*environment .*temperature\w*=\w*"(?<temperature>[^"]*)".*','names','once');
    if ~isempty(tmp), RoomTemperature = tmp.temperature; end
    tmp = regexpi(s,'.*<\s*environment .*humidity\w*=\w*"(?<humidity>[^"]*)".*','names','once');
    if ~isempty(tmp), RoomHumidity = tmp.humidity; end
  end
  fclose(metafid);
end

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
BackSubCloseStrel = strel('disk',BackSubCloseRadius);
areas = [];
nccs = zeros(1,BackSubNFramesSample);
for i = 1:BackSubNFramesSample,
  im = double(readframe(framessample(i)));
  diffim = abs(im-bkgdim);
  isForeLow = diffim >= BackSubThreshLow;
  isForeLow = imclose(isForeLow,BackSubCloseStrel);
  cc = bwconncomp(isForeLow);
  for j = 1:cc.NumObjects,
    areacurr = length(cc.PixelIdxList{j});
    if areacurr > BackSubMinCCArea && ...
        max(diffim(cc.PixelIdxList{j})) >= BackSubThreshHigh,
      nccs(i) = nccs(i)+1;
      areas(end+1) = areacurr; %#ok<AGROW>
    end
  end
end

if isempty(nccs),
  BackSubStats.meanNConnComps = nan;
  BackSubStats.minNConnComps = nan;
  BackSubStats.maxNConnComps = nan;
  BackSubStats.stdNConnComps = nan;
else
  BackSubStats.meanNConnComps = mean(nccs);
  BackSubStats.minNConnComps = min(nccs);
  BackSubStats.maxNConnComps = max(nccs);
  BackSubStats.stdNConnComps = std(nccs,1);
end
if isempty(areas),
  BackSubStats.meanBlobArea = nan;
  BackSubStats.minBlobArea = nan;
  BackSubStats.maxBlobArea = nan;
  BackSubStats.stdBlobArea = nan;
else
  BackSubStats.meanBlobArea = median(areas);
  BackSubStats.minBlobArea = min(areas);
  BackSubStats.maxBlobArea = max(areas);
  BackSubStats.stdBlobArea = median(abs(areas-BackSubStats.meanBlobArea));
end
out.BackSubStats = BackSubStats;

BackSubStatFns = {'NConnComps','BlobArea'};

%% done with the movie file

fclose(fid);

%% add temperature to existing structs

UFMFStats.summary.nTemperatureReadings = length(temp);
UFMFStats.summary.RoomTemperature = RoomTemperature;
UFMFStats.summary.RoomHumidity = RoomHumidity;

if isempty(temp),
  BackSubStats.meanTemperature = nan;
  BackSubStats.minTemperature = nan;
  BackSubStats.maxTemperature = nan;
  BackSubStats.stdTemperature = nan;
  BackSubStats.meanTemperaturePeriod = nan;
  BackSubStats.minTemperaturePeriod = nan;
  BackSubStats.maxTemperaturePeriod = nan;
  BackSubStats.stdTemperaturePeriod = nan;
else
  BackSubStats.meanTemperature = mean(temp);
  BackSubStats.minTemperature = min(temp);
  BackSubStats.maxTemperature = max(temp);
  BackSubStats.stdTemperature = std(temp,1);
  dt = diff(tempTimestamp);
  BackSubStats.meanTemperaturePeriod = mean(dt);
  BackSubStats.minTemperaturePeriod = min(dt);
  BackSubStats.maxTemperaturePeriod = max(dt);
  BackSubStats.stdTemperaturePeriod = std(dt,1);
end

UFMFStats.stream.Temperature = [temp';tempTimestamp'];
BackSubStatFns(end+1:end+2) = {'Temperature','TemperaturePeriod'};

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

nTableFns1 = length(UFMFSummaryFns);
nTableFns2 = length(UFMFSummaryStatFns) + length(BackSubStatFns);

data1 = cell(nTableFns1,1);
data2 = cell(nTableFns2,4);
rowheaders1 = UFMFSummaryFns;
rowheaders2 = cat(1,UFMFSummaryStatFns(:),BackSubStatFns(:));
colheaders1 = {'Value'};
colheaders2 = {'Mean','Std','Min','Max'};
for i = 1:length(UFMFSummaryFns),
  fn = UFMFSummaryFns{i};
  if isfield(UFMFStats.summary,fn),
    data1{i,1} = htmlcolor(UFMFStats.summary.(fn),fn);
  end
end
off = 0;
for i = 1:length(UFMFSummaryStatFns),
  j = off + i;
  fn = UFMFSummaryStatFns{i};
  meanfn = ['mean',fn];
  if isfield(UFMFStats.summary,meanfn),
    data2{j,1} = htmlcolor(UFMFStats.summary.(meanfn),meanfn);
  end
  stdfn = ['std',fn];
  if isfield(UFMFStats.summary,stdfn),
    data2{j,2} = htmlcolor(UFMFStats.summary.(stdfn),stdfn);
  end
  minfn = ['min',fn];
  if isfield(UFMFStats.summary,minfn),
    data2{j,3} = htmlcolor(UFMFStats.summary.(minfn),minfn);
  end
  maxfn = ['max',fn];
  if isfield(UFMFStats.summary,maxfn),
    data2{j,4} = htmlcolor(UFMFStats.summary.(maxfn),maxfn);
  end

end
off = off+length(UFMFSummaryStatFns);
for i = 1:length(BackSubStatFns),
  j = off + i;
  fn = BackSubStatFns{i};
  meanfn = ['mean',fn];
  if isfield(BackSubStats,meanfn),
    data2{j,1} = BackSubStats.(meanfn);
  end
  stdfn = ['std',fn];
  if isfield(BackSubStats,stdfn),
    data2{j,2} = BackSubStats.(stdfn);
  end
  minfn = ['min',fn];
  if isfield(BackSubStats,minfn),
    data2{j,3} = BackSubStats.(minfn);
  end
  maxfn = ['max',fn];
  if isfield(BackSubStats,maxfn),
    data2{j,4} = BackSubStats.(maxfn);
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
set(fig,'Units','Pixels','Position',FigPos,'Name',sprintf('Summary Stats %d',GUIi),'ToolBar','figure','NumberTitle','off');

% tables for statistics
TableColumnWidth = max((FigWidthFree - 2*TableRowLabelWidth - YLabelSpace - BorderX) / (length(colheaders1)+length(colheaders2)),MinTableColumnWidth);
TableHeight1 = min(TableRowHeight*(nTableFns1+1),FigHeightFree*MaxTableHeightFrac-XLabelSpace);
TableHeight2 = min(TableRowHeight*(nTableFns2+1),FigHeightFree*MaxTableHeightFrac-XLabelSpace);
TableHeight = max([TableHeight1,TableHeight2]);
TableWidth1 = TableRowLabelWidth + length(colheaders1)*TableColumnWidth;
TableWidth2 = TableRowLabelWidth + length(colheaders2)*TableColumnWidth;
TableLeft1 = FigBorderLeft;
TableTop = FigHeight-FigBorderTop;
TableBottom = TableTop - TableHeight;
TablePos1 = [TableLeft1,TableBottom,TableWidth1,TableHeight];
TableRight2 = FigWidth-FigBorderRight;
TableLeft2 = TableRight2 - TableWidth2;
TablePos2 = [TableLeft2,TableBottom,TableWidth2,TableHeight];

% axes for UFMF stream data
nUFMFStreamFns = length(UFMFStreamFns);
UFMFStream_nr = ceil(nUFMFStreamFns/UFMFStream_nc);
%StreamAxHeight = (TableHeight-XLabelSpace-XTickSpace-BorderY*(UFMFStream_nr-1))/UFMFStream_nr;
StreamAxHeightTotal = FigHeightFree*StreamHeightFrac;
StreamAxHeight = (StreamAxHeightTotal-BorderY*(UFMFStream_nr-1) - (XLabelSpace+XTickSpace))/UFMFStream_nr;
%StreamAxWidth = (FigWidthFree - TableWidth) / UFMFStream_nc - (BorderX+YLabelSpace+YTickSpace);
StreamAxWidth = (FigWidthFree-BorderX*(UFMFStream_nc-1)) / UFMFStream_nc  - (YLabelSpace+YTickSpace);
StreamAxTopTotal = TableBottom - BorderY - XLabelSpace;
StreamAxBottomTotal = StreamAxTopTotal - StreamAxHeightTotal;

l = FigBorderLeft + YLabelSpace + YTickSpace;
StreamAx = nan(UFMFStream_nr,UFMFStream_nc);
for c = 1:UFMFStream_nc,
  t = StreamAxTopTotal;
  for r = 1:UFMFStream_nr,
    StreamAx(r,c) = axes('Parent',fig,'Units','Pixels','Position',[l,t-StreamAxHeight,StreamAxWidth,StreamAxHeight],'FontUnits','pixels','Fontsize',9);
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
BkgdAxesTop = StreamAxBottomTotal - BorderY;
BkgdAxesBottom = FigBorderBottom + XLabelSpace;
BkgdAxesHeight = BkgdAxesTop - BkgdAxesBottom;
BkgdAxesWidth = FigWidthFree * BkgdAxesWidthFrac - BorderX/2;
BkgdAxesLeft = FigBorderLeft;
BkgdAx = nan(1,2);
BkgdAx(1) = axes('Parent',fig,'Units','Pixels','Position',[BkgdAxesLeft,BkgdAxesBottom,BkgdAxesWidth,BkgdAxesHeight],'FontUnits','pixels','Fontsize',9);
BkgdAxesLeft = BkgdAxesLeft + BkgdAxesWidth + BorderX;
BkgdAx(2) = axes('Parent',fig,'Units','Pixels','Position',[BkgdAxesLeft,BkgdAxesBottom,BkgdAxesWidth,BkgdAxesHeight],'FontUnits','pixels','Fontsize',9);
BkgdAxesRight = BkgdAxesLeft + BkgdAxesWidth;

% axis for intensity histogram
HistHeight = BkgdAxesHeight - XTickSpace;
HistWidth = FigWidthFree*HistWidthFrac - BorderX - YLabelSpace - YTickSpace;
HistLeft = BkgdAxesRight + BorderX + YLabelSpace + YTickSpace;
HistBottom = FigBorderBottom + XLabelSpace + XTickSpace;
HistRight = HistLeft + HistWidth;
HistAx = axes('Parent',fig,'Units','Pixels','Position',[HistLeft,HistBottom,HistWidth,HistHeight],'FontUnits','pixels','Fontsize',9);

% axes for scan line intensities
ScanHeight = (HistHeight - ((NBkgdScanLines-1)*BorderY))/NBkgdScanLines;
ScanLeft = HistRight + BorderX + YLabelSpace;
ScanRight = FigWidth - FigBorderRight;
ScanWidth = ScanRight - ScanLeft;
ScanBottom = HistBottom;

ScanAx = nan(1,NBkgdScanLines);
for i = 1:NBkgdScanLines,
  ScanAx(i) = axes('Parent',fig,'Units','Pixels','Position',[ScanLeft,ScanBottom,ScanWidth,ScanHeight],'FontUnits','pixels','Fontsize',9);
  ScanBottom = ScanBottom + ScanHeight + BorderY;
end

%% plot the tables

htable1 = uitable(fig,'Units','Pixels','Position',TablePos1,...
  'Data',data1,'ColumnName',colheaders1,'RowName',rowheaders1,...
  'FontUnits','Pixels','FontSize',10.6667,...
  'ColumnFormat',repmat({'char'},[1,length(colheaders1)]),...
  'ColumnWidth',repmat({TableColumnWidth},[1,length(colheaders1)]),...
  'BackgroundColor',[1,1,1]); %#ok<NASGU>
htable2 = uitable(fig,'Units','Pixels','Position',TablePos2,...
  'Data',data2,'ColumnName',colheaders2,'RowName',rowheaders2,...
  'FontUnits','Pixels','FontSize',10.6667,...
  'ColumnFormat',repmat({'char'},[1,length(colheaders2)]),...
  'ColumnWidth',repmat({TableColumnWidth},[1,length(colheaders2)])); %#ok<NASGU>


%% UFMF Diagnostics Stream plots

isbot = false(UFMFStream_nr,UFMFStream_nc);
isbot(end,:) = true;
x0 = UFMFStats.stream.timestamp(1);
x = UFMFStats.stream.timestamp(:)';
x = x - x0;
maxx = x(end);
if isfield(UFMFStreamMu,'timestamp'),
  maxx = max(maxx,max(UFMFStreamMu.timestamp));
end
if isempty(UFMFStreamXLim),
  UFMFStreamXLim = [-UFMFStreamXLimExtra*maxx,maxx*(1+UFMFStreamXLimExtra)];
end
for i = 1:nUFMFStreamFns,
  fn = UFMFStreamFns{i};

  % plot standard deviation
  maxy = -inf;
  miny = inf;
  if isfield(UFMFStreamSig,fn) && isfield(UFMFStreamMu,fn),
    xmu = UFMFStreamMu.timestamp;
    y = UFMFStreamMu.(fn)(:)';
    dy = UFMFStreamSig.(fn)(:)';
    maxy = max(maxy,max(y+dy));
    miny = min(miny,min(y+dy));
    patch([xmu,fliplr(xmu)],[y+dy,fliplr(y-dy)],SigColor,'LineStyle','none','parent',StreamAx(i));
    hold(StreamAx(i),'on');
  end
  if isfield(UFMFStreamMu,fn),
    maxy = max(maxy,max(UFMFStreamMu.(fn)(:)));
    miny = min(miny,min(UFMFStreamMu.(fn)(:)));
    xmu = UFMFStreamMu.timestamp;
    plot(StreamAx(i),xmu,UFMFStreamMu.(fn)(:)','-','Color',MuColor);
    hold(StreamAx(i),'on');
  end
  
  if ~isfield(UFMFStats.stream,fn) || isempty(UFMFStats.stream.(fn)),
    continue;
  end
  
  if size(UFMFStats.stream.(fn),1) == 2,
    xcurr = UFMFStats.stream.(fn)(2,:) - UFMFStats.stream.(fn)(2,1);
  else
    xcurr = x;
  end
  
  y = UFMFStats.stream.(fn)(1,:);
  miny = min(miny,min(y(:)));
  maxy = max(maxy,max(y(:)));
  plot(StreamAx(i),xcurr,y,'.-','Color',DataColor);
  if ~isfield(UFMFStreamYLim,fn),
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

%% Show background image

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

out.BkgdIntensityHist.ctrs = ctrs;
out.BkgdIntensityHist.frac = frac;

%% plot some scan lines through the center of the image at different
% orientations
x0 = (headerinfo.nc+1)/2;
y0 = (headerinfo.nc+1)/2;
r = min(headerinfo.nr,headerinfo.nc)/2;
theta = linspace(0,pi,NBkgdScanLines+1);
theta = theta(1:end-1);
off = -r+1:r-1;
hold(BkgdAx(1),'on');
out.BkgdScanLine.theta = theta;
out.BkgdScanLine.intensities = cell(NBkgdScanLines,1);
for i = 1:NBkgdScanLines,
  s = sprintf('%d',round(theta(i)*180/pi));
  % draw a line on the background
  plot(BkgdAx(1),x0+cos(theta(i))*[-r,r],y0+sin(theta(i))*[-r,r],'-','Color',DataColor);
  text(x0+cos(theta(i))*r,y0+sin(theta(i))*r,s,'parent',BkgdAx(1),'Color',DataColor);
  
  % sample
  x = round(x0 + cos(theta(i))*off);
  y = round(y0 + sin(theta(i))*off);  
  z = bkgdim(sub2ind([headerinfo.nr,headerinfo.nc],y,x));
  
  out.BkgdScanLine.intensities{i} = z;
  
  % standard deviation
  if size(ScanLineSig,1) >= i && size(ScanLineMu,1) >= i,
    y = ScanLineMu(i,:);
    dy = ScanLineSig(i,:);
    patch([off,fliplr(off)],[y+dy,fliplr(y-dy)],SigColor,'LineStyle','none','parent',ScanAx(i));
    hold(ScanAx(i),'on');
  end
  % mean
  if size(ScanLineMu,1) >= i,
    plot(ScanAx(i),off,ScanLineMu(i,:),'-','Color',MuColor);
    hold(ScanAx(i),'on');
  end
  
  % plot actual data
  plot(ScanAx(i),off,z,'-','Color',DataColor);
  axis(ScanAx(i),[-r,r,ScanLineYLim]);
  
  set(ScanAx(i),'xticklabel',{},'yticklabel',{},'ytick',[0,122.5,255],'ticklength',[.005,.005]);
  ylabel(ScanAx(i),s);
end
xlabel(ScanAx(1),'Bkgd scan line intensities');

linkaxes(ScanAx);

%% save figure

if ~isempty(SaveFileStr),
  SaveFileName = fullfile(expdir,SaveFileStr);
  export_fig(SaveFileName,fig);
end

%% save data

if ~isempty(SaveDataStr),
  SaveDataName = fullfile(expdir,SaveDataStr);
  % out.BackSubStats
  datafid = fopen(SaveDataName,'w');
  [success1,errmsg1] = csvwrite(datafid,out.BackSubStats,'BackSubStats');
  if ~success1,
    warnings{end+1} = sprintf('Error writing BackSubStats: %s',errmsg1);
  end
  % out.BkgdIntensityHist
  [success1,errmsg1] = csvwrite(datafid,out.BkgdIntensityHist,'BkgdIntensityHist');
  if ~success1,
    warnings{end+1} = sprintf('Error writing BkgdIntensityHist: %s',errmsg1);
  end
  % out.BkgdScanLine
  [success1,errmsg1] = csvwrite(datafid,out.BkgdScanLine,'BkgdScanLine');
  if ~success1,
    warnings{end+1} = sprintf('Error writing BkgdScanLine: %s',errmsg1);
  end
  fclose(datafid);
end

%% showufmf

ShowUFMFPos = [FigPos(1)+ShowUFMFBorderLeft,FigPos(2)+ShowUFMFBorderBottom,nan,nan];
%out.showufmf_handle = showufmf('UFMFName',MovieFile,'BackSubThresh',BackSubThreshLow);
out.showufmf_handle = showufmf('UFMFName',MovieFile,'BackSubThresh',BackSubThreshLow,'FigPos',ShowUFMFPos);

%% succeeded
success = true;
out.UFMFStats = UFMFStats;

function s = htmlcolor(v,fn)
  if ischar(v),
    s = v;
    v = str2double(v);
  else
    s = num2str(v);
  end
  if ~isfield(UFMFSummaryMu,fn) || ~isfield(UFMFSummarySig,fn),
    return;
  end
  if isnan(v),
    w = 1;
  else
    nsig = abs(v-UFMFSummaryMu.(fn))./max(.000001,UFMFSummarySig.(fn));
    w = min(1,nsig / UFMFSummary_NStd);
  end
  color = round((TableBackgroundColor*(1-w) + TableWarningColor*w)*255);
  s = sprintf('<html><font style="background-color: #%02x%02x%02x">%s</font></html>',color(1),color(2),color(3),num2str(UFMFStats.summary.(fn)));
end

end