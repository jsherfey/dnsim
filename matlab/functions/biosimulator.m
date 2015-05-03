function [data,t] = biosimulator(model,IC,functions,auxvars,varargin)
parms = mmil_args2parms( varargin, ...
                         {...
                            'timelimits',[0 40],[],...
                            'logfid',1,[],...
                            'dt',.01,[],...
                            'SOLVER','ode23',[],...
                            'nofunctions',0,[],...
                         }, false);
if numel(parms.timelimits)==1, parms.timelimits=[0 parms.timelimits]; end

clear global statedata
tspan = parms.timelimits;
fileID = parms.logfid;
dt = parms.dt;

% evaluate auxiliary variables (ie., adjacency matrices)
for k = 1:size(auxvars,1)
  if parms.nofunctions % will create temporary function below for integration ==> make variables global for temporary function access
    eval(sprintf('global %s',auxvars{k,1}));
  end
  % evaluate variable expressions
  eval( sprintf('%s = %s;',auxvars{k,1},auxvars{k,2}) );
end
% evaluate anonymous functions
for k = 1:size(functions,1)
  eval( sprintf('%s = %s;',functions{k,1},functions{k,2}) );
end

% if parms.nofunctions
%   % write model function
%   odefun = write_odefun(model,auxvars);
%   model = eval(sprintf('@%s',odefun));
% else
  model = eval(model);
% end

fprintf(fileID,'\nSimulation interval: %g-%g\n',tspan);
fprintf(fileID,'Starting integration (%s, dt=%g)\n',parms.SOLVER,dt);
switch lower(parms.SOLVER)
  case {'euler','modifiedeuler','rungekutta','rk','rk4','rk2'}
    tstart = tic;
    T = tspan(1):dt:tspan(2);
    nstep = length(T);
    nreports = 5;
    % preallocate and initialize data matrix
    Y = zeros(length(IC),nstep);
    Y(:,1) = IC;
    enableLog = 1:(nstep-1)/nreports:nstep;
    enableLog(1) = [];
    for k = 2:nstep
      t=T(k-1);
      switch parms.SOLVER
        case 'euler'
          Y(:,k) = Y(:,k-1) + dt*model(t,Y(:,k-1));
        case {'modifiedeuler','rk2'}
          Y(:,k) = Y(:,k-1) + dt*model(t+.5*dt,Y(:,k-1)+.5*dt*model(t,Y(:,k-1)));
        case {'rungekutta','rk','rk4'}
         k1 = model(t,Y(:,k-1));
         k2 = model(t+0.5*dt,Y(:,k-1)+0.5*dt*k1);
         k3 = model(t+0.5*dt,Y(:,k-1)+0.5*dt*k2);
         k4 = model(t+dt,Y(:,k-1)+dt*k3);
         Y(:,k) = Y(:,k-1)+(k1+2*(k2+k3)+k4)*dt/6;
      end
      if any(k == enableLog)
        elapsedTime = toc(tstart);
        elapsedTimeMinutes = floor(elapsedTime/60);
        elapsedTimeSeconds = rem(elapsedTime,60);
        if elapsedTimeMinutes
            fprintf(fileID,'Processed %g of %g ms (elapsed time: %g m %.3f s)\n',T(k),T(end),elapsedTimeMinutes,elapsedTimeSeconds);
        else
            fprintf(fileID,'Processed %g of %g ms (elapsed time: %.3f s)\n',T(k),T(end),elapsedTimeSeconds);
        end
      end
    end
    t = T; clear T
    data = Y'; clear Y
  otherwise % ode23, ode... (any built-in matlab solver)
    [t,data] = feval(parms.SOLVER,model,tspan,IC);
end

% clean up
% if parms.nofunctions
%   % clear global model variables
%   for k = 1:size(auxvars,1)
%     eval('clear global %s',auxvars{k,1});
%   end
%   delete([odefun '.m']);
% end

function odefun = write_odefun(model,auxvars)
odefun = ['odefun_' datestr(now,'yyyymmdd_HHMMSS')];
fid=fopen([odefun '.m'],'wt');
fprintf(fid,'function Y = %s(t,X)\n',odefun);
for i=1:size(auxvars,1)
  fprintf(fid,'global %s\n',auxvars{i,1});
end
fprintf(fid,'Y = zeros(size(X));\n');
% determine how many copies of each state variable
tmp = regexp(model,'X\(\d+:\d+','match','once');
N = length(str2num(strrep(tmp,'X(','')));
% split model into state ODEs
strread(model(9:end-2),'%s','delimiter',';');
cnt = 1;
for i=1:length(eqns)
  fprintf(fid,'Y(%g:%g) = %s;\n',cnt,cnt+N-1,eqns{i});
  cnt = cnt + N;
end
fclose(fid);
% wait for file before continuing to simulation
while ~exist([odefun '.m'],'file')
  pause(.01);
end
fprintf('model written to temporary file: %s.m\n',odefun);


