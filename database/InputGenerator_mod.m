%function I=InputGenerator(jnk,timelimits,dt,inputtype,Npop,amp,onset,offset,f0,fmin,fmax,deltaf,Ncycles,sharedfraction)
function I=InputGenerator(varargin)
% note: this function assumes time has units [ms] and is meant to be a
% helper function for mechanism InputGenerator.txt.
% Input types:
% 1: tonic input (step)
% 2: sinusoidal input
% 3: ZAP-like input
% [4: square, triangle
% [5: ramp
% 6: Poisson + exponential (lambda, tauD; poissrnd)
% 7: Poisson + double-exponential (lambda, tauR, tauD; Ben's method)
% [8: Poisson (coupled oscillator)
% [9: waveform (from file)

TIMELIMITS
DT
INPUTTYPE
NPOP
AMP
ONSET
OFFSET

F0
FMIN
FMAX
DELTAF
NCYCLES

LAMBDA
TAUR
TAUD
NINPUTS
SHAREDFRACTION

cfg.TIMELIMITS=[0 100];   % ms
cfg.DT=.01;               % ms
cfg.INPUTTYPE=7;
cfg.NPOP=20;
cfg.amp=1;
cfg.onset=0;
cfg.offset=inf;
cfg.f0=10;                % Hz
cfg.fmin=1;               % Hz
cfg.fmax=40;              % Hz
cfg.deltaf=1;             % Hz
cfg.Ncycles=3;
cfg.sharedfraction=0;     % fraction of inputs to share among cells
cfg.Ninputs=10;
cfg.tauD=2; % ms
cfg.tauR=.5; % ms
cfg.lambda=50; % Hz

length(varargin)
for i=1:2:length(varargin)
%   tmp='';
  val=varargin{i+1}
  % deal with coder issues
%   fld=regexp(varargin{i},'[a-zA-Z]+$','match')
%   fld=varargin{i};
%   ind=find(fld=='_');
%   ind2=ind(length(ind));
%   fld2=fld(ind2+1:length(fld));
%   cfg.(fld2)=val;
  fld=strrep(varargin{i},'pset.p.','')
%   ind=find(fld=='_')
%   if ~isempty(ind)
% %     tmp=fld(ind(end)+1:end)
% %     cfg.(tmp) = val;
%     cfg.(fld(ind(end)+1:end)) = val;
%   else
    cfg.(fld) = val;
%   end
  fprintf('%s=%g\n',fld,val(1));
end
cfg

% cfg = mmil_args2parms( varargin, ...
%          {  'timelimits',[0 100],[],...   % ms
%             'dt',.01,[],...               % ms
%             'inputtype',1,[],...
%             'Npop',1,[],...
%             'amp',1,[],...
%             'onset',0,[],...
%             'offset',inf,[],...
%             'f0',10,[],...                % Hz
%             'fmin',1,[],...               % Hz
%             'fmax',40,[],...              % Hz
%             'deltaf',1,[],...             % Hz
%             'Ncycles',3,[],...
%             'sharedfraction',0,[],...     % fraction of inputs to share among cells
%             'Ninputs',1,[],...
%             'tauD',2,[],... % ms
%             'tauR',.5,[],... % ms
%             'lambda',50,[],... % Hz
%          }, false);

if numel(cfg.timelimits)==1, cfg.timelimits=[0 cfg.timelimits]; end

I=0;
t=cfg.timelimits(1):cfg.dt:cfg.timelimits(2);
nt=length(t);
dt=cfg.dt;
Npop=cfg.Npop;

% define input
switch cfg.inputtype
  case 1 % tonic input (step)
    I=ones(Npop,nt);
  case 2 % sinusoidal input [0,1]
    I=sin(2*pi*cfg.f0*t/1000);
    I=I-min(I(:));
    I=I/max(I(:));
  case 3 % ZAP-like input
    f = cfg.fmin:cfg.deltaf:cfg.fmax;
    Tf = cfg.Ncycles*1000./f;
    Nf = floor(Tf/dt);
    Ttot = sum(Tf);
    Ntot = sum(Nf);
    tt = 0:dt:Ttot;
    zap = zeros(1,Ntot);
    for j=1:Nf(1)
      zap(j) = sin(2*pi*f(1)*tt(j)/1000);
    end 
    Na=Nf(1);
    for k=2:length(f)
      for j=Na+1:Na+Nf(k)
        zap(j) = sin(2*pi*f(k)*(tt(j)-tt(Na))/1000);
      end
      Na=Na+Nf(k);
    end
    if Ntot>nt
      I=zap(1:nt);
    elseif Ntot<nt
      I=zeros(1,nt);
      I(1:Ntot)=zap;
    else
      I=zap;
    end
  case 6 % Poisson-exponential (poissrnd method)
    Pmax=cfg.amp;
    spikes=poissrnd(cfg.lambda*(1e-4),[Npop nt]);
    G=zeros(Npop,nt);
    for k=2:nt
      G(:,k)=G(:,k-1) - dt*G(:,k-1)/cfg.tauD;
      if cfg.sharedfraction==0
        for i=1:Npop
          spiked=spikes(i,k);
          if all(spiked==1)
            G(i,k) = G(i,k) + Pmax.*(1-G(i,k));
          end
        end
      else
        spiked=spikes(k);
        if spiked==1
          G(:,k) = G(:,k) + Pmax.*(1-G(:,k));
        end
      end
    end
    I=G;

    % sharedfraction=.1;
    % ...
    
  case 7 % Poisson (Ben's method; double exponential)
    % iMultiPoissonExp.txt:
    %sharedfraction=.1;
    T=cfg.timelimits(end);     % ms, duration
%     tauD = 2;
%     tauR = .5;
    tau_1 = 1;
    tau_i = 1;%10;
    % EPSP for spikes at time t = 0.
    psp = tau_i*(exp(-max(t-tau_1,0)/cfg.tauD) - exp(-max(t-tau_1,0)/cfg.tauR))/(cfg.tauD-cfg.tauR);
    %psp = psp(psp > eps);
    psp = [zeros(1,length(psp)) psp];
    % input connectivity
    C = repmat(eye(Npop),1,cfg.Ninputs);
    if cfg.sharedfraction>0
      nshare=ceil(cfg.sharedfraction*cfg.Ninputs);
      C(:,1:nshare)=1;
    end
    % input spikes
    spikes = rand(cfg.Ninputs*Npop, ceil(T/dt));
    spikes = spikes < cfg.lambda*dt/1000;
    spike_arrivals = C*spikes; % Calculating presynaptic spikes for each cell.
    % convolve spike trains with EPSP shape
    G = nan(size(spike_arrivals)); % Calculating EPSP experienced by each cell.
    for c = 1:Npop
      G(c,:) = conv(spike_arrivals(c,:),psp,'same');
    end   
    I=G;
  otherwise
    % square, triangle
    % ramp
    % Poisson (lambda=sin(f0))
    % Poisson (coupled oscillator)
    % waveform (from file)
end
I=cfg.amp*I;

% zero input before onset and after offset
on=nearest(t,cfg.onset);
off=nearest(t,cfg.offset);
if on>1
  I(:,1:on-1)=0;
end
if off<length(I)
  I(:,off+1:end)=0;
end

