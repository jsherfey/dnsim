time=sim_data.epochs.time;
data=sim_data.epochs.data;
labels={sim_data.sensor_info.label};

figure; plot(time,data);
figure; plot(time,data(1:100,:));
figure; imagesc(data(1:100,:)); colormap gray; colorbar

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% load simulated data
% load(datafile,'sim_data');

% extract and prepare temporary data 
var1='MSN_V';
var2='GPe_V'; % 'GPe_GPeIa_h'

ind1=find(strcmp(var1,{sim_data(1).sensor_info.label}));
ind2=find(strcmp(var2,{sim_data(2).sensor_info.label}));
lfp1=squeeze(sum(sim_data(1).epochs.data(ind1,:,:),3));
lfp2=squeeze(sum(sim_data(1).epochs.data(ind1,:,:),3));
data=[lfp1' lfp2'];
tempfile='data.mat';
save(tempfile,'data');

% Analaysis
MM_epochs({tempfile},20,1,[],7);
run_GC_MM({tempfile},200,1,[],5);
MM_phase_by_freq({tempfile},{'Motor Ctx.','Striatum'},200,24,6:4:34);

