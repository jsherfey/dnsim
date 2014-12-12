function odefun = dnsimulator(spec,varargin)
parms = mmil_args2parms( varargin, ...
                         {...
                            'timelimits',[0 200],[],...
                            'dt',.02,[],...
                            'SOLVER','euler',[],...
                         }, false);

tspan = parms.timelimits;
dt = parms.dt;
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

odefun = ['odefun_' datestr(now,'yyyymmdd_HHMMSS')];
fid=fopen([odefun '.m'],'wt');
fprintf(fid,'function [Y,T] = %s\n',odefun);
fprintf(fid,'tspan=[%g %g]; dt=%g;\n',tspan,dt);
fprintf(fid,'T=tspan(1):dt:tspan(2); nstep=length(T);\n');
fprintf(fid,'fprintf(''\\nSimulation interval: %%g-%%g\\n'',tspan);');
fprintf(fid,'fprintf(''Starting integration (%s, dt=%%g)\\n'',dt);',solver);

% evaluate auxiliary variables (ie., adjacency matrices)
for k = 1:size(auxvars,1)
  fprintf(fid,'%s = %s;\n',auxvars{k,1},auxvars{k,2});
end
% evaluate anonymous functions
for k = 1:size(functions,1)
  fprintf(fid,'%s = %s;\n',functions{k,1},functions{k,2});
end

% REPLACE X(#:#) with unique variable names X# and initialize
Npops = [spec.(fld).multiplicity];
PopID = 1:length(Npops);
labels = spec.variables.labels;
ulabels = unique(labels,'stable');
ids = spec.variables.entity;
cnt = 1; ns=zeros(1,length(ulabels));
for k = 1:length(ulabels)
  varinds = find(strcmp(ulabels{k},labels));
  n = length(varinds); %Npops(ids(varinds(1))==PopID);
  ns(k)=n;
  fprintf(fid,'%s = zeros(%g,nstep);\n',ulabels{k},n);
  old = sprintf('X(%g:%g)',cnt,cnt+n-1);
  if n>1
    new = sprintf('%s(:,k-1)',ulabels{k});
    fprintf(fid,'%s(:,1) = [%s];\n',ulabels{k},num2str(IC(varinds)'));
  else
    new = sprintf('%s(k-1)',ulabels{k});
    fprintf(fid,'%s(1) = [%s];\n',ulabels{k},num2str(IC(varinds)'));
  end
  model = strrep(model,old,new);
  cnt = cnt + n;
end

% split model into state ODEs
odes = splitstr(model(9:end-2),';');

% Integrate
switch solver
  case 'euler'
    fprintf(fid,'for k=2:nstep\n');
    fprintf(fid,'\tt=T(k-1);\n');
    for i=1:length(odes)
      fprintf(fid,'\tF=%s;\n',odes{i});
      if ns(i)>1
        fprintf(fid,'\t%s(:,k) = %s(:,k-1) + dt*F;\n',ulabels{i},ulabels{i});
      else
        fprintf(fid,'\t%s(k) = %s(k-1) + dt*F;\n',ulabels{i},ulabels{i});
      end
    end
    fprintf(fid,'end\n');    
  case {'rk2','modifiedeuler'}
    fprintf(fid,'for k=2:nstep\n');
    tmpodes=odes;
    for i=1:length(odes)
      fprintf(fid,'\tt=T(k-1);\n');
      fprintf(fid,'\t%s1=%s;\n',ulabels{i},odes{i});
      for j=1:length(ulabels)
        if ns(j)>1
          tmpodes{i}=strrep(tmpodes{i},[ulabels{j} '(:,k-1)'],sprintf('(%s(:,k-1)+.5*dt*%s1)',ulabels{j},ulabels{j}));
        else
          tmpodes{i}=strrep(tmpodes{i},[ulabels{j} '(k-1)'],sprintf('(%s(k-1)+.5*dt*%s1)',ulabels{j},ulabels{j}));
        end
      end
    end
    for i=1:length(odes)
      fprintf(fid,'\tt=T(k-1)+.5*dt;\n');
      fprintf(fid,'\t%s2=%s;\n',ulabels{i},tmpodes{i});
    end
    for i=1:length(odes)
      if ns(i)>1
        fprintf(fid,'\t%s(:,k) = %s(:,k-1) + dt*%s2;\n',ulabels{i},ulabels{i},ulabels{i});
      else
        fprintf(fid,'\t%s(k) = %s(k-1) + dt*%s2;\n',ulabels{i},ulabels{i},ulabels{i});
      end
    end
    fprintf(fid,'end\n');    
  case 'rk4'
    % ...
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
delete([odefun '.m']);
%}
