function xpp = dnsim2xpp(spec,outfile)
% Purpose: generate xppaut code from a DNSim specification
% Created 02-Dec-0214 by JSS 
% Inputs:
%   spec = DNSim specification (eg, from dnsim GUI or infinitebrain.org)
%   outfile (optional) = ode filename to write xppaut model
% Outputs:
%   xpp = string containing xppaut model
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Standardize DNSim spec structure for backwards-compatibility
if ~isfield(spec,'model')
  spec = dnsim(spec);
end
spec = standardize(spec);

% Number of nodes and mechanisms in the model
numnodes = numel(spec.nodes);
nummechs = sum(arrayfun(@(x)numel(x.mechanisms),spec.nodes)) + ...
           sum(arrayfun(@(x)numel(x.mechanisms),spec.connections));

% How to preserve parameter/variable scopes / namespaces
if numnodes>1
  prefixflag = 2; % add node and mechanism prefixes
elseif nummechs>1
  prefixflag = 1; % add mechanism prefixes only
else
  prefixflag = 0; % add no prefixes
end

% Re-organize model data for xpp conversion
[odes,ics,functions,parameters] = collectdata(spec,prefixflag);

% Convert model to xpp format
xpp='';
% ODEs and ICs
for i=1:length(odes)
  xpp = sprintf('%s%s\n',xpp,odes{i});
  xpp = sprintf('%s%s\n',xpp,ics{i});
end
xpp=sprintf('%s\n\t# where\n',xpp);
% State functions
for i=1:length(functions)
  xpp = sprintf('%s%s\n',xpp,parameters{i});
end
xpp = sprintf('%s\n',xpp);
% Parameters
for i=1:length(parameters)
  xpp = sprintf('%sparam %s\n',xpp,parameters{i});
end
% Common parameters and simulation controls 
% ... (xpp = ...) (add Npop, Npre, Npost, dt, tspan, ...)
% Finish
xpp = sprintf('%s\ndone',xpp);

% Write xpp ode file
if nargin>1
  fid = fopen(outfile,'wt');
  fprintf(fid,xpp);
  fclose(fid);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% SUBFUNCTIONS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [ODEs,ICs,FUNCTIONS,PARAMETERS] = collectdata(spec,prefixflag)
ODEs={}; ICs={}; FUNCTIONS={}; PARAMETERS={};
for i=1:numel(spec.nodes)
  % add global node dynamics (ODEs) and parameters
    % PREREQUISITE TODO: modify buildmodel() to add spec.nodes(#).odes where odes 
    % contains dynamics with interface function substitutions and no parameter substitutions.
  % ...
  for j=1:numel(spec.nodes(i).mechanisms)
    % add intrinsic mechanism parameters, functions, and ODEs
    [odes,ics,functions,parameters] = collectmechdata(spec.nodes(i).mechs(j));
    ODEs=cat(2,ODEs,odes); ICs=cat(2,ICs,ics); FUNCTIONS=cat(2,FUNCTIONS,functions); PARAMETERS=cat(2,PARAMETERS,parameters);
  end
  for j=1:numel(spec.nodes)
    for k=1:numel(spec.connections(i,j).mechanisms)
      % add connection mechanism parameters, functions, and ODEs
      [odes,ics,functions,parameters] = collectmechdata(spec.connections(i,j).mechs(k));  
      ODEs=cat(2,ODEs,odes); ICs=cat(2,ICs,ics); FUNCTIONS=cat(2,FUNCTIONS,functions); PARAMETERS=cat(2,PARAMETERS,parameters);
    end
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [odes,ics,functions,parameters] = collectmechdata(mech)
odes={}; ics={}; functions={}; parameters={};
% ODEs
for i=1:size(mech.odes,1)
  % ... (odes and ic); 
  %     odes: statevars{j}'=odes{j} 
  %     ics:  statevars{j}(0)=eval(ic{j})
end
% State functions
for i=1:size(mech.functions,1)
  % ... (convert [f=@(x)expression] to [f(x)=expression])
end
% Parameters
keys = fieldnames(mech.params);
vals = struct2cell(mech.params);
for i=1:length(keys)
  % ... (param keys{i} = vals{i})
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function spec = standardize(spec)
if isfield(spec,'cells')
  spec.nodes=spec.cells;
  spec=rmfield(spec,'cells');
elseif isfield(spec,'entities')
  spec.nodes=spec.entities;
  spec=rmfield(spec,'entities');  
end


%{
# Morris-Lecar reduced model 
dv/dt=(i+gl*(vl-v)+gk*w*(vk-v)+gca*minf(v)*(vca-v))/c
dw/dt=lamw(v)*(winf(v)-w)
# where
minf(v)=.5*(1+tanh((v-v1)/v2))
winf(v)=.5*(1+tanh((v-v3)/v4))
lamw(v)=phi*cosh((v-v3)/(2*v4))
#
param vk=-84,vl=-60,vca=120
param i=0,gk=8,gl=2, gca=4, c=20
param v1=-1.2,v2=18,v3=2,v4=30,phi=.04
# for type II dynamics, use v3=2,v4=30,phi=.04
# for type I dynamics, use v3=12,v4=17,phi=.06666667
v(0)=-60.899
w(0)=0.014873
# track some currents
aux Ica=gca*minf(V)*(V-Vca)
aux Ik=gk*w*(V-Vk)
done
%}
