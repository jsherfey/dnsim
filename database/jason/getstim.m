function I=getstim(N,T,L,type,nchange)
% define stimulus movie [I] = [N^2 T]
if nargin<4, type=1; end
if nargin<5, nchange=20; end
%nchange=round(1/(2*flashfreq*dt))

I0 = 1;
mid = N^2/2 - N/2;

switch type
	case 1 % Gabor patch
    cpp = (100/N)*L;
    I = gabor([N N],cpp,90,0,L,I0,I0); % sigma = L
    I = repmat(I,[1 1 T]);
    I = reshape(permute(I,[2 1 3]),[N^2 T]);	case 2 % Random dots
    cpp = (100/N)*L;
    rho = .3;
    I = randDot([N N],L,I0,0,rho);
    I = repmat(I,[1 1 T]);
    I = reshape(permute(I,[2 1 3]),[N^2 T]);
end

% add flashing
if nchange~=0
    tmp = [ones(1,nchange) zeros(1,nchange)];
    tmp = repmat(tmp,[1 ceil(T/length(tmp))]);
    tmp = tmp(1:T);
    I(:,tmp==0) = 0;
end


%{
    szw = 1;% bar width
    szh = round(N/2); % bar height
    sp = 3; % spacing bw bars
    I = zeros(N,N,T);
    II = floor(linspace(0,N-L-sp,T));
    for k = 1:T
      offset = II(k);
      by = 1:szw;
      bx = (N-szh+1):N;
      I(max(1,bx-offset),offset+by,k) = 1;
      I(max(1,bx-offset),offset+sp+by,k) = 1;
    end
    I = reshape(permute(I,[2 1 3]),[N^2 T]);

  case 26
    % concave outline
    % simple concave & convex outlines
    % Frame Oval: imageMatrix = drawOvalFrame(BaseIm, TopLeft_BotRight, foreground, frameWidth)
%     I = ones(N,N); % base image
    I = drawOvalFrame(Ibase,round([.33*N .33*N .66*N .66*N]),I0,L);
    I(:,round(.5*N):end) = 1;
    % I(round(.5*N):end,:) = 1;
    I = repmat(I,[1 1 T]);
%     B = drawOvalFrame(A,[50 50 50 50], 0.5,10);
    I = reshape(permute(I,[2 1 3]),[N^2 T]);    
  case 27
    % rectangular frame
    % Frame rectangle: imageMatrix = drawRectFrame(BaseIm, TopLeft_BotRight, foreground, frameWidth)
    % square frame with variable size
%     I = ones(N,N); % base image
    I = drawRectFrame(Ibase,round([.33*N .33*N .66*N .66*N]),I0,L);
    I = repmat(I,[1 1 T]);
    I = reshape(permute(I,[2 1 3]),[N^2 T]);    
  case 28
    % sinusoidal grating
    % Sine grating: imageMatrix = sinGrating(vhSize, cyclesPer100Pix, orientation, phase, mean, amplitude)
%     cpp = round(.05*N);
    cpp = (100/N)*L;
    orientation = 90;
    if saccadflag || driftflag
      Ihat = sinGrating([M M],cpp,orientation,0,I0,I0)/2;
    else
      I = sinGrating([N N],cpp,orientation,0,I0,I0)/2;
      I = repmat(I,[1 1 T]);
      I = reshape(permute(I,[2 1 3]),[N^2 T]);
    end
  case 29
    % concentric sine pattern
    % Concentric sine pattern: imageMatrix = sinConcentric(vhSize, cyclePer100pix, phase, mean, amplitude)
    cpp = (100/N)*L;%cpp =L;% round(.05*N);
    if saccadflag || driftflag
      Ihat = sinConcentric([M M],cpp,0,I0,I0)/2;
    else
      I = sinConcentric([N N],cpp,0,I0,I0)/2;
      I = repmat(I,[1 1 T]);
      I = reshape(permute(I,[2 1 3]),[N^2 T]);
    end
  case 30
    % gabor patch
    % Gabor patch: imageMatrix = gabor(vhSize, cyclesPer100Pix,orientation, phase, sigma , mean, amplitude)
    cpp = (100/N)*L;%cpp = round(.05*N);
    I = gabor([N N],cpp,90,0,L,I0,I0); % sigma = L
    I = repmat(I,[1 1 T]);
    I = reshape(permute(I,[2 1 3]),[N^2 T]);
  case 31
    % variable random dots
    % Random dots: imageMatrix = randDot(vhSize, dotSize, dotCol, backCol, density);
    cpp = (100/N)*L;%cpp = round(.05*N);
    rho = .3;
    I = randDot([N N],L,I0,0,rho);
    I = repmat(I,[1 1 T]);
    I = reshape(permute(I,[2 1 3]),[N^2 T]);
%}
