% Lundqvist, Compte, Lansner 2010. Bistable, Irregular Firing and 
% Population Oscillations in a Modular Attractor Memory Network.
cd /project/crc-nak/sherfey/projects/wm/models-PFC/superficial/mine

% cell parameters
nE=40; nI=1; nCB=2;  % number of cells (nE=40, 200)
dE=21; dI=7; dCB=7; % soma diameter [um]. area=pi*(d/2)^2 dendritic area=4*soma area.
SE=pi*(dE/2)^2; SEd=4*SE; SI=pi*(dI/2)^2; SCB=pi*(dCB/2)^2;

% synaptic parameters
Eampa=0;    tauRampa=.083;  tauDampa=2;
Enmda=0;    tauRnmda=2E-5;  tauDnmda=150;
Egaba=-80;  tauRgaba=.083;  tauDgaba=10;

gEEampa=.77; % .77/.34
gEEnmda=2.5;%1.7; % 2.7;  1.35/.6
gEIampa=1.09;%.09;
gEInmda=0;
gECBampa=.1;%.009;
gECBnmda=.2;%.015;
gIE=1.16;%4.11;
gII=.6;%.25;
gCBE=2.2;

EEspan=.25; %EEfanout=(EEspan*nE)/2;
EIfanout=inf;
ECBfanout=inf;
IEfanout=inf;
IIfanout=inf;
CBEfanout=inf;

net=[];

%% Define compartments for all cells and connect compartments within cells
% ------------------------------------
% E-cell
name  ='E';
num   =nE;
vnoise=35;
gcore =.81;
cm    =.8; 
gm    =.54;  Eleak =-80;
gNa   =80;   ENa   =55;    
gK    =36;   EK    =-80;   
gNap  = .6;  ENap  = ENa;  napshift=5;
gCan  =.07;  ECan  =-20;   tauca=80; alphacaf=.002;  % gCan=.1
gCa   =(29.4/SE)*100; ECa=150;
onset=100; offset=200; amp=15; span=.25; % injected current
% ------------------------------------
% soma
cell=[];
cell.label = name;
cell.multiplicity = num;
cell.mechanisms = {'ifocal2','iL','iNa','iK','iCa','noise','iNap','CaDyn','iCan'};
cell.parameters = {'g_l',gm,'E_l',Eleak,'cm',cm,'V_IC',-70,'IC_noise',0,'V_noise',vnoise,...
                   'gNa',gNa,'ENa',ENa,'gNap',gNap,'napshift',napshift,'ENap',ENap,'gKf',gK,'EKf',EK,'gCaf',gCa,'ECaf',ECa,... 
                   'gCan',gCan,'ECan',ECan,'tauca',tauca,'alphacaf',alphacaf,...
                   'sigamp2',amp,'sigonset2',onset,'sigoffset2',offset,'sigspan',span}; % 'sigspan',.25
cell.dynamics = 'V''=(current)./cm';
net.cells(1) = cell; 

from=1; to=1;
net.connections(from,to).label = [net.cells(from).label '-' net.cells(to).label];
net.connections(from,to).mechanisms = {'iNMDAgbar'};%,'iSYNgbar'};
net.connections(from,to).parameters = {...
  'g_NMDA',gEEnmda,'E_NMDA',Enmda,'alphar',1/tauRnmda,'NtauD',tauDnmda,'NMspan',EEspan,...%'NMspan',EEspan,...
  'g_SYN',gEEampa,'E_SYN',Eampa,'tauDx',tauDampa,'tauRx',tauRampa,'span',EEspan};

modeler(net);


% % dendrite
% cell.label = [name 'd'];
% net.cells(2) = cell; Edend=cell;
% % connect compartments
% from=2; to=1; % Ed->E
% net.connections(from,to).label = [net.cells(from).label '-' net.cells(to).label];
% net.connections(from,to).mechanisms = 'Icore';
% net.connections(from,to).parameters = {'gcore',gcore};
% from=1; to=2; % E->Ed
% net.connections(from,to).label = [net.cells(from).label '-' net.cells(to).label];
% net.connections(from,to).mechanisms = {'Icore','INMDACa','Isyn'};
% net.connections(from,to).parameters = {'gcore',gcore,...
%   'gNMDA',gEEnmda,'ENMDA',Enmda,'taurNMDA',tauRnmda,'taudNMDA',tauDnmda,'fanout',EEfanout,'taurCaNMDA',taurCaNMDA,'taudCaNMDA',taudCaNMDA,'Aap',Aap,'Cap',Cap,'Abp',Abp,'Cbp',Cbp,...
%     'ICsNMDA_noise',0,'ICCaNMDA_noise',0,'ICp_noise',0,...
%   'g_SYN',gEEampa,'E_SYN',Eampa,'tauRx',tauRampa,'tauDx',tauDampa,'fanout',EEfanout};
% Ecell=net;
% modeler(Ecell);

% ------------------------------------
% I-cell
name  ='I';
num   =nI;
gcore =.81;
cm    =1; 
gm    =.44;   Eleak=-75;
gext  =.015;   Eext  =0;
gNa   =15;   ENa   =50; % gNa initial segment = 2500
gK    =100;  EK    =-80;   EKCa=EK;
gCa   =105;   ECa   =150;   gKCa=gCa;%ECaNMDA=20;
taurCaAP  =1;      taudCaAP=4;
taurCaNMDA=10.6E6; taudCaNMDA=1;
% ------------------------------------
cell=[];
cell.label = name;
cell.multiplicity = num;
cell.mechanisms = {}; 
cell.parameters = {};
cell.dynamics = 'V''=(current)./cm';
net.cells(3) = cell; 
Icell=cell;

% ------------------------------------
% CB-cell
name  ='CB';
num   =nCB;
gcore =.81;
cm    =.01; 
gm    =.44;   Eleak=-75;
gext  =.015;   Eext  =0;
gNa   =15;   ENa   =50; % gNa initial segment = 2500
gK    =100;  EK    =-80;   EKCa=EK;
gCa   =.368;  ECa   =150;   gKCa=gCa;%ECaNMDA=20;
taurCaAP  =1;      taudCaAP=4;
taurCaNMDA=10.6E6; taudCaNMDA=1;
% ------------------------------------
cell=[];
cell.label = name;
cell.multiplicity = num;
cell.mechanisms = {}; 
cell.parameters = {};
cell.dynamics = 'V''=(current)./cm';
net.cells(3) = cell; 
CBcell=cell;

%% Connect cells between cell populations

% ------------------------------------
% I->E (GABAa)
% ------------------------------------
from=3; to=1;
net.connections(from,to).label = [net.cells(from).label '-' net.cells(to).label];
net.connections(from,to).mechanisms = 'iSYNgbar';
net.connections(from,to).parameters = {};



