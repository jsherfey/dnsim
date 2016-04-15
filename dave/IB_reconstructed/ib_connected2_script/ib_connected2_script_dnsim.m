% Model: ib_connected2_script
% cd /home/davestanley/Dropbox/git/dnsim/dave/IB_reconstructed/ib_connected2_script;
spec=[];
spec.nodes(1).label = 'IBa';
spec.nodes(1).multiplicity = 2;
spec.nodes(1).dynamics = {'V''=(current)/Cm'};
spec.nodes(1).mechanisms = {'IBa_itonic','IBa_noise','IBa_iNaF','IBa_iKDR','IBa_iM'};
spec.nodes(1).parameters = {'hNaF_IC',0.5,'mKDR_IC',0.34,'mM_IC',0.05,'mCaH_IC',0.2,'stim',4,'V_noise',0.5,'IC_noise',0.01,'E_l',-70,'g_l',0.25,'Cm',0.9,'gKDR',5,'KDR_V1',29.5,'KDR_d1',10,'KDR_v2',10,'KDR_d2',10,'E_KDR',-95,'gNaF',100,'NaF_V0',34.5,'NaF_V1',59.4,'NaF_d1',10.7,'NaF_V2',33.5,'NaF_d2',15,'E_NaF',50,'c_MaM',1.5,'c_MbM',0.75,'gM',1.5,'E_M',-95};
spec.nodes(2).label = 'IBs';
spec.nodes(2).multiplicity = 2;
spec.nodes(2).dynamics = {'V''=(current)'};
spec.nodes(2).mechanisms = {'IBs_itonic','IBs_noise','IBs_iNaF','IBs_iKDR'};
spec.nodes(2).parameters = {'hNaF_IC',0.5,'mKDR_IC',0.34,'mAR_IC',0.3,'mM_IC',0.05,'mCaH_IC',0.2,'stim',4.5,'V_noise',0,'IC_noise',0.01,'E_l',-70,'g_l',1,'Cm',0.9,'gKDR',10,'KDR_V1',29.5,'KDR_d1',10,'KDR_v2',10,'KDR_d2',10,'E_KDR',-95,'gNaF',50,'NaF_V0',34.5,'NaF_V1',59.4,'NaF_d1',10.7,'NaF_V2',33.5,'NaF_d2',15,'E_NaF',50};
spec.nodes(3).label = 'IBda';
spec.nodes(3).multiplicity = 2;
spec.nodes(3).dynamics = {'V''=(current)'};
spec.nodes(3).mechanisms = {'IBda_itonic','IBda_noise','IBda_iNaF','IBda_iKDR','IBda_iAR','IBda_iM','IBda_iCaH'};
spec.nodes(3).parameters = {'hNaF_IC',0.5,'mKDR_IC',0.34,'mAR_IC',0.3,'mM_IC',0.05,'mCaH_IC',0.2,'stim',-23.5,'V_noise',1,'IC_noise',0.01,'E_l',-70,'g_l',2,'Cm',0.9,'gKDR',10,'KDR_V1',29.5,'KDR_d1',10,'KDR_v2',10,'KDR_d2',10,'E_KDR',-95,'gNaF',125,'NaF_V0',34.5,'NaF_V1',59.4,'NaF_d1',10.7,'NaF_V2',33.5,'NaF_d2',15,'E_NaF',50,'AR_V0',75,'E_AR',-25,'gAR',155,'c_ARaM',2.75,'c_ARbM',3,'c_CaHaM',3,'c_CaHbM',3,'gCaH',6.5,'c_MaM',1,'c_MbM',1,'gM',0.75,'E_M',-95};
spec.nodes(4).label = 'IBdb';
spec.nodes(4).multiplicity = 2;
spec.nodes(4).dynamics = {'V''=(current)'};
spec.nodes(4).mechanisms = {'IBdb_itonic','IBdb_noise','IBdb_iNaF','IBdb_iKDR','IBdb_iAR','IBdb_iM','IBdb_iCaH'};
spec.nodes(4).parameters = {'hNaF_IC',0.5,'mKDR_IC',0.34,'mAR_IC',0.3,'mM_IC',0.05,'mCaH_IC',0.2,'stim',-23.5,'V_noise',1,'IC_noise',0.01,'E_l',-70,'g_l',2,'Cm',0.9,'gKDR',10,'KDR_V1',29.5,'KDR_d1',10,'KDR_v2',10,'KDR_d2',10,'E_KDR',-95,'gNaF',125,'NaF_V0',34.5,'NaF_V1',59.4,'NaF_d1',10.7,'NaF_V2',33.5,'NaF_d2',15,'E_NaF',50,'AR_V0',75,'E_AR',-25,'gAR',115,'c_ARaM',2.75,'c_ARbM',3,'c_CaHaM',3,'c_CaHbM',3,'gCaH',6.5,'c_MaM',1,'c_MbM',1,'gM',0.75,'E_M',-95};
spec.connections(1,2).label = 'IBa-IBs';
spec.connections(1,2).mechanisms = {'IBa_IBs_iCOM'};
spec.connections(1,2).parameters = [];
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
data = runsim(spec,'timelimits',[0 100],'dt',.02,'SOLVER','euler'); % simulate DNSim models
plotv(data,spec,'varlabel','V'); % quickly plot select variables
%visualizer(data); % ugly interactive tool hijacked to visualize sim_data

% Sweep over parameter values:
model=buildmodel(spec); % parse DNSim spec structure
simstudy(model,{'IBa'},{'N'},{'[1 2]'},'timelimits',[0 100],'dt',.02,'SOLVER','euler'); % N = # of cells


% Manual simulation and plots:
%{
%-----------------------------------------------------------
% Auxiliary variables:
	IBs_IBa_iCOM_UB      = max((2),(2));
	IBs_IBa_iCOM_Xpre    = linspace(1,IBs_IBa_iCOM_UB,(2))'*ones(1,(2));
	IBs_IBa_iCOM_Xpost   = (linspace(1,IBs_IBa_iCOM_UB,(2))'*ones(1,(2)))';
	IBs_IBa_iCOM_mask    = abs(IBs_IBa_iCOM_Xpre-IBs_IBa_iCOM_Xpost)<=(0.5);
	IBa_IBs_iCOM_UB      = max((2),(2));
	IBa_IBs_iCOM_Xpre    = linspace(1,IBa_IBs_iCOM_UB,(2))'*ones(1,(2));
	IBa_IBs_iCOM_Xpost   = (linspace(1,IBa_IBs_iCOM_UB,(2))'*ones(1,(2)))';
	IBa_IBs_iCOM_mask    = abs(IBa_IBs_iCOM_Xpre-IBa_IBs_iCOM_Xpost)<=(0.5);
	IBda_IBs_iCOM_UB     = max((2),(2));
	IBda_IBs_iCOM_Xpre   = linspace(1,IBda_IBs_iCOM_UB,(2))'*ones(1,(2));
	IBda_IBs_iCOM_Xpost  = (linspace(1,IBda_IBs_iCOM_UB,(2))'*ones(1,(2)))';
	IBda_IBs_iCOM_mask   = abs(IBda_IBs_iCOM_Xpre-IBda_IBs_iCOM_Xpost)<=(0.5);
	IBdb_IBs_iCOM_UB     = max((2),(2));
	IBdb_IBs_iCOM_Xpre   = linspace(1,IBdb_IBs_iCOM_UB,(2))'*ones(1,(2));
	IBdb_IBs_iCOM_Xpost  = (linspace(1,IBdb_IBs_iCOM_UB,(2))'*ones(1,(2)))';
	IBdb_IBs_iCOM_mask   = abs(IBdb_IBs_iCOM_Xpre-IBdb_IBs_iCOM_Xpost)<=(0.5);
	IBs_IBda_iCOM_UB     = max((2),(2));
	IBs_IBda_iCOM_Xpre   = linspace(1,IBs_IBda_iCOM_UB,(2))'*ones(1,(2));
	IBs_IBda_iCOM_Xpost  = (linspace(1,IBs_IBda_iCOM_UB,(2))'*ones(1,(2)))';
	IBs_IBda_iCOM_mask   = abs(IBs_IBda_iCOM_Xpre-IBs_IBda_iCOM_Xpost)<=(0.5);
	IBs_IBdb_iCOM_UB     = max((2),(2));
	IBs_IBdb_iCOM_Xpre   = linspace(1,IBs_IBdb_iCOM_UB,(2))'*ones(1,(2));
	IBs_IBdb_iCOM_Xpost  = (linspace(1,IBs_IBdb_iCOM_UB,(2))'*ones(1,(2)))';
	IBs_IBdb_iCOM_mask   = abs(IBs_IBdb_iCOM_Xpre-IBs_IBdb_iCOM_Xpost)<=(0.5);

% Anonymous functions:
	IBa_itonic_Itonic    = @(t) (4)*(t>(0) & t<(Inf));             
	IBa_iNaF_hinf        = @(IBa_V) 1./(1+exp((IBa_V+(59.4))/(10.7)));
	IBa_iNaF_htau        = @(IBa_V) (0.15) + (1.15)./(1+exp((IBa_V+(33.5))/(15)));
	IBa_iNaF_m0          = @(IBa_V) 1./(1+exp((-IBa_V-(34.5))/10));
	IBa_iNaF_aH          = @(IBa_V) (1./(1+exp((IBa_V+(59.4))/(10.7)))) ./ ((0.15) + (1.15)./(1+exp((IBa_V+(33.5))/(15))));
	IBa_iNaF_bH          = @(IBa_V) (1-(1./(1+exp((IBa_V+(59.4))/(10.7)))))./((0.15) + (1.15)./(1+exp((IBa_V+(33.5))/(15))));
	IBa_iNaF_INaF        = @(IBa_V,h) (100).*(1./(1+exp((-IBa_V-(34.5))/10))).^3.*h.*(IBa_V-(50));
	IBa_iKDR_minf        = @(IBa_V) 1./(1+exp((-IBa_V-(29.5))/(10)));
	IBa_iKDR_mtau        = @(IBa_V) .25+4.35*exp(-abs(IBa_V+(10))/(10));
	IBa_iKDR_aM          = @(IBa_V) (1./(1+exp((-IBa_V-(29.5))/(10)))) ./ (.25+4.35*exp(-abs(IBa_V+(10))/(10)));
	IBa_iKDR_bM          = @(IBa_V) (1-(1./(1+exp((-IBa_V-(29.5))/(10)))))./(.25+4.35*exp(-abs(IBa_V+(10))/(10)));
	IBa_iKDR_IKDR        = @(IBa_V,m) (5).*m.^4.*(IBa_V-(-95));    
	IBa_iM_aM            = @(IBa_V) (1.5).*(.02./(1+exp((-20-IBa_V)/5)));
	IBa_iM_bM            = @(IBa_V) (0.75).*(.01*exp((-43-IBa_V)/18));
	IBa_iM_IM            = @(IBa_V,m) (1.5).*m.*(IBa_V-(-95));     
	IBs_IBa_iCOM_ICOM    = @(V1,V2) (0.3).*sum(((V1*ones(1,size(V1,1)))'-(V2*ones(1,size(V2,1)))).*IBs_IBa_iCOM_mask,2);
	IBs_itonic_Itonic    = @(t) (4.5)*(t>(0) & t<(Inf));           
	IBs_iNaF_hinf        = @(IBs_V) 1./(1+exp((IBs_V+(59.4))/(10.7)));
	IBs_iNaF_htau        = @(IBs_V) (0.15) + (1.15)./(1+exp((IBs_V+(33.5))/(15)));
	IBs_iNaF_m0          = @(IBs_V) 1./(1+exp((-IBs_V-(34.5))/10));
	IBs_iNaF_aH          = @(IBs_V) (1./(1+exp((IBs_V+(59.4))/(10.7)))) ./ ((0.15) + (1.15)./(1+exp((IBs_V+(33.5))/(15))));
	IBs_iNaF_bH          = @(IBs_V) (1-(1./(1+exp((IBs_V+(59.4))/(10.7)))))./((0.15) + (1.15)./(1+exp((IBs_V+(33.5))/(15))));
	IBs_iNaF_INaF        = @(IBs_V,h) (50).*(1./(1+exp((-IBs_V-(34.5))/10))).^3.*h.*(IBs_V-(50));
	IBs_iKDR_minf        = @(IBs_V) 1./(1+exp((-IBs_V-(29.5))/(10)));
	IBs_iKDR_mtau        = @(IBs_V) .25+4.35*exp(-abs(IBs_V+(10))/(10));
	IBs_iKDR_aM          = @(IBs_V) (1./(1+exp((-IBs_V-(29.5))/(10)))) ./ (.25+4.35*exp(-abs(IBs_V+(10))/(10)));
	IBs_iKDR_bM          = @(IBs_V) (1-(1./(1+exp((-IBs_V-(29.5))/(10)))))./(.25+4.35*exp(-abs(IBs_V+(10))/(10)));
	IBs_iKDR_IKDR        = @(IBs_V,m) (10).*m.^4.*(IBs_V-(-95));   
	IBa_IBs_iCOM_ICOM    = @(V1,V2) (0.3).*sum(((V1*ones(1,size(V1,1)))'-(V2*ones(1,size(V2,1)))).*IBa_IBs_iCOM_mask,2);
	IBda_IBs_iCOM_ICOM   = @(V1,V2) (0.4).*sum(((V1*ones(1,size(V1,1)))'-(V2*ones(1,size(V2,1)))).*IBda_IBs_iCOM_mask,2);
	IBdb_IBs_iCOM_ICOM   = @(V1,V2) (0.4).*sum(((V1*ones(1,size(V1,1)))'-(V2*ones(1,size(V2,1)))).*IBdb_IBs_iCOM_mask,2);
	IBda_itonic_Itonic   = @(t) (-23.5)*(t>(0) & t<(Inf));         
	IBda_iNaF_hinf       = @(IBda_V) 1./(1+exp((IBda_V+(59.4))/(10.7)));
	IBda_iNaF_htau       = @(IBda_V) (0.15) + (1.15)./(1+exp((IBda_V+(33.5))/(15)));
	IBda_iNaF_m0         = @(IBda_V) 1./(1+exp((-IBda_V-(34.5))/10));
	IBda_iNaF_aH         = @(IBda_V) (1./(1+exp((IBda_V+(59.4))/(10.7)))) ./ ((0.15) + (1.15)./(1+exp((IBda_V+(33.5))/(15))));
	IBda_iNaF_bH         = @(IBda_V) (1-(1./(1+exp((IBda_V+(59.4))/(10.7)))))./((0.15) + (1.15)./(1+exp((IBda_V+(33.5))/(15))));
	IBda_iNaF_INaF       = @(IBda_V,h) (125).*(1./(1+exp((-IBda_V-(34.5))/10))).^3.*h.*(IBda_V-(50));
	IBda_iKDR_minf       = @(IBda_V) 1./(1+exp((-IBda_V-(29.5))/(10)));
	IBda_iKDR_mtau       = @(IBda_V) .25+4.35*exp(-abs(IBda_V+(10))/(10));
	IBda_iKDR_aM         = @(IBda_V) (1./(1+exp((-IBda_V-(29.5))/(10)))) ./ (.25+4.35*exp(-abs(IBda_V+(10))/(10)));
	IBda_iKDR_bM         = @(IBda_V) (1-(1./(1+exp((-IBda_V-(29.5))/(10)))))./(.25+4.35*exp(-abs(IBda_V+(10))/(10)));
	IBda_iKDR_IKDR       = @(IBda_V,m) (10).*m.^4.*(IBda_V-(-95)); 
	IBda_iAR_minf        = @(IBda_V) 1 ./ (1+exp(((-87.5)-IBda_V)/(-5.5)));
	IBda_iAR_mtau        = @(IBda_V) 1./((1).*exp(-14.6-.086*IBda_V)+(1).*exp(-1.87+.07*IBda_V));
	IBda_iAR_aM          = @(IBda_V) (2.75).*((1 ./ (1+exp(((-87.5)-IBda_V)/(-5.5)))) ./ (1./((1).*exp(-14.6-.086*IBda_V)+(1).*exp(-1.87+.07*IBda_V))));
	IBda_iAR_bM          = @(IBda_V) (3).*((1-(1 ./ (1+exp(((-87.5)-IBda_V)/(-5.5)))))./(1./((1).*exp(-14.6-.086*IBda_V)+(1).*exp(-1.87+.07*IBda_V))));
	IBda_iAR_IAR         = @(IBda_V,m) (155).*m.*(IBda_V-(-25));   
	IBda_iM_aM           = @(IBda_V) (1).*(.02./(1+exp((-20-IBda_V)/5)));
	IBda_iM_bM           = @(IBda_V) (1).*(.01*exp((-43-IBda_V)/18));
	IBda_iM_IM           = @(IBda_V,m) (0.75).*m.*(IBda_V-(-95));  
	IBda_iCaH_aM         = @(IBda_V) (3).*(1.6./(1+exp(-.072*(IBda_V-5))));
	IBda_iCaH_bM         = @(IBda_V) (3).*(.02*(IBda_V+8.9)./(exp((IBda_V+8.9)/5)-1));
	IBda_iCaH_ICaH       = @(IBda_V,m) (6.5).*m.^2.*(-125+IBda_V); 
	IBs_IBda_iCOM_ICOM   = @(V1,V2) (0.4).*sum(((V1*ones(1,size(V1,1)))'-(V2*ones(1,size(V2,1)))).*IBs_IBda_iCOM_mask,2);
	IBdb_itonic_Itonic   = @(t) (-23.5)*(t>(0) & t<(Inf));         
	IBdb_iNaF_hinf       = @(IBdb_V) 1./(1+exp((IBdb_V+(59.4))/(10.7)));
	IBdb_iNaF_htau       = @(IBdb_V) (0.15) + (1.15)./(1+exp((IBdb_V+(33.5))/(15)));
	IBdb_iNaF_m0         = @(IBdb_V) 1./(1+exp((-IBdb_V-(34.5))/10));
	IBdb_iNaF_aH         = @(IBdb_V) (1./(1+exp((IBdb_V+(59.4))/(10.7)))) ./ ((0.15) + (1.15)./(1+exp((IBdb_V+(33.5))/(15))));
	IBdb_iNaF_bH         = @(IBdb_V) (1-(1./(1+exp((IBdb_V+(59.4))/(10.7)))))./((0.15) + (1.15)./(1+exp((IBdb_V+(33.5))/(15))));
	IBdb_iNaF_INaF       = @(IBdb_V,h) (125).*(1./(1+exp((-IBdb_V-(34.5))/10))).^3.*h.*(IBdb_V-(50));
	IBdb_iKDR_minf       = @(IBdb_V) 1./(1+exp((-IBdb_V-(29.5))/(10)));
	IBdb_iKDR_mtau       = @(IBdb_V) .25+4.35*exp(-abs(IBdb_V+(10))/(10));
	IBdb_iKDR_aM         = @(IBdb_V) (1./(1+exp((-IBdb_V-(29.5))/(10)))) ./ (.25+4.35*exp(-abs(IBdb_V+(10))/(10)));
	IBdb_iKDR_bM         = @(IBdb_V) (1-(1./(1+exp((-IBdb_V-(29.5))/(10)))))./(.25+4.35*exp(-abs(IBdb_V+(10))/(10)));
	IBdb_iKDR_IKDR       = @(IBdb_V,m) (10).*m.^4.*(IBdb_V-(-95)); 
	IBdb_iAR_minf        = @(IBdb_V) 1 ./ (1+exp(((-87.5)-IBdb_V)/(-5.5)));
	IBdb_iAR_mtau        = @(IBdb_V) 1./((1).*exp(-14.6-.086*IBdb_V)+(1).*exp(-1.87+.07*IBdb_V));
	IBdb_iAR_aM          = @(IBdb_V) (2.75).*((1 ./ (1+exp(((-87.5)-IBdb_V)/(-5.5)))) ./ (1./((1).*exp(-14.6-.086*IBdb_V)+(1).*exp(-1.87+.07*IBdb_V))));
	IBdb_iAR_bM          = @(IBdb_V) (3).*((1-(1 ./ (1+exp(((-87.5)-IBdb_V)/(-5.5)))))./(1./((1).*exp(-14.6-.086*IBdb_V)+(1).*exp(-1.87+.07*IBdb_V))));
	IBdb_iAR_IAR         = @(IBdb_V,m) (115).*m.*(IBdb_V-(-25));   
	IBdb_iM_aM           = @(IBdb_V) (1).*(.02./(1+exp((-20-IBdb_V)/5)));
	IBdb_iM_bM           = @(IBdb_V) (1).*(.01*exp((-43-IBdb_V)/18));
	IBdb_iM_IM           = @(IBdb_V,m) (0.75).*m.*(IBdb_V-(-95));  
	IBdb_iCaH_aM         = @(IBdb_V) (3).*(1.6./(1+exp(-.072*(IBdb_V-5))));
	IBdb_iCaH_bM         = @(IBdb_V) (3).*(.02*(IBdb_V+8.9)./(exp((IBdb_V+8.9)/5)-1));
	IBdb_iCaH_ICaH       = @(IBdb_V,m) (6.5).*m.^2.*(-125+IBdb_V); 
	IBs_IBdb_iCOM_ICOM   = @(V1,V2) (0.4).*sum(((V1*ones(1,size(V1,1)))'-(V2*ones(1,size(V2,1)))).*IBs_IBdb_iCOM_mask,2);

% ODE Handle, ICs, integration, and plotting:
ODEFUN = @(t,X) [(((((4)*(t>(0) & t<(Inf))))+(((0.5).*randn((2),1))+((-((100).*(1./(1+exp((-X(1:2)-(34.5))/10))).^3.*X(3:4).*(X(1:2)-(50))))+((-((5).*X(5:6).^4.*(X(1:2)-(-95))))+((-((1.5).*X(7:8).*(X(1:2)-(-95))))+((-((0.3).*sum(((X(1:2)*ones(1,size(X(1:2),1)))'-(X(9:10)*ones(1,size(X(9:10),1)))).*IBs_IBa_iCOM_mask,2)))+0)))))))/(0.9);((1./(1+exp((X(1:2)+(59.4))/(10.7)))) ./ ((0.15) + (1.15)./(1+exp((X(1:2)+(33.5))/(15))))).*(1-X(3:4))-((1-(1./(1+exp((X(1:2)+(59.4))/(10.7)))))./((0.15) + (1.15)./(1+exp((X(1:2)+(33.5))/(15))))).*X(3:4);((1./(1+exp((-X(1:2)-(29.5))/(10)))) ./ (.25+4.35*exp(-abs(X(1:2)+(10))/(10)))).*(1-X(5:6))-((1-(1./(1+exp((-X(1:2)-(29.5))/(10)))))./(.25+4.35*exp(-abs(X(1:2)+(10))/(10)))).*X(5:6);(((1.5).*(.02./(1+exp((-20-X(1:2))/5)))).*(1-X(7:8))-((0.75).*(.01*exp((-43-X(1:2))/18))).*X(7:8));(((((4.5)*(t>(0) & t<(Inf))))+(((0).*randn((2),1))+((-((50).*(1./(1+exp((-X(9:10)-(34.5))/10))).^3.*X(11:12).*(X(9:10)-(50))))+((-((10).*X(13:14).^4.*(X(9:10)-(-95))))+((-((0.3).*sum(((X(9:10)*ones(1,size(X(9:10),1)))'-(X(1:2)*ones(1,size(X(1:2),1)))).*IBa_IBs_iCOM_mask,2)))+((-((0.4).*sum(((X(9:10)*ones(1,size(X(9:10),1)))'-(X(15:16)*ones(1,size(X(15:16),1)))).*IBda_IBs_iCOM_mask,2)))+((-((0.4).*sum(((X(9:10)*ones(1,size(X(9:10),1)))'-(X(27:28)*ones(1,size(X(27:28),1)))).*IBdb_IBs_iCOM_mask,2)))+0))))))));((1./(1+exp((X(9:10)+(59.4))/(10.7)))) ./ ((0.15) + (1.15)./(1+exp((X(9:10)+(33.5))/(15))))).*(1-X(11:12))-((1-(1./(1+exp((X(9:10)+(59.4))/(10.7)))))./((0.15) + (1.15)./(1+exp((X(9:10)+(33.5))/(15))))).*X(11:12);((1./(1+exp((-X(9:10)-(29.5))/(10)))) ./ (.25+4.35*exp(-abs(X(9:10)+(10))/(10)))).*(1-X(13:14))-((1-(1./(1+exp((-X(9:10)-(29.5))/(10)))))./(.25+4.35*exp(-abs(X(9:10)+(10))/(10)))).*X(13:14);(((((-23.5)*(t>(0) & t<(Inf))))+(((1).*randn((2),1))+((-((125).*(1./(1+exp((-X(15:16)-(34.5))/10))).^3.*X(17:18).*(X(15:16)-(50))))+((-((10).*X(19:20).^4.*(X(15:16)-(-95))))+((-((155).*X(21:22).*(X(15:16)-(-25))))+((-((0.75).*X(23:24).*(X(15:16)-(-95))))+((-((6.5).*X(25:26).^2.*(-125+X(15:16))))+((-((0.4).*sum(((X(15:16)*ones(1,size(X(15:16),1)))'-(X(9:10)*ones(1,size(X(9:10),1)))).*IBs_IBda_iCOM_mask,2)))+0)))))))));((1./(1+exp((X(15:16)+(59.4))/(10.7)))) ./ ((0.15) + (1.15)./(1+exp((X(15:16)+(33.5))/(15))))).*(1-X(17:18))-((1-(1./(1+exp((X(15:16)+(59.4))/(10.7)))))./((0.15) + (1.15)./(1+exp((X(15:16)+(33.5))/(15))))).*X(17:18);((1./(1+exp((-X(15:16)-(29.5))/(10)))) ./ (.25+4.35*exp(-abs(X(15:16)+(10))/(10)))).*(1-X(19:20))-((1-(1./(1+exp((-X(15:16)-(29.5))/(10)))))./(.25+4.35*exp(-abs(X(15:16)+(10))/(10)))).*X(19:20);((2.75).*((1 ./ (1+exp(((-87.5)-X(15:16))/(-5.5)))) ./ (1./((1).*exp(-14.6-.086*X(15:16))+(1).*exp(-1.87+.07*X(15:16)))))).*(1-X(21:22))-((3).*((1-(1 ./ (1+exp(((-87.5)-X(15:16))/(-5.5)))))./(1./((1).*exp(-14.6-.086*X(15:16))+(1).*exp(-1.87+.07*X(15:16)))))).*X(21:22);(((1).*(.02./(1+exp((-20-X(15:16))/5)))).*(1-X(23:24))-((1).*(.01*exp((-43-X(15:16))/18))).*X(23:24));(((3).*(1.6./(1+exp(-.072*(X(15:16)-5))))).*(1-X(25:26))-((3).*(.02*(X(15:16)+8.9)./(exp((X(15:16)+8.9)/5)-1))).*X(25:26))/(0.333333);(((((-23.5)*(t>(0) & t<(Inf))))+(((1).*randn((2),1))+((-((125).*(1./(1+exp((-X(27:28)-(34.5))/10))).^3.*X(29:30).*(X(27:28)-(50))))+((-((10).*X(31:32).^4.*(X(27:28)-(-95))))+((-((115).*X(33:34).*(X(27:28)-(-25))))+((-((0.75).*X(35:36).*(X(27:28)-(-95))))+((-((6.5).*X(37:38).^2.*(-125+X(27:28))))+((-((0.4).*sum(((X(27:28)*ones(1,size(X(27:28),1)))'-(X(9:10)*ones(1,size(X(9:10),1)))).*IBs_IBdb_iCOM_mask,2)))+0)))))))));((1./(1+exp((X(27:28)+(59.4))/(10.7)))) ./ ((0.15) + (1.15)./(1+exp((X(27:28)+(33.5))/(15))))).*(1-X(29:30))-((1-(1./(1+exp((X(27:28)+(59.4))/(10.7)))))./((0.15) + (1.15)./(1+exp((X(27:28)+(33.5))/(15))))).*X(29:30);((1./(1+exp((-X(27:28)-(29.5))/(10)))) ./ (.25+4.35*exp(-abs(X(27:28)+(10))/(10)))).*(1-X(31:32))-((1-(1./(1+exp((-X(27:28)-(29.5))/(10)))))./(.25+4.35*exp(-abs(X(27:28)+(10))/(10)))).*X(31:32);((2.75).*((1 ./ (1+exp(((-87.5)-X(27:28))/(-5.5)))) ./ (1./((1).*exp(-14.6-.086*X(27:28))+(1).*exp(-1.87+.07*X(27:28)))))).*(1-X(33:34))-((3).*((1-(1 ./ (1+exp(((-87.5)-X(27:28))/(-5.5)))))./(1./((1).*exp(-14.6-.086*X(27:28))+(1).*exp(-1.87+.07*X(27:28)))))).*X(33:34);(((1).*(.02./(1+exp((-20-X(27:28))/5)))).*(1-X(35:36))-((1).*(.01*exp((-43-X(27:28))/18))).*X(35:36));(((3).*(1.6./(1+exp(-.072*(X(27:28)-5))))).*(1-X(37:38))-((3).*(.02*(X(27:28)+8.9)./(exp((X(27:28)+8.9)/5)-1))).*X(37:38))/(0.333333);];
IC = [0           0         0.5         0.5        0.34        0.34        0.05        0.05           0           0         0.5         0.5        0.34        0.34           0           0         0.5         0.5        0.34        0.34         0.3         0.3        0.05        0.05         0.2         0.2           0           0         0.5         0.5        0.34        0.34         0.3         0.3        0.05        0.05         0.2         0.2];

[t,y]=ode23(ODEFUN,[0 100],IC);   % numerical integration
figure; plot(t,y);           % plot all variables/functions
try legend('IBa\_V','IBa\_iNaF\_hNaF','IBa\_iKDR\_mKDR','IBa\_iM\_mM','IBs\_V','IBs\_iNaF\_hNaF','IBs\_iKDR\_mKDR','IBda\_V','IBda\_iNaF\_hNaF','IBda\_iKDR\_mKDR','IBda\_iAR\_mAR','IBda\_iM\_mM','IBda\_iCaH\_mCaH','IBdb\_V','IBdb\_iNaF\_hNaF','IBdb\_iKDR\_mKDR','IBdb\_iAR\_mAR','IBdb\_iM\_mM','IBdb\_iCaH\_mCaH'); end
%-
%}
