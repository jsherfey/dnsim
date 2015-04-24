% Model: test1
% cd /Users/davestanley/src/dnsim/test1;
clear
spec=[];
spec.nodes(1).label = 'B';
spec.nodes(1).multiplicity = 1;
spec.nodes(1).dynamics = {'V''=(current)/Cm'};
spec.nodes(1).mechanisms = {'B_B_itonic','B_B_noise','B_B_iNaF','B_B_iKDR','B_B_leak','B_iSYNdualexp_test1'};
% spec.nodes(1).mechanisms = {'B_B_itonic','B_B_noise','B_B_iNaF','B_B_iKDR','B_B_leak'};
spec.nodes(1).parameters = {'V_IC',-65,'Cm',0.9};
% dnsim(spec); % open model in DNSim GUI


% DNSim simulation and plots:
data = runsim(spec,'timelimits',[0 10],'dt',.01,'SOLVER','euler'); % simulate DNSim models
plotv(data,spec,'varlabel','V'); % quickly plot select variables
%visualizer(data); % ugly interactive tool hijacked to visualize sim_data