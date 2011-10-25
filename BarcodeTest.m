addpath ../JCtrax/filehandling;
addpath ../JCtrax/misc;

%% read barcode list
barcode_filename = 'barcode_test/Olympiad Trp Set 77.txt';
barcodes = importdata(barcode_filename);
nbarcodes = numel(barcodes);
%% start recording video

% name of output ufmf file
vid_filename = 'test.ufmf';

% time to record for
RecordTime = 10000;

Imaq_VideoFormat = 'Format 7, Mode 0';
% Camera adaptor
Imaq_Adaptor = 'udcam';
% Device name
Imaq_DeviceName = 'A622f';
% Video ROI Position
Imaq_ROIPosition = [128,0,1024,1024];
% Shutter period
Imaq_Shutter = 100;
% Gain
Imaq_Gain = 170;
% Brightness
Imaq_Brightness = 25;
% max frame rate
Imaq_MaxFrameRate = 31;
% Device ID
DeviceID = 0;
% maximum fraction of pixels that can be foreground to try compressing frame
UFMFMaxFracFgCompress = .2;
% number of frames the background model should be based on 
UFMFMaxBGNFrames = 100;
% number of seconds between updates to the background model
UFMFBGUpdatePeriod = 1;
% number of seconds between spitting out a new background model
UFMFBGKeyFramePeriod = 100;
% max length of box stored during compression
UFMFMaxBoxLength = 5;
% threshold for background subtraction
UFMFBackSubThresh = 15;
% first nFramesInit we always update the background model
UFMFNFramesInit = 100;
% while ramping up the background model, use the following keyframe periods
UFMFBGKeyFramePeriodInit = [1,10,25,50,75];
% Whether to compute UFMF diagnostics
UFMFPrintStats = 1;
% number of frames between outputting per-frame compression statistics: 0 means don't print, 1 means every frame
UFMFStatStreamPrintFreq = 30;
% number of frames between computing statistics of compression error. 0 means don't compute, 1 means every frame
UFMFStatComputeFrameErrorFreq = 30;
% whether to print information about the time each part of the computation takes
UFMFStatPrintTimings = 1;

imaqreset;
adaptorinfo = imaqhwinfo(Imaq_Adaptor);
vid = videoinput(Imaq_Adaptor,DeviceID,Imaq_VideoFormat);
timestamp = now;
datestrformat = 'yyyymmddTHHMMSS';

% create a temporary name for the log file
TmpUFMFLogFileName = sprintf('FBDC_UFMF_Log_%s.txt',...
  datestr(timestamp,datestrformat));

% create a temporary name for the diagnostics file
TmpUFMFStatFileName = sprintf('FBDC_UFMF_Diagnostics_%s.txt',...
  datestr(timestamp,datestrformat));
    
set(vid.Source,'maxFracFgCompress',UFMFMaxFracFgCompress,...
  'maxBGNFrames',UFMFMaxBGNFrames,...
  'BGUpdatePeriod',UFMFBGUpdatePeriod,...
  'BGKeyFramePeriod',UFMFBGKeyFramePeriod,...
  'boxLength',UFMFMaxBoxLength,...
  'backSubThresh',UFMFBackSubThresh,...
  'nFramesInit',UFMFNFramesInit,...
  'debugFileName',TmpUFMFLogFileName,...
  'statFileName',TmpUFMFStatFileName,...
  'printStats',UFMFPrintStats,...
  'statStreamPrintFreq',UFMFStatStreamPrintFreq,...
  'statComputeFrameErrorFreq',UFMFStatComputeFrameErrorFreq,...
  'statPrintTimings',UFMFStatPrintTimings,...
  'Shutter',Imaq_Shutter,...
  'Brightness',Imaq_Brightness);

set(vid,'ROIPosition',Imaq_ROIPosition);


v = get(vid.Source,'bgKeyFramePeriodInit');
l = min(length(v),length(UFMFBGKeyFramePeriodInit));
v(:) = 0;
v(1:l) = UFMFBGKeyFramePeriodInit(1:l);
set(vid.Source,'bgKeyFramePeriodInit',v);

set(vid.Source,'ufmfFileName',vid_filename);

preview(vid);

% gain needs to be set after preview for some reason?
% set gain if possible and necessary
set(vid.source,'Gain',Imaq_Gain);

%%

hfig = figure(2);
clf(hfig);
hax = gca;

thisPath = mfilename('fullpath');
parentDir = fileparts(thisPath);
jarpath = fullfile(parentDir, 'mysql-connector-java-5.0.8-bin.jar');
if ~ismember(jarpath,javaclasspath)
  javaaddpath(jarpath, '-end');
end

drv = com.mysql.jdbc.Driver;
url = 'jdbc:mysql://10.40.11.14:3306/flyboy?user=flyfRead&password=flyfRead';
%url = 'jdbc:mysql://mysql2.int.janelia.org:3306/flyboy?user=flyfRead&password=flyfRead';
con = drv.connect(url,'');
stm = con.createStatement;

niters = 1000;
dts = nan(niters,nbarcodes);
timestamps = nan(niters,nbarcodes);
nsamples_check = 10;


set(vid.Source,'nFramesTarget',RecordTime*Imaq_MaxFrameRate);
pause(5);
FrameCountsPrev = [-inf(1,nsamples_check-2),get(vid.Source,'nFramesLogged')];

for j = 1:niters,

  for i = 1:nbarcodes,
    barcode = barcodes(i);
    timestamps(j,i) = now;
    tic;
    scanValue = FlyBoyQuery( barcode, 'FB', 1, stm);
    dt = toc;
    %fprintf('%d: %f\n',i,dt);
    dts(j,i) = dt;
    
    % check on video
    FrameCount = get(vid.Source,'nFramesLogged');
    if FrameCount <= FrameCountsPrev(1),
      error('No frames recorded in the past %d samples',nsamples_check);
    end
    FrameCountsPrev = [FrameCountsPrev(2:end),FrameCount];
    empFrameRates(j,i) = get(vid.Source,'empFrameRate');
    
  end
  fprintf('** iter %d: mean = %f, std = %f, max = %f, nframes logged = %d\n',j,mean(dts(j,:)),std(dts(j,:)),max(dts(j,:)),get(vid.Source,'nFramesLogged'));  
  set(0,'CurrentFigure',hfig);
  plot(timestamps(j,:),dts(j,:)','b.-');
  if j == 1,
    hold on;
  end
  plot(timestamps(j,:),empFrameRates(j,:)/30,'g.-');
  plot(mean(timestamps(j,:)),mean(dts(j,:)),'ko','markerfacecolor','k');
  axisalmosttight;
  datetick;
  drawnow;
  
  if mod(j,10) == 0,
    
    %save BarcodeTest_reconnecting.mat timestamps dts empFrameRates niters barcodes barcode_filename;
    %saveas(gcf,'BarcodeTest_reconnecting.fig');
  
  end
  
end

set(vid.Source,'nFramesTarget',0);

%save BarcodeTest_reconnecting.mat;
%saveas(gcf,'BarcodeTest_reconnecting.fig');