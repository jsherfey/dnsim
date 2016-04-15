% Model: ib_connected_script
% cd /home/davestanley/Dropbox/git/dnsim/dave/IB_reconstructed/ib_connected_script;
spec=[];
spec.nodes(1).label = 'IBa';
spec.nodes(1).multiplicity = 5;
spec.nodes(1).dynamics = {'V''=(current)/Cm'};
spec.nodes(1).mechanisms = {'IBa_itonic','IBa_noise','IBa_iNaF','IBa_iKDR','IBa_iM'};
spec.nodes(1).parameters = {'hNaF_IC',0.5,'mKDR_IC',0.34,'mM_IC',0.05,'mCaH_IC',0.2,'stim',4,'V_noise',0.5,'IC_noise',0.01,'E_l',-70,'g_l',0.25,'Cm',0.9,'gKDR',5,'KDR_V1',29.5,'KDR_d1',10,'KDR_v2',10,'KDR_d2',10,'E_KDR',-95,'gNaF',100,'NaF_V0',34.5,'NaF_V1',59.4,'NaF_d1',10.7,'NaF_V2',33.5,'NaF_d2',15,'E_NaF',50,'c_MaM',1.5,'c_MbM',0.75,'gM',1.5,'E_M',-95};
spec.nodes(2).label = 'IBs';
spec.nodes(2).multiplicity = 5;
spec.nodes(2).dynamics = {'V''=(current)'};
spec.nodes(2).mechanisms = {'IBs_itonic','IBs_noise','IBs_iNaF','IBs_iKDR'};
spec.nodes(2).parameters = {'hNaF_IC',0.5,'mKDR_IC',0.34,'mAR_IC',0.3,'mM_IC',0.05,'mCaH_IC',0.2,'stim',4.5,'V_noise',0,'IC_noise',0.01,'E_l',-70,'g_l',1,'Cm',0.9,'gKDR',10,'KDR_V1',29.5,'KDR_d1',10,'KDR_v2',10,'KDR_d2',10,'E_KDR',-95,'gNaF',50,'NaF_V0',34.5,'NaF_V1',59.4,'NaF_d1',10.7,'NaF_V2',33.5,'NaF_d2',15,'E_NaF',50};
spec.nodes(3).label = 'IBda';
spec.nodes(3).multiplicity = 5;
spec.nodes(3).dynamics = {'V''=(current)'};
spec.nodes(3).mechanisms = {'IBda_itonic','IBda_noise','IBda_iNaF','IBda_iKDR','IBda_iAR','IBda_iM','IBda_iCaH'};
spec.nodes(3).parameters = {'hNaF_IC',0.5,'mKDR_IC',0.34,'mAR_IC',0.3,'mM_IC',0.05,'mCaH_IC',0.2,'stim',-23.5,'V_noise',1,'IC_noise',0.01,'E_l',-70,'g_l',2,'Cm',0.9,'gKDR',10,'KDR_V1',29.5,'KDR_d1',10,'KDR_v2',10,'KDR_d2',10,'E_KDR',-95,'gNaF',125,'NaF_V0',34.5,'NaF_V1',59.4,'NaF_d1',10.7,'NaF_V2',33.5,'NaF_d2',15,'E_NaF',50,'AR_V0',75,'E_AR',-25,'gAR',155,'c_ARaM',2.75,'c_ARbM',3,'c_CaHaM',3,'c_CaHbM',3,'gCaH',6.5,'c_MaM',1,'c_MbM',1,'gM',0.75,'E_M',-95};
spec.nodes(4).label = 'IBdb';
spec.nodes(4).multiplicity = 5;
spec.nodes(4).dynamics = {'V''=(current)'};
spec.nodes(4).mechanisms = {'IBdb_itonic','IBdb_noise','IBdb_iNaF','IBdb_iKDR','IBdb_iAR','IBdb_iM','IBdb_iCaH'};
spec.nodes(4).parameters = {'hNaF_IC',0.5,'mKDR_IC',0.34,'mAR_IC',0.3,'mM_IC',0.05,'mCaH_IC',0.2,'stim',-23.5,'V_noise',1,'IC_noise',0.01,'E_l',-70,'g_l',2,'Cm',0.9,'gKDR',10,'KDR_V1',29.5,'KDR_d1',10,'KDR_v2',10,'KDR_d2',10,'E_KDR',-95,'gNaF',125,'NaF_V0',34.5,'NaF_V1',59.4,'NaF_d1',10.7,'NaF_V2',33.5,'NaF_d2',15,'E_NaF',50,'AR_V0',75,'E_AR',-25,'gAR',115,'c_ARaM',2.75,'c_ARbM',3,'c_CaHaM',3,'c_CaHbM',3,'gCaH',6.5,'c_MaM',1,'c_MbM',1,'gM',0.75,'E_M',-95};
spec.connections(1,1).label = 'IBa-IBa';
spec.connections(1,1).mechanisms = {'IBa_IBa_iSYNdiv'};
spec.connections(1,1).parameters = [];
spec.connections(1,2).label = 'IBa-IBs';
spec.connections(1,2).mechanisms = {'IBa_IBs_iGAP'};
spec.connections(1,2).parameters = [];
spec.connections(2,1).label = 'IBs-IBa';
spec.connections(2,1).mechanisms = {'IBs_IBa_iGAP'};
spec.connections(2,1).parameters = [];
spec.connections(2,2).label = 'IBs-IBs';
spec.connections(2,2).mechanisms = {'IBs_IBs_iSYNconv'};
spec.connections(2,2).parameters = [];
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
	IBa_IBa_iSYNdiv_Xpre = sorti(randn((5),(5)),2);
	IBa_IBa_iSYNdiv_mask = IBa_IBa_iSYNdiv_Xpre <= (2);
	IBs_IBa_iGAP_UB      = max((5),(5));
	IBs_IBa_iGAP_Xpre    = linspace(1,IBs_IBa_iGAP_UB,(5))'*ones(1,(5));
	IBs_IBa_iGAP_Xpost   = (linspace(1,IBs_IBa_iGAP_UB,(5))'*ones(1,(5)))';
	IBs_IBa_iGAP_mask    = abs(IBs_IBa_iGAP_Xpre-IBs_IBa_iGAP_Xpost)<=(Inf);
	IBa_IBs_iGAP_UB      = max((5),(5));
	IBa_IBs_iGAP_Xpre    = linspace(1,IBa_IBs_iGAP_UB,(5))'*ones(1,(5));
	IBa_IBs_iGAP_Xpost   = (linspace(1,IBa_IBs_iGAP_UB,(5))'*ones(1,(5)))';
	IBa_IBs_iGAP_mask    = abs(IBa_IBs_iGAP_Xpre-IBa_IBs_iGAP_Xpost)<=(1);
	IBs_IBs_iSYNconv_Xpre = sorti(randn((5),(5)),1);
	IBs_IBs_iSYNconv_mask = IBs_IBs_iSYNconv_Xpre <= (2);

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
	IBa_IBa_iSYNdiv_ISYNdiv = @(IBa_V,s) ((0.5).*(s'*IBa_IBa_iSYNdiv_mask)'.*(IBa_V-(-80)));
	IBs_IBa_iGAP_IGAP    = @(V1,V2) (0.2).*sum(((V1*ones(1,size(V1,1)))'-(V2*ones(1,size(V2,1)))).*IBs_IBa_iGAP_mask,2);
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
	IBa_IBs_iGAP_IGAP    = @(V1,V2) (0.2).*sum(((V1*ones(1,size(V1,1)))'-(V2*ones(1,size(V2,1)))).*IBa_IBs_iGAP_mask,2);
	IBs_IBs_iSYNconv_ISYNconv = @(IBs_V,s) ((0.5).*(s'*IBs_IBs_iSYNconv_mask)'.*(IBs_V-(-80)));
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

% ODE Handle, ICs, integration, and plotting:
ODEFUN = @(t,X) [(((((4)*(t>(0) & t<(Inf))))+(((0.5).*randn((5),1))+((-((100).*(1./(1+exp((-X(1:5)-(34.5))/10))).^3.*X(6:10).*(X(1:5)-(50))))+((-((5).*X(11:15).^4.*(X(1:5)-(-95))))+((-((1.5).*X(16:20).*(X(1:5)-(-95))))+((-(((0.5).*(X(21:25)'*IBa_IBa_iSYNdiv_mask)'.*(X(1:5)-(-80)))))+((((0.2).*sum(((X(26:30)*ones(1,size(X(26:30),1)))'-(X(1:5)*ones(1,size(X(1:5),1)))).*IBs_IBa_iGAP_mask,2)))+0))))))))/(0.9);((1./(1+exp((X(1:5)+(59.4))/(10.7)))) ./ ((0.15) + (1.15)./(1+exp((X(1:5)+(33.5))/(15))))).*(1-X(6:10))-((1-(1./(1+exp((X(1:5)+(59.4))/(10.7)))))./((0.15) + (1.15)./(1+exp((X(1:5)+(33.5))/(15))))).*X(6:10);((1./(1+exp((-X(1:5)-(29.5))/(10)))) ./ (.25+4.35*exp(-abs(X(1:5)+(10))/(10)))).*(1-X(11:15))-((1-(1./(1+exp((-X(1:5)-(29.5))/(10)))))./(.25+4.35*exp(-abs(X(1:5)+(10))/(10)))).*X(11:15);(((1.5).*(.02./(1+exp((-20-X(1:5))/5)))).*(1-X(16:20))-((0.75).*(.01*exp((-43-X(1:5))/18))).*X(16:20));-X(21:25)./(1) + ((1-X(21:25))/(0.25)).*(1+tanh(X(1:5)/10));(((((4.5)*(t>(0) & t<(Inf))))+(((0).*randn((5),1))+((-((50).*(1./(1+exp((-X(26:30)-(34.5))/10))).^3.*X(31:35).*(X(26:30)-(50))))+((-((10).*X(36:40).^4.*(X(26:30)-(-95))))+((((0.2).*sum(((X(1:5)*ones(1,size(X(1:5),1)))'-(X(26:30)*ones(1,size(X(26:30),1)))).*IBa_IBs_iGAP_mask,2)))+((-(((0.5).*(X(41:45)'*IBs_IBs_iSYNconv_mask)'.*(X(26:30)-(-80)))))+0)))))));((1./(1+exp((X(26:30)+(59.4))/(10.7)))) ./ ((0.15) + (1.15)./(1+exp((X(26:30)+(33.5))/(15))))).*(1-X(31:35))-((1-(1./(1+exp((X(26:30)+(59.4))/(10.7)))))./((0.15) + (1.15)./(1+exp((X(26:30)+(33.5))/(15))))).*X(31:35);((1./(1+exp((-X(26:30)-(29.5))/(10)))) ./ (.25+4.35*exp(-abs(X(26:30)+(10))/(10)))).*(1-X(36:40))-((1-(1./(1+exp((-X(26:30)-(29.5))/(10)))))./(.25+4.35*exp(-abs(X(26:30)+(10))/(10)))).*X(36:40);-X(41:45)./(1) + ((1-X(41:45))/(0.25)).*(1+tanh(X(26:30)/10));(((((-23.5)*(t>(0) & t<(Inf))))+(((1).*randn((5),1))+((-((125).*(1./(1+exp((-X(46:50)-(34.5))/10))).^3.*X(51:55).*(X(46:50)-(50))))+((-((10).*X(56:60).^4.*(X(46:50)-(-95))))+((-((155).*X(61:65).*(X(46:50)-(-25))))+((-((0.75).*X(66:70).*(X(46:50)-(-95))))+((-((6.5).*X(71:75).^2.*(-125+X(46:50))))+0))))))));((1./(1+exp((X(46:50)+(59.4))/(10.7)))) ./ ((0.15) + (1.15)./(1+exp((X(46:50)+(33.5))/(15))))).*(1-X(51:55))-((1-(1./(1+exp((X(46:50)+(59.4))/(10.7)))))./((0.15) + (1.15)./(1+exp((X(46:50)+(33.5))/(15))))).*X(51:55);((1./(1+exp((-X(46:50)-(29.5))/(10)))) ./ (.25+4.35*exp(-abs(X(46:50)+(10))/(10)))).*(1-X(56:60))-((1-(1./(1+exp((-X(46:50)-(29.5))/(10)))))./(.25+4.35*exp(-abs(X(46:50)+(10))/(10)))).*X(56:60);((2.75).*((1 ./ (1+exp(((-87.5)-X(46:50))/(-5.5)))) ./ (1./((1).*exp(-14.6-.086*X(46:50))+(1).*exp(-1.87+.07*X(46:50)))))).*(1-X(61:65))-((3).*((1-(1 ./ (1+exp(((-87.5)-X(46:50))/(-5.5)))))./(1./((1).*exp(-14.6-.086*X(46:50))+(1).*exp(-1.87+.07*X(46:50)))))).*X(61:65);(((1).*(.02./(1+exp((-20-X(46:50))/5)))).*(1-X(66:70))-((1).*(.01*exp((-43-X(46:50))/18))).*X(66:70));(((3).*(1.6./(1+exp(-.072*(X(46:50)-5))))).*(1-X(71:75))-((3).*(.02*(X(46:50)+8.9)./(exp((X(46:50)+8.9)/5)-1))).*X(71:75))/(0.333333);(((((-23.5)*(t>(0) & t<(Inf))))+(((1).*randn((5),1))+((-((125).*(1./(1+exp((-X(76:80)-(34.5))/10))).^3.*X(81:85).*(X(76:80)-(50))))+((-((10).*X(86:90).^4.*(X(76:80)-(-95))))+((-((115).*X(91:95).*(X(76:80)-(-25))))+((-((0.75).*X(96:100).*(X(76:80)-(-95))))+((-((6.5).*X(101:105).^2.*(-125+X(76:80))))+0))))))));((1./(1+exp((X(76:80)+(59.4))/(10.7)))) ./ ((0.15) + (1.15)./(1+exp((X(76:80)+(33.5))/(15))))).*(1-X(81:85))-((1-(1./(1+exp((X(76:80)+(59.4))/(10.7)))))./((0.15) + (1.15)./(1+exp((X(76:80)+(33.5))/(15))))).*X(81:85);((1./(1+exp((-X(76:80)-(29.5))/(10)))) ./ (.25+4.35*exp(-abs(X(76:80)+(10))/(10)))).*(1-X(86:90))-((1-(1./(1+exp((-X(76:80)-(29.5))/(10)))))./(.25+4.35*exp(-abs(X(76:80)+(10))/(10)))).*X(86:90);((2.75).*((1 ./ (1+exp(((-87.5)-X(76:80))/(-5.5)))) ./ (1./((1).*exp(-14.6-.086*X(76:80))+(1).*exp(-1.87+.07*X(76:80)))))).*(1-X(91:95))-((3).*((1-(1 ./ (1+exp(((-87.5)-X(76:80))/(-5.5)))))./(1./((1).*exp(-14.6-.086*X(76:80))+(1).*exp(-1.87+.07*X(76:80)))))).*X(91:95);(((1).*(.02./(1+exp((-20-X(76:80))/5)))).*(1-X(96:100))-((1).*(.01*exp((-43-X(76:80))/18))).*X(96:100));(((3).*(1.6./(1+exp(-.072*(X(76:80)-5))))).*(1-X(101:105))-((3).*(.02*(X(76:80)+8.9)./(exp((X(76:80)+8.9)/5)-1))).*X(101:105))/(0.333333);];
IC = [0           0           0           0           0         0.5         0.5         0.5         0.5         0.5        0.34        0.34        0.34        0.34        0.34        0.05        0.05        0.05        0.05        0.05         0.1         0.1         0.1         0.1         0.1           0           0           0           0           0         0.5         0.5         0.5         0.5         0.5        0.34        0.34        0.34        0.34        0.34         0.1         0.1         0.1         0.1         0.1           0           0           0           0           0         0.5         0.5         0.5         0.5         0.5        0.34        0.34        0.34        0.34        0.34         0.3         0.3         0.3         0.3         0.3        0.05        0.05        0.05        0.05        0.05         0.2         0.2         0.2         0.2         0.2           0           0           0           0           0         0.5         0.5         0.5         0.5         0.5        0.34        0.34        0.34        0.34        0.34         0.3         0.3         0.3         0.3         0.3        0.05        0.05        0.05        0.05        0.05         0.2         0.2         0.2         0.2         0.2];

[t,y]=ode23(ODEFUN,[0 100],IC);   % numerical integration
figure; plot(t,y);           % plot all variables/functions
try legend('IBa\_V','IBa\_iNaF\_hNaF','IBa\_iKDR\_mKDR','IBa\_iM\_mM','IBa\_IBa\_iSYNdiv\_sSYNpre','IBs\_V','IBs\_iNaF\_hNaF','IBs\_iKDR\_mKDR','IBs\_IBs\_iSYNconv\_sSYNpre','IBda\_V','IBda\_iNaF\_hNaF','IBda\_iKDR\_mKDR','IBda\_iAR\_mAR','IBda\_iM\_mM','IBda\_iCaH\_mCaH','IBdb\_V','IBdb\_iNaF\_hNaF','IBdb\_iKDR\_mKDR','IBdb\_iAR\_mAR','IBdb\_iM\_mM','IBdb\_iCaH\_mCaH'); end
%-
%}
