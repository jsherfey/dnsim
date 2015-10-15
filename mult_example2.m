    %% Demo: DNSim batch simulations
% Purpose: demonstrate how to run simulation batches varying model parameters
% on local machine or cluster with or without codegen.
% Created by Jason Sherfey (27-Mar-2015)
% -------------------------------------------------------------------------
% model specification
spec=[];
spec.nodes(1).label = 'HH';                       % name of this node population
spec.nodes(1).multiplicity = 2;                   % size of this node population
spec.nodes(1).dynamics = {'V''=current/c'};       % node dynamics for state variables that can be "seen" by other nodes
spec.nodes(1).mechanisms = {'iNa','iK','itonic'}; % note: corresponding mechanism files (e.g., iNa.txt) should exist in matlab path
spec.nodes(1).parameters = {'stim',7,'c',1};      % user-specified parameter values (note: these override default values set in mechanism files)

% simulation controls
tspan=[0 3000];     % [beg end], ms, simulation time limits
SOLVER='euler';     % numerical integration method
dt=.01;             % integration time step [ms]
dsfact=10;          % downsample factor (applied to simulated data)
codepath='~/x010-dnsim/dnsim'; % path to dnsim toolbox
% codepath='~/dnsim'; % path to dnsim toolbox

% %% SINGLE SIMULATION
% % local simulation with codegen
% data = runsim(spec,'timelimits',tspan,'dt',dt,'SOLVER',SOLVER,'dsfact',dsfact,...
%   'coder',1,'verbose',0);
% plotv(data,spec,'varlabel','V');

%% SIMULATION BATCHES

% output controls
rootdir = pwd;     % where to save outputs
% rootdir = '/projectnb/crc-nak/asoplata/dnsim_data/p1d1q26c3_hh_test_single_cell_derp';
savedata_flag = 0; % 0 or 1, whether to save the simulated data (after downsampling)
saveplot_flag = 1; % 0 or 1, whether to save plots
plotvars_flag = 1; % 0 or 1, whether to plot state variables

% what to vary across batch
scope = 'HH';       % node or connection label whose parameter you want to vary
variable = 'c';     % parameter to vary (e.g., capacitance)
values = '[1]'; % values for each simulation in batch (varied across batches)

%{
  Prerequisites for submitting jobs to cluster:
  1. add path-to-dnsim/csh to your environment.
     e.g., add to .bashrc: "export PATH=$PATH:$HOME/dnsim/csh"
  2. run matlab on cluster node that recognizes the command 'qsub'
%}

% % -------------------------------------------------------------------------
% % LOCAL BATCHES (run serial jobs on current machine)
% cluster_flag=0; % 0 or 1, whether to submit jobs to a cluster (requires: running on a cluster node that recognizes the command 'qsub')
% 
% % without codegen
% values = '[1 1.5]';
% [~,~,outdir]=simstudy(spec,{scope},{variable},{values},...
%   'dt',dt,'SOLVER',SOLVER,'rootdir',rootdir,'timelimits',tspan,'dsfact',dsfact,...
%   'savedata_flag',savedata_flag,'saveplot_flag',saveplot_flag,'plotvars_flag',plotvars_flag,'addpath',codepath,...
%   'cluster_flag',cluster_flag,'coder',0);
% 
% % with codegen
% values = '[2 2.5]';
% [~,~,outdir]=simstudy(spec,{scope},{variable},{values},...
%   'dt',dt,'SOLVER',SOLVER,'rootdir',rootdir,'timelimits',tspan,'dsfact',dsfact,...
%   'savedata_flag',savedata_flag,'saveplot_flag',saveplot_flag,'plotvars_flag',plotvars_flag,'addpath',codepath,...
%   'cluster_flag',cluster_flag,'coder',1);

% -------------------------------------------------------------------------
% CLUSTER BATCHES (submit to queue for running parallel jobs on cluster nodes)
cluster_flag=1; % 0 or 1, whether to submit jobs to a cluster (requires: running on a cluster node that recognizes the command 'qsub')

% without codegen
% values = '[3 3.5]';
[~,~,outdir]=simstudy(spec,{scope},{variable},{values},...
  'dt',dt,'SOLVER',SOLVER,'rootdir',rootdir,'timelimits',tspan,'dsfact',dsfact,...
  'savedata_flag',savedata_flag,'saveplot_flag',saveplot_flag,'plotvars_flag',plotvars_flag,'addpath',codepath,...
  'cluster_flag',cluster_flag,'coder',0);

% % with codegen
% values = '[4 4.5]';
% [~,~,outdir]=simstudy(spec,{scope},{variable},{values},...
%   'dt',dt,'SOLVER',SOLVER,'rootdir',rootdir,'timelimits',tspan,'dsfact',dsfact,...
%   'savedata_flag',savedata_flag,'saveplot_flag',saveplot_flag,'plotvars_flag',plotvars_flag,'addpath',codepath,...
%   'cluster_flag',cluster_flag,'coder',1);
