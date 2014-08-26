% Kramer model (high kainate version; no IBdb-IBdb or Poisson->IBdb)
% Reference: ...
% Script created by JSS on 11-Jun-2014

N=10; % number of cells per population

% CELLS

x=[];
x.multiplicity = N;
x.dynamics = 'V''=(current)/Cm';
x.mechanisms = [];
x.parameters = [];

% RS
s=x;
s.label = 'RS';
s.mechanisms = {'itonic' 'noise' 'iNaF' 'iKDR' 'iAR'};
s.parameters = {'V_IC' -65 'hNaF_IC' .5 'mKDR_IC' .34 'mAR_IC' .3 'stim' 12.5 'V_noise' [8] 'IC_noise' [.01] 'E_l' -70 'g_l' 1 'Cm' .9 'gKDR' 20 'KDR_V1' 29.5 'KDR_d1' 10 'KDR_v2' 10 'KDR_d2' 10 'E_KDR' -95 'gNaF' 200 'NaF_V0' 34.5 'NaF_V1' 59.4 'NaF_d1' 10.7 'NaF_V2' 33.5 'NaF_d2' 15 'E_NaF' 50 'AR_V0' 87.5 'E_AR' -35 'gAR' 25 'c_ARaM' 1.75 'c_ARbM' .5};
RS=s;

% B
s=x;
s.label = 'B';
s.mechanisms = {'itonic' 'noise' 'iNaF' 'iKDR'};
s.parameters = {'V_IC' -65 'hNaF_IC' .5 'mKDR_IC' .34 'stim' -16 'V_noise' [3] 'IC_noise' [.01] 'E_l' -65 'g_l' 1 'Cm' .9 'gKDR' 20 'KDR_V1' 27 'KDR_d1' 11.5 'KDR_v2' 10 'KDR_d2' 10 'E_KDR' -100 'gNaF' 200 'NaF_V0' 38 'NaF_V1' 58.3 'NaF_d1' 6.7 'NaF_V2' 37 'NaF_d2' 15 'E_NaF' 50 'AR_V0' 87.5 'E_AR' -35 'gAR' 50 'c_ARaM' 1 'c_ARbM' 1};
B=s;

% LTS
s=x;
s.label = 'LTS';
s.mechanisms = {'itonic' 'noise' 'iNaF' 'iKDR' 'iAR'};
s.parameters = {'V_IC' -65 'hNaF_IC' .5 'mKDR_IC' .34 'mAR_IC' .3 'stim' -40 'V_noise' [5] 'IC_noise' [.01] 'E_l' -65 'g_l' 6 'Cm' .9 'gKDR' 10 'KDR_V1' 27 'KDR_d1' 11.5 'KDR_v2' 10 'KDR_d2' 10 'E_KDR' -100 'gNaF' 200 'NaF_V0' 38 'NaF_V1' 58.3 'NaF_d1' 6.7 'NaF_V2' 37 'NaF_d2' 15 'E_NaF' 50 'AR_V0' 75 'E_AR' -35 'gAR' 50 'c_ARaM' 1 'c_ARbM' 1};
LTS=s;

% IBda
s=x;
s.label = 'IBda';
s.mechanisms = {'itonic' 'noise' 'iNaF' 'iKDR' 'iAR' 'iM' 'iCaH'};
s.parameters = {'V_IC' -65 'hNaF_IC' [.5] 'mKDR_IC' [.34] 'mAR_IC' [.3] 'mM_IC' [.05] 'mCaH_IC' [.2] 'stim' [-23.5] 'V_noise' [1] 'IC_noise' [.01] 'E_l' [-70] 'g_l' [2] 'Cm' [.9] 'gKDR' [10] 'KDR_V1' [29.5] 'KDR_d1' [10] 'KDR_v2' [10] 'KDR_d2' [10] 'E_KDR' [-95] 'gNaF' [125] 'NaF_V0' [34.5] 'NaF_V1' [59.4] 'NaF_d1' [10.7] 'NaF_V2' [33.5] 'NaF_d2' [15] 'E_NaF' [50] 'AR_V0' [75] 'E_AR' [-25] 'gAR' [155] 'c_ARaM' [2.75] 'c_ARbM' [3] 'c_CaHaM' [3] 'c_CaHbM' [3] 'gCaH' [6.5] 'c_MaM' [1] 'c_MbM' [1] 'gM' [.75] 'E_M' [-95]};
IBda=s;

% IBs
s=x;
s.label = 'IBs';
s.mechanisms = {'itonic' 'noise' 'iNaF' 'iKDR'};
s.parameters = {'V_IC' -65 'hNaF_IC' [.5] 'mKDR_IC' [.34] 'mAR_IC' [.3] 'mM_IC' [.05] 'mCaH_IC' [.2] 'stim' [4.5] 'V_noise' [0] 'IC_noise' [.01] 'E_l' [-70] 'g_l' [1] 'Cm' [.9] 'gKDR' [10] 'KDR_V1' [29.5] 'KDR_d1' [10] 'KDR_v2' [10] 'KDR_d2' [10] 'E_KDR' [-95] 'gNaF' [50] 'NaF_V0' [34.5] 'NaF_V1' [59.4] 'NaF_d1' [10.7] 'NaF_V2' [33.5] 'NaF_d2' [15] 'E_NaF' [50]};
IBs=s;

% IBdb
s=x;
s.label = 'IBdb';
s.mechanisms = {'itonic' 'noise' 'iNaF' 'iKDR' 'iAR' 'iM' 'iCaH'};
s.parameters = {'V_IC' -65 'hNaF_IC' [.5] 'mKDR_IC' [.34] 'mAR_IC' [.3] 'mM_IC' [.05] 'mCaH_IC' [.2] 'stim' [-23.5] 'V_noise' [1] 'IC_noise' [.01] 'E_l' [-70] 'g_l' [2] 'Cm' [.9] 'gKDR' [10] 'KDR_V1' [29.5] 'KDR_d1' [10] 'KDR_v2' [10] 'KDR_d2' [10] 'E_KDR' [-95] 'gNaF' [125] 'NaF_V0' [34.5] 'NaF_V1' [59.4] 'NaF_d1' [10.7] 'NaF_V2' [33.5] 'NaF_d2' [15] 'E_NaF' [50] 'AR_V0' [75] 'E_AR' [-25] 'gAR' [115] 'c_ARaM' [2.75] 'c_ARbM' [3] 'c_CaHaM' [3] 'c_CaHbM' [3] 'gCaH' [6.5] 'c_MaM' [1] 'c_MbM' [1] 'gM' [.75] 'E_M' [-95]};
IBdb=s;

% IBa
s=x;
s.label = 'IBa';
s.mechanisms = {'itonic' 'noise' 'iNaF' 'iKDR' 'iM'};
s.parameters = {'V_IC' -65 'hNaF_IC' [.5] 'mKDR_IC' [.34] 'mM_IC' [.05] 'mCaH_IC' [.2] 'stim' [6] 'V_noise' [.5] 'IC_noise' [0.01] 'E_l' [-70] 'g_l' [.25] 'Cm' [.9] 'gKDR' [5] 'KDR_V1' [29.5] 'KDR_d1' [10] 'KDR_v2' [10] 'KDR_d2' [10] 'E_KDR' [-95] 'gNaF' [100] 'NaF_V0' [34.5] 'NaF_V1' [59.4] 'NaF_d1' [10.7] 'NaF_V2' [33.5] 'NaF_d2' [15] 'E_NaF' [50] 'c_MaM' [1.5] 'c_MbM' [.75] 'gM' [1.5] 'E_M' [-95]};
IBa=s;

% CONNECTIONS

% ,       ,"RS"   ,"B"    ,"LTS"  ,"IBda" ,"IBs"  ,"IBdb" ,"IBa"
% ,"RS"   ,"iGAP" ,"iSYN" ,"iSYN" ,       ,       ,       ,
% ,"B"    ,"iSYN" ,"iSYN" ,"iSYN" ,       ,       ,       ,
% ,"LTS"  ,"iSYN" ,       ,"iSYN" ,"iSYN" ,       ,       ,
% ,"IBda" ,       ,       ,       ,       ,"iCOM" ,       ,
% ,"IBs"  ,       ,       ,       ,"iCOM" ,       ,"iCOM" ,"iCOM"
% ,"IBdb" ,       ,       ,       ,       ,"iCOM" ,       ,
% ,"IBa"  ,       ,"iSYN" ,"iSYN" ,       ,"iCOM" ,       ,"iGAP"

s=[];

% RS -> RS
a=RS; b=RS;
s.label=[a.label '-' b.label];
s.mechanisms = 'iGAP';
s.parameters = {'fanout' [inf] 'g_GAP' [.04]};
RSRS=s;

% RS -> B
a=RS; b=B;
s.label=[a.label '-' b.label];
s.mechanisms = 'iSYN';
s.parameters = {'fanout' [0.5] 'E_SYN' [0] 'g_SYN' [1] 'tauDx' [1] 'tauRx' [.25] 'IC_noise' [.01]};
RSB=s;

% RS -> LTS
a=RS; b=LTS;
s.label=[a.label '-' b.label];
s.mechanisms = 'iSYN';
s.parameters = {'fanout' [0.5] 'E_SYN' [0] 'g_SYN' [2] 'tauDx' [1] 'tauRx' [2.5] 'IC_noise' [.01]};
RSLTS=s;

% B -> RS    
a=B; b=RS;
s.label=[a.label '-' b.label];
s.mechanisms = 'iSYN';
s.parameters = {'fanout' [0.5] 'E_SYN' [-80] 'g_SYN' [45] 'tauDx' [5] 'tauRx' [.5] 'IC_noise' [0]};
BRS=s;

% B -> B
a=B; b=B;
s.label=[a.label '-' b.label];
s.mechanisms = 'iSYN';
s.parameters = {'fanout' [0.5] 'g_SYN' [15] 'E_SYN' [-75] 'tauDx' [5] 'tauRx' [.5] 'IC_noise' [0]};
BB=s;

% B -> LTS
a=B; b=LTS;
s.label=[a.label '-' b.label];
s.mechanisms = 'iSYN';
s.parameters = {'fanout' [0.5] 'E_SYN' [-80] 'g_SYN' [8] 'tauDx' [6] 'tauRx' [.5] 'IC_noise' [.01]};
BLTS=s;

% LTS -> RS
a=LTS; b=RS;
s.label=[a.label '-' b.label];
s.mechanisms = 'iSYN';
s.parameters = {'fanout' [0.5] 'E_SYN' [-80] 'g_SYN' [2.5] 'tauDx' [20] 'tauRx' [.5] 'IC_noise' [.01]};
LTSRS=s;

% LTS -> LTS
a=LTS; b=LTS;
s.label=[a.label '-' b.label];
s.mechanisms = 'iSYN';
s.parameters = {'fanout' [0.5] 'E_SYN' [-80] 'g_SYN' [5] 'tauDx' [20] 'tauRx' [.5] 'IC_noise' [.01]};
LTSLTS=s;

% LTS -> IBda
a=LTS; b=IBda;
s.label=[a.label '-' b.label];
s.mechanisms = 'iSYN';
s.parameters = {'fanout' [0.5] 'E_SYN' [-80] 'g_SYN' [4] 'tauDx' [20] 'tauRx' [.5] 'IC_noise' [.01]};
LTSIBda=s;

% IBda -> IBs
a=IBda; b=IBs;
s.label=[a.label '-' b.label];
s.mechanisms = 'iCOM';
s.parameters = {'fanout' [0.5] 'g_COM' [.4]};
IBdaIBs=s;

% IBs -> IBda
a=IBs; b=IBda;
s.label=[a.label '-' b.label];
s.mechanisms = 'iCOM';
s.parameters = {'fanout' [0.5] 'g_COM' [.2]};
IBsIBda=s;

% IBs -> IBdb
a=IBs; b=IBdb;
s.label=[a.label '-' b.label];
s.mechanisms = 'iCOM';
s.parameters = {'fanout' [0.5] 'g_COM' [.2]};
IBsIBdb=s;

% IBs -> IBa
a=IBs; b=IBa;
s.label=[a.label '-' b.label];
s.mechanisms = 'iCOM';
s.parameters = {'fanout' [0.5] 'g_COM' [.3]};
IBsIBa=s;

% IBdb -> IBs
a=IBdb; b=IBs;
s.label=[a.label '-' b.label];
s.mechanisms = 'iCOM';
s.parameters = {'fanout' [0.5] 'g_COM' [.4]};
IBdbIBs=s;

% IBa -> B
a=IBa; b=B;
s.label=[a.label '-' b.label];
s.mechanisms = 'iSYN';
s.parameters = {'fanout' [inf] 'E_SYN' [0] 'g_SYN' [.045] 'tauDx' [1] 'tauRx' [.25] 'IC_noise' [0]};
IBaB=s;

% IBa -> LTS
a=IBa; b=LTS;
s.label=[a.label '-' b.label];
s.mechanisms = 'iSYN';
s.parameters = {'fanout' [inf] 'E_SYN' [0] 'g_SYN' [.04] 'tauDx' [50] 'tauRx' [2.5] 'IC_noise' [0]};
IBaLTS=s;

% IBa -> IBs
a=IBa; b=IBs;
s.label=[a.label '-' b.label];
s.mechanisms = 'iCOM';
s.parameters = {'fanout' [0.5] 'g_COM' [.3]};
IBaIBs=s;

% IBa -> IBa
a=IBa; b=IBa;
s.label=[a.label '-' b.label];
s.mechanisms = 'iGAP';
s.parameters = {'fanout' [inf] 'g_GAP' .002};
IBaIBa=s;

% CONNECT CELLS
net = [];       % 1  2 3   4    5   6    7  
net.cells = cat(2,RS,B,LTS,IBda,IBs,IBdb,IBa);

net.connections(1,1)=RSRS;    % RS -> RS
net.connections(1,2)=RSB;     % RS -> B
net.connections(1,3)=RSLTS;   % RS -> LTS
net.connections(2,1)=BRS;     % B -> RS  
net.connections(2,2)=BB;      % B -> B
net.connections(2,3)=BLTS;    % B -> LTS
net.connections(3,1)=LTSRS;   % LTS -> RS
net.connections(3,3)=LTSLTS;  % LTS -> LTS
net.connections(3,4)=LTSIBda; % LTS -> IBda
net.connections(4,5)=IBdaIBs; % IBda -> IBs
net.connections(5,4)=IBsIBda; % IBs -> IBda
net.connections(5,6)=IBsIBdb; % IBs -> IBdb
net.connections(5,7)=IBsIBa;  % IBs -> IBa
net.connections(6,5)=IBdbIBs; % IBdb -> IBs
net.connections(7,2)=IBaB;    % IBa -> B
net.connections(7,3)=IBaLTS;  % IBa -> LTS
net.connections(7,5)=IBaIBs;  % IBa -> IBs
net.connections(7,7)=IBaIBa;  % IBa -> IBa

% launch modeler
modeler(net);

%{
% Kramer model

"ID","N","Mechanisms","Key/Value Pairs","Dynamics"
"RS",30,"{'itonic' 'noise' 'iNaF' 'iKDR' 'iAR'}","{'hNaF' .5 'mKDR' .34 'mAR' .3 'stim' 12.5 'V_noise' [8] 'IC_noise' [.01] 'E_l' -70 'g_l' 1 'Cm' .9 'gKDR' 20 'KDR_V1' 29.5 'KDR_d1' 10 'KDR_v2' 10 'KDR_d2' 10 'E_KDR' -95 'gNaF' 200 'NaF_V0' 34.5 'NaF_V1' 59.4 'NaF_d1' 10.7 'NaF_V2' 33.5 'NaF_d2' 15 'E_NaF' 50 'AR_V0' 87.5 'E_AR' -35 'gAR' 25 'c_ARaM' 1.75 'c_ARbM' .5}
"B",30,"{'itonic' 'noise' 'iNaF' 'iKDR'}","{'hNaF' .5 'mKDR' .34 'stim' -16 'V_noise' [3] 'IC_noise' [.01] 'E_l' -65 'g_l' 1 'Cm' .9 'gKDR' 20 'KDR_V1' 27 'KDR_d1' 11.5 'KDR_v2' 10 'KDR_d2' 10 'E_KDR' -100 'gNaF' 200 'NaF_V0' 38 'NaF_V1' 58.3 'NaF_d1' 6.7 'NaF_V2' 37 'NaF_d2' 15 'E_NaF' 50 'AR_V0' 87.5 'E_AR' -35 'gAR' 50 'c_ARaM' 1 'c_ARbM' 1}
"LTS",30,"{'itonic' 'noise' 'iNaF' 'iKDR' 'iAR'}","{'hNaF' .5 'mKDR' .34 'mAR' .3 'stim' -40 'V_noise' [5] 'IC_noise' [.01] 'E_l' -65 'g_l' 6 'Cm' .9 'gKDR' 10 'KDR_V1' 27 'KDR_d1' 11.5 'KDR_v2' 10 'KDR_d2' 10 'E_KDR' -100 'gNaF' 200 'NaF_V0' 38 'NaF_V1' 58.3 'NaF_d1' 6.7 'NaF_V2' 37 'NaF_d2' 15 'E_NaF' 50 'AR_V0' 75 'E_AR' -35 'gAR' 50 'c_ARaM' 1 'c_ARbM' 1}
"IBda",30,"{'itonic' 'noise' 'iNaF' 'iKDR' 'iAR' 'iM' 'iCaH'}","{'hNaF' [.5] 'mKDR' [.34] 'mAR' [.3] 'mM' [.05] 'mCaH' [.2] 'stim' [-23.5] 'V_noise' [1] 'IC_noise' [.01] 'E_l' [-70] 'g_l' [2] 'Cm' [.9] 'gKDR' [10] 'KDR_V1' [29.5] 'KDR_d1' [10] 'KDR_v2' [10] 'KDR_d2' [10] 'E_KDR' [-95] 'gNaF' [125] 'NaF_V0' [34.5] 'NaF_V1' [59.4] 'NaF_d1' [10.7] 'NaF_V2' [33.5] 'NaF_d2' [15] 'E_NaF' [50] 'AR_V0' [75] 'E_AR' [-25] 'gAR' [155] 'c_ARaM' [2.75] 'c_ARbM' [3] 'c_CaHaM' [3] 'c_CaHbM' [3] 'gCaH' [6.5] 'c_MaM' [1] 'c_MbM' [1] 'gM' [.75] 'E_M' [-95]}
"IBs",30,"{'itonic' 'noise' 'iNaF' 'iKDR'}","{'hNaF' [.5] 'mKDR' [.34] 'mAR' [.3] 'mM' [.05] 'mCaH' [.2] 'stim' [4.5] 'V_noise' [0] 'IC_noise' [.01] 'E_l' [-70] 'g_l' [1] 'Cm' [.9] 'gKDR' [10] 'KDR_V1' [29.5] 'KDR_d1' [10] 'KDR_v2' [10] 'KDR_d2' [10] 'E_KDR' [-95] 'gNaF' [50] 'NaF_V0' [34.5] 'NaF_V1' [59.4] 'NaF_d1' [10.7] 'NaF_V2' [33.5] 'NaF_d2' [15] 'E_NaF' [50]}
"IBdb",30,"{'itonic' 'noise' 'iNaF' 'iKDR' 'iAR' 'iM' 'iCaH'}","{'hNaF' [.5] 'mKDR' [.34] 'mAR' [.3] 'mM' [.05] 'mCaH' [.2] 'stim' [-23.5] 'V_noise' [1] 'IC_noise' [.01] 'E_l' [-70] 'g_l' [2] 'Cm' [.9] 'gKDR' [10] 'KDR_V1' [29.5] 'KDR_d1' [10] 'KDR_v2' [10] 'KDR_d2' [10] 'E_KDR' [-95] 'gNaF' [125] 'NaF_V0' [34.5] 'NaF_V1' [59.4] 'NaF_d1' [10.7] 'NaF_V2' [33.5] 'NaF_d2' [15] 'E_NaF' [50] 'AR_V0' [75] 'E_AR' [-25] 'gAR' [115] 'c_ARaM' [2.75] 'c_ARbM' [3] 'c_CaHaM' [3] 'c_CaHbM' [3] 'gCaH' [6.5] 'c_MaM' [1] 'c_MbM' [1] 'gM' [.75] 'E_M' [-95]}
"IBa",30,"{'itonic' 'noise' 'iNaF' 'iKDR' 'iM'}","{'hNaF' [.5] 'mKDR' [.34] 'mM' [.05] 'mCaH' [.2] 'stim' [4] 'V_noise' [.5] 'IC_noise' [0.01] 'E_l' [-70] 'g_l' [.25] 'Cm' [.9] 'gKDR' [5] 'KDR_V1' [29.5] 'KDR_d1' [10] 'KDR_v2' [10] 'KDR_d2' [10] 'E_KDR' [-95] 'gNaF' [100] 'NaF_V0' [34.5] 'NaF_V1' [59.4] 'NaF_d1' [10.7] 'NaF_V2' [33.5] 'NaF_d2' [15] 'E_NaF' [50] 'c_MaM' [1.5] 'c_MbM' [.75] 'gM' [1.5] 'E_M' [-95]}

,       ,"RS"   ,"B"    ,"LTS"  ,"IBda" ,"IBs"  ,"IBdb" ,"IBa"
,"RS"   ,"iGAP" ,"iSYN" ,"iSYN" ,       ,       ,       ,
,"B"    ,"iSYN" ,"iSYN" ,"iSYN" ,       ,       ,       ,
,"LTS"  ,"iSYN" ,       ,"iSYN" ,"iSYN" ,       ,       ,
,"IBda" ,       ,       ,       ,       ,"iCOM" ,       ,
,"IBs"  ,       ,       ,       ,"iCOM" ,       ,"iCOM" ,"iCOM"
,"IBdb" ,       ,       ,       ,       ,"iCOM" ,       ,
,"IBa"  ,       ,"iSYN" ,"iSYN" ,       ,"iCOM" ,       ,"iGAP"

,,"(post)",,,,,,
,,"RS","B","LTS","IBda","IBs","IBdb","IBa"
"(pre)","RS","{'fanout' [inf] 'g_GAP' [.04]}","{'fanout' [0.5] 'E_SYN' [0] 'g_SYN' [1] 'tauDx' [1] 'tauRx' [.25] 'IC_noise' [.01]}","{'fanout' [0.5] 'E_SYN' [0] 'g_SYN' [2] 'tauDx' [1] 'tauRx' [2.5] 'IC_noise' [.01]}",,,,
,"B","{'fanout' [0.5] 'E_SYN' [-80] 'g_SYN' [45] 'tauDx' [5] 'tauRx' [.5] 'IC_noise' [0]}","{'fanout' [0.5] 'g_SYN' [15] 'E_SYN' [-75] 'tauDx' [5] 'tauRx' [.5] 'IC_noise' [0]}","{'fanout' [0.5] 'E_SYN' [-80] 'g_SYN' [8] 'tauDx' [6] 'tauRx' [.5] 'IC_noise' [.01]}",,,,
,"LTS","{'fanout' [0.5] 'E_SYN' [-80] 'g_SYN' [2.5] 'tauDx' [20] 'tauRx' [.5] 'IC_noise' [.01]}",,"{'fanout' [0.5] 'E_SYN' [-80] 'g_SYN' [5] 'tauDx' [20] 'tauRx' [.5] 'IC_noise' [.01]}","{'fanout' [0.5] 'E_SYN' [-80] 'g_SYN' [4] 'tauDx' [20] 'tauRx' [.5] 'IC_noise' [.01]}",,,
,"IBda",,,,,"{'fanout' [0.5] 'g_COM' [.4]}",,
,"IBs",,,,"{'fanout' [0.5] 'g_COM' [.2]}",,"{'fanout' [0.5] 'g_COM' [.2]}","{'fanout' [0.5] 'g_COM' [.3]}"
,"IBdb",,,,,"{'fanout' [0.5] 'g_COM' [.4]}",,
,"IBa",,"{'fanout' [inf] 'E_SYN' [0] 'g_SYN' [.045] 'tauDx' [1] 'tauRx' [.25] 'IC_noise' [0]}","{'fanout' [inf] 'E_SYN' [0] 'g_SYN' [.04] 'tauDx' [50] 'tauRx' [2.5] 'IC_noise' [0]}",,"{'fanout' [0.5] 'g_COM' [.3]}",,"{'fanout' [inf] 'g_GAP' .002}"

%}    