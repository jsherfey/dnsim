function [data,t] = biosimulator(model,IC,functions,auxvars,varargin)
parms = mmil_args2parms( varargin, ...
                         {...
                            'timelimits',[0 40],[],...
                            'logfid',1,[],...
                            'dt',.01,[],...
                            'SOLVER','ode23',[],...
                            'RELTOL',1e-3,[],...
                            'ABSTOL',1e-6,[],...
                            'MAXINTSTEP',9e-4,[],...
                         }, false);
if numel(parms.timelimits)==1, parms.timelimits=[0 parms.timelimits]; end

clear global statedata
timelimits = parms.timelimits;
fileID = parms.logfid;
dt = parms.dt;

% evaluate auxiliary variables (ie., adjacency matrices)
for k = 1:size(auxvars,1)
  try % TEMPORARY TRY STATEMENT (also in biosim() at line 73)
      % added to catch mask=mask-diag(diag(mask)) when mask is not square
      % WARNING: this is a dangerous TRY statement that should be removed!
    eval( sprintf('%s = %s;',auxvars{k,1},auxvars{k,2}) );
  end
end
% evaluate anonymous functions
for k = 1:size(functions,1)
  eval( sprintf('%s = %s;',functions{k,1},functions{k,2}) );
end
model = eval(model);

fprintf(fileID,'\nSimulation time: %g-%g ms\n',timelimits);
switch lower(parms.SOLVER)
  case 'euler'
    tstart = tic;
    fprintf(fileID,'Starting integration (Euler Integration) ...\n');
    nvars = length(IC);
    tmin  = timelimits(1);
    tmax  = timelimits(2);
    tvec  = tmin:dt:tmax;
    nstep = length(tvec);
    nreports  = 10;
    cntreport = 1;
    % Euler integration
    Y = zeros(nstep,nvars);
    T = zeros(nstep,1);
    Y(1,:) = IC';
    t = tmin;
    h = dt;
    for k = 2:nstep
      if rem(k,round(nstep/nreports))==0
        fprintf(fileID,'Processing %g of %gms (report %g of %g at %g min)\n',t,tmax,cntreport,nreports,toc(tstart)/60);
        cntreport = cntreport + 1;
      end
      Y(k,:) = Y(k-1,:) + dt*model(t,Y(k-1,:)')';
      T(k,1) = T(k-1,1) + dt;
      t = t + dt;
    end
    t = T; clear T
    data = Y; clear Y %X = Y; clear Y              
  case 'ode23'
    [t,data] = ode23(model,timelimits,IC);
  otherwise
    [t,data] = feval(parms.SOLVER,model,timelimits,IC);
end
    



