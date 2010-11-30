function calibration = detectCalibrationMarks(varargin)

%% parse inputs

[saveName,...
  bkgdImage,movieName,annName,bkgdNSampleFrames,...
  method,...
  circleImageType,circleRLim,circleXLim,circleYLim,...
  crossFilterRadius,nRotations,minCrossFeatureStrength,...
  diskFilterRadius,minFeatureStrengthLow,minFeatureStrengthHigh,...
  minDistCenterFrac,maxDistCenterFrac,...
  maxDistCornerFrac_BowlLabel,...
  nCalibrationPoints,featureRadius,...
  maxDThetaMate,...
  pairDist_mm,...
  circleRadius_mm,...
  bowlMarkerPairTheta_true,...
  maxDThetaBowlMarkerPair,...
  markerPairAngle_true,...
  DEBUG,...
  calibrationData,...
  nr,nc] = ...
  myparse(varargin,...
  'saveName','',...
  'bkgdImage',[],...
  'movieName','',...
  'annName','',...
  'bkgdNSampleFrames',10,...
  'method','normcorr',...
  'circleImageType','raw',...
  'circleRLim',[.4,.55],...
  'circleXLim',[.3,.6],...
  'circleYLim',[.3,.6],...
  'crossFilterRadius',9,...
  'nRotations',20,...
  'minCrossFeatureStrength',.92,...
  'diskFilterRadius',11,...
  'minFeatureStrengthLow',20,...
  'minFeatureStrengthHigh',30,...
  'minDistCenterFrac',.5,...
  'maxDistCenterFrac',.57,...
  'maxDistCornerFrac_BowlLabel',.17,...
  'nCalibrationPoints',8,...
  'featureRadius',25,...
  'maxDThetaMate',10*pi/180,...
  'pairDist_mm',133,...
  'circleRadius_mm',63.5,...
  'bowlMarkerPairTheta_true',-3*pi/4,...
  'maxDThetaBowlMarkerPair',pi/12,...
  'markerPairAngle_true',pi/6,...
  'debug',false,...
  'calibrationData',[],...
  'nr',[],'nc',[]);

%% return register function

if ~isempty(calibrationData),
  calibrationData.registerfn = @(x,y) register(x,y,calibrationData.offX,...
    calibrationData.offY,calibrationData.offTheta,calibrationData.scale);
  return;
end

%% get background image

isBkgdImage = ~isempty(bkgdImage);

if ~isBkgdImage && ~isempty(annName),
  if ~exist(annName,'file'),
    error('Ann file %s does not exist',annName);
  end
  % try reading 
  [bkgdImage,bkgdMed,bkgdMean,bg_algorithm,movie_height,movie_width] = ...
    read_ann(annName,'background_center',...
    'background_median','background_mean','bg_algorithm',...
    'movie_height','movie_width');
  if isempty(bkgdImage),
    if strcmpi(bg_algorithm,'median'),
      bkgdImage = bkgdMed;
    else
      bkgdImage = bkgdMean;
    end
  end
  if isempty(bkgdImage),
    error('Could not read background center from ann file');
  end
  if ~isempty(movie_height),
    nr = movie_height;
  end
  if ~isempty(movie_width),
    nc = movie_width;
  end
  if isempty(nr) || isempty(nc),
    error('Shape of movie could not be read from ann file');
  end
  bkgdImage = reshape(bkgdImage,[nr,nc]);
  isBkgdImage = true;
end
if ~isBkgdImage,
  if isempty(movieName),
    error('Either bkgdImage, annName, or movieName must be input. Ann file must contain background center parameter');
  end
  if ~exist(movieName,'file'),
    error('Movie file %s does not exist',movieName);
  end
  % open the movie
  [readframe,~,fid,headerinfo] = get_readframe_fcn(movieName);
  
  % take the median
  if headerinfo.nmeans > 1,
    meanims = ufmf_read_mean(headerinfo,'meani',2:headerinfo.nmeans);
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

[nr,nc,ncolors] = size(bkgdImage); %#ok<NASGU>
r = min(nr,nc);

%% feature detection filtering

% compute gradient magnitude image
gradI = [diff(bkgdImage,1,1).^2;zeros(1,nc)] + [diff(bkgdImage,1,2).^2,zeros(nr,1)];
% filter with uniform filter of input radius
fil = fspecial('disk',diskFilterRadius);
gradfilI = imfilter(gradI,fil,0,'same');

if strcmpi(method,'normcorr'),
  
  % make a cross filter
  fil0 = zeros(crossFilterRadius*2+1);
  fil0(crossFilterRadius+1,:) = 1;
  fil0(:,crossFilterRadius+1) = 1;
  
  % steer
  fils = cell(1,nRotations);
  thetas = linspace(0,90,nRotations+1);
  thetas = thetas(1:end-1);
  for i = 1:nRotations,
    fils{i} = 1-2*imrotate(fil0,thetas(i),'bilinear','loose');
  end

  % compute normalized maximum correlation
  filI1 = -inf(nr,nc);
  for i = 1:nRotations,
    filI1 = max(filI1,imfilter(bkgdImage,fils{i},'replicate') ./ ...
                      imfilter(bkgdImage,ones(size(fils{i})),'replicate'));
  end
  
elseif strcmpi(method,'gradient'),
  
  filI1 = gradfilI;
  
elseif strcmpi(method,'circle'),
  
  % hough circle transform to detect 
  if strcmpi(circleImageType,'raw'),
    circleim = bkgdImage;
  elseif strcmpi(circleImageType,'edge'),
    circleim = gradI;
  else
    error('Unknown circleImageType %s',circleImageType);
  end
  [circleCenterX,circleCenterY,circleRadius] = hough_circle(circleim,'rlim',circleRLim,'xlim',circleXLim,'ylim',circleYLim);

else
  
  error('Unknown method for calibration mark detection: %s',method);
  
end


%% find bowl label

% compute distance to corners
[xGrid,yGrid] = meshgrid(1:nc,1:nr);
[dxGrid,dyGrid] = meshgrid(-featureRadius:featureRadius,-featureRadius:featureRadius);
distCorner = inf(nr,nc);
corners = [1,1,nc,nc;1,nr,nr,1];
for i = 1:size(corners,2),
  distCorner = min(distCorner, sqrt( (xGrid-corners(1,i)).^2 + (yGrid-corners(2,i)).^2 ));
end

% threshold max distance to some corner
filI4 = gradfilI;
maxDistCorner_BowlLabel = maxDistCornerFrac_BowlLabel * r;
filI4(distCorner > maxDistCorner_BowlLabel) = 0;

% find maximum 
[success,x,y] = getNextFeaturePoint(filI4,'grad2');
if success,
  bowlMarkerPoints = [x;y];
else
  error('Could not detect bowl marker');
end

%% find calibration points

if ~strcmpi(method,'circle'),

  % compute distance from center of image
  minDistCenter = minDistCenterFrac * r;
  maxDistCenter = maxDistCenterFrac * r;
  distCenter = sqrt((xGrid-nc/2).^2 + (yGrid-nr/2).^2);
  
  % threshold distance from center
  filI2 = filI1;
  filI2(distCenter < minDistCenter | distCenter > maxDistCenter) = 0;
  
  % zero out bowl marker
  filI2 = zeroOutDetection(bowlMarkerPoints(1),bowlMarkerPoints(2),filI2);
  
  calibrationPoints = [];
  featureStrengths = [];
  filI3 = filI2;
  for i = 1:nCalibrationPoints,
    
    [success,x,y,featureStrength,filI3] = getNextFeaturePoint(filI3,method);
    if ~success,
      break;
    end
    calibrationPoints(:,i) = [x;y]; %#ok<AGROW>
    featureStrengths(i) = featureStrength; %#ok<AGROW>
    
  end
  
  if isempty(calibrationPoints),
    error('No calibration points detected');
  end
  
end

%% origin is the average of all the calibration points
if strcmpi('method','circle'),
  originX = circleCenterX;
  originY = circleCenterY;
else
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
end

offX = -originX;
offY = -originY;

%% sort calibration points counterclockwise from bowl label
if ~strcmpi(method,'circle'),

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
end

%% find the rotation

if strcmpi(method,'circle'),
  % calibration marker
  bowlMarkerPairTheta = bowlMarkerTheta;
else
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
end

offTheta = mod(bowlMarkerPairTheta_true-bowlMarkerPairTheta+pi,2*pi)-pi;


%% find scale

if strcmpi(method,'circle'),
  scale = circleRadius_mm / circleRadius;
else
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
end

registerfn = @(x,y) register(x,y,offX,offY,offTheta,scale);

calibration = struct('offX',offX,...
  'offY',offY,...
  'offTheta',offTheta,...
  'scale',scale,...
  'bowlMarkerTheta',bowlMarkerTheta,...
  'bkgdImage',bkgdImage);
if strcmpi(method,'circle'),
  calibration.circleCenterX = circleCenterX;
  calibration.circleCenterY = circleCenterY;
  calibration.circleRadius = circleRadius;
else
  calibration.calibrationPoints = calibrationPoints;
  calibration.bowlMarkerPoints = bowlMarkerPoints;
  calibration.featureStrengths = featureStrengths;
  calibration.dtheta = dtheta;
  calibration.nPairs = nPairs;
  calibration.nLeftCalibrationPoints = nLeftCalibrationPoints;
  calibration.nRightCalibrationPoints = nRightCalibrationPoints;
  calibration.nTopCalibrationPoints = nTopCalibrationPoints;
  calibration.nBottomCalibrationPoints = nBottomCalibrationPoints;
end
if ~isempty(saveName),
  save(saveName,'-struct','calibration');
end
calibration.registerfn = registerfn;

if DEBUG,
  figure(1);
  clf;
  hax = zeros(1,3);
  hax(1) = subplot(1,4,1);
  imagesc(bkgdImage);
  hold on;
  if strcmpi(method,'circle'),
    l = circleRadius_mm/2 / scale;
  else
    l = pairDist_mm/4 / scale;
  end
  quiver(originX,originY,cos(-offTheta)*l,sin(-offTheta)*l,0,'k--');
  text(originX+cos(-offTheta)*l,sin(-offTheta)*l,'x');
  quiver(originX,originY,cos(-offTheta+pi/2)*l,sin(-offTheta+pi/2)*l,0,'k-');
  text(originX+cos(-offTheta+pi/2)*l,sin(-offTheta+pi/2)*l,'y');
  if strcmpi(method,'circle'),
    tmp = linspace(0,2*pi,50);
    plot(circleCenterX + circleRadius*cos(tmp),circleCenterY + circleRadius*sin(tmp),'k-');
  else
    plot(calibrationPoints(1,:),calibrationPoints(2,:),'ks');
  end
  plot(bowlMarkerPoints(1),bowlMarkerPoints(2),'mo');
  axis image xy;
  hax(2) = subplot(1,4,2);
  image(cat(3,min(1,bkgdImage/255 + double(filI1 >= minFeatureStrengthLow)*.3), repmat(bkgdImage/255,[1,1,2])));
  hold on;
  quiver(originX,originY,cos(-offTheta)*l,sin(-offTheta)*l,0,'k-');
  quiver(originX,originY,cos(-offTheta+pi/2)*l,sin(-offTheta+pi/2)*l,0,'k-');
  if strcmpi(method,'circle'),
    tmp = linspace(0,2*pi,50);
    plot(circleCenterX + circleRadius*cos(tmp),circleCenterY + circleRadius*sin(tmp),'k-');
  else
    scatter(calibrationPoints(1,:),calibrationPoints(2,:),50,1:size(calibrationPoints,2),'s');
  end
  plot(bowlMarkerPoints(1),bowlMarkerPoints(2),'mo');
  axis image xy;
  hax(3) = subplot(1,4,3);
  if strcmpi(method,'circle'),
    imagesc(circleim);
  else
    imagesc(filI1);
  end
  hold on;
  quiver(originX,originY,cos(-offTheta)*l,sin(-offTheta)*l,0,'w-');
  quiver(originX,originY,cos(-offTheta+pi/2)*l,sin(-offTheta+pi/2)*l,0,'w-');
  if strcmpi(method,'circle'),
    tmp = linspace(0,2*pi,50);
    plot(circleCenterX + circleRadius*cos(tmp),circleCenterY + circleRadius*sin(tmp),'k-');
  else
    scatter(calibrationPoints(1,:),calibrationPoints(2,:),50,1:size(calibrationPoints,2),'s');
  end
  plot(bowlMarkerPoints(1),bowlMarkerPoints(2),'mo');
  axis image xy;
  linkaxes(hax);
  if ~strcmpi(method,'circle'),
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
end

function [success,x,y,featureStrength,filI] = getNextFeaturePoint(filI,methodcurr)

  success = false;

  % find the next strongest feature
  [featureStrength,j] = max(filI(:));
  [y,x] = ind2sub([nr,nc],j);
  
  % make sure it meets threshold
  if strcmpi(methodcurr,'grad2'),
    if featureStrength < minFeatureStrengthHigh,
      return;
    end
  else
    if featureStrength < minCrossFeatureStrength,
      return;
    end
  end

  % subpixel accuracy: 
  
  if strcmpi(methodcurr,'grad2'),
    % take box around point and compute weighted average of feature strength
    [box] = padgrab(filI,0,y-featureRadius,y+featureRadius,x-featureRadius,x+featureRadius);
    box = double(box > minFeatureStrengthLow);
    Z = sum(box(:));
    dx = sum(box(:).*dxGrid(:))/Z;
    dy = sum(box(:).*dyGrid(:))/Z;
    x = x + dx;
    y = y + dy;
  end
  
  filI = zeroOutDetection(x,y,filI);
  success = true;

end

  function filI = zeroOutDetection(x,y,filI)
    
    % zero out region around feature
    i1 = max(1,round(x)-featureRadius);
    i2 = min(nc,round(x)+featureRadius);
    j1 = max(1,round(y)-featureRadius);
    j2 = min(nr,round(y)+featureRadius);
    filI(j1:j2,i1:i2) = 0;
    
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