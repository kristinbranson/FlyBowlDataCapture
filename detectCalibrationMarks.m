function [registerfn,offX,offY,offTheta,scale,calibrationPoints,bowlMarkerPoints,...
  featureStrengths,bowlMarkerTheta,dtheta,bkgdImage,...
  nPairs,...
  nLeftCalibrationPoints,nRightCalibrationPoints,...
  nTopCalibrationPoints,nBottomCalibrationPoints] = ...
  detectCalibrationMarks(varargin)

[bkgdImage,movieName,bkgdNSampleFrames,diskFilterRadius,...
  minFeatureStrengthLow,minFeatureStrengthHigh,...
  minDistCenterFrac,maxDistCenterFrac,...
  maxDistCornerFrac_BowlLabel,...
  nCalibrationPoints,featureRadius,...
  maxDThetaMate,...
  pairDist_mm,...
  bowlMarkerPairTheta_true,...
  maxDThetaBowlMarkerPair,...
  markerPairAngle_true,...
  DEBUG] = ...
  myparse(varargin,...
  'bkgdImage',[],...
  'movieName','',...
  'bkgdNSampleFrames',10,...
  'diskFilterRadius',11,...
  'minFeatureStrengthLow',20,...
  'minFeatureStrengthHigh',30,...
  'minDistCenterFrac',.5,...
  'maxDistCenterFrac',.57,...
  'maxDistCornerFrac_BowlLabel',.14,...
  'nCalibrationPoints',8,...
  'featureRadius',25,...
  'maxDThetaMate',10*pi/180,...
  'pairDist_mm',133,...
  'bowlMarkerPairTheta_true',-3*pi/4,...
  'maxDThetaBowlMarkerPair',pi/12,...
  'markerPairAngle_true',pi/6,...
  'debug',false);

if isempty(bkgdImage),
  if isempty(movieName),
    error('If bkgdImage not input, then movieName must be input.');
  end
  if ~exist(movieName,'file'),
    error('Movie file %s does nhot exist',movieName);
  end
  % open the movie
  [readframe,nframes,fid,headerinfo] = get_readframe_fcn(movieName);
  
  % take the median
  if headerinfo.nmeans > 1,
    [meanims,headerinfo] = ufmf_read_mean(headerinfo,'meani',2:headerinfo.nmeans);
  else
    sampleframes = unique(round(linspace(1,headerinfo.nframes,bkgdNSampleFrames)));
    meanims = repmat(double(readframe(1)),[1,1,1,bkgdNSampleFrames]);
    for i = 2:bkgdNSampleFrames,
      meanims(:,:,:,i) = double(readframe(sampleframes(i)));
    end
  end
  meanims = double(meanims);
  bkgdImage = median(meanims,4);
  fclose(fid);
end

[nr,nc,ncolors] = size(bkgdImage);
r = min(nr,nc);

% compute gradient magnitude image
gradI = [diff(bkgdImage,1,1).^2;zeros(1,nc)] + [diff(bkgdImage,1,2).^2,zeros(nr,1)];
% filter with uniform filter of input radius
fil = fspecial('disk',diskFilterRadius);
filI1 = imfilter(gradI,fil,0,'same');

% compute distance from center of image
minDistCenter = minDistCenterFrac * r;
maxDistCenter = maxDistCenterFrac * r;
[xGrid,yGrid] = meshgrid(1:nc,1:nr);
distCenter = sqrt((xGrid-nc/2).^2 + (yGrid-nr/2).^2);

% threshold distance from center
filI2 = filI1;
filI2(distCenter < minDistCenter | distCenter > maxDistCenter) = 0;

calibrationPoints = [];
featureStrengths = [];
[dxGrid,dyGrid] = meshgrid(-featureRadius:featureRadius,-featureRadius:featureRadius);
filI3 = filI2;
for i = 1:nCalibrationPoints,
  
  [success,x,y,featureStrength,filI3] = getNextFeaturePoint(filI3);
  if ~success,
    break;
  end
  calibrationPoints(:,i) = [x;y];
  featureStrengths(i) = featureStrength;
  
end

% find bowl label
% compute distance to corners
distCorner = inf(nr,nc);
corners = [1,1,nc,nc;1,nr,nr,1];
for i = 1:size(corners,2),
  distCorner = min(distCorner, sqrt( (xGrid-corners(1,i)).^2 + (yGrid-corners(2,i)).^2 ));
end

% threshold max distance to some corner
filI4 = filI1;
maxDistCorner_BowlLabel = maxDistCornerFrac_BowlLabel * r;
filI4(distCorner > maxDistCorner_BowlLabel) = 0;

% zero out all calibration points
for i = 1:size(calibrationPoints,2),
  x = calibrationPoints(1,i);
  y = calibrationPoints(2,i);
  i1 = max(1,round(x)-featureRadius);
  i2 = min(nc,round(x)+featureRadius);
  j1 = max(1,round(y)-featureRadius);
  j2 = min(nr,round(y)+featureRadius);
  filI4(j1:j2,i1:i2) = 0;  
end

% find maximum 
[success,x,y] = getNextFeaturePoint(filI4);
if success,
  bowlMarkerPoints = [x;y];
else
  bowlMarkerPoints = nan(2,1);
end

% origin is the average of all the calibration points
isleft = calibrationPoints(1,:) <= nc/2;
nLeftCalibrationPoints = nnz(isleft);
nRightCalibrationPoints = nnz(~isleft);
istop = calibrationPoints(2,:) >= nr/2;
nTopCalibrationPoints = nnz(istop);
nBottomCalibrationPoints = nnz(~istop);

originX = (sum(calibrationPoints(1,isleft))/nLeftCalibrationPoints + ...
  sum(calibrationPoints(1,~isleft))/nRightCalibrationPoints)/2;
originY = (sum(calibrationPoints(2,istop))/nTopCalibrationPoints + ...
  sum(calibrationPoints(2,~istop))/nBottomCalibrationPoints)/2;

offX = -originX;
offY = -originY;

% sort calibration points counterclockwise from bowl label
if success,
  bowlMarkerTheta = atan2(bowlMarkerPoints(2)-originY,bowlMarkerPoints(1)-originX);
else
  bowlMarkerTheta = atan2(1-originY,1-originX);
end
theta = atan2(calibrationPoints(2,:)-originY,calibrationPoints(1,:)-originX);
% offset from bowlMarkerTheta
dtheta = mod((theta - bowlMarkerTheta),2*pi);
[dtheta,order] = sort(dtheta);
calibrationPoints = calibrationPoints(:,order);
featureStrengths = featureStrengths(order);


% take the average of the pair of points around the bowl marker
d1 = mod(dtheta(1)+pi,2*pi)-pi;
d2 = mod(dtheta(end)+pi,2*pi)-pi;
inrange = d1 > 0 && (abs(abs(d1) - markerPairAngle_true/2) <= maxDThetaBowlMarkerPair) && ...
  d2 < 0 && (abs(abs(d2) - markerPairAngle_true/2) <= maxDThetaBowlMarkerPair);
if inrange,
  x = (calibrationPoints(1,1)+calibrationPoints(1,end))/2;
  y = (calibrationPoints(2,1)+calibrationPoints(2,end))/2;
  bowlMarkerPairTheta = atan2(y-originY,x-originX);
else
  bowlMarkerPairTheta = bowlMarkerTheta;
end

offTheta = mod(bowlMarkerPairTheta_true-bowlMarkerPairTheta+pi,2*pi)-pi;

nPairs = 0;
d = 0;
for i = 1:size(calibrationPoints,2),
  thetaCurr = dtheta(i);
  if thetaCurr > pi,
    break;
  end
  [dThetaMate,j] = min(abs(thetaCurr+pi-dtheta));
  isMate = dThetaMate <= maxDThetaMate;
  if isMate,
    d = d + sqrt(diff(calibrationPoints(1,[i,j])).^2+diff(calibrationPoints(2,[i,j])).^2);
    nPairs = nPairs + 1;
  end
end
meanDistPair_px = d / nPairs;
scale = pairDist_mm / meanDistPair_px;

registerfn = @(x,y) register(x,y,offX,offY,offTheta,scale);

if DEBUG,
  figure(1);
  clf;
  hax = zeros(1,3);
  hax(1) = subplot(1,4,1);
  imagesc(bkgdImage);
  hold on;
  l = pairDist_mm/4 / scale;
  quiver(originX,originY,cos(-offTheta)*l,sin(-offTheta)*l,0,'k-');
  quiver(originX,originY,cos(-offTheta+pi/2)*l,sin(-offTheta+pi/2)*l,0,'k-');
  plot(calibrationPoints(1,:),calibrationPoints(2,:),'ks');
  plot(bowlMarkerPoints(1),bowlMarkerPoints(2),'mo');
  axis image xy;
  hax(2) = subplot(1,4,2);
  image(cat(3,min(1,bkgdImage/255 + double(filI1 >= minFeatureStrengthLow)*.3), repmat(bkgdImage/255,[1,1,2])));
  hold on;
  quiver(originX,originY,cos(-offTheta)*l,sin(-offTheta)*l,0,'k-');
  quiver(originX,originY,cos(-offTheta+pi/2)*l,sin(-offTheta+pi/2)*l,0,'k-');
  scatter(calibrationPoints(1,:),calibrationPoints(2,:),50,1:size(calibrationPoints,2),'s');
  plot(bowlMarkerPoints(1),bowlMarkerPoints(2),'mo');
  axis image xy;
  hax(3) = subplot(1,4,3);
  imagesc(filI1);
  hold on;
  quiver(originX,originY,cos(-offTheta)*l,sin(-offTheta)*l,0,'w-');
  quiver(originX,originY,cos(-offTheta+pi/2)*l,sin(-offTheta+pi/2)*l,0,'w-');
  plot(calibrationPoints(1,:),calibrationPoints(2,:),'ks');
  plot(bowlMarkerPoints(1),bowlMarkerPoints(2),'mo');
  axis image xy;
  linkaxes(hax);
  subplot(1,4,4);
  tmp = linspace(0,2*pi,100);
  plot(cos(tmp)*pairDist_mm/2,sin(tmp)*pairDist_mm/2,'b');
  hold on;
  tmp = pi/2:pi/2:2*pi;
  plot([cos(bowlMarkerPairTheta_true+markerPairAngle_true/2+tmp)*pairDist_mm/2;zeros(size(tmp))],...
    [sin(bowlMarkerPairTheta_true+markerPairAngle_true/2+tmp)*pairDist_mm/2;zeros(size(tmp))],'g-');
  plot([cos(bowlMarkerPairTheta_true-markerPairAngle_true/2+tmp)*pairDist_mm/2;zeros(size(tmp))],...
    [sin(bowlMarkerPairTheta_true-markerPairAngle_true/2+tmp)*pairDist_mm/2;zeros(size(tmp))],'g-');
  plot([0,cos(bowlMarkerPairTheta_true)*pairDist_mm/2],[0,sin(bowlMarkerPairTheta_true)*pairDist_mm/2],'m-');
  [x,y] = registerfn(calibrationPoints(1,:),calibrationPoints(2,:));
  plot(x,y,'ks');
  [x,y] = registerfn(bowlMarkerPoints(1),bowlMarkerPoints(2));
  plot(x,y,'mo');
  quiver(0,0,pairDist_mm/4,0,0,'k');
  quiver(0,0,0,pairDist_mm/4,0,'k');
  axis equal;
  axisalmosttight;
end

function [success,x,y,featureStrength,filI] = getNextFeaturePoint(filI)

  success = false;

  % find the next strongest feature
  [featureStrength,j] = max(filI(:));
  [y,x] = ind2sub([nr,nc],j);
  
  % make sure it meets threshold
  if featureStrength < minFeatureStrengthHigh,
    return;
  end

  % subpixel accuracy: take box around point and compute weighted average
  % of feature strength
  [box] = padgrab(filI,0,y-featureRadius,y+featureRadius,x-featureRadius,x+featureRadius);
  box = double(box > minFeatureStrengthLow);
  Z = sum(box(:));
  dx = sum(box(:).*dxGrid(:))/Z;
  dy = sum(box(:).*dyGrid(:))/Z;
  x = x + dx;
  y = y + dy;
  
  % zero out region around feature
  i1 = max(1,round(x)-featureRadius);
  i2 = min(nc,round(x)+featureRadius);
  j1 = max(1,round(y)-featureRadius);
  j2 = min(nr,round(y)+featureRadius);
  filI(j1:j2,i1:i2) = 0;
  
  success = true;

end

  function [x,y] = register(x,y,offX,offY,offTheta,scale)
    sz = size(x);
    if numel(sz) ~= numel(size(y)) || ~all(sz == size(y)),
      error('Size of x and y must match');
    end
    costheta = cos(offTheta); sintheta = sin(offTheta);
    X = [x(:)'+offX;y(:)'+offY];
    X = [costheta,-sintheta;sintheta,costheta] * X * scale;
    x = reshape(X(1,:),sz);
    y = reshape(X(2,:),sz);    
  end

end