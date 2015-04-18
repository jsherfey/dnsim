% Model: basket_only
%cd /home/davestanley/src/dnsim/dave/basket_only;
spec=[];
spec.nodes(1).label = 'B';
spec.nodes(1).multiplicity = 10;
spec.nodes(1).dynamics = {'V''=(current)/Cm'};
spec.nodes(1).mechanisms = {'B_B_itonic','B_B_noise','B_B_iNaF','B_B_iKDR','B_B_leak'};
spec.nodes(1).parameters = {'V_IC',-65,'Cm',0.9};
spec.connections(1,1).label = 'B-B';
spec.connections(1,1).mechanisms = {'B_B_B_B_iSYN'};
spec.connections(1,1).parameters = {'fanout',Inf};
%dnsim(spec); % open model in DNSim GUI

% DNSim simulation and plots:
data = runsim(spec,'timelimits',[0 100],'dt',.02,'SOLVER','euler'); % simulate DNSim models
plotv(data,spec,'varlabel','V'); % quickly plot select variables
%visualizer(data); % ugly interactive tool hijacked to visualize sim_data

% Sweep over parameter values:
model=buildmodel(spec); % parse DNSim spec structure
simstudy(model,{'B'},{'N'},{'[1 2]'},'timelimits',[0 100],'dt',.02,'SOLVER','euler'); % N = # of cells


% Manual simulation and plots:
%{
%-----------------------------------------------------------
% Auxiliary variables:
	B_B_itonic_offset    = inf;
	B_B_B_B_iSYN_fanout  = inf;
	B_B_B_B_iSYN_UB      = max((10),(10));
	B_B_B_B_iSYN_Xpre    = linspace(1,B_B_B_B_iSYN_UB,(10))'*ones(1,(10));
	B_B_B_B_iSYN_Xpost   = (linspace(1,B_B_B_B_iSYN_UB,(10))'*ones(1,(10)))';
	B_B_B_B_iSYN_mask    = abs(B_B_B_B_iSYN_Xpre-B_B_B_B_iSYN_Xpost)<=(Inf);

% Anonymous functions:
	B_B_itonic_Itonic    = @(t) (16)*(t>(0) & t<B_B_itonic_offset);
	B_B_iNaF_hinf        = @(B_V) 1./(1+exp((B_V+(58.3))/(6.7)));  
	B_B_iNaF_htau        = @(B_V) (0.15) + (1.15)./(1+exp((B_V+(37))/(15)));
	B_B_iNaF_m0          = @(B_V) 1./(1+exp((-B_V-(38))/10));      
	B_B_iNaF_aH          = @(B_V) (1./(1+exp((B_V+(58.3))/(6.7)))) ./ ((0.15) + (1.15)./(1+exp((B_V+(37))/(15))));
	B_B_iNaF_bH          = @(B_V) (1-(1./(1+exp((B_V+(58.3))/(6.7)))))./((0.15) + (1.15)./(1+exp((B_V+(37))/(15))));
	B_B_iNaF_INaF        = @(B_V,h) (200).*(1./(1+exp((-B_V-(38))/10))).^3.*h.*(B_V-(50));
	B_B_iKDR_minf        = @(B_V) 1./(1+exp((-B_V-(27))/(11.5)));  
	B_B_iKDR_mtau        = @(B_V) .25+4.35*exp(-abs(B_V+(10))/(10));
	B_B_iKDR_aM          = @(B_V) (1./(1+exp((-B_V-(27))/(11.5)))) ./ (.25+4.35*exp(-abs(B_V+(10))/(10)));
	B_B_iKDR_bM          = @(B_V) (1-(1./(1+exp((-B_V-(27))/(11.5)))))./(.25+4.35*exp(-abs(B_V+(10))/(10)));
	B_B_iKDR_IKDR        = @(B_V,m) (20).*m.^4.*(B_V-(-100));      
	B_B_leak_Ileak       = @(IN) (1).*(IN-(-65));                  
	B_B_B_B_iSYN_ISYN    = @(B_V,s) ((20).*(s'*B_B_B_B_iSYN_mask)'.*(B_V-(-75)));

% ODE Handle, ICs, integration, and plotting:
ODEFUN = @(t,X) [(((-((16)*(t>(0) & t<B_B_itonic_offset)))+(((1).*randn((10),1))+((-((200).*(1./(1+exp((-X(1:10)-(38))/10))).^3.*X(11:20).*(X(1:10)-(50))))+((-((20).*X(21:30).^4.*(X(1:10)-(-100))))+((-((1).*(X(1:10)-(-65))))+((-(((20).*(X(31:40)'*B_B_B_B_iSYN_mask)'.*(X(1:10)-(-75)))))+0)))))))/(0.9);((1./(1+exp((X(1:10)+(58.3))/(6.7)))) ./ ((0.15) + (1.15)./(1+exp((X(1:10)+(37))/(15))))).*(1-X(11:20))-((1-(1./(1+exp((X(1:10)+(58.3))/(6.7)))))./((0.15) + (1.15)./(1+exp((X(1:10)+(37))/(15))))).*X(11:20);((1./(1+exp((-X(1:10)-(27))/(11.5)))) ./ (.25+4.35*exp(-abs(X(1:10)+(10))/(10)))).*(1-X(21:30))-((1-(1./(1+exp((-X(1:10)-(27))/(11.5)))))./(.25+4.35*exp(-abs(X(1:10)+(10))/(10)))).*X(21:30);-X(31:40)./(5) + ((1-X(31:40))/(0.5)).*(1+tanh(X(1:10)/10));];
IC = [-65          -65          -65          -65          -65          -65          -65          -65          -65          -65   0.00880223   0.00660965   0.00222057   0.00481427   0.00631839   0.00594352   0.00212356   0.00462782   0.00561668   0.00874208   0.00647189   0.00770608   0.00628079   0.00403987  0.000535433   0.00659718    0.0056934   0.00784178   0.00282743   0.00107971          0.1          0.1          0.1          0.1          0.1          0.1          0.1          0.1          0.1          0.1];

[t,y]=ode23(ODEFUN,[0 100],IC);   % numerical integration
figure; plot(t,y);           % plot all variables/functions
try legend('B\_V','B\_B\_iNaF\_hNaF','B\_B\_iKDR\_mKDR','B\_B\_B\_B\_iSYN\_sSYNpre'); end
%-
%}
