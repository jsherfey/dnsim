function W = WeightGenerator(Npre,Npost,weighttype,span,normalize,zerodiag,prob)
if nargin<1, Npre=1; end
if nargin<2, Npost=1; end
if nargin<3, weighttype=1; end
if nargin<4, span=inf; end
if nargin<5, normalize=0; end
  % 1 --> normalize s.t. sum(W|inputs)=1
  % 2 --> normalize s.t. max(W)=1
if nargin<6, zerodiag=0; end
if nargin<7, prob=1; end

% Types:
% 1: all-to-all
% 2: neighbors (distance<=fanout)
% 3: gaussian (mu,sigma)
% : load from file
% : Mattia task
% : NEF/nengo
% : machine learning

srcpos=linspace(0,1,Npre)'*ones(1,Npost);
dstpos = (linspace(0,1,Npost)'*ones(1,Npre))';
D = abs(srcpos-dstpos); % distance

switch weighttype
  case 1 % all-to-all
    W=ones(Npost,Npre);
  case 2 % neighbors (distance<=fanout)
    W=double((D<=span)');
  case 3 % gaussian (mu,sigma)
    W=exp(-D.^2/span^2)';
  otherwise
    W=zeros(Npost,Npre);
    % load from file
    % Mattia task
    % NEF/nengo
    % machine learning
end

if zerodiag
  if Npre~=Npost
    disp('not subtracting diagonal; populations have different sizes');
  else
    W=W-eye(Npost,Npre);
  end
end

if prob<1
  W=W.*(rand(Npost,Npre)<=prob);
end

if normalize==1 % normalize by the sum over presynaptic inputs s.t. sum(W)=1
  denom=repmat(sum(W,2),[1 Npre]);
  denom(denom==0)=1; % prevent division by zero
  W=W./denom;
elseif normalize==2 % normalize s.t. max(W|inputs)=1
  denom=repmat(max(W,[],2),[1 Npre]);
  denom(denom==0)=1; % prevent division by zero
  W=W./denom;  
end

% if prob<1
%   W=W.*(rand(Npost,Npre)<=prob);
% end
