function Iinj = getStepProtocolStim(dt,isi,nsteps,steptime,stepsize,membranearea,nsections,tonictime,bltime,timelimits)
if nargin<1
  dt = .01; % ms
end
if nargin<2
  isi = 1000; % ms
end
if nargin<3
  nsteps = 5; % number of current pulses
end
if nargin<4
  steptime = 400; % ms
end
if nargin<5
  stepsize = 100; % pA. typically: 100-500pA (.1-.5nA)
end
if nargin<6
  membranearea = 1500; % um^2. typically: 1000-2000 um2
end
if nargin<7
  nsections = 5; % number of blocks of current pulses
end
if nargin<8
  tonictime = 60000; % ms
end
if nargin<9
  bltime = 100; % ms, baseline duration. baseline = [0 bltime].
end
if nargin<10
  timelimits = [0 nsections*nsteps*isi+bltime+tonictime];
elseif numel(timelimits)==1
  timelimits = [0 timelimits];
end
%stepsize = 100; % pA. typically: 100-500pA (.1-.5nA)
%membranearea = 1500; % um^2. typically: 1000-2000 um2
CF = (1e-6)/(1e-8); % pA/um^2 => uA/cm^2. note: 1um2=1e-8cm2, 1pA=1e-6uA
Iapp = CF*stepsize/membranearea; % uA/cm^2

bl = zeros(size(0:dt:bltime));
tstep=0:dt:isi;
I0 = zeros(size(tstep));
I0(tstep<steptime)=Iapp;
I0 = repmat(I0,[1 nsteps]);

I1=[]; I2=[];
for a=1:nsections
  I1=[I1 -a*I0];
  I2=[I2 a*I0];
end
ramprate=20;
I3 = linspace(0,nsections*Iapp*ramprate,round(tonictime/dt));
Iinj = [bl I1 I2 I3];
allt = timelimits(1):dt:timelimits(2);
if length(Iinj)<length(allt)
  Iinj0 = Iinj;
  Iinj = zeros(1,length(allt));
  Iinj(1:length(Iinj0)) = Iinj0;
end
%t = (0:length(Iinj)-1)*dt;
%figure; plot(t/1000,Iinj);

%%
% function test=SpikeCheck(V,thresh)
% global statedata
% test=0;
% if ~isfield(statedata,'spiked'), statedata.spiked=0; end
% if statedata.spiked==1, test=1; return; end
% if nargin<2, thresh=0; end
% if any(V(:)>thresh), test=1; end
% statedata.spiked=test;
% 
% %% StepProtocol.txt
% 
% dt = .01; % ms
% isi = 1000; % ms
% nsteps = 5; % number of current pulses
% steptime = 400; % ms
% stepsize = 100; % pA. typically: 100-500pA (.1-.5nA)
% membranearea = 1500; % um^2. typically: 1000-2000 um2
% nsections = 5; % number of blocks of current pulses
% tonictime = 60000; % ms
% Iinj = getStepProtocolStim(dt,isi,nsteps,steptime,stepsize,membranearea,nsections);
% 
% Iapp=min(Iinj(Iinj>0));
% Iramp = linspace(0,nsections*Iapp,round(tonictime/dt));
% 
% tcheck = length(Iinj)*dt;
% I = @(t) Iinj(round(t/dt))*(t<tcheck) + Iramp


