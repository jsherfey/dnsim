% Model: Kramer 2008, PLoS Comp Bio
% Single compartment version of Kramer model

% simulation controls
tspan=[0 250]; dt=.01; solver='euler'; % euler, rk2, rk4
dsfact=1; % downsample factor, applied after simulation

% number of cells per population
N=10;

% tonic input currents
Jd=23.5; % apical: 23.5(25.5), basal: 23.5(42.5)
Js=-4.5; % -4.5
Ja=-6;   % -6(-.4)

% Poisson IPSPs to IBdb (basal dendrite)
gRAN=125;

% some intrinsic currents
gAR_L=50;  % 50,  LTS - max conductance of h-channel
gAR_d=155; % 155, IBda - max conductance of h-channel

% connection strengths
gad=0;      % IBa -> IBdb, 0(.04)
gsd=.2;     % IBs -> IBda,IBdb
gds=.4;     % IBda,IBdb -> IBs
gas=.3;     % IBa -> IBs
gsa=.3;     % IBs -> IBa
ggja=.002;  % IBa -> IBa


gM_s = 0.75;

gCaH_s = 0.65;

% constant biophysical parameters
Cm=.9;        % membrane capacitance
ENa=50;      % sodium reversal potential
E_EKDR=-95;  % potassium reversal potential for excitatory cells
IB_Eh=-25;   % h-current reversal potential for deep layer IB cells
ECa=125;     % calcium reversal potential
IC_noise=.01;% fractional noise in initial conditions

spec=[];

spec.nodes(1).label = 'IBs';
spec.nodes(1).multiplicity = N;
spec.nodes(1).dynamics = {'V''=(current)/Cm'};
spec.nodes(1).mechanisms = {'IBs_itonic','IBs_noise','IBs_iNaF','IBs_iKDR','IBda_iAR','IBda_iM','IBda_iCaH','IBs_leak'};
spec.nodes(1).parameters = {...
  'V_IC',-65,'IC_noise',IC_noise,'Cm',Cm,'E_l',-70,'g_l',1,...
  'stim',Js,'onset',0,'V_noise',0,...
  'gNaF',50,'E_NaF',ENa,'NaF_V0',34.5,'NaF_V1',59.4,'NaF_d1',10.7,'NaF_V2',33.5,'NaF_d2',15,'NaF_c0',.15,'NaF_c1',1.15,...
  'gKDR',10,'E_KDR',E_EKDR,'KDR_V1',29.5,'KDR_d1',10,'KDR_V2',10,'KDR_d2',10,...
  'gAR',gAR_d,'E_AR',IB_Eh,'AR_V12',-87.5,'AR_k',-5.5,'c_ARaM',2.75,'c_ARbM',3,'AR_L',1,'AR_R',1,...
  'gM',gM_s,'E_M',E_EKDR,'c_MaM',1,'c_MbM',1,...
  'gCaH',gCaH_s,'E_CaH',ECa,'tauCaH',.33333,'c_CaHaM',3,'c_CaHbM',3,...
  };


% process specification and simulate model
data = runsim(spec,'timelimits',tspan,'dt',dt,'dsfact',dsfact,'solver',solver,'coder',0);
plotv(data,spec,'varlabel','V');
% dnsim(spec);

