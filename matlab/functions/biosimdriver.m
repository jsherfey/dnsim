function varargout = biosimdriver(spec,varargin)

parms = mmil_args2parms( varargin, ...
                         {  'logfid',1,[],...
                            'savedata_flag',1,[],...
                            'jsondata_flag',0,[],...
                            'savepopavg_flag',1,[],...
                            'savespikes_flag',1,[],...
                            'saveplot_flag',1,[],...
                            'plotvars_flag',1,[],...
                            'plotrates_flag',1,[],...
                            'plotpower_flag',1,[],...
                            'plotpacoupling_flag',0,[],...
                            'reply_address','sherfey@bu.edu',[],...
                            'rootoutdir',[],[],...
                            'prefix','sim',[],...
                            'verbose',1,[],...
                            'cluster_flag',0,[],...
                            'plot_flag',1,[],...
                            'batchdir',pwd,[],...
                            'jobname','job.m',[],...
                            'overwrite_flag',0,[],...
                         }, false);

plot_flag = parms.plotvars_flag || parms.plotrates_flag || parms.plotpower_flag || parms.plotpacoupling_flag; % whether to plot anything at all
save_flag = parms.savedata_flag || parms.savepopavg_flag || parms.savespikes_flag || (parms.saveplot_flag && plot_flag); % whether to save anything at all
analysis_flag = parms.plotrates_flag || parms.plotpower_flag || parms.plotpacoupling_flag || parms.savepopavg_flag || parms.savespikes_flag; % whether to create an analysis directory
overwrite_flag = parms.overwrite_flag;

logfid = parms.logfid;
reply_address = parms.reply_address;  % FROM address on the emails that get generated.
rootoutdir = parms.rootoutdir;
prefix = parms.prefix;
% formats={'-dpng','-depsc'}; exts={'.png','.eps'}; % ,'-djpeg' ,'.jpg'
formats={'-dpng'}; exts={'.png'}; % ,'-djpeg' ,'.jpg'
filenames={};

try
%% prepare output directory
if save_flag
  datafile = fullfile(rootoutdir,'data',[prefix '_sim_data.mat']);
  if exist(datafile,'file') && ~overwrite_flag
    fprintf('Aborting simulation. \nsim_data already exists: %s\n',datafile);
    return;
  end
  % create rootoutdir
  if ~exist(rootoutdir,'dir'), mkdir(rootoutdir); end
  if ~exist(fullfile(rootoutdir,'model'),'dir'), mkdir(fullfile(rootoutdir,'model')); end
  if parms.cluster_flag
    if ~exist(fullfile(rootoutdir,'logs'),'dir'), mkdir(fullfile(rootoutdir,'logs')); end
  end
  % save spec in unique specfile in specs dir
  specfile = fullfile(rootoutdir,'model',[prefix '_model-specification.mat']);
  save(specfile,'spec','parms');
  filenames{end+1}=specfile;
  % create directory for saving analysis results
  if analysis_flag && ~exist(fullfile(rootoutdir,'data'),'dir'), mkdir(fullfile(rootoutdir,'data')); end
end

%% simulate

% run biosim
args = mmil_parms2args(spec.simulation);
[sim_data,spec,parms.biosim] = runsim(spec,args{:},'verbose',parms.verbose);
if isempty(sim_data)
  fprintf(logfid,'Simulation failed. No data to save.\n');
  return;
end

% save simulated data with prefix
if parms.savedata_flag
  if ~exist(fullfile(rootoutdir,'data'),'dir'), mkdir(fullfile(rootoutdir,'data')); end
    if parms.jsondata_flag
      savejson('', {sim_data,spec,parms}, fullfile(rootoutdir,'data',[prefix '_sim_data.json']));
      fprintf(logfid,'Simulated data saved to: %s\n',fullfile(rootoutdir,'data',[prefix '_sim_data.json']));
    else
      save(datafile,'sim_data','spec','parms','-v7.3');
      fprintf(logfid,'Simulated data saved to: %s\n',datafile);
    end
end

%% analyze and plot simulated data

% spectral analysis parameters
NFFT=[];
WINDOW=[];
NOVERLAP=[];
% spike rate parameters
window_size = 30/1000;%50/1000;
dW = 5/1000;
spikethreshold=0;
% cell characterization protocol mechanisms
SimMech='iStepProtocol';

% -----------------------------------------------------
% Data and LFP
% get and plot results
h1=[]; h2=[]; h3=[]; h4=[]; h5=[];
if issubfield(spec,'variables.global_oldlabel')
  varlabels=unique(spec.variables.global_oldlabel);
else
  varlabels={'V'};
end
% state variables
vars={}; h1vars={}; h5vars={}


if parms.plotvars_flag || parms.savepopavg_flag
  for i=1:length(varlabels)
  try
    [h,lfp,time]=plotv(sim_data,spec,'plot_flag',parms.plotvars_flag,'varlabel',varlabels{i}); % V (per population): image and (traces + mean(V))
    vars={vars{:},'lfp','time'};
    h1=[h1 h];
    h1vars{end+1}=varlabels{i};

    [h_derp,lfp,time]=plotv_single(sim_data,spec,'plot_flag',parms.plotvars_flag,'varlabel',varlabels{i}); % V (per population): image and (traces + mean(V))
    h5=[h5 h_derp];
    h5vars{end+1}=varlabels{i};

  catch err
    disperror(err);
  end
  end
end


% power spectrum
if parms.plotpower_flag
  try
    [h2,pow,freq]=plotpow(sim_data,spec,'plot_flag',parms.plotpower_flag,...
                          'NFFT',NFFT,'WINDOW',WINDOW,'NOVERLAP',NOVERLAP,'FreqRange',[10 80]); % LFP power and spectrogram
    vars={vars{:},'pow','freq','NFFT','WINDOW','NOVERLAP'};
  catch err
    h2=[];
    disperror(err);
  end
end

% LFP data to lfp directory
if parms.savepopavg_flag && ~isempty(vars)
  if ~exist(fullfile(rootoutdir,'data','lfp'),'dir'), mkdir(fullfile(rootoutdir,'data','lfp')); end
  vars{end+1}='spec';
  outfile = fullfile(rootoutdir,'data','lfp',[prefix '_sim_data_LFPs.mat']);
  save(outfile,vars{:},'-v7.3');
  fprintf('LFP data saved to %s\n',outfile);
  clear vars
end

% -----------------------------------------------------
% SPIKES
if parms.plotrates_flag || parms.savespikes_flag
  try
    [h3,rates,tmins,spiketimes,spikeinds]=plotspk(sim_data,spec,'plot_flag',parms.plotrates_flag,...
                                    'window_size',window_size,'dW',dW,'spikethreshold',spikethreshold); % firing rate(t) and FRH
    if parms.savespikes_flag
      if ~exist(fullfile(rootoutdir,'data','spikes'),'dir'), mkdir(fullfile(rootoutdir,'data','spikes')); end
      % save spike data to spikes directory
      outfile = fullfile(rootoutdir,'data','spikes',[prefix '_sim_data_spikes.mat']);
      save(outfile,'rates','tmins','spiketimes','spikeinds','window_size','dW','spikethreshold','spec','-v7.3');
      fprintf('Spike data saved to %s\n',outfile);
    end
  catch err
    h3=[];
    disperror(err);
  end
end

% -----------------------------------------------------
% Phase amplitude coupling (PAC) analysis

if parms.plotpacoupling_flag
  try
    [h4]=plotpacoupling(sim_data,spec,'plot_flag',parms.plotpacoupling_flag);
  catch err
    h4=[];
    disperror(err);
  end
end

figs = [h1 h2 h3 h4 h5];


% -----------------------------------------------------
% save figures
if plot_flag && parms.saveplot_flag
  % save plots
  if ~exist(fullfile(rootoutdir,'images'),'dir'), mkdir(fullfile(rootoutdir,'images')); end
  if ~isempty(h1)
    for j=1:length(h1)
      var=h1vars{j};
      if ~exist(fullfile(rootoutdir,'images','rawv'),'dir'), mkdir(fullfile(rootoutdir,'images',['raw' var])); end
      filenames{end+1} = fullfile(rootoutdir,'images',['raw' var],[prefix '_raw' var]);
      fprintf('saving plots - voltage traces: %s\n',filenames{end});
      for i=1:length(exts)
        try
          % '-mXXX' is an option to magnify the on-screen pixel dimensions, where XXX is a number
          export_fig([filenames{end} exts{i}],h1(j),'-m1.5','-painters');
        catch err
            disperror(err);
        end;
      end
    end
  end
  if ~isempty(h2)
    if ~exist(fullfile(rootoutdir,'images','power'),'dir'), mkdir(fullfile(rootoutdir,'images','power')); end
    filenames{end+1} = fullfile(rootoutdir,'images','power',[prefix '_power']);
    fprintf('saving plots - field power: %s\n',filenames{end});
    for i=1:length(exts)
      try
        export_fig([filenames{end} exts{i}],h2,'-m1.5','-painters');
      catch err
            disperror(err);
      end;
    end
  end
  if ~isempty(h3)
    if ~exist(fullfile(rootoutdir,'images','spikes'),'dir'), mkdir(fullfile(rootoutdir,'images','spikes')); end
    filenames{end+1} = fullfile(rootoutdir,'images','spikes',[prefix '_rates']);
    fprintf('saving plots - spike rates: %s\n',filenames{end});
    for i=1:length(exts)
      try
        export_fig([filenames{end} exts{i}],h3,'-m1.5','-painters');
      catch err
            disperror(err);
      end;
    end
  end
  if ~isempty(h4)
    % Hopefully there isn't any other place that is responsible for creating the data directories
    if ~exist(fullfile(rootoutdir,'images','coupling'),'dir'), mkdir(fullfile(rootoutdir,'images','coupling')); end
    filenames{end+1} = fullfile(rootoutdir,'images','coupling',[prefix '_coupling']);
    fprintf('saving plots - phase amplitude coupling: %s\n',filenames{end});
    for i=1:length(exts)
      try
        export_fig([filenames{end} exts{i}],h4,'-m1.5','-painters');
      catch err
            disperror(err);
      end;
    end
  end
  if ~isempty(h5)
    for j=1:length(h5)
      var=h5vars{j};
      if ~exist(fullfile(rootoutdir,'images','rawv'),'dir'), mkdir(fullfile(rootoutdir,'images',['raw' var])); end
      filenames{end+1} = fullfile(rootoutdir,'images',['raw' var],[prefix '_raw02' var]);
      fprintf('saving plots - SINGLE voltage traces: %s\n',filenames{end});
      for i=1:length(exts)
        try
          export_fig([filenames{end} exts{i}],h5(j),'-m1.5','-painters');
        catch err
            disperror(err);
        end;
      end
    end
  end
end

% -----------------------------------------------------
% plot state vars
% statevars = {sim_data.sensor_info.label};
% - remove cell label prefixes from statevars
% [h1,lfp,time]=plotv(sim_data,spec,'plot_flag',parms.plot_flag,'var',var);
% todo:
%   - modify plotv() to use var labels instead of indices
%   - loop over state vars; call plotv() once per var
%   - in plotv(): skip subplot row if var label not present in pop

% -----------------------------------------------------
%% cleanup
if plot_flag && parms.saveplot_flag && ~parms.cluster_flag
  close(figs);
end

% save cluster log
if parms.cluster_flag
  [p,name]=fileparts(parms.jobname);
  outlog=fullfile(parms.batchdir,'pbsout',[name '.out']);
  errlog=fullfile(parms.batchdir,'pbsout',[name '.err']);
  outoutlog=fullfile(rootoutdir,'logs',[prefix '_' name '.out']);
  outerrlog=fullfile(rootoutdir,'logs',[prefix '_' name '.err']);
  fprintf(logfid,'saving cluster log (%s) to %s.\n',outlog,outoutlog);
  cmd = sprintf('cp %s %s',outlog,outoutlog);
  [s,m] = system(cmd);
  if s, fprintf(logfid,'%s',m); end
  cmd = sprintf('cp %s %s',errlog,outerrlog);
  [s,m] = system(cmd);
  if s, fprintf(logfid,'%s',m); end
end

if ~parms.savedata_flag
  assignin('base','sim_data',sim_data);
  assignin('base','spec',spec);
  fprintf('sim_data and spec assigned to base workspace.\n');
end

catch err
  disperror(err);

  % save cluster log
  if parms.cluster_flag
    [p,name]=fileparts(parms.jobname);
    outlog=fullfile(parms.batchdir,'pbsout',[name '.out']);
    errlog=fullfile(parms.batchdir,'pbsout',[name '.err']);
    outoutlog=fullfile(rootoutdir,'logs',[prefix '_' name '.out']);
    outerrlog=fullfile(rootoutdir,'logs',[prefix '_' name '.err']);
    fprintf(logfid,'saving cluster log (%s) to %s.\n',outlog,outoutlog);
    cmd = sprintf('cp %s %s',outlog,outoutlog);
    [s,m] = system(cmd);
    if s, fprintf(logfid,'%s',m); end
    cmd = sprintf('cp %s %s',errlog,outerrlog);
    [s,m] = system(cmd);
    if s, fprintf(logfid,'%s',m); end
  end
end

function disperror(err)
  fprintf('Error: %s\n',err.message);
  for i=1:length(err.stack)
    fprintf('\t in %s (line %g)\n',err.stack(i).name,err.stack(i).line);
  end
  %rethrow(err);
