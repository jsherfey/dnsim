function I=InputGenerator(jnk,timelimits,dt,inputtype,Npop,amp,onset,offset,f0,fmin,fmax,deltaf,Ncycles,sharedfraction)
% note: this function assumes time has units [ms] and is meant to be a
% helper function for mechanism InputGenerator.txt.
% Inputs:
disp(jnk)
% f0 = frequency [Hz]
if nargin<1, timelimits=[0 100]; elseif numel(timelimits)==1, timelimits=[0 timelimits]; end
if nargin<2, dt=.01; end
if nargin<3, inputtype=1; end
if nargin<4, Npop=1; end
if nargin<5, amp=1; end
if nargin<6, onset=0; end
if nargin<7, offset=inf; end
if nargin<8, f0=10; end
if nargin<9, fmin=1; end
if nargin<10, fmax=40; end
if nargin<11, deltaf=1; end
if nargin<12, Ncycles=3; end
if nargin<13, sharedfraction=0; end

% Types:
% 1: tonic input (step)
% 2: sinusoidal input
% 3: ZAP-like input
% [4: square, triangle
% [5: ramp
% 6: Poisson + exponential (lambda, tauD; poissrnd)
% 7: Poisson + double-exponential (lambda, tauR, tauD; Ben's method)
% [8: Poisson (coupled oscillator)
% [9: waveform (from file)

I=0;
t=timelimits(1):dt:timelimits(2);
nt=length(t);

% define input
switch inputtype
  case 1 % tonic input (step)
    I=ones(1,nt);
  case 2 % sinusoidal input [0,1]
    I=sin(2*pi*f0*t/1000);
    I=I-min(I(:));
    I=I/max(I(:));
  case 3 % ZAP-like input
    f = fmin:deltaf:fmax;
    Tf = Ncycles*1000./f;
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
    independent=1;
    Pmax=amp;
    tauD=10;
    lambda=50;
    spikes=poissrnd(lambda*(1e-4),[Npop nt]);
    G=zeros(Npop,nt);
    for k=2:nt
      G(:,k)=G(:,k-1) - dt*G(:,k-1)/tauD;
      if independent
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
    lambda=50;%2;     % Hz, Poisson spike rate
    T=timelimits(end);     % ms, duration
    tauD = 2;
    tauR = .5;
    tau_1 = 1;
    tau_i = 1;%10;
    Ninputs = 10;
    % EPSP for spikes at time t = 0.
    psp = tau_i*(exp(-max(t-tau_1,0)/tauD) - exp(-max(t-tau_1,0)/tauR))/(tauD-tauR);
    %psp = psp(psp > eps);
    psp = [zeros(1,length(psp)) psp];
    % input connectivity
    C = repmat(eye(Npop),1,Ninputs);
    if sharedfraction>0
      nshare=ceil(sharedfraction*Ninputs);
      C(:,1:nshare)=1;
    end
    % input spikes
    spikes = rand(Ninputs*Npop, ceil(T/dt));
    spikes = spikes < lambda*dt/1000;
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
I=amp*I;

% zero input before onset and after offset
on=nearest(t,onset);
off=nearest(t,offset);
if on>1
  I(1:on-1)=0;
end
if off<length(I)
  I(off+1:end)=0;
end

