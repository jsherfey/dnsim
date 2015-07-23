%function I=InputGenerator(jnk,timelimits,dt,inputtype,Npop,amp,onset,offset,f0,fmin,fmax,deltaf,Ncycles,sharedfraction)
function I=InputGenerator(varargin)
% note: this function assumes time has units [ms] and is meant to be a
% helper function for mechanism InputGenerator.txt.
% Input types:
% 1: tonic input (step)
% 2: oscillatory input (f0,wavetype{sin,square,sawtooth})
% 3: ZAP-like input
% 6: Poisson + exponential (lambda,tauD,f0,wavetype; poissrnd)
% 7: Poisson + double-exponential (lambda, tauR, tauD; Ben's method)
% 8: coincidence detection probe (exponential synapse)
% todo - waveform (from file)

% set default values
cfg.TIMELIMITS=[0 1000];  % ms
cfg.DT=.01;               % ms
cfg.INPUTTYPE=7;
cfg.NPOP=20;
cfg.AMP=1;
cfg.ONSET=0;
cfg.OFFSET=inf;
cfg.F0=0;                 % Hz
cfg.FMIN=1;               % Hz
cfg.FMAX=40;              % Hz
cfg.DELTAF=1;             % Hz
cfg.NCYCLES=3;
cfg.SHAREDFRACTION=0;     % fraction of inputs to share among cells
cfg.NINPUTS=10;
cfg.TAUD=2; % ms
cfg.TAUR=.5; % ms
cfg.LAMBDA=50; % Hz, modulation
cfg.LAMBDA0=0; % Hz, baseline
cfg.WAVETYPE='sin'; % {'sin','square','sawtooth'}
cfg.MODE='increasing'; % {'increasing','decreasing'}
cfg.ISI=100; % time between stimuli [ms]
cfg.TSHIFT=1; % time shift between sequential stimuli (ms)

for i=1:2:length(varargin)
  val=varargin{i+1};
  fld=varargin{i};
  cfg.(fld) = val;
  % deal with coder issues
%   fld=regexp(varargin{i},'[a-zA-Z]+$','match') % <-- regexp not supported by coder
%   fld=varargin{i};
%   ind=find(fld=='_');
%   ind2=ind(length(ind));
%   fld2=fld(ind2+1:length(fld));
%   cfg.(fld2)=val;
%   fld=strrep(varargin{i},'pset.p.','')
%   ind=find(fld=='_')
%   if ~isempty(ind)
% %     tmp=fld(ind(end)+1:end)
% %     cfg.(tmp) = val;
%     cfg.(fld(ind(end)+1:end)) = val;
%   else
%     cfg.(fld{1}) = val;
%   end
%   fprintf('%s=%g\n',fld,val(1));
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

if numel(cfg.TIMELIMITS)==1, cfg.TIMELIMITS=[0 cfg.TIMELIMITS]; end

I=0;
t=cfg.TIMELIMITS(1):cfg.DT:cfg.TIMELIMITS(2);
nt=length(t);
dt=cfg.DT;
Npop=cfg.NPOP;

% define input
switch cfg.INPUTTYPE
  case 1 % tonic input (step)
    I=ones(Npop,nt);
  case 2 % sinusoidal input [0,1]
    % source: http://www.mathworks.com/matlabcentral/fileexchange/37376-oscillator-and-signal-generator/content/oscillator.m
    phase=0; tt=t/1000;
    switch cfg.WAVETYPE % note: feval is incompatible with coder
      case 'sin'
        I=sin((2*pi*cfg.F0*tt)+(2*pi*phase)); % [nt x 1]
      case {'square','squ'}
        I = sin((2*pi*phase)+(2*pi*cfg.F0*linspace(0,(tt(end)-tt(1)),nt)));
        I(I>=0)=1; I(I<0)=-1;
      case {'sawtooth','saw'}
        I=2*mod(phase+.5+linspace(0,(tt(end)-tt(1))*cfg.F0,nt),1)-1;
      otherwise
        error('unrecognized wave type');
    end
    %I=sin(2*pi*cfg.F0*t/1000);
    I=I-min(I(:));
    I=I/max(I(:));
    I=repmat(I,[Npop 1]);
  case 3 % ZAP-like input
    f = cfg.FMIN:cfg.DELTAF:cfg.FMAX;
    Tf = cfg.NCYCLES*1000./f;
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
    I=repmat(I,[Npop 1]);
  case 6 % Poisson-exponential (poissrnd method)
    Pmax=cfg.AMP;
    %lambda=cfg.LAMBDA; % per sec
    lambda=cfg.LAMBDA/(1/(dt/1000)); % per step
    % prepare independent poisson inputs
    if cfg.F0==0 % homogeneous poisson process
      allspikes=poissrnd(lambda,[Npop nt cfg.NINPUTS]);
    else % nonhomogeneous poisson process
      tt=t/1000; % sec
      %baseline=cfg.LAMBDA0; % per sec
      baseline=cfg.LAMBDA0/(1/(dt/1000)); % per step
      phase=0;
      switch cfg.WAVETYPE % note: feval is incompatible with coder
        % source: http://www.mathworks.com/matlabcentral/fileexchange/37376-oscillator-and-signal-generator/content/oscillator.m
        case 'sin'
          wave=sin((2*pi*cfg.F0*tt)+(2*pi*phase)); % [nt x 1]
        case {'square','squ'}
          wave = sin((2*pi*phase)+(2*pi*cfg.F0*linspace(0,(tt(end)-tt(1)),nt)));
          % all positive values set to 1 and all negative values to -1:
          wave(wave>=0)=1; wave(wave<0)=-1;
          % modulation=square(2*pi*cfg.F0*tt); % note: square is incompatible with coder
        case {'sawtooth','saw'}
          wave=2*mod(phase+.5+linspace(0,(tt(end)-tt(1))*cfg.F0,nt),1)-1;
          % modulation=sawtooth(2*pi*cfg.F0*tt); % note: sawtooth is incompatible with coder
        otherwise
          error('unrecognized wave type');
      end
      modulation=(1+wave)/2; % [-1,1] --> [0,1]
      lam=baseline+lambda*modulation;
      % inspect: figure; plot(tt,lam)
      % validate: s=poissrnd(lam,[1 nt]); length(find(s>0))/(tt(end)-tt(1)) == cfg.LAMDA
      lam=repmat(lam,[Npop 1]);
      lam=repmat(lam,[1 1 cfg.NINPUTS]);
      allspikes=poissrnd(lam);
    end
    % share some fraction of the inputs among cells of the population
    if cfg.SHAREDFRACTION>0
      nshare=ceil(cfg.SHAREDFRACTION*cfg.NINPUTS);
      allspikes(:,:,1:nshare)=repmat(allspikes(1,:,1:nshare),[Npop 1 1]);
    end
    % combine inputs to each cell
    spikes=sum(allspikes,3);
    % calc exponential response to poisson inputs
    G=zeros(Npop,nt);
    for k=2:nt
      G(:,k)=G(:,k-1) - dt*G(:,k-1)/cfg.TAUD;
      for i=1:Npop
        numspikes=spikes(i,k);
        if numspikes>=1
          G(i,k) = G(i,k) + (Pmax*numspikes).*(1-G(i,k));
        end
      end
    end
    I=G;
  case 7 % Poisson (Ben's method; double exponential)
    % iMultiPoissonExp.txt:
    T=cfg.TIMELIMITS(end);     % ms, duration
    tau_1 = 1;
    tau_i = 1;%10;
    % EPSP for spikes at time t = 0.
    psp = tau_i*(exp(-max(t-tau_1,0)/cfg.TAUD) - exp(-max(t-tau_1,0)/cfg.TAUR))/(cfg.TAUD-cfg.TAUR);
    psp = [zeros(1,length(psp)) psp];
    % input connectivity
    C = repmat(eye(Npop),1,cfg.NINPUTS);
    if cfg.SHAREDFRACTION>0
      nshare=ceil(cfg.SHAREDFRACTION*cfg.NINPUTS);
      C(:,1:nshare)=1;
    end
    % input spikes
    spikes = rand(cfg.NINPUTS*Npop, ceil(T/dt));
    spikes = spikes < cfg.LAMBDA*dt/1000;
    spike_arrivals = C*spikes; % Calculating presynaptic spikes for each cell.
    % convolve spike trains with EPSP shape
    G = nan(size(spike_arrivals)); % Calculating EPSP experienced by each cell.
    for c = 1:Npop
      G(c,:) = conv(spike_arrivals(c,:),psp,'same');
    end   
    I=G;
  case 8 % coincidence detection probe
    isi=round(cfg.ISI/dt); % steps per ISI
    tshift=round(cfg.TSHIFT/dt); % steps per shift
    onset=round(cfg.ONSET/dt)+1;
    spikes=zeros(length(t),2);
    step=onset; n=0;
    while step<length(t)
      spikes(step,1)=1;
      switch cfg.MODE
        case 'increasing'
          spikes(step+n*tshift,2)=1;
        case 'decreasing'
          spikes(step+isi-(n+1)*tshift,2)=1;
      end
      step=step+isi;
      n=n+1;
      if (n*tshift)>=isi
        n=0;
      end
    end
    if 0 % slower, memory-intensive method (works with any synaptic filter)
      % convolve spikes with postsynaptic filter:
      %psp=(exp(-t/(cfg.TAUD))-exp(-t/(cfg.TAUR)));
      psp=(exp(-t/(cfg.TAUD)));
      psp=(psp/max(psp));
      psp=[zeros(1,length(psp)) psp];
      x1=cfg.AMP*conv(spikes(:,1),psp,'same');
      x2=cfg.AMP*conv(spikes(:,2),psp,'same');
      % combine the variably-coincident inputs
      x=(x1+x2)'; %figure; plot(t,x1,'b',t,x2,'r',t,x,'k-')
      % repeat across population
      I=repmat(x,[Npop 1]);
    else % faster method (uses exponential filter)
      % calc exponential response to spike train
      G=zeros(2,nt);
      for k=2:nt
        G(:,k)=G(:,k-1) - dt*G(:,k-1)/cfg.TAUD;
        numspikes=spikes(k,1);
        if numspikes>=1
          G(1,k) = G(1,k) + (cfg.AMP*numspikes).*(1-G(1,k));
        end
        numspikes=spikes(k,2);
        if numspikes>=1
          G(2,k) = G(2,k) + (cfg.AMP*numspikes).*(1-G(2,k));
        end
      end
      I=repmat(sum(G,1),[Npop 1]);
    end
  otherwise
    % square, triangle
    % ramp
    % Poisson (lambda=sin(f0))
    % Poisson (coupled oscillator)
    % waveform (from file)
end
I=cfg.AMP*I;

% zero input before onset and after offset
on=nearest(t,cfg.ONSET);
off=nearest(t,cfg.OFFSET);
if on>1
  I(:,1:on-1)=0;
end
if off<length(I)
  I(:,off+1:end)=0;
end

% zero input to non-targets
if isfield(cfg,'TARGETS') && ~isempty(cfg.TARGETS)
  nontargets=setdiff(1:Npop,cfg.TARGETS);
  if ~isempty(nontargets)
    I(nontargets,:)=0;
  end
end


