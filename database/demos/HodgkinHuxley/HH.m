% Model: base Hodgkin-Huxley neuron
cd(fileparts(mfilename('fullpath')));
spec=[];
spec.nodes(1).label = 'HH';
spec.nodes(1).multiplicity = 5;
spec.nodes(1).dynamics = {'v''=current/c'};
spec.nodes(1).mechanisms = {'K','Na','leak','input','randn'};
spec.nodes(1).parameters = {'c',1,'v_IC',-65,'stim',7,'noise',100};

% process specification and simulate model
data = runsim(spec,'timelimits',[0 150],'dt',.05,'dsfact',10,'coder',1);
plotv(data,spec,'varlabel','v');
% dnsim(spec);
