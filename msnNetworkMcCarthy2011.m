%
% Striatal MSN network
% Based on Michelle's C++ code; adapted to DNSim by Jason and Salva
%

startup; % of dnsim
addpath(pwd);

% Parameters
ncells = 100;  % number of MSN cells in the pool
g_gaba = 0.1/(ncells-1); % recurrent gaba conductance, normalized to the number of cells
g_m = 1.2; % 1.2; % 1.3; % 1.2 parkinsonian, 1.3 normal
V_ic = -63; % -63+5*randn(1,ncells); % Initial conditions for the phases
tspan = [0 8]; % in s
interval = diff(tspan);
dt = 5e-5; % in s
factor_time_dnsim = 1e3; % dnsim works in ms
solver = 'rk4';
coder = 1; % whether to use matlab's codegen

% Generic Michelle's MSN model specification

MSNpop_spec = [];
MSNpop_spec.nodes(1).label = 'MSN';
MSNpop_spec.nodes(1).multiplicity = ncells;
MSNpop_spec.nodes(1).dynamics = {'V''=(current)./cm'};

MSNpop_spec.nodes(1).mechanisms = {'naCurrentMSN','kCurrentMSN','mCurrentMSN','leakCurrentMSN','injectedCurrentMSN','noisyInputMSN'};

MSNpop_spec.nodes(1).parameters = {'cm',1,'V_IC',V_ic,'g_m',g_m,'timelimits',tspan*factor_time_dnsim,'interval',interval*factor_time_dnsim,'dt',dt*factor_time_dnsim}; % V_IC refers to the initial condition for the membrane potential

MSNpop_spec.connections(1,1).label = [MSNpop_spec.nodes(1).label,'-',MSNpop_spec.nodes(1).label];
MSNpop_spec.connections(1,1).mechanisms = {'gabaRecInputMSN'};
MSNpop_spec.connections(1,1).parameters = {'g_gaba',g_gaba};

save('genericMSN.mat','MSNpop_spec');

% Simulating the model
dsfact = 2;
data = runsim(MSNpop_spec,'timelimits',tspan*factor_time_dnsim,'dt',dt*factor_time_dnsim,'SOLVER',solver,'dsfact',dsfact,'timesurfer_flag',0,'verbose',0,'coder',coder); % dsfact is for saving data in multiples of dt, here each 2dt; timesurfer_flag set to 0 for using new data format
