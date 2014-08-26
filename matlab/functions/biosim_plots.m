function imgfiles = biosim_plots(data,varargin)
% TODO: make new layout function and use it instead of 'ordered'

parms = mmil_args2parms( varargin, ...
                           {'cluster_flag',0,[],...
                            'savefig_flag',0,[],...
                            'plotvars',[],[],...
                            'plottype','all',[],...
                            'format','jpg',[],...
                            'rootoutdir',pwd,[],...
                            'prefix','biosim_images',[],...
                            'layout',[],[],...
                            'xlim',[],[],...
                            'ylim',[],[],...
                            'powrepmat',1,[],...
                            'colorbar','yes',[],...
                            'toilim',[],[],...
                           }, false);
if isempty(parms.ylim)
  autoscale_flag = 1;
else
  autoscale_flag = 0;
end
if isempty(parms.plottype) || isequal(parms.plottype,'all')
  plottype = {'trace','image','power'};
else
  plottype = parms.plottype;
  if ~iscell(plottype), plottype = {plottype}; end
end
if ischar(parms.format)
  imageformats = {parms.format};
else
  imageformats = parms.format;
end
cluster_flag = parms.cluster_flag;

% if cluster_flag
%   figure('visible','off'); 
%   set(gcf,'color','w','position',[150 50 800 850]);%[150 50 1150 850]);
%   celltypes = {pop.type};
%   ntypes = length(celltypes);
%   for i = 1:ntypes
%     V = pop(i).V;    
%     subplot(ntypes,1,i)
%     imagesc(t,1:size(V,2),V'); xlabel('time (ms)');
%     title(pop(i).type);
%     colorbar; % caxis([-75 40]);
%   end    
% else
  % prepare data for plotting (pad & combine across entity types)
  npops = length(data);
%   % add population means as additional "trial"
%   for i=1:npops
%     for j=1:length(data(i).epochs)
%       data(i).epochs(j).data = cat(3,data(i).epochs(j).data,nanmean(data(i).epochs(j).data,3));
%       data(i).epochs(j).num_trials = data(i).epochs(j).num_trials + 1;
%     end
%   end  
  maxvars = max([data.num_sensors]);
  maxtrls = max(arrayfun(@(x)x.epochs.num_trials,data));
  rmlabels = {};
  cnt = 0;
  for i = 1:length(data)
    addrows = maxvars - data(i).num_sensors;
    if i==1
      alldata = data(i);
      alldata.epochs.data = nan([maxvars*numel(data) length(data(i).epochs.time) maxtrls]);
      alldata.num_sensors = maxvars*length(data);
    else
      alldata.sensor_info = cat(2,alldata.sensor_info,data(i).sensor_info);
    end
    alldata.sensor_info(end+1:end+addrows) = deal(alldata.sensor_info(end));
    tmplabels = cellfun(@num2str,num2cell(data(i).sensor_info(1).kind*100+(1:addrows)),'uniformoutput',false);
    rmlabels = {rmlabels{:} tmplabels{:}};
    [alldata.sensor_info(end-addrows+1:end).label] = deal(tmplabels{:});
    alldata.epochs.data(cnt+1:cnt+data(i).num_sensors,:,1:data(i).epochs.num_trials) = data(i).epochs.data;
    cnt = cnt + maxvars;
  end
%   for i=1:alldata.num_sensors
%     alldata.sensor_info(i).label=strrep(alldata.sensor_info(i).label,'_','');
%   end
    
  % what to plot?
  L = {alldata.sensor_info.label};
  try
    allplotvars = {};
    if ~iscell(parms.plotvars),parms.plotvars={parms.plotvars}; end
    for i = 1:length(parms.plotvars)
      l = parms.plotvars{i};
      if ismember(l,L)
        allplotvars{end+1} = l;
      else
        idx = regexp(L,sprintf('(^%s|%s$|_%s_)+',l,l,l),'match');
        allplotvars = {allplotvars{:} L{~cellfun(@isempty,idx)}};
      end
    end
  catch
    allplotvars = L;
  end
  if isempty(allplotvars), allplotvars = L; end
  if ~isempty(allplotvars)
    alldata = ts_data_selection(alldata,'chanlabels',allplotvars);
  end
  if ~isempty(rmlabels)
    alldata = ts_data_selection(alldata,'badlabels',rmlabels);
  end
  if ~isempty(parms.toilim)
    alldata = ts_data_selection(alldata,'toilim',parms.toilim);
  end
  % add population means as additional "trial"
  alldata.epochs.data = cat(3,alldata.epochs.data,nanmean(alldata.epochs.data,3));
  alldata.epochs.num_trials = alldata.epochs.num_trials + 1;
  % calculate power spectrum for each population mean
  if ismember('power',plottype)
    try
      WINDOW=[]; NOVERLAP=[]; FREQS=[];
      allpower = rmfield(alldata,'epochs');
      allpower.averages = rmfield(alldata.epochs,'data');
      allpower.averages.num_trials = allpower.averages.num_trials-1;
%       allpower = rmsubfield(alldata,'epochs.data');
      dt = max(.00001,1/alldata.sfreq);
      x = alldata.epochs.time;
      X = x(1):dt:x(end);
      y = alldata.epochs.data(:,:,end);
  %     Y = zeros(size(y,1),length(X));    
      for i = 1:size(y,1)
  %       Y(i,:) = interp1(x,y,X);
        if parms.powrepmat>1
          tmp = y(i,:);
          tmp = interp1(x,tmp,X);
          tmp = ts_freq_filt(tmp',1/dt,200,5,'lowpass')';
          tmp = repmat(tmp,[1 parms.powrepmat]);
        else
          tmp = y(i,:);
          tmp = interp1(x,tmp,X);
          tmp = ts_freq_filt(tmp',1/dt,200,5,'lowpass')';
        end
        tmp = tmp(round(length(tmp)*.1):round(length(tmp)*.9));
        [Pxx,F]=periodogram(tmp-mean(tmp),[],length(tmp),1/dt);        
          % x = ts_freq_filt(tmp,Fs,[f0-fsz f0+fsz],[0 0],'bandpass');
          % X = hilbert(x);
          % phi = angle(X);
%         [Pxx,F] = pwelch(tmp,WINDOW,NOVERLAP,FREQS,1/dt);
        if i==1
          allpower.averages.data = zeros(size(y,1),length(F));
          allpower.averages.time = F;
          allpower.sfreq = 1/(F(2)-F(1));
        end
        allpower.averages.data(i,:) = 10*log10(Pxx);
      end
    catch
      allpower.averages.data = [];
    end
  end
%   figure;
%   set(gcf,'color','w','position',[150 50 1150 850]);
  axestype = 'all'; % 'all','yes','no'
  try 
    imagetitle = alldata.epochs.cond_label;
  catch
    imagetitle = '';
  end
  if any(ismember({'trace','waveform'},plottype))
    thisprefix = [parms.prefix '_traces'];
    args=varargin;
    k=find(cellfun(@(x)isequal(x,'prefix'),args));
    if ~isempty(k)
      args{k+1}=thisprefix;
    else
      args{end+1}='prefix'; args{end+1}=thisprefix;
    end    
    for i = 1:length(imageformats)
      if parms.savefig_flag==0 && i>1, break; end
      try
        %ts_ezplot(alldata,'nr',npops,'nc',ceil(alldata.num_sensors/npops),'trials_flag',1,'showlabels','yes','autoscale',autoscale_flag,varargin{:});
        ts_ezplot(alldata,'layout','ordered','trials_flag',1,'showlabels','yes',args{:});%,'autoscale',autoscale_flag
      catch
        try ts_ezplot(alldata,'nr',npops,'nc',ceil(alldata.num_sensors/npops),'trials_flag',1,'showlabels','yes','autoscale',autoscale_flag,'axes',axestype,'title',imagetitle,'rootoutdir',parms.rootoutdir,'prefix',thisprefix,'save',parms.savefig_flag,'close',parms.savefig_flag,'format',imageformats{i},'layout',parms.layout,'fontweight','bold','fontcolor','b','fontsize',12,'xlim',parms.xlim,'zlim',parms.ylim); end
      end
    end
  end
  % crop image using linux command line utility:
  % http://www.imagemagick.org/Usage/crop/#crop
  % convert rose: -crop 40x30+10+10  +repage  repage.gif
  
  % prepare data for plotting color images
  alldata.timefreq = alldata.epochs;
  alldata = rmfield(alldata,'epochs');
  alldata.timefreq.frequencies = 1:alldata.timefreq.num_trials;
  alldata.timefreq.power = alldata.timefreq.data;
  alldata.timefreq = rmfield(alldata.timefreq,'data');
  
  if any(ismember({'image','imagesc'},plottype))
    thisprefix = [parms.prefix '_imagesc'];
    args=varargin;
    k=find(cellfun(@(x)isequal(x,'prefix'),args));
    if ~isempty(k)
      args{k+1}=thisprefix;
    else
      args{end+1}='prefix'; args{end+1}=thisprefix;
    end        
    for i = 1:length(imageformats)
      if parms.savefig_flag==0 && i>1, break; end
      try
        %ts_ezplot(alldata,'nr',npops,'nc',ceil(alldata.num_sensors/npops),'trials_flag',1,'showlabels','yes','autoscale',autoscale_flag,'axes',axestype,'save',parms.savefig_flag,'close',parms.savefig_flag,'format',imageformats{i},'layout',parms.layout,'colorbar',parms.colorbar,varargin{:});
        ts_ezplot(alldata,'trials_flag',1,'showlabels','yes',args{:});%,'autoscale',autoscale_flag,varargin{:});%,'axes',axestype,'save',parms.savefig_flag,'close',parms.savefig_flag,'format',imageformats{i},'layout',parms.layout,'colorbar',parms.colorbar,varargin{:});
      catch
        try ts_ezplot(alldata,'nr',npops,'nc',ceil(alldata.num_sensors/npops),'trials_flag',1,'showlabels','yes','autoscale',autoscale_flag,'axes',axestype,'title',imagetitle,'rootoutdir',parms.rootoutdir,'prefix',thisprefix,'save',parms.savefig_flag,'close',parms.savefig_flag,'format',imageformats{i},'layout',parms.layout,'fontweight','bold','fontcolor','b','fontsize',12,'xlim',parms.xlim,'zlim',parms.ylim,'colorbar',parms.colorbar); end
      end
    end
  end
  
  if any(ismember({'power','power-spectrum'},plottype))
    thisprefix = [parms.prefix '_power-spectrum'];
    args=varargin;
    k=find(cellfun(@(x)isequal(x,'prefix'),args));
    if ~isempty(k)
      args{k+1}=thisprefix;
    else
      args{end+1}='prefix'; args{end+1}=thisprefix;
    end        
    k=find(cellfun(@(x)isequal(x,'xlim'),args));
    if ~isempty(k)
      args=args(setdiff(1:length(args),[k k+1]));
    end    
    k=find(cellfun(@(x)isequal(x,'toilim'),args));
    if ~isempty(k)
      args=args(setdiff(1:length(args),[k k+1]));
    end    
    for i = 1:length(imageformats)
      if parms.savefig_flag==0 && i>1, break; end
      try
        allpower=ts_data_selection(allpower,'toilim',[3 100]);
        ts_ezplot(allpower,'nr',npops,'nc',ceil(allpower.num_sensors/npops),'trials_flag',1,'showlabels','yes',args{:});%,'autoscale',autoscale_flag,varargin{:});%,'axes',axestype,imagetitle,'rootoutdir',parms.rootoutdir,'prefix',thisprefix,'save',parms.savefig_flag,'close',parms.savefig_flag,'format',imageformats{i},'layout',parms.layout,'fontweight','bold','fontcolor','b','fontsize',12,'zlim',parms.ylim);
      end
    end
  end
  
  % end

if parms.savefig_flag
  d=dir(fullfile(parms.rootoutdir,'images')); f={}; [f{1:numel(d),1}]=deal(d.name);
  pat = cellfun(@(x)[x '|'],imageformats,'uniformoutput',false);
  pat = [pat{:}];
  pat = ['^' parms.prefix '.*\.(' pat(1:end-1) ')$'];
  idx = regexp(f,pat,'match');
  imgfiles = f(~cellfun(@isempty,idx));
  for f = 1:length(imgfiles)
    imgfiles{f} = fullfile(parms.rootoutdir,'images',imgfiles{f});
  end
else
  imgfiles = [];
end
