function psps = repeated_Poisson(no_cells, inputs_per_cell, rate, tau_i, tau_1, tau_d, tau_r, T, dt)

t = 0:dt:T;

% EPSP for spikes at time t = 0.
psp = tau_i*(exp(-max(t - tau_1,0)/tau_d) - exp(-max(t - tau_1,0)/tau_r))/(tau_d - tau_r);
psp = psp(psp > eps);    %?
psp = [zeros(1,length(psp)) psp]; %?

no_inputs = inputs_per_cell;

C = ones(no_cells, inputs_per_cell);
    
spikes = rand(no_inputs, ceil(T/dt));
spikes = spikes < rate*dt/1000;

spike_arrivals = C*spikes; % Calculating presynaptic spikes for each cell.

psps = nan(size(spike_arrivals)); % Calculating EPSP experienced by each cell.
for c = 1:no_cells
    psps(c,:) = conv(spike_arrivals(c,:),psp,'same');
end