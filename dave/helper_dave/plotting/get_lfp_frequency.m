
%% Setup paths
addpath(genpath(fullfile('~','src','ds_kb','funcs_general')));
addpath(genpath(fullfile('~','src','chronux')));


%% Load data 

data_to_load = 3;
s1=load('~/Dropbox/git/dnsim/data_out/kramer_comparison/data_kramerfull/20150424/data/lfp/job0001_RS-multiplicity10_time0-440_sim_data_LFPs.mat');
s2=load('~/Dropbox/git/dnsim/data_out/kramer_comparison/data_kramerfull_onlyIB/20150424/data/lfp/job0001_IBda-multiplicity10_time0-440_sim_data_LFPs.mat');
s3=load('~/Dropbox/git/dnsim/data_out/kramer_comparison/data_kramer_IB/20150424/data/lfp/job0001_IBda-multiplicity10_time0-440_sim_data_LFPs.mat');
switch data_to_load
    case 1
        vars_pull(s1);
        chosen_channel = 7;
    case 2
        vars_pull(s2);
        chosen_channel = 4;
    case 3
        vars_pull(s3);
        chosen_channel = 4;
end


vars = {(spec.entities.label)};

t=time;
dt = mode(diff(t));
lfp = lfp';

%% Plot raw data

figure; plot(t,lfp);
legend(vars{:})

%% Plot lfp


figure; plott_psd(lfp(:,chosen_channel),'fs',1/dt,'logplot',1,'mode',2)


%% Plot cross correlation

x = zscore(lfp(:,chosen_channel));
[C,lags] = xcorr(x,'unbiased');

figure; plot(lags*dt,C)
xlim([-0.05 0.05]);


