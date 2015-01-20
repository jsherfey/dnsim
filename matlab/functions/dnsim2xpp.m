function dnsim2xpp_noparms(spec,outfile,tspan,dt)
% Purpose: convert DNSim model into XPPAUT format. The resulting file will
% not define any parameters or functions; all parameters and functions will
% have been substituted into the ODEs already. A future version of this
% function will explicitly define parameters and functions for easier
% manipulation of the model from the XPPAUT file. This version supports
% networks of connected nodes but not populations.
% Example usage: 
% load('Morris-Lecar-Neuron.mat','spec');  % Load DNSim model specification
% dnsim2xpp_noparms(spec,'Morris-Lecar-Neuron.ode',[0 1000],.05);
% Then to run the resulting XPP model: xppaut Morris-Lecar-Neuron.ode

% Info needed from the DNSim specification:
model=spec.model.ode;            % function handle string containing full ODE system
IC=spec.model.IC;                % vector of initial conditions
varlist = spec.variables.labels; % cell array of state variable names

% Make the model more human-readable --
% Substitute generic state vectors for meaningful variable names
for k = 1:length(varlist)
  varindex = sprintf('X(%g:%g)',k,k);
  varlist{k}=strrep(varlist{k},'_','');
  model = strrep(model,varindex,varlist{k});
end
% Eliminate unsupported Matlab syntax
model = strrep(model,'./','/');
model = strrep(model,'.*','*');
model = strrep(model,'.^','^');  
% Split the function handle string into a cell array of ODEs
odes = regexp(model(9:end-2),';','split');
odes = odes(~cellfun(@isempty,odes));

% Write XPPAUT ODE file
fid=fopen(outfile,'wt');
for k=1:length(odes)
  % ODEs
  odes{k} = strrep(odes{k},';',''); % eliminate more unsupported Matlab syntax
  fprintf(fid,'%s''=%s\n',varlist{k},odes{k});
  % Initial conditions
  fprintf(fid,'%s(0)=%g\n',varlist{k},IC(k));
end
% Write additional controls
fprintf(fid,'@ TOTAL=%g, DT=%g\n',tspan(2),dt);
fprintf(fid,'@ xplot=t,yplot=%s\n',varlist{1});
fclose(fid);


%{
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
% if numnodes>1
%   prefixflag = 2; % add node and mechanism prefixes
% elseif nummechs>1
%   prefixflag = 1; % add mechanism prefixes only
% else
%   prefixflag = 0; % add no prefixes
% end

% Re-organize model data for xpp conversion
[odes,ics,functions,parameters] = collectdata(spec);%,prefixflag);

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
function [ODEs,ICs,FUNCTIONS,PARAMETERS] = collectdata(spec)
ODEs={}; ICs={}; FUNCTIONS={}; PARAMETERS={};
parsedfunctions=spec.model.functions;
for i=1:numel(spec.nodes)
  % add global node dynamics (ODEs) and parameters
  for j=1:numel(spec.nodes(i).odes_str)
    ODEs{end+1}=sprintf('%s''=%s',spec.nodes(i).ode_labels{j},spec.nodes(i).odes_str{j});
  end
  % add intrinsic mechanism parameters, functions, and ODEs
  for j=1:numel(spec.nodes(i).mechanisms)
    prefix=sprintf('%s_%s',spec.nodes(i).label,spec.nodes(i).mechanisms{j});
    [odes,ics,functions,parameters] = collectmechdata(spec.nodes(i).mechs(j),prefix,parsedfunctions);
    ODEs=cat(2,ODEs,odes); ICs=cat(2,ICs,ics); FUNCTIONS=cat(2,FUNCTIONS,functions); PARAMETERS=cat(2,PARAMETERS,parameters);
  end
  % add connection mechanism parameters, functions, and ODEs
  for j=1:numel(spec.nodes)
    for k=1:numel(spec.connections(i,j).mechanisms)
      prefix=strrep(sprintf('%s_%s',spec.connections(i,j).label,spec.connections(i,j).mechanisms{k}),'-','_');
      [odes,ics,functions,parameters] = collectmechdata(spec.connections(i,j).mechs(k),prefix,parsedfunctions);  
      ODEs=cat(2,ODEs,odes); ICs=cat(2,ICs,ics); FUNCTIONS=cat(2,FUNCTIONS,functions); PARAMETERS=cat(2,PARAMETERS,parameters);
    end
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [odes,ics,functions,parameters] = collectmechdata(mech,prefix,parsedfunctions)
odes={}; ics={}; functions={}; parameters={};
% Parameters
keys = fieldnames(mech.params);
vals = struct2cell(mech.params);
for i=1:length(keys)
  if isnumeric(vals{i})
    val=num2str(vals{i});
  else
    val=vals{i};
  end
  parameters{end+1} = sprintf('%s_%s = %s',prefix,keys{i},val);
end
newkeys = cellfun(@(x)[prefix '_' x],keys,'uni',0);
% State functions
keyboard
for i=1:size(mech.functions,1)
  % convert [f=@(x)expression] to [f(x)=expression]
  name = [prefix '_' mech.functions{i,1}];
  vars1 = parsedfunctions{strcmp(name,parsedfunctions(:,1)),2};
  vars1 = regexp(vars1,'^@([^\s]+)','match');
  vars1 = strrep(strrep(vars1{1},'@(',''),')','');
  vars2 = mech.functions{i,2};
  vars2 = regexp(vars2,'^@([^\s]+)','match');
  vars2 = strrep(strrep(vars2{1},'@(',''),')','');
  expr = strrep(mech.functions{i,2},['@(' vars2 ')'],'');
  for j=1:length(keys)
    expr = strrep(expr,keys{j},newkeys{j});
  end
  for j=1:size(parsedfunctions,1)
    expr = strrep(expr,parsedfunctions{j,3},parsedfunctions{j,1});
  end  
  expr = sprintf('%s_%s(%s) =%s',prefix,mech.functions{i,1},vars1,expr);
  functions{end+1}=expr;  
end
% ODEs
for i=1:size(mech.odes,1)
  % ... (odes and ic); 
  %     odes: statevars{j}'=odes{j} 
  %     ics:  statevars{j}(0)=eval(ic{j})
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

%}