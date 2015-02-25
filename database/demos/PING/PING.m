% Model: Pyramidal-Interneuron-Network-Gamma (PING)
cd(fileparts(mfilename('fullpath')));
spec=[];
spec.nodes(1).label = 'E';
spec.nodes(1).multiplicity = 1;
spec.nodes(1).dynamics = {'V''=(current)./Cm'};
spec.nodes(1).mechanisms = {'K','Na','leak','input','randn'};
spec.nodes(1).parameters = {'Cm',1,'V_IC',-70,'stim',10,'noise',0};
spec.nodes(2).label = 'I';
spec.nodes(2).multiplicity = 1;
spec.nodes(2).dynamics = {'V''=(current)./Cm'};
spec.nodes(2).mechanisms = {'K','Na','leak','input','randn'};
spec.nodes(2).parameters = {'Cm',1,'V_IC',-70,'stim',0,'noise',0};
spec.connections(1,2).label = 'E-I';
spec.connections(1,2).mechanisms = {'AMPA'};
spec.connections(1,2).parameters = {'tauDx',2,'g_SYN',.2};
spec.connections(2,1).label = 'I-E';
spec.connections(2,1).mechanisms = {'GABAa'};
spec.connections(2,1).parameters = {'tauDx',10,'g_SYN',.5}; % tauDx=10,13

% process specification and simulate model
data = runsim(spec,'timelimits',[0 150],'dt',.02,'dsfact',10,'coder',1);
plotv(data,spec,'varlabel','V');
% dnsim(spec);
