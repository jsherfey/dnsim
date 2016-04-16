function [allspecs,timestamp,rootoutdir] = simstudy(spec,scope,variable,values,varargin)
% allspecs = simstudy(spec,scope,variable,values)
% allspecs = get_search_space(net,'E','multiplicity','[10:10:50]','sim_cluster','scc1.bu.edu');
% allspecs = get_search_space(net,{'{E,I}','E'},{'mechanisms','multiplicity'},{'{iNa,iK,ileak}','[10 20 30]'})

% Load spec
if ischar(spec) % this is a path to specification files
  if exist(spec,'dir')
    spec = loadspec(spec);
  else
    error('specification not find.');
  end
end

% parameters
spec.simulation = mmil_args2parms( varargin, ...
                   {  'logfid',1,[],...
                      'logfile',[],[],...
                      'sim_cluster_flag',[],[],...
                      'cluster_flag',0,[],...
                      'sim_cluster','scc2.bu.edu',[],...
                      'sim_qsubscript','qmatjobs_memlimit',[],...
                      'sim_driver','biosimdriver.m',[],...
                      'description',[],[],...
                      'dt',.01,[],...
                      'SOLVER','euler',[],...
                      'memlimit','8G',[],...
                      'batchdir',[],[],...
                      'rootdir',pwd,[],...
                      'override',[],[],...
                      'timelimits',[],[],...
                      'dsfact',[],[],...
                      'timestamp',datestr(now,'yyyymmdd-HHMMSS'),[],...
                      'savedata_flag',0,[],...
                      'jsondata_flag',0,[],...
                      'savepopavg_flag',0,[],...
                      'savespikes_flag',0,[],...
                      'saveplot_flag',0,[],...
                      'plotvars_flag',1,[],...
                      'plotrates_flag',0,[],...
                      'plotpower_flag',0,[],...
                      'plotpacoupling_flag',0,[],...
                      'overwrite_flag',0,[],...
                      'addpath',[],[],...
                      'coder',0,[],...
                      'sims_per_job',1,[],...
                      'timesurfer_flag',1,[],...
                   }, false);

% coder (0 or 1): whether to compile sim and run mex
% sims_per_job (integer): # sims per job

if ~isempty(spec.simulation.sim_cluster_flag) % for backwards-compatibility
  spec.simulation.cluster_flag=spec.simulation.sim_cluster_flag;
end

if spec.simulation.coder==1
  if ~exist('codegen')
    fprintf('codegen not found. will run m-file simulation.\n');
    spec.simulation.coder=0;
  else
    cwd=pwd;
    try
      % create MEX file
      tmpparms=spec.simulation;
      tmpparms.cluster_flag=0; % set to 0 b/c job-specific params.mat should be created from the compute node
      args = mmil_parms2args(tmpparms);
      spec = buildmodel(spec,args{:});
      file = dnsimulator(spec,args{:}); % saved to odefun/odefun_timestamp.m
      [odefun_subdir,file]=fileparts(file);
      cd(odefun_subdir);
      tic
      codegen_odefun(file);
      toc
      filemex = fullfile(odefun_subdir,[file,'_mex.mexa64']);
      mfile = fullfile(odefun_subdir,[file '.m']);
      cd(cwd);
    catch err
      fprintf('Error: %s\n',err.message);
      for i=1:length(err.stack)
        fprintf('\t in %s (line %g)\n',err.stack(i).name,err.stack(i).line);
      end
      fprintf('Re-run simstudy() with "coder" set to 0\n');
      cd(cwd);
      return
    end
    % (below: copy mex and odefun.m to [batchdir]/odefun)
  end
end

if ischar(scope), scope={scope}; end
if ischar(variable), scope={variable}; end
% get search space
spec.simulation.scope = scope;
spec.simulation.variable = variable;
spec.simulation.values = values;
%if (isequal(variable,'mechanisms') || (iscell(variable) && isequal(variable{1},'mechanisms'))) && (isequal(values,'-1') || (iscell(values) && isequal(values{1},'-1')))
if (iscell(variable) && isequal(variable{1},'mechanisms')) && ((iscell(values) && isequal(values{1},'-1')))
  scope=scope{1};
  scope=strrep(scope,'(','');
  scope=strrep(scope,')','');
  if ~isempty(scope)
    scope=strread(scope,'%s','delimiter',',');
  end
  allspecs = get_leaveoneout_space(spec,scope);
else
  allspecs = get_search_space(spec);
end

timestamp = spec.simulation.timestamp;
p=spec.simulation;
plot_flag = p.plotvars_flag || p.plotrates_flag || p.plotpower_flag || p.plotpacoupling_flag; % whether to plot anything at all
save_flag = p.savedata_flag || p.jsondata_flag || p.savepopavg_flag || p.savespikes_flag || (p.saveplot_flag && plot_flag); % whether to save anything at all

% log file
logfile=spec.simulation.logfile;
logfid=spec.simulation.logfid;
if ischar(logfile) && ~isempty(logfile), logfid = fopen(logfile,'w'); else logfid = 1; end

% define output directory structure
scopes = cellfun(@(x)x.simulation.scope,allspecs,'uni',0);
vars = cellfun(@(x)x.simulation.variable,allspecs,'uni',0);
vals = cellfun(@(x)x.simulation.values,allspecs,'uni',0);
uniqscopes = unique(scopes);
outdirs={}; dirinds=zeros(size(allspecs));
for k=1:length(uniqscopes)
  scopeparts = regexp(uniqscopes{k},'[^\(\)]*','match');
  uniqscopeparts = unique(scopeparts);
  specind = find(strcmp(uniqscopes{k},scopes));
  varparts = regexp(vars{specind(1)},'[^\(\)]*','match');
  dirname = '';
  for j=1:length(uniqscopeparts)
    selind = find(strcmp(uniqscopeparts{j},scopeparts));
    dirname = [dirname '__' strrep(uniqscopeparts{j},',','+')];
    for i=1:length(selind)
      dirname = [dirname '-' strrep(varparts{selind(i)},'_','')];
    end
  end
  outdirs{end+1} = dirname(3:end);
  dirinds(specind)=k;
end

rootoutdir={}; prefix={};
for i=1:length(allspecs)
  % removed timestamp dir from path on 22-Oct-2014
  %rootoutdir{i} = fullfile(spec.simulation.rootdir,timestamp,outdirs{dirinds(i)});
  %rootoutdir{i} = fullfile(spec.simulation.rootdir,outdirs{dirinds(i)});
  rootoutdir{i} = fullfile(spec.simulation.rootdir,outdirs{dirinds(i)},datestr(now,'yyyymmdd'));
  try
    scopeparts=regexp(allspecs{i}.simulation.scope,'[^\(\)]*','match');
    varparts = regexp(allspecs{i}.simulation.variable,'[^\(\)]*','match');
    valparts = regexp(allspecs{i}.simulation.values,'[^\(\)]*','match');
    uniqscopeparts = unique(scopeparts);
    pname='';
    for j=1:length(uniqscopeparts)
      selind = find(strcmp(uniqscopeparts{j},scopeparts));
      pname = [pname '__' strrep(uniqscopeparts{j},',','+')];
      for k=1:length(selind)
        pname = [pname '-' strrep(varparts{selind(k)},'_','') strrep(valparts{selind(k)},'.','pt')];
      end
    end
    prefix{i}=sprintf('job%4.4i_%s',i,pname(3:end));
  catch
    tmp=regexp(allspecs{i}.simulation.description,'[^\d_].*','match');
    prefix{i}=sprintf('job%4.4i_%s',i,strrep([tmp{:}],',','_'));
  end
  if ~isempty(spec.simulation.timelimits)
    prefix{i}=sprintf('%s_time%g-%g',prefix{i},spec.simulation.timelimits);
  end
  if save_flag
    fprintf(logfid,'%s: %s\n',rootoutdir{i},prefix{i});
  end
end
% save allspecs(i) results in rootoutdir{i}

% system info
[o,host]=system('echo $HOSTNAME');
[o,home]=system('echo $HOME');
home=home(1:end-1); % remove new line character
cwd = pwd;

if spec.simulation.cluster_flag % run on cluster
  % create batchdir
  if isempty(spec.simulation.batchdir)
    batchname = ['B' timestamp];
    batchdir = sprintf('%s/batchdirs/%s',home,batchname);
    spec.simulation.batchdir=batchdir;
  else
    [fp,batchname]=fileparts(spec.simulation.batchdir);
    batchdir = spec.simulation.batchdir;
  end
  mkdir(batchdir);
  cd(batchdir);
  driverscript = which(spec.simulation.sim_driver);
  [fpath,scriptname,fext] = fileparts(driverscript);
  %allfiles = {driverscript spec.files{:}};
  %for i = 1:length(allfiles)
  %  unix(sprintf('cp %s .',allfiles{i}));
  %end
  % create jobs
  jobs={};
  auxcmd = 'clear all; ';
  if ischar(p.addpath)
    auxcmd=sprintf('addpath(genpath(''%s'')); ',p.addpath);
  end
  auxcmd = [auxcmd 'try rng(''shuffle''); end; '];
  for k=1:length(allspecs)
    if spec.simulation.coder==1
      subdir = fullfile(batchdir,odefun_subdir,['job' num2str(k)]);
      auxcmd2 = [auxcmd sprintf('addpath(''%s''); ',subdir)];
      mkdir(subdir);
    else
      auxcmd2 = auxcmd;
    end
    modelspec=allspecs{k};
    modelspec.jobnumber = sprintf('job%4.4i',k);
    specfile = sprintf('spec%g.mat',k);
    save(specfile,'modelspec');
    jobs{end+1} = sprintf('job%g.m',k);
    fileID = fopen(jobs{end},'wt');

    fprintf(fileID,'%sload(''%s'',''modelspec''); %s(modelspec,''rootoutdir'',''%s'',''prefix'',''%s'',''cluster_flag'',1,''batchdir'',''%s'',''jobname'',''%s'',''savedata_flag'',%g,''jsondata_flag'',%g,''savepopavg_flag'',%g,''savespikes_flag'',%g,''saveplot_flag'',%g,''plotvars_flag'',%g,''plotrates_flag'',%g,''plotpower_flag'',%g,''plotpacoupling_flag'',%g,''overwrite_flag'',%g,''timesurfer_flag'',%g);\n',auxcmd,specfile,scriptname,rootoutdir{k},prefix{k},batchdir,jobs{end},p.savedata_flag,p.jsondata_flag,p.savepopavg_flag,p.savespikes_flag,p.saveplot_flag,p.plotvars_flag,p.plotrates_flag,p.plotpower_flag,p.plotpacoupling_flag,p.overwrite_flag,p.timesurfer_flag);
    if spec.simulation.sims_per_job==1
      fprintf(fileID,'exit\n');
    end
    fclose(fileID);
  end
  if spec.simulation.coder==1
    % copy mex and m files to batchdir/odefun_subdir
    [status,result]=system(sprintf('cp %s %s',fullfile(cwd,filemex),fullfile(batchdir,filemex)));
    if status, disp(result); return; end % if error occurred
    [status,result]=system(sprintf('cp %s %s',fullfile(cwd,mfile),fullfile(batchdir,mfile)));
    if status, disp(result); return; end % if error occurred
  end
  if spec.simulation.sims_per_job>1
    % create jobs grouping several simulation scripts
    jobs={};
    nperjob=spec.simulation.sims_per_job;
    nsims=length(allspecs);
    njobs=ceil(nsims/nperjob);
    cnt=0;
    for k=1:njobs
      jobs{end+1}=sprintf('jobs%g.m',k);
      fileID=fopen(jobs{end},'wt');
      if spec.simulation.coder==1
        subdir = fullfile(batchdir,odefun_subdir,['jobs' num2str(k)]);
        fprintf(fileID,'addpath %s\n',subdir);
        mkdir(subdir);
      end
      for i=1:nperjob
        if (cnt+i)>nsims
          break;
        end
        fprintf(fileID,'job%g;\n',cnt+i);
      end
      cnt=cnt+nperjob;
      fprintf(fileID,'exit\n');
      fclose(fileID);
    end
  end
  % create scriptlist.txt (list of jobs)
  fileID = fopen('scriptlist.txt', 'wt');
  for i = 1:length(jobs)
    [a,this] = fileparts(jobs{i});
    fprintf(fileID,'%s\n',this);
  end
  fclose(fileID);
  % submit the jobs
  cmd = sprintf('%s %s %s',spec.simulation.sim_qsubscript,batchname,spec.simulation.memlimit);
  fprintf(logfid,'executing: "%s" on cluster %s\n',cmd,spec.simulation.sim_cluster);
  if ~strmatch(host,spec.simulation.sim_cluster);
    % connect to cluster and submit jobs
  else
    % submit jobs on the current host
    [s,m] = system(cmd);
  end
  % log errors
  if s, fprintf(logfid,'%s',m); end
  if spec.simulation.sims_per_job==1
    fprintf(logfid,'%g jobs submitted.\n',length(jobs));
  else
    fprintf(logfid,'%g jobs submitted (%g simulations).\n',length(jobs),length(allspecs));
  end
else
  % run on local machine
  for specnum = 1:length(allspecs) % loop over elements of search space
    modelspec = allspecs{specnum};
    modelspec.jobnumber = sprintf('job%4.4i',1);
    fprintf(logfid,'processing simulation...');
    try
      biosimdriver(modelspec,'rootoutdir',rootoutdir{specnum},'prefix',prefix{specnum},'verbose',1,...
       'savedata_flag',p.savedata_flag,'jsondata_flag',p.jsondata_flag,'savepopavg_flag',p.savepopavg_flag,'savespikes_flag',p.savespikes_flag,...
       'saveplot_flag',p.saveplot_flag,'plotvars_flag',p.plotvars_flag,'plotrates_flag',p.plotrates_flag,'plotpower_flag',p.plotpower_flag,...
       'plotpacoupling_flag',p.plotpacoupling_flag,'overwrite_flag',p.overwrite_flag,'timesurfer_flag',p.timesurfer_flag);
    catch err
      fprintf('Error: %s\n',err.message);
      for i=1:length(err.stack)
        fprintf('\t in %s (line %g)\n',err.stack(i).name,err.stack(i).line);
      end
    end
    fprintf(logfid,'done (%g of %g)\n',specnum,length(allspecs));
  end
end
cd(cwd);
end % end main function
