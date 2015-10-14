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
