function varargout = biosimdriver(spec,varargin)

parms = mmil_args2parms( varargin, ...
                         {  'logfid',1,[],...
                            'savedata_flag',1,[],...
                            'savepopavg_flag',1,[],...
                            'savespikes_flag',1,[],...
                            'saveplot_flag',1,[],...
                            'plotvars_flag',1,[],...
                            'plotrates_flag',1,[],...
                            'plotpower_flag',1,[],...
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

plot_flag = parms.plotvars_flag || parms.plotrates_flag || parms.plotpower_flag; % whether to plot anything at all
save_flag = parms.savedata_flag || parms.savepopavg_flag || parms.savespikes_flag || (parms.saveplot_flag && plot_flag); % whether to save anything at all
analysis_flag = parms.plotrates_flag || parms.plotpower_flag || parms.savepopavg_flag || parms.savespikes_flag; % whether to create an analysis directory
overwrite_flag = parms.overwrite_flag;

logfid = parms.logfid;
reply_address = parms.reply_address;  % FROM address on the emails that get generated. 
rootoutdir = parms.rootoutdir;
prefix = parms.prefix;
% formats={'-dpng','-depsc'}; exts={'.png','.eps'}; % ,'-djpeg' ,'.jpg'
formats={'-dpng'}; exts={'.png'}; % ,'-djpeg' ,'.jpg'
filenames={};

% saveplot_flag = parms.saveplot_flag;
% save_flag = parms.saveplot_flag || parms.savedata_flag || parms.cluster_flag;

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

% save simulated data with prefix
if parms.savedata_flag
  if ~exist(fullfile(rootoutdir,'data'),'dir'), mkdir(fullfile(rootoutdir,'data')); end
  save(datafile,'sim_data','spec','parms');%,'-v7.3');
  fprintf(logfid,'Simulated data saved to: %s\n',datafile);
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
h1=[]; h2=[]; h3=[];
if issubfield(spec,'variables.global_oldlabel')
  varlabels=unique(spec.variables.global_oldlabel);
else
  varlabels={'V'};
end
% state variables
vars={}; h1vars={};
if parms.plotvars_flag || parms.savepopavg_flag
  for i=1:length(varlabels)
  try
    [h,lfp,time]=plotv(sim_data,spec,'plot_flag',parms.plotvars_flag,'varlabel',varlabels{i}); % V (per population): image and (traces + mean(V))
    %[h1,lfp,time]=plotv(sim_data,spec,'plot_flag',parms.plotvars_flag); % V (per population): image and (traces + mean(V))
    vars={vars{:},'lfp','time'};
    h1=[h1 h];
    h1vars{end+1}=varlabels{i};
  catch err
    disperror(err);
  end
  end
end

% power spectrum
if parms.plotpower_flag
  try
    %NFFT=[]; WINDOW=[]; NOVERLAP=[];
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
  save(outfile,vars{:});%,'-v7.3');
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
      save(outfile,'rates','tmins','spiketimes','spikeinds','window_size','dW','spikethreshold','spec');%,'-v7.3');  
      fprintf('Spike data saved to %s\n',outfile);
    end
  catch err
    h3=[];
    disperror(err);
  end
end
figs = [h1 h2 h3];

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
          print(h1(j),formats{i},[filenames{end} exts{i}]); 
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
        print(h2,formats{i},[filenames{end} exts{i}]); 
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
        print(h3,formats{i},[filenames{end} exts{i}]); 
      catch err
        disperror(err);        
      end; 
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
% characterize cells if appropriate (if contains iStepProtcol)
if parms.savedata_flag && ismember(SimMech,spec.entities(1).mechanisms)
  try
    inputs={};
    for i=1:length(sim_data)
      inputs{i}.sim_data=sim_data(i);
      inputs{i}.spec=spec;
      inputs{i}.spec.entities = spec.entities(i);    
      inputs{i}.rootoutdir=fullfile(rootoutdir,'data');
      inputs{i}.prefix=prefix;
    end
    [results,cellids,allparms,setfiles] = getcharacteristics(inputs,'sim');
    %results = getcharacteristics(datafile,'sim');
    clear inputs
    if parms.plot_flag
      h=plotcharacteristics(results,spec);
      if parms.saveplot_flag
        % save plots: hyperpol & depol overlays, tonic depol plots
        if ~exist(fullfile(rootoutdir,'images','cell_characteristics'),'dir'), mkdir(fullfile(rootoutdir,'images','cell_characteristics')); end
        for i=1:length(h)
          filenames{end+1} = fullfile(rootoutdir,'images','cell_characteristics',[prefix '_cell_characteristics_' spec.entities(i).label]);
          fprintf('saving plots - cell characteristics (%s): %s\n',filenames{end},spec.entities(i).label);
          for j=1:length(exts)
            try
              print(h(i),formats{j},[filenames{end} exts{j}]); 
            catch err
              disperror(err);              
            end; 
          end
        end
      end
      figs = [figs h];
    end
  catch err
    disperror(err);
  end
end

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

%% Old driver script
% 
% % Things to adjust manually until a better solution exists
% % output_list = parms.output_list;%'output'; % TODO: make this part of spec by adding to simtools.html
% cfg = loadjson(strrep(spec.simulation.figure_keyvalue,'''','"'));
% if isfield(cfg,'vars')
%   plotvars = strtrim(splitstr(cfg.vars,',')); 
% else
%   plotvars = [];
% end  
% if ~isempty(plotvars)
%   if any(strcmp('output',plotvars))
%     output_list = 'output';
%   end
% end
% 
% layout=[];%if ~isempty(output_list), layout='ordered'; else layout=[]; end
% 
% % Hard-coded values
% pushscript = '/space/mdeh3/9/halgdev/projects/jsherfey/outbox/pushfiles.csh';
% localoutbox = '/space/mdeh3/9/halgdev/projects/jsherfey/outbox';
% 
% if ~isfield(spec.simulation,'ProjName'), spec.simulation.ProjName = 'sandbox'; end
% if ~isfield(spec.simulation,'StudyName'), spec.simulation.StudyName = datestr(now,29); end
% if ~isfield(spec.simulation,'SetName'), spec.simulation.SetName = datestr(now,30); end
% if ischar(spec.simulation.sim_start), spec.simulation.sim_start = str2num(spec.simulation.sim_start); end
% if ischar(spec.simulation.sim_stop), spec.simulation.sim_stop = str2num(spec.simulation.sim_stop); end
% spec.simulation.timelimits = [spec.simulation.sim_start spec.simulation.sim_stop];
% 
% ProjName        = spec.simulation.ProjName;
% StudyName       = spec.simulation.StudyName;
% SetName         = spec.simulation.SetName;
% cluster_flag    = str2num(spec.simulation.sim_cluster_flag); % 1
% cluster         = spec.simulation.sim_cluster;
% qsubscript      = spec.simulation.sim_qsubscript;
% rootoutdir      = spec.simulation.sim_rootoutdir; % this is where results will be saved
% prefix       = spec.simulation.sim_file_prefix;
% report_address  = spec.simulation.sim_report_address;  % 'jssherfey@gmail.com';  % Target email address for the reports generated by this script.
% codepath        = spec.simulation.sim_codepath; %'/space/mdeh3/9/halgdev/projects/jsherfey/code/hhnetsim';
% SOLVER          = spec.simulation.sim_solver;
% timelimits      = spec.simulation.timelimits;
% dt              = str2num(spec.simulation.sim_dt);
% target_fs       = spec.simulation.sim_target_fs;   try target_fs = str2num(target_fs); end
% 
% rootoutdir = strrep(rootoutdir,',','-');
% rootoutdir = strrep(rootoutdir,' ','_');
% 
% % Derived parameters
% prefix = sprintf('%s_%s_%s',prefix,StudyName,SetName);
% localfilepath = rootoutdir;
% localfilepath = strrep(localfilepath,'ProjName',ProjName);
% localfilepath = strrep(localfilepath,'StudyName',StudyName);
% localfilepath = strrep(localfilepath,'SetName',SetName);
% results_dir        = localfilepath;
% figures_dir        = localfilepath;
% spec_dir           = localfilepath;
% matfile             = fullfile(localfilepath,[prefix '_simulation_results.mat']);
% if exist(matfile,'file') % check if analysis is already complete
%   fprintf('Aborting analysis. Results file already exists: %s\n',matfile);
%   return;
% end
% if ~exist(localfilepath,'dir') && ~log_flag && saveplot_flag
%   mkdir(localfilepath);
% end
% 
% xmlfile = fullfile(localfilepath,'biosim.xml');
% driverscript = mfilename('fullpath') ;       % Name of this current file. Note: matlab leaves off the .m extension when the 'fullpath' switch is used.
% SimDescription = sprintf('t=%g-%gms, %s',timelimits,SOLVER); % change to inc
% ModelName = StudyName;
% 
% if ~isempty(target_fs)
%   orig_fs = 1/(dt/1000);
%   dsfact = max(1,round(orig_fs/target_fs));
% else
%   dsfact = 1;
% end
% 
% if log_flag==0 && saveplot_flag==0 && cluster_flag==1
%   fprintf('Forcing cluster_flag=0 because user indicated no results should be saved.\n');
% end
% 
% script_begin = tic;  % Start keeping time for the whole script.
% % -------------------------------------------------------------------------
% if log_flag
%   if cluster_flag
%     % add a jitter in processing to avoid problems with different jobs
%     % trying to access the same disk location at  the same time (doesn't
%     % happen very often but when executing many jobs at the same time it
%     % becomes likely to occur at least once when reading pref files/etc).
%     pause(10*randn);
%   end
% 
%   %% Log Parameters
%   % ## Variables and Settings generated from parameters above. ## %
%   results_dir        = fullfile(localfilepath,'matfiles');
%   figures_dir        = fullfile(localfilepath,'images');  
%   spec_dir           = fullfile(localfilepath,'spec');  
%   matfile             = fullfile(results_dir,[prefix '_simulation_results.mat']);
%   reportfile          = fullfile(localfilepath,[prefix '_simulation_report.txt']);   % filename for progress report file for the script.
% %   figfile_pop         = fullfile(figures_dir,[prefix '_population_responses']);
%   CPUs                = feature('numcores');          % Matlab command to get the number of processor cores on current host machine.
% %   computername='removedbcslow';
% %   meminfo='removedbcslow';
% %   total_memory='removedbcslow';
% %   cpuinfo='removedbcslow';
% %   CPU_type='removedbcslow';
% %   CPU_cache='removedbcslow';
%   [zzz, computername] = system('hostname');           % Uses linux system command to get the machine name of host. 
%   [zzz, meminfo]      = system('cat /proc/meminfo');  % Uses linux system command to get a report on system memory
%   total_memory        = textscan(meminfo, '%*s %s %s', 1);  % Parses the memory report for 2nd and 3rd space-delimited items of first line: memory amount.
%   total_memory        = [total_memory{1}{1} ' ' total_memory{2}{1}];  % Extracts the info from cell array to create char array.
%   [zzz, cpuinfo]      = system('cat /proc/cpuinfo');  % Uses linux system command to get a report on CPU types and speeds, etc.
%   cpuinfo             = textscan(cpuinfo, '%*s %*s %*s %*s %s %*s %*s %s', 1, 'delimiter', '\n'); % Extracts lines 5 and 8 of report: Proc Type, and Cache
%   CPU_type            = textscan(cpuinfo{1}{1}, '%*s %s', 1, 'delimiter' , ':'); % Parses line that includes CPU type.
%   CPU_type            = [strrep(CPU_type{1}{1},'  ','') ];    % ## Look for better way for this: collapse all repeated white space stretches to single spaces.
%   CPU_cache           = textscan(cpuinfo{2}{1}, '%*s %s', 1, 'delimiter' , ':'); % Parses line that includes the cache info
%   CPU_cache           = [CPU_cache{1}{1} ];                                      % Takes the cache info out of the cell array.
%   matlab_version      = version;
%   clear zzz cpuinfo meminfo;
%   cwd = pwd;
%   if exist(matfile,'file') % check if analysis is already complete
%     fprintf('Aborting analysis. Results file already exists: %s\n',matfile);
%     return;
%   end
%   if ~exist(localfilepath,'dir')
%     mkdir(localfilepath);
%   end
%   if ~exist(results_dir,'dir'),    mkdir(results_dir);    end  % Create directory if needed.
%   if ~exist(figures_dir,'dir'), mkdir(figures_dir); end  % Create directory if needed.
%   if ~exist(spec_dir,'dir'), mkdir(spec_dir); end  % Create directory if needed.
%   fprintf('Creating report file: %s\n',reportfile);
%   fileID = fopen(reportfile, 'wt');   % Open file to contain the report of timings.
%                                       % Set to 1 to output to terminal instead of a file
%   fprintf(fileID,'\n** REPORT FILE for Simulation: %s **\n%s\n\n',[ProjName '_' ModelName '_' SetName],SimDescription);
%   fprintf(fileID,'Location on file server: %s\n',reportfile);
%   fprintf(fileID,'\nAnalysis run by script: %s.\n', [driverscript '.m'] );
%   fprintf(fileID,['\nMachine info (harvested from system):\n  Host Computer: %s  Processors: %g.\n  Type = "%s" \n'...
%                    '  Processor Cache: %s.\n  Total Memory: %s.\n  Matlab Version: %s.\n'],...
%                    computername,CPUs, CPU_type, CPU_cache, total_memory, matlab_version);
%   fprintf(fileID,'\nScript initiated at: %s.\n',datestr(now,31));
%   fprintf('\nStarting simulation (%s): %s.\n\n',[ProjName '_' ModelName '_' SetName], datestr(now,31));
%   fprintf(fileID,'\nBeginning simulation (%s): %s...\n\n',[ProjName '_' ModelName '_' SetName], datestr(now,31));
% else
%   fileID = 1;
% end
% if cluster_flag
%   if iscell(codepath)
%     for i = 1:length(codepath)
%       addpath(genpath(codepath{i}));
%     end
%   else
%     addpath(genpath(codepath));
%   end
% end
% 
% % figure; k=1; plot(t,data(:,k)); title(datalabels{k});
% try
%   [data,spec,parms] = biosim(spec,'timelimits',timelimits,'dsfact',dsfact,'SOLVER',SOLVER,'dt',dt,'logfid',fileID,'output_list',output_list);
% catch
%   try
%     fprintf(fileID,'Failed to complete simulation and return precalculated auxiliary functions.  Repeating with only simulation.\n');
%     [data,spec,parms] = biosim(spec,'timelimits',timelimits,'dsfact',dsfact,'SOLVER',SOLVER,'dt',dt,'logfid',fileID,'output_list',[]);
%   catch exception
%     fprintf(fileID,'Aborting! Simulation failed:\n');
%     fprintf(fileID,'%s\n',getReport(exception));
%     %return
%   end
% end
% run_time = toc(script_begin)/60;
% 
% if log_flag || saveplot_flag
%   % Save results. This is what will be used in future for all figures & spike train & LFP analysis. 
%   try
%     save(matfile,'data','spec','parms','-v7.3'); %,'t','pop','NetCon','parms','model','spec','-v7.3');
%     fprintf(fileID,'Results saved successfully: %s\n',matfile);
%   catch exception
%     fprintf(fileID,'Failed to save results: %s\n',matfile);
%     fprintf(fileID,'%s\n',getReport(exception));
%   end  
% end
% 
% % copy spec files to project dir
% if log_flag
%   for k = 1:length(spec.files)
%     [fpath,fname,fext] = fileparts(spec.files{k});
%     [s,m] = unix(sprintf('cp %s %s',spec.files{k},fullfile(spec_dir,[fname fext])));
%     if s, fprintf(fileID,'%s',m); end
%   end
%   fprintf('\nFinished! The %s simulation (%g ms) took %0.2f minutes.\n\n',[ProjName '_' ModelName '_' SetName],diff(timelimits),toc(script_begin)/60);
%   fprintf(fileID,'\n ==> The %s simulation (%g ms) took %0.2f minutes.\n\n',[ProjName '_' ModelName '_' SetName],diff(timelimits),toc(script_begin)/60);
% end
% 
% % Plot results
% try
%   imgfiles = biosim_plots(data,'cluster_flag',cluster_flag,'saveplot_flag',saveplot_flag,'plotvars',plotvars,'format',{'jpg','png'},'rootoutdir',localfilepath,'prefix',prefix,'layout',layout,'powrepmat',powrepmat);
%   fprintf(fileID,'Results plotted successfully:\n'); 
%   for i = 1:length(imgfiles)
%     if exist(imgfiles{i},'file')
%       fprintf(fileID,'saved: %s\n',imgfiles{i});
%     else
%       fprintf(fileID,'failed to save: %s\n',imgfiles{i});
%     end
%   end
% catch exception
%   fprintf(fileID,'%s\n',getReport(exception));
%   if log_flag && saveplot_flag && ~exist('imgfiles','var')
%     d=dir(figures_dir); f={}; [f{1:numel(d),1}]=deal(d.name);
%     imgfiles = f; clear f d
%   end
%   fprintf(fileID,'An error occurred while plotting or saving figures.\n');
% end
% 
% if log_flag
%   
%   % cluster logs
%   clusterscript = ''; clusterstdout=''; clusterstderr='';
%   try
%    if cluster_flag
%       caller = dbstack;
%       [jnk,batchjob] = fileparts(caller(end).file);
%       clusterscript = [cwd '/' batchjob '.m'];
%       f{1} = [cwd '/pbsout/' batchjob '.out'];
%       f{2} = [cwd '/pbsout/' batchjob '.err'];
%       if exist(f{1},'file')
%   %       email_attachments = {email_attachments{:} f{:}};
%         clusterstdout = f{1};
%         clusterstderr = f{2};        
%       end
%     end
%   catch exception
%     fprintf(fileID,'Failed to retrieve cluster logs.\n');
%     fprintf(fileID,'%s\n',getReport(exception));
%   end
%   % mechanism and spec files
%   idx = ~cellfun(@isempty,regexp(spec.files,'.txt$','match'));
%   mechfiles = spec.files(idx);
%   idx = ~cellfun(@isempty,regexp(spec.files,'.csv$','match'));
%   csvfiles = spec.files(idx);
%   idx = ~cellfun(@isempty,regexp(spec.files,'.json$','match'));
%   jsonfiles = spec.files(idx);
%   
%   % email attachments
%   simulator = which('biosim.m');
%   driver = which([driverscript '.m']);
% %   imgfiles = {jpgfile};%,epsfile}; % pngfile
%   cstlogs  = {clusterstdout,clusterstderr};
%   allfiles = {csvfiles{:} jsonfiles{:} driver clusterscript cstlogs{:} reportfile imgfiles{:} mechfiles{:} simulator};
%   [allfiles{~cellfun(@exist,allfiles)}] = deal('');
%   web_files = allfiles;
%   email_attachments = allfiles(~cellfun(@isempty,allfiles));  
%     
%   %% Create XML specifications and transfer files
% %   addpath /space/mdeh3/9/halgdev/projects/jsherfey/code/hhnetsim/scripts/xml_toolbox
%   model_files = [csvfiles mechfiles];
%   fprintf(fileID,'Preparing XML spec...\n');
%   try
%     sim2xml;
%   catch exception
%     failed_flag = 1;
%     fprintf(fileID,'Failed to prepare XML spec for web server!\n');
%     fprintf(fileID,'%s\n',getReport(exception));
%   end
%   
%   try
%     fprintf(fileID,'Saving model and result info in XML format for updating Django models.\n');
%     fid = fopen(xmlfile,'w+');
%     fprintf(fid,'%s',XML);
%     fclose(fid);
% 
%     % add biosim.xml to the other file lists
%     allfiles{end+1} = xmlfile;
%     web_files = allfiles;
%     email_attachments = allfiles(~cellfun(@isempty,allfiles));
% 
%     %% Prepare outbox
%     % Add archived temp copies of the results to outbox
%     fprintf(fileID,'Preparing temporary result archive for transfer to web server:\n');
% 
%     % create outbox
%     if ~exist(localoutbox,'dir')
%       [s,m]=mkdir(localoutbox);
%       if ~s, fprintf(fileID,'%s\n',m); end
%     end
% 
%     % create temp dir
%     tag = sprintf('%s_%g',datestr(now,30),round(100*rand));
%     tempdir = fullfile(localoutbox,tag);
%     [s,m]=mkdir(tempdir);
%     if ~s, fprintf(fileID,'%s\n',m); end
% 
%     % copy files to temp dir
%     % Compress in /inbox
%     web_files_ = cellfun(@(x)[x ' '],web_files,'uniformoutput',false); 
%     [s,m]=unix(sprintf('cp %s %s',[web_files_{:}],tempdir));
%     if s, fprintf(fileID,'%s\n',m); end
% 
%     % archive files
%     fprintf(fileID,'Archiving files for transfer to web server...\n');
%     cd(localoutbox);[s,m]=unix(sprintf('tar cvzf %s.tar.gz %s',tag,tag));cd(cwd);
%     fprintf(fileID,'%s\n',m);
%     
%     outfile = [tag '.tar.gz'];
%     if exist(fullfile(localoutbox,outfile),'file')
%       fprintf(fileID,'Archive file: %s\n',outfile);
%       % remove temp dir
%       [s,m]=unix(sprintf('rm -rf %s',tempdir));
%       if s, fprintf(fileID,'%s\n',m); end
%       fprintf(fileID,'End of web report. Log continues in report on file server.\n');
%       % secure transfer archive to web server
%       remoteinbox = 'public_html/inbox';
%       cmd = sprintf('%s %s %s',pushscript,outfile,remoteinbox);
%       attempts = 0; maxattempts = 10; chks = 0;
%       while 1
%         fprintf(fileID,'Executing command: %s\n',cmd);
%         [s,m] = unix(cmd);
%         if s, break; end
%         % check if file on server
%         [chks,chkm] = unix(['wget http://www.neurophilosophica.com/inbox/' outfile]);
%         if chks % || any(regexp(chkm,'404 NOT FOUND'))
%           attempts = attempts + 1;
%           if attempts > maxattempts
%             fprintf(fileID,'Exceeded maximum transfer attempts. Aborting transfer. Files to transfer stored in %s/%s\n',localoutbox,outfile);
%             break;
%           end
%           fprintf(fileID,'Failed to push files to server. Trying again...\n');
%         else
%           break;
%         end
%       end
%       if s % Failed to execute push script
%         fprintf(fileID,'%s\n',m);
%       elseif chks % Push script failed to transfer file
%         fprintf(fileID,'%s\n',chkm);
%       else % Transfer successful => remove local files & update DB
%         fprintf(fileID,'%sArchive transferred to remote server.\n',m);% Removing temporary files.\n');
%         cmd = sprintf('rm %s',fullfile(localoutbox,outfile));
%         [s,m] = unix(cmd);
%         if s
%           fprintf(fileID,'%s\n',m);
%         else
%           fprintf(fileID,'Temporary files removed successfully.\n');
%         end
%         %pause(5);
%         if web_update_flag
%         try
%           [s,m] = unix('wget http://www.neurophilosophica.com/inbox/');
%           if s
%             fprintf(fileID,'%s\n',m);
%           else
%             fprintf(fileID,'\n%sPython xml2models() triggered and database updated successfully.\n',m);
%           end
%           try unix('rm index.html*'); end
%         catch exception
%           fprintf(fileID,'Failed to launch web browser. Data not pushed to web server. \nGoto http://neurophilosophica.com/inbox to update the website.\n');
%           fprintf(fileID,'%s\n',getReport(exception));
%         end
%         end
%       end
%       % To uncompress: tar -xvzf $tarfile
%     else
%       fprintf(fileID,'Failed to prepare archive for transfer to web server.\n');
%     end
%   catch exception
%     fprintf(fileID,'Failed to transfer files to web server.\n');
%     fprintf(fileID,'%s\n',getReport(exception));
%   end
%   
%   % Closing remarks before emailing results
%   fprintf('\nMaster script finished. Total elapsed time: %0.2f minutes]\n',run_time);
%   fprintf(fileID,'\nANALYSIS SUMMARY\n\nProcessed simulation "%s".\n',[ProjName '_' ModelName '_' SetName]);
%   fprintf(fileID,['\nMachine info (harvested from system):\n  Host Computer: %s  Processors: %g.\n  Type = "%s" \n'...
%                    '  Processor Cache: %s.\n  Total Memory: %s.\n  Matlab Version: %s.\n\n'],...
%                    computername,CPUs, CPU_type, CPU_cache, total_memory, matlab_version);
%   fprintf(fileID,'\nThe script that ran this analysis and generated this report is attached to this email.\n\n');
% %   fprintf(fileID,['\nMachine info (harvested from system):\n  Host Computer: %s  Processors: %g.\n  Type = "%s" \n'...
% %                    '  Processor Cache: %s.\n  Total Memory: %s.\n  Matlab Version: %s.\n\n'],...
% %                    computername,CPUs, CPU_type, CPU_cache, total_memory, matlab_version);
%   fclose(fileID);
% 
%   %% Send Email
%   try
%     setpref('Internet','SMTP_Server','127.0.0.1'); % Sets the outgoing mail server - often the default 127.0.0.1
%     setpref('Internet','E_mail',reply_address);    % Sets the email FROM/reply address for all outgoing email reports.
%     fprintf('Files attached to report email:\n');
%     email_attachments{:}
%     sendmail(report_address,sprintf('Analysis report for model "%s"',ModelName),...
%        [10 prefix '. Total proc time: ' sprintf('%0.2f min',toc(script_begin)/60) '. Browse results online at http://www.neurophilosophica.com/browse. Current time: ' datestr(now,31) '  (Automated message from my Matlab script: NeuroDriver.m.)' 10],...
%        {email_attachments{:}});  
%     fprintf('\nReport emailed successfully to: %s\n',report_address);
%   catch exception
%     fprintf('\nFailed to email report to: %s\n',report_address);
%     fprintf('%s\n',getReport(exception));
%   end
% end
% 
% if cluster_flag
%   exit;
% end
% 
% if nargout>0, varargout{1} = data; end
% if nargout>1, varargout{2} = spec; end
% if nargout>2, varargout{3} = parms; end