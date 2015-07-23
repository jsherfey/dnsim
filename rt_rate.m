function r = rt_rate(V,tvec,T,id,thresh)
% use global variable to store V(t-1) and spikes from all source cells over [t-T,t]
% return r=(1/T)*(# spikes) (for each source cell)
if nargin<3, T=1; end
if nargin<4, id=1; end
if nargin<5, thresh=0; end
global eventdata
if size(tvec,1)>1, tvec=tvec(1,:); end
r=zeros(size(V,1),length(tvec));
for k=1:length(tvec)
  t=tvec(k);
  if isnumeric(id), id=['id' num2str(id)]; end
  N=length(V);
  if t<=.01 || ~isfield(eventdata.(id),'V1')
    eventdata.(id).V1=V;
    eventdata.(id).spiketimes = cell(size(V,1),1);
  end
  % detect spike(s) in Vpre at t=now
  spiked=(V>=thresh)&(eventdata.(id).V1<thresh);
  % store spikes
  for i=1:size(V,1)
    spk=eventdata.(id).spiketimes{i};
    spk=spk(spk>=(t-T));
    if spiked(i)==1
      spk(end+1)=t;
    end
    eventdata.(id).spiketimes{i} = spk;
  end
  % calc rate
  r(:,k) = cellfun(@length,eventdata.(id).spiketimes)/T;
end
