function Gnew = updateGalpha(t,dt,spikes,id,N,tau)
% update conductance G with difference equation (assume K=alpha for now) in updateGalpha()
% => need to store G and spikes at t-1 and t-2 (use global variable in this helper function)
global eventdata
if isnumeric(id), id=['id' num2str(id)]; end
if t==0 || ~isfield(eventdata.(id),'G1')
  eventdata.(id).G1=zeros(N,1);
  eventdata.(id).G2=zeros(N,1);
  eventdata.(id).S1=zeros(N,1);
  eventdata.(id).S2=zeros(N,1);
end
if t<(3*dt)
  Gnew=zeros(N,1);
  return;
end
G1=eventdata.(id).G1;
G2=eventdata.(id).G2;
S1=eventdata.(id).S1;
S2=eventdata.(id).S2;
h=1-dt/tau;
Gnew = 2*h.*G1 - h^2.*G2 + (dt/tau)^2.*S2;
eventdata.(id).G1=Gnew;
eventdata.(id).G2=G1;
eventdata.(id).S1=spikes;
eventdata.(id).S2=S1;


