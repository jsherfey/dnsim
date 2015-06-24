function odefun = dnsimulator(spec,varargin)
parms = mmil_args2parms( varargin, ...
                         {...
                            'timelimits',[0 200],[],...
                            'logfid',1,[],...
                            'dt',.02,[],...
                            'SOLVER','euler',[],...
                            'cluster_flag',0,[],...
                            'coder',0,[],...
                         }, false);
coderprefix = 'pset.p';
% (param struct in odefun).(param var below).(param name in buildmodel)
% ex) pset = param struct in odefun), p = (param var below)

tspan = parms.timelimits;
dt = parms.dt;
fileID = parms.logfid;
solver = parms.SOLVER;

if isfield(spec,'cells'), fld='cells';
elseif isfield(spec,'nodes'), fld='nodes';
elseif isfield(spec,'entities'), fld='entities';
end

model=spec.model.ode;
IC=spec.model.IC;
functions=spec.model.functions;
auxvars=spec.model.auxvars;

T = tspan(1):dt:tspan(2);
nstep = length(T);

% create subdirectory for temporary integrator scripts
subdir = 'odefun';
if ~exist(fullfile(pwd,subdir),'dir')
  mkdir(subdir);
end

% write params.mat if using coder
if exist('codegen') && parms.coder==1
  p=spec.model.parameters; % variable name 'p' must match coderprefix
  if parms.cluster_flag % write params to job-specific subdir
    stck=dbstack;
    subdir2=fullfile(subdir,stck(end).name); % create subdir for this job
    if ~exist(subdir2,'dir')
      mkdir(subdir2);
    end
    save(fullfile(subdir2,'params.mat'),'p');
  else
    save(fullfile(subdir,'params.mat'),'p');
  end
end

% create odefun file that integrates the ODE system
odefun_file = [subdir,'_' datestr(now,'yyyymmdd_HHMMSSFFF') '_' spec.jobnumber];
odefun = [subdir,'/',odefun_file];
fid=fopen([odefun '.m'],'wt');

if ~exist('codegen') || parms.coder == 0 % if matlab coder is not available or you don't want to use it because it does not support your code
  fprintf(fid,'function [Y,T] = %s\n',odefun_file);
  fprintf(fid,'tspan=[%g %g]; dt=%g;\n',tspan,dt);
else % use codegen
  fprintf(fid,'function [Y,T] = odefun\n'); % this is useful to avoid codegen to be called if the mex file is already created
  % load params.mat at start of odefun file
  fprintf(fid,'pset=load(''params.mat'');\n'); % variable name 'pset' must match coderprefix
  fprintf(fid,'tspan=%s.timelimits; dt=%s.dt;\n',coderprefix,coderprefix);
end
fprintf(fid,'T=tspan(1):dt:tspan(2); nstep=length(T);\n');

if ~exist('codegen') || parms.coder == 0 % if matlab coder is not available or you don't want to use it because it does not support your code
  fprintf(fid,'nreports = 5; tmp = 1:(nstep-1)/nreports:nstep; enableLog = tmp(2:end);\n');
end
fprintf(fid,'fprintf(''\\nThe odefun file used is: %s \\n'');\n',odefun_file);
fprintf(fid,'fprintf(''\\nSimulation interval: %%g-%%g\\n'',tspan(1),tspan(2));\n');
fprintf(fid,'fprintf(''Starting integration (%s, dt=%%g)\\n'',dt);\n',solver);

% evaluate auxiliary variables (ie., adjacency matrices)
for k = 1:size(auxvars,1)
  if strncmp(solver,'rk',2)
    dt_scaling_factor = '0.5';
    strParts = regexp(auxvars{k,2},'pset.p.','split')';
    for l = 2:length(strParts)
      strParts{l} = ['pset.p.',strParts{l}];
      if regexp(strParts{l}, '^.+_dt[,)]$')
        prevStr = strParts{l}(1:end-1);
        newStr = regexprep(strParts{l}(1:end-1), '^.+_dt$', [dt_scaling_factor,'*',strParts{l}(1:end-1)]);
        fprintf(fid,'%s = %s; \n',prevStr,newStr);
      end
    end
  end
  fprintf(fid,'%s = %s;\n',auxvars{k,1},auxvars{k,2});
end
%  % evaluate anonymous functions
%  if ~exist('codegen') || parms.coder == 0 % if matlab coder is not available or you don't want to use it because it does not support your code
%    for k = 1:size(functions,1)
%      fprintf(fid,'%s = %s;\n',functions{k,1},functions{k,2});
%    end
%  end

% REPLACE X(#:#) with unique variable names X#
% Set Initial conditions
Npops = [spec.(fld).multiplicity];
EL = {spec.(fld).label};
PopID = 1:length(Npops);
labels = spec.variables.labels;
[ulabels,I] = unique(labels,'stable');
ids = spec.variables.entity;
uids = ids(I);
cnt = 1; ns=zeros(1,length(ulabels));
for k = 1:length(ulabels)
  varinds = find(strcmp(ulabels{k},labels));
  n = length(varinds); % # cells in the pop with this var   % Npops(ids(varinds(1))==PopID);
  ns(k)=n;
%   if ~exist('codegen') || parms.coder==0
    fprintf(fid,'%s = zeros(%g,nstep);\n',ulabels{k},n);
%   else
%     fprintf(fid,'coder.varsize(''%s'');\n',ulabels{k});
%     fprintf(fid,'%s = zeros(length(%s.%s),nstep);\n',ulabels{k},coderprefix,['IC_' ulabels{k}]);
%   end
  old = sprintf('X(%g:%g)',cnt,cnt+n-1);
  if n>1
    new = sprintf('%s(:,k-1)',ulabels{k});
    if ~exist('codegen') || parms.coder==0
      fprintf(fid,'%s(:,1) = [%s];\n',ulabels{k},num2str(IC(varinds)'));
    else
      fprintf(fid,'%s(:,1) = %s.%s;\n',ulabels{k},coderprefix,['IC_' ulabels{k}]);
    end
  else
    new = sprintf('%s(k-1)',ulabels{k});
    if ~exist('codegen') || parms.coder==0
      fprintf(fid,'%s(1) = [%s];\n',ulabels{k},num2str(IC(varinds)'));
    else
      fprintf(fid,'%s(1) = %s.%s;\n',ulabels{k},coderprefix,['IC_' ulabels{k}]);
    end
  end
  model = strrep(model,old,new);
  cnt = cnt + n;
end

% split model into state ODEs
odes = strread(model(9:end-2),'%s','delimiter',';');

% Integrate
if ~exist('codegen') || parms.coder == 0 % if matlab coder is not available or you don't want to use it because it does not support your code
  fprintf(fid,'tstart = tic;\n');
end
switch solver
  case 'euler'
    fprintf(fid,'for k=2:nstep\n');
    fprintf(fid,'  t=T(k-1);\n');
    for i=1:length(odes)
      fprintf(fid,'  F=%s;\n',odes{i});
      if ns(i)>1
        fprintf(fid,'  %s(:,k) = %s(:,k-1) + dt*F;\n',ulabels{i},ulabels{i});
      else
        fprintf(fid,'  %s(k) = %s(k-1) + dt*F;\n',ulabels{i},ulabels{i});
      end
    end
    if ~exist('codegen') || parms.coder == 0 % if matlab coder is not available or you don't want to use it because it does not support your code
      enableLog(fid);
    end
    fprintf(fid,'end\n');
  case {'rk2','modifiedeuler'}
    fprintf(fid,'for k=2:nstep\n');
    tmpodes=odes;
    fprintf(fid,'  t=T(k-1);\n');
    for i=1:length(odes)
      fprintf(fid,'  %s1=%s;\n',ulabels{i},odes{i});
      for j=1:length(ulabels)
        if ns(j)>1
          tmpodes{i}=strrep(tmpodes{i},[ulabels{j} '(:,k-1)'],sprintf('(%s(:,k-1)+.5*dt*%s1)',ulabels{j},ulabels{j}));
        else
          tmpodes{i}=strrep(tmpodes{i},[ulabels{j} '(k-1)'],sprintf('(%s(k-1)+.5*dt*%s1)',ulabels{j},ulabels{j}));
        end
      end
    end
    fprintf(fid,'  t=t+0.5*dt;\n');
    for i=1:length(odes)
      fprintf(fid,'  %s2=%s;\n',ulabels{i},tmpodes{i});
    end
    for i=1:length(odes)
      if ns(i)>1
        fprintf(fid,'  %s(:,k) = %s(:,k-1) + dt*%s2;\n',ulabels{i},ulabels{i},ulabels{i});
      else
        fprintf(fid,'  %s(k) = %s(k-1) + dt*%s2;\n',ulabels{i},ulabels{i},ulabels{i});
      end
    end
    if ~exist('codegen') || parms.coder == 0 % if matlab coder is not available or you don't want to use it because it does not support your code
      enableLog(fid);
    end
    fprintf(fid,'end\n');
  case  {'rk4','rungekutta','rk'}
    fprintf(fid,'for k=2:nstep\n');
    tmpodes1=odes;
    tmpodes2=odes;
    tmpodes3=odes;
    fprintf(fid,'  t=T(k-1);\n');
    for i=1:length(odes)
      % set k1
      fprintf(fid,'  %s1=%s;\n',ulabels{i},odes{i});
      % set k2
      for j=1:length(ulabels)
        if ns(j)>1
          tmpodes1{i}=strrep(tmpodes1{i},[ulabels{j} '(:,k-1)'],sprintf('(%s(:,k-1)+.5*dt*%s1)',ulabels{j},ulabels{j}));
        else
          tmpodes1{i}=strrep(tmpodes1{i},[ulabels{j} '(k-1)'],sprintf('(%s(k-1)+.5*dt*%s1)',ulabels{j},ulabels{j}));
        end
      end
    end
    fprintf(fid,'  t=t+0.5*dt;\n');
    for i=1:length(odes)
      fprintf(fid,'  %s2=%s;\n',ulabels{i},tmpodes1{i});
      % set k3
      for j=1:length(ulabels)
        if ns(j)>1
          tmpodes2{i}=strrep(tmpodes2{i},[ulabels{j} '(:,k-1)'],sprintf('(%s(:,k-1)+.5*dt*%s2)',ulabels{j},ulabels{j}));
        else
          tmpodes2{i}=strrep(tmpodes2{i},[ulabels{j} '(k-1)'],sprintf('(%s(k-1)+.5*dt*%s2)',ulabels{j},ulabels{j}));
        end
      end
    end
    for i=1:length(odes)
      fprintf(fid,'  %s3=%s;\n',ulabels{i},tmpodes2{i});
      % set k4
      for j=1:length(ulabels)
        if ns(j)>1
          tmpodes3{i}=strrep(tmpodes3{i},[ulabels{j} '(:,k-1)'],sprintf('(%s(:,k-1)+dt*%s3)',ulabels{j},ulabels{j}));
        else
          tmpodes3{i}=strrep(tmpodes3{i},[ulabels{j} '(k-1)'],sprintf('(%s(k-1)+dt*%s3)',ulabels{j},ulabels{j}));
        end
      end
    end
    fprintf(fid,'  t=t+0.5*dt;\n');
    for i=1:length(odes)
      fprintf(fid,'  %s4=%s;\n',ulabels{i},tmpodes3{i});
    end
    for i=1:length(odes)
      if ns(i)>1
        fprintf(fid,'  %s(:,k) = %s(:,k-1) + (dt/6)*(%s1+2*(%s2+%s3)+%s4);\n',ulabels{i},ulabels{i},ulabels{i},ulabels{i},ulabels{i},ulabels{i});
      else
        fprintf(fid,'  %s(k) = %s(k-1) + (dt/6)*(%s1+2*(%s2+%s3)+%s4);\n',ulabels{i},ulabels{i},ulabels{i},ulabels{i},ulabels{i},ulabels{i});
      end
    end
    if ~exist('codegen') || parms.coder == 0 % if matlab coder is not available or you don't want to use it because it does not support your code
      enableLog(fid);
    end
    fprintf(fid,'end\n');
end

% COMBINE UNIQUE VARIABLE NAMES INTO ONE DATA MATRIX
fprintf(fid,'Y=cat(1');
for i=1:length(ulabels)
  fprintf(fid,',%s',ulabels{i});
end
fprintf(fid,')'';\n');
fclose(fid);

% wait for file before continuing to simulation
while ~exist([odefun '.m'],'file')
  pause(.01);
end
%fprintf('model written to: %s.m\n',odefun);
%{
fprintf('running simulation...\n');
eval(sprintf('[data,t]=%s;',odefun));
%}
