window_size = 30/1000;%50/1000;
dW = 5/1000;
[h,rates,tmins,spiketimes,spikeinds]=plotspk(sim_data,spec,'plot_flag',1,...
                               'window_size',window_size,'dW',dW); % firing rate(t) and FRH
pop=1;
x = sim_data(pop).epochs.data; % [ncells x nsteps]

