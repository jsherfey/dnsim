% Model: basket2
% cd /home/davestanley/Dropbox/git/dnsim/kramer/kramer/basket2;
spec=[];
spec.nodes(1).label = 'B';
spec.nodes(1).multiplicity = 2;
spec.nodes(1).dynamics = {'V''=(current)/Cm'};
spec.nodes(1).mechanisms = {'B_B_itonic','B_B_noise','B_B_iNaF','B_B_iKDR','B_B_leak'};
spec.nodes(1).parameters = {'V_IC',-65,'Cm',0.9};
spec.connections(1,1).label = 'B-B';
spec.connections(1,1).mechanisms = {'B_B_iSYNdualexp2'};
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
	B_B_iSYNdualexp2_width = inf;
	B_B_iSYNdualexp2_Nmax = max((2),(2));
	B_B_iSYNdualexp2_srcpos = linspace(1,B_B_iSYNdualexp2_Nmax,(2))'*ones(1,(2));
	B_B_iSYNdualexp2_dstpos = (linspace(1,B_B_iSYNdualexp2_Nmax,(2))'*ones(1,(2)))';
	B_B_iSYNdualexp2_netcon = (abs(B_B_iSYNdualexp2_srcpos-B_B_iSYNdualexp2_dstpos)<=B_B_iSYNdualexp2_width)';
	B_B_iSYNdualexp2_c   = (1/(((0.25)/(10))^((0.25)/((10)-(0.25)))-((0.25)/(10))^((10)/((10)-(0.25)))))/2;

% Anonymous functions:
	B_B_itonic_Itonic    = @(t) (2)*(t>(0) & t<B_B_itonic_offset); 
	B_B_iNaF_hinf        = @(B_V) 1./(1+exp((B_V+(58.3))/(6.7)));  
	B_B_iNaF_htau        = @(B_V) (0.15) + (1.15)./(1+exp((B_V+(37))/(15)));
	B_B_iNaF_m0          = @(B_V) 1./(1+exp((-B_V-(38))/10));      
	B_B_iNaF_aH          = @(B_V) B_B_iNaF_hinf(B_V) ./ B_B_iNaF_htau(B_V);
	B_B_iNaF_bH          = @(B_V) (1-B_B_iNaF_hinf(B_V))./B_B_iNaF_htau(B_V);
	B_B_iNaF_INaF        = @(B_V,h) (200).*B_B_iNaF_m0(B_V).^3.*h.*(B_V-(50));
	B_B_iKDR_minf        = @(B_V) 1./(1+exp((-B_V-(27))/(11.5)));  
	B_B_iKDR_mtau        = @(B_V) .25+4.35*exp(-abs(B_V+(10))/(10));
	B_B_iKDR_aM          = @(B_V) B_B_iKDR_minf(B_V) ./ B_B_iKDR_mtau(B_V);
	B_B_iKDR_bM          = @(B_V) (1-B_B_iKDR_minf(B_V))./B_B_iKDR_mtau(B_V);
	B_B_iKDR_IKDR        = @(B_V,m) (20).*m.^4.*(B_V-(-100));      
	B_B_leak_Ileak       = @(IN) (1).*(IN-(-65));                  
	B_B_iSYNdualexp2_f   = @(s) B_B_iSYNdualexp2_c*(exp(-((20)-s)/(10)) - exp(-((20)-s)/(0.25)));
	B_B_iSYNdualexp2_ISYN = @(B_V,B_B_iSYNdualexp2_s1,B_B_iSYNdualexp2_s2,B_B_iSYNdualexp2_s3) ((0).*(B_B_iSYNdualexp2_netcon*(B_B_iSYNdualexp2_f(B_B_iSYNdualexp2_s1) + B_B_iSYNdualexp2_f(B_B_iSYNdualexp2_s2) + B_B_iSYNdualexp2_f(B_B_iSYNdualexp2_s3))).*(B_V-(0)));

% ODE Handle, ICs, integration, and plotting:
ODEFUN = @(t,X) [(((-B_B_itonic_Itonic(t))+(((1).*randn((2),1))+((-B_B_iNaF_INaF(X(1:2),X(3:4)))+((-B_B_iKDR_IKDR(X(1:2),X(5:6)))+((-B_B_leak_Ileak(X(1:2)))+((-B_B_iSYNdualexp2_ISYN(X(1:2),X(7:8),X(11:12),X(15:16)))+0)))))))/(0.9);B_B_iNaF_aH(X(1:2)).*(1-X(3:4))-B_B_iNaF_bH(X(1:2)).*X(3:4);B_B_iKDR_aM(X(1:2)).*(1-X(5:6))-B_B_iKDR_bM(X(1:2)).*X(5:6);((20)*((20)-X(7:8))/(0.25)).*(1+tanh(X(1:2)/10)).*(X(9:10) < (1-(0.1)))/2 - 1*(X(7:8) > 0);(1-X(9:10))/(0.25).*(1+tanh((X(7:8)-(20)*(1-(0.1)))))/2 - 1/(0.25)*X(9:10).*(X(7:8) < (20)*(0.1));((20)*((20)-X(11:12))/(0.25)).*(1+tanh(X(1:2)/10)).*(X(13:14) < (1-(0.1)))/2.*(X(7:8) > (20)*(0.1)).*(X(9:10)>(1-(0.1))) - 1*(X(11:12) > 0);(1-X(13:14))/(0.25).*(1+tanh((X(11:12)-(20)*(1-(0.1)))))/2 - 1/(0.25)*X(13:14).*(X(11:12) < (20)*(0.1));((20)*((20)-X(15:16))/(0.25)).*(1+tanh(X(1:2)/10)).*(X(17:18) < (1-(0.1)))/2.*(X(11:12) > (20)*(0.1)).*(X(13:14)>(1-(0.1))) - 1*(X(15:16) > 0);(1-X(17:18))/(0.25).*(1+tanh((X(15:16)-(20)*(1-(0.1)))))/2 - 1/(0.25)*X(17:18).*(X(15:16) < (20)*(0.1));];
IC = [-65          -65   0.00480232    0.0070218   0.00241014   0.00749959            0            0            0            0            0            0            0            0            0            0            0            0];

[t,y]=ode23(ODEFUN,[0 100],IC);   % numerical integration
figure; plot(t,y);           % plot all variables/functions
try legend('B\_V','B\_B\_iNaF\_hNaF','B\_B\_iKDR\_mKDR','B\_B\_iSYNdualexp2\_s1','B\_B\_iSYNdualexp2\_t1','B\_B\_iSYNdualexp2\_s2','B\_B\_iSYNdualexp2\_t2','B\_B\_iSYNdualexp2\_s3','B\_B\_iSYNdualexp2\_t3'); end
%-
%}
