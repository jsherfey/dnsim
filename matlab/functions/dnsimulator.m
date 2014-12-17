function odefun = dnsimulator(spec,varargin)
parms = mmil_args2parms( varargin, ...
                         {...
                            'timelimits',[0 200],[],...
                            'logfid',1,[],...
                            'dt',.02,[],...
                            'SOLVER','euler',[],...
                         }, false);

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

odefun = ['odefun_' datestr(now,'yyyymmdd_HHMMSS')];
fid=fopen([odefun '.m'],'wt');
fprintf(fid,'function [Y,T] = %s\n',odefun);
fprintf(fid,'tspan=[%g %g]; dt=%g;\n',tspan,dt);
fprintf(fid,'T=tspan(1):dt:tspan(2); nstep=length(T);\n');
if ischar(fileID)
  fprintf(fid,'fileID = %s; nreports = 5; enableLog = 1:(nstep-1)/nreports:nstep;enableLog(1) = [];\n',fileID);
else
  fprintf(fid,'fileID = %d; nreports = 5; enableLog = 1:(nstep-1)/nreports:nstep;enableLog(1) = [];\n',fileID);
end
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
fprintf(fid,'tstart = tic;\n');
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
    fprintf(fid,'  if any(k == enableLog)\n');
    fprintf(fid,'    elapsedTime = toc(tstart);\n');
    fprintf(fid,'    elapsedTimeMinutes = floor(elapsedTime/60);\n');
    fprintf(fid,'    elapsedTimeSeconds = rem(elapsedTime,60);\n');
    fprintf(fid,'    if elapsedTimeMinutes\n');
    logMS = 'Processed %g of %g ms (elapsed time: %g m %.3f s)\n';
    logS = 'Processed %g of %g ms (elapsed time: %.3f s)\n';
    fprintf(fid,'        fprintf(fileID,''%s'',T(k),T(end),elapsedTimeMinutes,elapsedTimeSeconds);\n',logMS);
    fprintf(fid,'    else\n');
    fprintf(fid,'        fprintf(fileID,''%s'',T(k),T(end),elapsedTimeSeconds);\n',logS);
    fprintf(fid,'    end\n');
    fprintf(fid,'  end\n');    
    fprintf(fid,'end\n');    
  case {'rk2','modifiedeuler'}
    fprintf(fid,'for k=2:nstep\n');
    tmpodes=odes;
    for i=1:length(odes)
      fprintf(fid,'  t=T(k-1);\n');
      fprintf(fid,'  %s1=%s;\n',ulabels{i},odes{i});
      for j=1:length(ulabels)
        if ns(j)>1
          tmpodes{i}=strrep(tmpodes{i},[ulabels{j} '(:,k-1)'],sprintf('(%s(:,k-1)+.5*dt*%s1)',ulabels{j},ulabels{j}));
        else
          tmpodes{i}=strrep(tmpodes{i},[ulabels{j} '(k-1)'],sprintf('(%s(k-1)+.5*dt*%s1)',ulabels{j},ulabels{j}));
        end
      end
    end
    for i=1:length(odes)
      fprintf(fid,'  t=T(k-1)+.5*dt;\n');
      fprintf(fid,'  %s2=%s;\n',ulabels{i},tmpodes{i});
    end
    for i=1:length(odes)
      if ns(i)>1
        fprintf(fid,'  %s(:,k) = %s(:,k-1) + dt*%s2;\n',ulabels{i},ulabels{i},ulabels{i});
      else
        fprintf(fid,'  %s(k) = %s(k-1) + dt*%s2;\n',ulabels{i},ulabels{i},ulabels{i});
      end
    end
    fprintf(fid,'  if any(k == enableLog)\n');
    fprintf(fid,'    elapsedTime = toc(tstart);\n');
    fprintf(fid,'    elapsedTimeMinutes = floor(elapsedTime/60);\n');
    fprintf(fid,'    elapsedTimeSeconds = rem(elapsedTime,60);\n');
    fprintf(fid,'    if elapsedTimeMinutes\n');
    logMS = 'Processed %g of %g ms (elapsed time: %g m %.3f s)\n';
    logS = 'Processed %g of %g ms (elapsed time: %.3f s)\n';
    fprintf(fid,'        fprintf(fileID,''%s'',T(k),T(end),elapsedTimeMinutes,elapsedTimeSeconds);\n',logMS);
    fprintf(fid,'    else\n');
    fprintf(fid,'        fprintf(fileID,''%s'',T(k),T(end),elapsedTimeSeconds);\n',logS);
    fprintf(fid,'    end\n');
    fprintf(fid,'  end\n');    
    fprintf(fid,'end\n');    
%           k1 = model(t,Y(:,k-1));
%           k2 = model(t+.5*dt,Y(:,k-1)+0.5*dt*k1)
%           Y(:,k) = Y(:,k-1) + dt*k2;
  case {'rk4','rungekutta','rk'}
    fprintf(fid,'for k=2:nstep\n');
    tmpodes1=odes;
    tmpodes2=odes;
    tmpodes3=odes;
    for i=1:length(odes)
      fprintf(fid,'  t=T(k-1);\n');
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
    for i=1:length(odes)
      fprintf(fid,'  t=T(k-1)+.5*dt;\n');
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
      fprintf(fid,'  t=T(k-1)+.5*dt;\n');
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
    for i=1:length(odes)
      fprintf(fid,'  t=T(k-1)+dt;\n');
      fprintf(fid,'  %s4=%s;\n',ulabels{i},tmpodes3{i});
    end
    for i=1:length(odes)
      if ns(i)>1
        fprintf(fid,'  %s(:,k) = %s(:,k-1) + (dt/6)*(%s1+2*(%s2+%s3)+%s4);\n',ulabels{i},ulabels{i},ulabels{i},ulabels{i},ulabels{i},ulabels{i});
      else
        fprintf(fid,'  %s(k) = %s(k-1) + (dt/6)*(%s1+2*(%s2+%s3)+%s4);\n',ulabels{i},ulabels{i},ulabels{i},ulabels{i},ulabels{i},ulabels{i});
      end
    end    
    fprintf(fid,'  if any(k == enableLog)\n');
    fprintf(fid,'    elapsedTime = toc(tstart);\n');
    fprintf(fid,'    elapsedTimeMinutes = floor(elapsedTime/60);\n');
    fprintf(fid,'    elapsedTimeSeconds = rem(elapsedTime,60);\n');
    fprintf(fid,'    if elapsedTimeMinutes\n');
    logMS = 'Processed %g of %g ms (elapsed time: %g m %.3f s)\n';
    logS = 'Processed %g of %g ms (elapsed time: %.3f s)\n';
    fprintf(fid,'        fprintf(fileID,''%s'',T(k),T(end),elapsedTimeMinutes,elapsedTimeSeconds);\n',logMS);
    fprintf(fid,'    else\n');
    fprintf(fid,'        fprintf(fileID,''%s'',T(k),T(end),elapsedTimeSeconds);\n',logS);
    fprintf(fid,'    end\n');
    fprintf(fid,'  end\n');    
    fprintf(fid,'end\n');        
%          k1 = model(t,Y(:,k-1)); 
%          k2 = model(t+0.5*dt,Y(:,k-1)+0.5*dt*k1);
%          k3 = model(t+0.5*dt,Y(:,k-1)+0.5*dt*k2);
%          k4 = model(t+dt,Y(:,k-1)+dt*k3);   
%          Y(:,k) = Y(:,k-1)+(k1+2*(k2+k3)+k4)*dt/6;
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
