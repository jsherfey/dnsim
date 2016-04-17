% Model: Kramer 2008, PLoS Comp Bio

% simulation controls
tspan=[0 250]; dt=.01; solver='euler'; % euler, rk2, rk4
dsfact=1; % downsample factor, applied after simulation

% number of cells per population
N=10;

% tonic input currents
Je=-10.5;% -10.5(1)
Ji=2;   % 16(35)
JL=40;   % 40(45)
Jd=23.5; % apical: 23.5(25.5), basal: 23.5(42.5)
Js=-4.5; % -4.5
Ja=-6;   % -6(-.4)

% Poisson IPSPs to IBdb (basal dendrite)
gRAN=125;

% some intrinsic currents
gAR_L=50;  % 50,  LTS - max conductance of h-channel
gAR_d=155; % 155, IBda - max conductance of h-channel

% connection strengths
gie=25;     % B -> RS
gLe=2.5;    % LTS -> RS
ggje=.04;   % RS -> RS
gei=1;      % RS -> B
gii=20;     % B -> B
gai=.045;   % IBa -> B, uniformly distributed +/- .01
geL=2;      % RS -> LTS
giL=8;      % B -> LTS
gLL=5;      % LTS -> LTS
gaL=.04;    % IBa -> LTS, uniformly distributed +/- .005
gad=0;      % IBa -> IBdb, 0(.04)
gLd=4;      % LTS -> IBda
gsd=.2;     % IBs -> IBda,IBdb
gds=.4;     % IBda,IBdb -> IBs
gas=.3;     % IBa -> IBs
gsa=.3;     % IBs -> IBa
ggja=.002;  % IBa -> IBa

% connection fanout among superficial cells
sup_fanout=.5; % .5, inf

% constant biophysical parameters
Cm=.9;        % membrane capacitance
ENa=50;      % sodium reversal potential
E_EKDR=-95;  % potassium reversal potential for excitatory cells
I_EKDR=-100; % potassium reversal potential for inhibitory cells
Eh=-35;      % h-current reversal potential for superficial cells
IB_Eh=-25;   % h-current reversal potential for deep layer IB cells
ECa=125;     % calcium reversal potential
IC_noise=.01;% fractional noise in initial conditions

spec=[];
spec.nodes(1).label = 'B';
spec.nodes(1).multiplicity = N;
spec.nodes(1).dynamics = {'V''=(current)/Cm'};
%spec.nodes(1).mechanisms = {'B_itonic','B_noise','B_iNaF','B_iKDR','B_leak','B_iAPoirazi'};    % Does not work
spec.nodes(1).mechanisms = {'B_itonic','B_noise','B_iNaF','B_iKDR','B_leak','B_iA'};    % Note, B_iA originally had random initial conditions
spec.nodes(1).parameters = {...
  'V_IC',-65,'IC_noise',IC_noise,'Cm',Cm,'E_l',-65,'g_l',1,...
  'stim',Ji,'onset',0,'V_noise',1,...
  'gNaF',200,'E_NaF',ENa,'NaF_V0',38,'NaF_V1',58.3,'NaF_d1',6.7,'NaF_V2',37,'NaF_d2',15,'NaF_c0',.15,'NaF_c1',1.15,...
  'gKDR',20,'E_KDR',I_EKDR,'KDR_V1',27,'KDR_d1',11.5,'KDR_V2',10,'KDR_d2',10,...
  'gA',1,...
  };


spec.connections(1,1).label = 'B-B';
% spec.connections(1,1).mechanisms = {'B_B_iSYN'};
spec.connections(1,1).mechanisms = {'B_B_iSYN','B_B_iGABAB'};
spec.connections(1,1).parameters = {'g_SYN',gii,'E_SYN',-75,'tauDx',5,'tauRx',.5,'fanout',sup_fanout,'IC_noise',0,'gGABAB',0.005};


% process specification and simulate model
data = runsim(spec,'timelimits',tspan,'dt',dt,'dsfact',dsfact,'solver',solver,'coder',0);
plotv(data,spec,'varlabel','V');
% dnsim(spec);
