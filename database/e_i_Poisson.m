function current = e_i_Poisson(no_cells, e_inputs_per_cell, i_inputs_per_cell, e_rate, i_rate)

% EPSP for spikes at time t = 0.
epsp = tau_i*(exp(-max(t - tau_e1,0)/tau_ed) - exp(-max(t - tau_e1,0)/tau_er))/(tau_ed - tau_er);
epsp = epsp(epsp > eps);    %?
epsp = [zeros(1,length(epsp)) epsp]; %?

% IPSP for spikes at time t = 0.
ipsp = tau_i*(exp(-max(t - tau_i1,0)/tau_id) - exp(-max(t - tau_i1,0)/tau_ir))/(tau_id - tau_ir);
ipsp = ipsp(ipsp > eps);
ipsp = [zeros(1,length(ipsp)) ipsp];

no_e_inputs = e_inputs_per_cell*no_cells;
e_size = 0.0053; %changes magnitude of input. 0.0053 gets you between 5 and 2 Hz firing rate.
%you stop getting firing rate decreases as conductance increases for 10 cells around 0.015. 
%at around 0.5 you can get increased spike pairs with increased conductance
%in 10 cell networks, but firing rate is deeply weird.

no_i_inputs = i_inputs_per_cell*no_cells;
i_size = 0.0053;

CE_e = repmat(eye(no_cells), 1, no_e_inputs/no_cells);
CE_i = repmat(eye(no_cells), 1, no_i_inputs/no_cells);

e_spikes = rand(no_e_inputs, length(t));
e_spikes = e_spikes < e_rate*dt/1000;

e_spike_arrivals = CE_e*e_spikes; % Calculating presynaptic spikes for each cell.

epsps = nan(size(e_spike_arrivals)); % Calculating EPSP experienced by each cell.
for c = 1:no_cells
    epsps(c,:) = e_size*conv(e_spike_arrivals(c,:),epsp,'same');
end

i_spikes = rand(no_i_inputs,length(t));
i_spikes = i_spikes < i_rate*dt/1000;

i_spike_arrivals = CE_i*i_spikes; % Calculating presynaptic spikes for each cell.

ipsps = nan(size(i_spike_arrivals)); % Calculating IPSP experienced by each cell.

for c = 1:no_cells
    ipsps(c,:) = i_size*conv(i_spike_arrivals(c,:),ipsp,'same');
end

current = epsps - ipsps;