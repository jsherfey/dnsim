function [fig,lfps,T]=plotv(data,spec,varargin)
% Purpose: plot V (per population): image and (traces + mean(V))
lfps=[]; T=[];

parms = mmil_args2parms( varargin, ...
                   {  'plot_flag',1,[],...
                      'maxtraces',10,[],...
                      'var',[],[],...
                      'varlabel','V',[],...
                      'visible_flag',1,[],...
                   }, false);
                 
if ~isfield(spec,'entities') && isfield(spec,'cells')
  spec.entities=spec.cells;
end
if ~isfield(spec,'entities') && isfield(spec,'nodes')
  spec.entities=spec.nodes;
end
npop = length(spec.entities);
popflag = any([spec.entities.multiplicity]>1);

% Fill screen with subplots:
nrows = npop;
if popflag==1
  ncols = 2;
else
  ncols = 1;
end
nplots = nrows*ncols;
maxtraces=parms.maxtraces;
var = parms.var;

% ------------------------------
dx = 1 / ncols;
dy = 1 / nrows;
 
xstep = mod((1:ncols)-1,ncols);
ystep = mod((1:nrows)-1,nrows)+1;
xpos = .035+xstep*dx; % .02+xstep*dx;
ypos = .05+1-ystep*dy; % .02+1-ystep*dy;
 
if parms.plot_flag
  cnt=1;
  screensize = get(0,'screensize');
  if parms.visible_flag==0
    fig=figure('position',screensize.*[1 1 .8 min(.3*nrows,.9)],'visible','off');
  else
    fig=figure('position',screensize.*[1 1 .8 min(.3*nrows,.9)],'visible','on');
  end
  %fig=figure('position',screensize);
  pause(1)
  %set(gca,'Units','normalized','Position',[0 0 1 1]);
  for i = 1:nplots
    xi = mod(i-1,ncols)+1;
    yi = floor((i-1)./ncols)+1;
    subplot('Position',[xpos(xi) ypos(yi) .9/ncols .9/nrows]); set(gca,'units','normalized');
    pop = ceil(i/ncols); % index to this population
    if pop>length(data), continue; end
    labels = {data(pop).sensor_info.label};
    if isempty(parms.var)
      var = find(strcmp(labels,parms.varlabel));
      if isempty(var)
        var = find(~cellfun(@isempty,regexp(labels,['_' parms.varlabel '$'])),1,'first');
      end
    else
      var = parms.var;
    end
    if isempty(var), continue; end
    T = data(pop).epochs.time;
    if spec.entities(pop).multiplicity <= data(pop).epochs.num_trials
      n=spec.entities(pop).multiplicity;
    else
      n=data(pop).epochs.num_trials;%spec.entities(pop).multiplicity; %data(pop).epochs.num_trials;
    end
    lab = data(pop).sensor_info(var).label;
    if popflag && mod(i,2)==1 % odd, plot trace
%       T = data(pop).epochs.time;
%       if spec.entities(pop).multiplicity <= data(pop).epochs.num_trials
%         n=spec.entities(pop).multiplicity;
%       else
%         n=data(pop).epochs.num_trials;%spec.entities(pop).multiplicity; %data(pop).epochs.num_trials;
%       end              
%      n = data(pop).epochs.num_trials;%spec.entities(pop).multiplicity; 
      dat = squeeze(data(pop).epochs.data(var,:,1:n))';
%       lab = data(pop).sensor_info(var).label;
      imagesc(T,1:n,dat); axis xy; colormap(1-gray); colorbar
      xlabel('time [s]'); ylabel('cell');
      % calc LFP to overlay with traces
      text(min(xlim)+.2*diff(xlim),min(ylim)+.8*diff(ylim),strrep(lab,'_','\_'),'fontsize',14,'fontweight','bold');
      lfp = mean(dat,1)';
      if cnt==1, lfps = zeros(npop,length(T)); end
      lfps(pop,:) = lfp;
      cnt=cnt+1;
      xlim([T(1) T(end)]);
    else % even, plot spectrum
      nshow=min(maxtraces,n);
      show=randperm(n);
      show=show(1:nshow);
      plot(T,squeeze(data(pop).epochs.data(var,:,show))); hold on
      % overlay LFP
      if popflag
        plot(T,lfp,'k-','linewidth',3);
      end
      xlabel('time [s]'); ylabel(strrep(lab,'_','\_'));%'V');
      text(min(xlim)+.2*diff(xlim),min(ylim)+.8*diff(ylim),[strrep(lab,'_','\_') ' (' num2str(nshow) '-cell subset)'],'fontsize',14,'fontweight','bold');
      xlim([T(1) T(end)]);
    end
  end
else
  fig = []; cnt=1;
  for i=1:npop
    labels = {data(i).sensor_info.label};
    if isempty(parms.var)
      var = find(~cellfun(@isempty,regexp(labels,['_' parms.varlabel '$'])),1,'first');
    else
      var = parms.var;
    end    
    if isempty(var), continue; end
    T = data(i).epochs.time;
    if spec.entities(i).multiplicity <= data(i).epochs.num_trials
      n=spec.entities(i).multiplicity;
    else
      n=data(i).epochs.num_trials;%spec.entities(pop).multiplicity; %data(pop).epochs.num_trials;
    end      
%     try
%       n=spec.entities(pop).multiplicity;
%     catch
%       n=data(pop).epochs.num_trials;%spec.entities(pop).multiplicity; %data(pop).epochs.num_trials;
%     end      
%    n = data(pop).epochs.num_trials;%spec.entities(i).multiplicity;
    dat = squeeze(data(i).epochs.data(var,:,1:n))';
    if cnt==1, lfps = zeros(npop,length(T)); end
    lfps(i,:) = mean(dat,1)';
    cnt=cnt+1;
  end
end