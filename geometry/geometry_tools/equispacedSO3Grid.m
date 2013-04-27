function S3G = equispacedSO3Grid(CS,SS,varargin)
% defines a equispaced grid in the orientation space

% may be we should populate only a ball
maxAngle = get_option(varargin,'maxAngle',2*pi);

% get fundamental region
[maxAlpha,maxBeta,maxGamma] = symmetry2Euler(CS,SS,'SO3Grid');
maxGamma = maxGamma/2;
if ~check_option(varargin,'center'), maxGamma = min(maxGamma,maxAngle);end

% determine resolution
if check_option(varargin,'points')

  points = get_option(varargin,'points');
  
  switch Laue(CS)  % special case: cubic symmetry
    case 'm-3'
      points = 3*points;
    case 'm-3m'
      points = 2*points;
  end
  
  % calculate number of subdivisions for the angles alpha,beta,gamma
  res = 2/(points/( maxBeta*maxGamma))^(1/3);
  
  if  maxAngle < pi * 2 && maxAngle < maxBeta
    res = res * maxAngle; % bug: does not work properly for all syms
  end
  
else
  
  res = get_option(varargin,'resolution',5*degree);
  
end

alphabeta = S2Grid('equispaced','RESOLUTION',res,...
  'MAXTHETA',maxBeta,'MINRHO',0,'MAXRHO',maxAlpha,...
  no_center(res),'RESTRICT2MINMAX');

ap2 = round(2*maxGamma/res);

[beta,alpha] = polar(alphabeta);

% calculate gamma shift
re = cos(beta).*cos(alpha) + cos(alpha);
im = -(cos(beta)+1).*sin(alpha);
dGamma = atan2(im,re);
dGamma = repmat(reshape(dGamma,1,[]),ap2,1);
gamma = -maxGamma + (0:ap2-1) * 2 * maxGamma / ap2;

% arrange alpha, beta, gamma
gamma  = dGamma+repmat(gamma.',1,numel(alphabeta));
alpha = repmat(reshape(alpha,1,[]),ap2,1);
beta  = repmat(reshape(beta,1,[]),ap2,1);

ori = orientation('Euler',alpha,beta,gamma,'ZYZ',CS,SS);

gamma = S1Grid(gamma,-maxGamma+dGamma(1,:),...
  maxGamma+dGamma(1,:),'periodic','matrix');

res = 2 * maxGamma / ap2;

% eliminiate 3 fold symmetry axis of cubic symmetries
ind = fundamental_region(ori,CS,symmetry());

if nnz(ind) ~= 0
  % eliminate those rotations
  ori(ind) = [];
  
  % eliminate from index set
  gamma = subGrid(gamma,~ind);
  alphabeta  = subGrid(alphabeta,GridLength(gamma)>0);
  gamma(GridLength(gamma)==0) = [];
  
end


S3G = SO3Grid(ori,alphabeta,gamma,'resolution',res);

end


function s = no_center(res)

if mod(round(2*pi/res),2) == 0
  s = 'no_center';
else
  s = '';
end
end

function res = ori2res(ori)

if numel(ori) == 0, res = 2*pi; return;end
ml = min(numel(ori),500);
ind1 = discretesample(numel(ori),ml);
ind2 = discretesample(numel(ori),ml);
d = angle_outer(ori(ind1),ori(ind2));
d(d<0.005) = pi;
res = quantile(min(d,[],2),min(0.9,sqrt(ml/numel(ori))));
end

function ind = fundamental_region(q,cs,ss)

if numel(q) == 0, ind = []; return; end

c = {};

% eliminiate 3 fold symmetry axis of cubic symmetries
switch Laue(cs)
  
  case   {'m-3m','m-3'}
    
    c{end+1}.v = vector3d([1 1 1 1 -1 -1 -1 -1],[1 1 -1 -1 1 1 -1 -1],[1 -1 1 -1 1 -1 1 -1]);
    c{end}.h = sqrt(3)/3;
    
    if strcmp(Laue(cs),'m-3m')
      c{end+1}.v = vector3d([1 -1 0 0 0 0],[0 0 1 -1 0 0],[0 0 0 0 1 -1]);
      c{end}.h = sqrt(2)-1;
    end
end

switch Laue(ss)
  case 'mmm'
   c{end+1}.v = vector3d([-1 0],[0 -1],[0 0]);
   c{end}.h = 0;
end 

% find rotation not part of the fundamental region
rodrigues = Rodrigues(q); clear q;
ind = false(numel(rodrigues),1);
for i = 1:length(c)
  for j = 1:length(c{i}.v)
    p = dot(rodrigues,1/norm(c{i}.v(j)) * c{i}.v(j));
    ind = ind | (p(:)>c{i}.h);
  end
end

end
