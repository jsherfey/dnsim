% Model: ib_connected3
cd /home/davestanley/research/dnsim/ib_connected3;
spec=[];
spec.nodes(1).label = 'IBa';
spec.nodes(1).multiplicity = 3;
spec.nodes(1).dynamics = {'V''=(current)/Cm'};
spec.nodes(1).mechanisms = {'IBa_itonic','IBa_noise','IBa_iNaF','IBa_iKDR','IBa_iM'};
spec.nodes(1).parameters = {'hNaF_IC',0.5,'mKDR_IC',0.34,'mM_IC',0.05,'mCaH_IC',0.2,'stim',6,'V_noise',0,'IC_noise',0.01,'E_l',-70,'g_l',0.25,'Cm',0.9,'gKDR',5,'KDR_V1',29.5,'KDR_d1',10,'KDR_v2',10,'KDR_d2',10,'E_KDR',-95,'gNaF',100,'NaF_V0',34.5,'NaF_V1',59.4,'NaF_d1',10.7,'NaF_V2',33.5,'NaF_d2',15,'E_NaF',50,'c_MaM',1.5,'c_MbM',0.75,'gM',1.5,'E_M',-95};
spec.nodes(2).label = 'IBs';
spec.nodes(2).multiplicity = 3;
spec.nodes(2).dynamics = {'V''=(current)'};
spec.nodes(2).mechanisms = {'IBs_itonic','IBs_noise','IBs_iNaF','IBs_iKDR'};
spec.nodes(2).parameters = {'hNaF_IC',0.5,'mKDR_IC',0.34,'mAR_IC',0.3,'mM_IC',0.05,'mCaH_IC',0.2,'stim',4.5,'V_noise',0,'IC_noise',0.01,'E_l',-70,'g_l',1,'Cm',0.9,'gKDR',10,'KDR_V1',29.5,'KDR_d1',10,'KDR_v2',10,'KDR_d2',10,'E_KDR',-95,'gNaF',50,'NaF_V0',34.5,'NaF_V1',59.4,'NaF_d1',10.7,'NaF_V2',33.5,'NaF_d2',15,'E_NaF',50};
spec.nodes(3).label = 'IBda';
spec.nodes(3).multiplicity = 3;
spec.nodes(3).dynamics = {'V''=(current)'};
spec.nodes(3).mechanisms = {'IBda_itonic','IBda_noise','IBda_iNaF','IBda_iKDR','IBda_iAR','IBda_iM','IBda_iCaH'};
spec.nodes(3).parameters = {'hNaF_IC',0.5,'mKDR_IC',0.34,'mAR_IC',0.3,'mM_IC',0.05,'mCaH_IC',0.2,'stim',-23.5,'V_noise',0,'IC_noise',0.01,'E_l',-70,'g_l',2,'Cm',0.9,'gKDR',10,'KDR_V1',29.5,'KDR_d1',10,'KDR_v2',10,'KDR_d2',10,'E_KDR',-95,'gNaF',125,'NaF_V0',34.5,'NaF_V1',59.4,'NaF_d1',10.7,'NaF_V2',33.5,'NaF_d2',15,'E_NaF',50,'AR_V0',75,'E_AR',-25,'gAR',155,'c_ARaM',2.75,'c_ARbM',3,'c_CaHaM',3,'c_CaHbM',3,'gCaH',6.5,'c_MaM',1,'c_MbM',1,'gM',0.75,'E_M',-95};
spec.nodes(4).label = 'IBdb';
spec.nodes(4).multiplicity = 3;
spec.nodes(4).dynamics = {'V''=(current)'};
spec.nodes(4).mechanisms = {'IBdb_itonic','IBdb_noise','IBdb_iNaF','IBdb_iKDR','IBdb_iAR','IBdb_iM','IBdb_iCaH','IBdb_iPoissonExp'};
spec.nodes(4).parameters = {'hNaF_IC',0.5,'mKDR_IC',0.34,'mAR_IC',0.3,'mM_IC',0.05,'mCaH_IC',0.2,'stim',-23.5,'V_noise',0,'IC_noise',0.01,'E_l',-70,'g_l',2,'Cm',0.9,'gKDR',10,'KDR_V1',29.5,'KDR_d1',10,'KDR_v2',10,'KDR_d2',10,'E_KDR',-95,'gNaF',125,'NaF_V0',34.5,'NaF_V1',59.4,'NaF_d1',10.7,'NaF_V2',33.5,'NaF_d2',15,'E_NaF',50,'AR_V0',75,'E_AR',-25,'gAR',115,'c_ARaM',2.75,'c_ARbM',3,'c_CaHaM',3,'c_CaHbM',3,'gCaH',6.5,'c_MaM',1,'c_MbM',1,'gM',0.75,'E_M',-95};
spec.connections(1,2).label = 'IBa-IBs';
spec.connections(1,2).mechanisms = {'IBa_IBs_iCOM'};
spec.connections(1,2).parameters = [];
spec.connections(1,4).label = 'IBa-IBdb';
spec.connections(1,4).mechanisms = {'IBa_IBdb_iSYNconv'};
spec.connections(1,4).parameters = [];
spec.connections(2,1).label = 'IBs-IBa';
spec.connections(2,1).mechanisms = {'IBs_IBa_iCOM'};
spec.connections(2,1).parameters = [];
spec.connections(2,3).label = 'IBs-IBda';
spec.connections(2,3).mechanisms = {'IBs_IBda_iCOM'};
spec.connections(2,3).parameters = [];
spec.connections(2,4).label = 'IBs-IBdb';
spec.connections(2,4).mechanisms = {'IBs_IBdb_iCOM'};
spec.connections(2,4).parameters = [];
spec.connections(3,2).label = 'IBda-IBs';
spec.connections(3,2).mechanisms = {'IBda_IBs_iCOM'};
spec.connections(3,2).parameters = [];
spec.connections(4,2).label = 'IBdb-IBs';
spec.connections(4,2).mechanisms = {'IBdb_IBs_iCOM'};
spec.connections(4,2).parameters = [];
%dnsim(spec); % open model in DNSim GUI

% DNSim simulation and plots:
data = runsim(spec,'timelimits',[0 100],'dt',.01,'SOLVER','euler'); % simulate DNSim models
plotv(data,spec,'varlabel','V'); % quickly plot select variables
%visualizer(data); % ugly interactive tool hijacked to visualize sim_data
% 

t=data(1).epochs.time;
IBaV=squeeze(data(1).epochs.data(4,:,:)); % [time x cells]
IBsV=squeeze(data(2).epochs.data(3,:,:));
IBdaV=squeeze(data(3).epochs.data(6,:,:));
IBdbV=squeeze(data(4).epochs.data(7,:,:));

figure; plot(t,IBdaV(:,1));% IBda, cell 1
figure; plot(t,IBdaV(:,2));% IBda, cell 2

% % Sweep over parameter values:
model=buildmodel(spec); % parse DNSim spec structure
simstudy(model,{'IBa'},{'N'},{'[1 2]'},'timelimits',[0 100],'dt',.02,'SOLVER','euler'); % N = # of cells

