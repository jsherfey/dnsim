function [outdata,opt,err] = ts_data_selection(data,varargin)
%  condition - condition number (not event code) used to index data inside structure
% data selection
      %	- choose ranges: (conds,chans,trials,toi,foi)
      % - remove rejected: (reject_data,tf_reject_data,
      % sensor_info.badchan)
%  badchans    - indices of bad channels
%  chanlabel - cell array of strings listing channel labels
%  chantype - channel type (e.g. 'mag','grad1','grad2','eeg', or 'grad')
%    {default: 'all'} ('all' returns all non-"other" channels)
%  channels - vector of channel indices - overrides chantype
%    {default: []}
% % data: epoch_data, avg_data, timefreq_data, stat_data
% % uses: reject_data, tf_reject_data, badchanfile

% modified by JSS on 11/11/2009: changed default removebadchans to 1

parms = mmil_args2parms(varargin,{...
        'condition',[],[],...
        'event',[],[],...
        'channel',[],[],...
        'channels',[],[],...
        'chantype','all', [],...
        'chanlabel',[],[],...
        'badchans',[],[],...
        'badlabels',[],[],...
        'keepbadchans',0,{0,1},...
        'keepbadtrials',0,{0,1},...
        'removebadchans',1,{0,1},...
        'trial',[],[],...
        'rejects',[],[],...
        'toilim',[],[],...
        'toi',[],[],...
        'foilim',[],[],...
        'foi',[],[],...
        'badchanfile',[],[],...
        'rejectfile',[],[],...
        'reject_data',[],[],...
        'sensor_info',[],[],...
        'opt',[],[],...
        'dataparam',[],[],...
        'verbose',1,{0,1},...
        'logfile',      [],[],...
        'logfid',       [1],[], ...           
        },false);
      
parms = backcompatible(parms,varargin{:});     
data  = ts_checkdata_header(data,'events',parms.event);
if isempty(parms.sensor_info), parms.sensor_info = data.sensor_info; end


err = 0; opt = [];
[object,datafield,dataparam] = ts_object_info(data,varargin{:});
if ~isempty(parms.dataparam), dataparam = parms.dataparam; end  
if ~iscell(dataparam), dataparam = {dataparam}; end
if ~isempty(parms.chanlabel) && ~iscell(parms.chanlabel), parms.chanlabel = {parms.chanlabel}; end

%% conditions
if isempty(parms.event) && isempty(parms.condition)
  cond = 1:length(data.(datafield));
elseif ~isempty(parms.condition)
  cond = parms.condition;
elseif ~isempty(parms.event)
  if iscell(parms.event)
    parms.event = unique([parms.event{:}]);
  end
  cond = find(ismember([data.(datafield).event_code],parms.event));
end
events = [data.(datafield)(cond).event_code];

%% rejects
badchans                      = parms.badchans;
[badtrials{1:length(cond)}]   = deal([]);

% reject matfile with reject_data
if ~isempty(parms.rejectfile) && exist(parms.rejectfile,'file')
  mmil_logstr(parms,'loading reject file: %s\n',parms.rejectfile);
%   fprintf('%s: loading reject file: %s\n',mfilename,parms.rejectfile);
  load(parms.rejectfile);
  parms.reject_data = reject_data;
  if isfield(parms.reject_data,'badchanlabels')
    [sel1 sel2] = match_str({parms.sensor_info.label},parms.reject_data.badchanlabels);
    parms.reject_data.badchans = sel1;
  elseif ~isempty(parms.reject_data.badchans)
    mmil_logstr(parms,'warning: the following chans will be rejected based on indices, not labels:\n');
%     fprintf('%s: warning: the following chans will be rejected based on indices, not labels:\n',mfilename);
    {parms.sensor_info(parms.reject_data.badchans).label}
  end
  badchans = union(badchans,parms.reject_data.badchans);
  if isfield(parms.reject_data,'event_code')
    for k = 1:length(parms.reject_data.badtrials)
      if ismember(parms.reject_data.event_code(k),events)
        badtrials{parms.reject_data.event_code(k)==events} = parms.reject_data.badtrials{k};
      end
    end
  elseif length(parms.reject_data.badtrials) == length(events)
    [badtrials{:}]  = deal(parms.reject_data.badtrials{cond});
  end
elseif isstruct(parms.reject_data)
  if isfield(parms.reject_data,'badchanlabels')
    [sel1 sel2] = match_str({parms.sensor_info.label},parms.reject_data.badchanlabels);
    parms.reject_data.badchans = sel1;
  elseif ~isempty(parms.reject_data.badchans)
    mmil_logstr(parms,'warning: the following chans will be rejected based on indices, not labels:\n');
%     fprintf('%s: warning: the following chans will be rejected based on indices, not labels:\n',mfilename);
    {parms.sensor_info(parms.reject_data.badchans).label}
  end
  badchans        = union(badchans,parms.reject_data.badchans);
  if isfield(parms.reject_data,'event_code')
    for k = 1:length(parms.reject_data.badtrials)
      if ismember(parms.reject_data.event_code(k),events)
        badtrials{parms.reject_data.event_code(k)==events} = parms.reject_data.badtrials{k};
      end
    end
  elseif length(parms.reject_data.badtrials) == length(events)
    [badtrials{:}]  = deal(parms.reject_data.badtrials{cond});
  end
end

% ascii file listing bad channel labels
if ~isempty(parms.badchanfile) && exist(parms.badchanfile,'file')
  badchans = union(badchans,ts_read_txt_badchans(parms.badchanfile,{parms.sensor_info.label}));
end

% bad channels flagged in sensor_info
badchans = union(badchans,find([parms.sensor_info.badchan]));

% bad channel labels
if ~isempty(parms.badlabels) 
  if iscellstr(parms.badlabels)
    [sel,jnk] = match_str({parms.sensor_info.label},parms.badlabels);
  elseif ischar(parms.badlabels)
    sel = strmatch(parms.badlabels,{parms.sensor_info.label});
  else
    sel = [];
  end
  badchans = union(badchans,sel);
end
badchans = sort(unique(badchans));

if parms.keepbadchans
  badchans = [];
	[data.sensor_info.badchan]  = deal(0);
  [parms.sensor_info.badchan] = deal(0);
end

%% channels
chans = [];
if ~isempty(parms.chanlabel) && iscell(parms.chanlabel)
  [sel1 chans] = match_str(parms.chanlabel,{parms.sensor_info.label});
elseif ~isempty(parms.channel)
  chans = parms.channel;  
elseif ~isempty(parms.channels)
  chans = parms.channels;
elseif ~isempty(parms.chantype)
  if ~isempty(parms.sensor_info)
    switch lower(parms.chantype)
      case {'mag' 'grad1' 'grad2' 'eeg', 'other','sti','eog','ekg'}
        chans     = find(strcmp(parms.chantype,{parms.sensor_info.typestring}));
      case 'ieeg'
        chans     = find(strcmp('eeg',{parms.sensor_info.typestring}));
        if isempty(chans)
          chans   = find(strcmp('ieeg',{parms.sensor_info.typestring}));
        end
      case {'grad'}
        chans     = find(strncmp(parms.chantype,{parms.sensor_info.typestring},length(parms.chantype)));
      case 'meg'
        [a,chans] = find(ismember({parms.sensor_info.typestring},{'mag', 'grad1', 'grad2'}));
      case 'all'
        try chans = setdiff(1:data.num_sensors,find(strcmp('other',{parms.sensor_info.typestring}))); end;
      otherwise
        chans     = find(strcmp(parms.chantype,{parms.sensor_info.typestring}));
    end
  end
else
  chans = 1:length(parms.sensor_info);
end
% [badchans sel2] = match_str({parms.sensor_info(chans).label},{parms.sensor_info(badchans).label});
badchans = sort(intersect(badchans,chans));
chans    = sort(setdiff(chans,badchans));
badchans = sort(setdiff(1:data.num_sensors,chans));
if isempty(chans)
  mmil_logstr(parms,'no good channels selected\n');
%   fprintf('%s: no good channels selected\n',mfilename);
  err = 1; outdata = [];
  return;
end;


for i = 1:length(cond)
  %% trials
  if ~isempty(parms.trial)
    trials{i} = parms.trial;
  elseif isfield(data.(datafield),'num_trials')
    trials{i} = 1:data.(datafield)(cond(i)).num_trials;
  else
    trials{i} = 1;
  end
  if isfield(data.(datafield),'trial_info') && ~parms.keepbadtrials % added 25-Jan-2011 by JSS
    badtrials{i} = [badtrials{i} find([data.(datafield)(cond(i)).trial_info.badtrial]==1)];
  end
  trials{i} = sort(setdiff(trials{i},badtrials{i}));
  if isempty(trials{i})
    mmil_logstr(parms,'no good trials selected for event %g\n',data.(datafield)(cond(i)).event_code);
%     fprintf('%s: no good trials selected for event %g\n',mfilename,data.(datafield)(cond(i)).event_code);
    trials{i} = [];
%     err = 1;  outdata = [];
%     return;
  end
  trialvals(i) = length(trials{i});
  if strcmp(datafield,'averages') || ~isfield(data.(datafield),'num_trials') || ~ismember(data.(datafield)(cond(i)).num_trials,size(data.(datafield)(cond(i)).(dataparam{1}))) ...
      || (isfield(data.(datafield)(cond(i)),'frequencies') && ndims(data.(datafield)(cond(i)).(dataparam{1})) < 4)
    trials{i} = 1;  % this is an average
  end
  %% time
  if ~isempty(parms.toi)
    [c tidx{i} ib] = intersect(data.(datafield)(cond(1)).time,parms.toi);
  else
    if isempty(parms.toilim) || length(parms.toilim)~=2
      parms.toilim = [data.(datafield)(cond(i)).time(1) data.(datafield)(cond(i)).time(end)];
    end
    tidx{i} = find(data.(datafield)(cond(i)).time>=parms.toilim(1) & ...
                   data.(datafield)(cond(i)).time<=parms.toilim(end));
%     tidx{i} = nearest(data.(datafield)(cond(i)).time,parms.toilim(1)):...
%               nearest(data.(datafield)(cond(i)).time,parms.toilim(end));  
  end
  %% frequency     
  freq = 0;
  if isfield(data.(datafield),'frequencies')
    freq = 1;
    if ~isempty(parms.foi)
      [c fidx{i} ib] = intersect(data.(datafield)(cond(i)).frequencies,parms.foi);
    else
      if isempty(parms.foilim) || length(parms.foilim)~=2
        parms.foilim = [data.(datafield)(cond(i)).frequencies(1) data.(datafield)(cond(i)).frequencies(end)];
      end
      fidx{i} = find(data.(datafield)(cond(i)).frequencies>=parms.foilim(1) & ...
                     data.(datafield)(cond(i)).frequencies<=parms.foilim(end));
%       fidx{i} = nearest(data.(datafield)(cond(i)).frequencies,parms.foilim(1)):...
%                 nearest(data.(datafield)(cond(i)).frequencies,parms.foilim(end));          
    end
  end
end;

%% correct channels for PLV and other 4D data sets
% chans will be for indices into the data matrix
% sens will be for indices into the sensor_info array
senschans    = chans;
sensbadchans = badchans;
if issubfield(data,'timefreq.labelcmb')
  sen = {data.sensor_info(senschans).label};
  cmb = data.timefreq(1).labelcmb;
  keep=[];
  for i = 1:length(sen)
    keep = [keep find(ismember(cmb(:,1),sen{i}) | ismember(cmb(:,2),sen{i}))];
  end
  chans = unique(keep);
  sen = {data.sensor_info(sensbadchans).label};
  cmb = data.timefreq(1).labelcmb;
  keep=[];
  for i = 1:length(sen)
    keep = [keep find(ismember(cmb(:,1),sen{i}) | ismember(cmb(:,2),sen{i}))];
  end
  badchans = unique(keep);
end

%% data selection

outdata = rmfield(data,datafield);
outdata.(datafield) = data.(datafield)(cond);
for i = 1:length(cond)
  for j = 1:length(dataparam)
    dat = dataparam{j};
    if ~isfield(data.(datafield)(cond(i)),dat) || isempty(data.(datafield)(cond(i)).(dat)), continue; end
    if freq == 0
      if parms.removebadchans
        outdata.(datafield)(i).(dat)        = data.(datafield)(cond(i)).(dat)(chans,tidx{i},trials{i});
      else
        outdata.(datafield)(i).(dat)        = data.(datafield)(cond(i)).(dat)(:,tidx{i},trials{i});
      end
    else
      if parms.removebadchans
        outdata.(datafield)(i).(dat)        = data.(datafield)(cond(i)).(dat)(chans,tidx{i},fidx{i},trials{i});
      else
        outdata.(datafield)(i).(dat)        = data.(datafield)(cond(i)).(dat)(:,tidx{i},fidx{i},trials{i});
      end
      outdata.(datafield)(i).frequencies  = data.(datafield)(cond(i)).frequencies(fidx{i});
    end
    if ~parms.keepbadtrials && isfield(outdata.(datafield),'trial_info')
      outdata.(datafield)(i).trial_info.number        = outdata.(datafield)(i).trial_info.number(trials{i});
      outdata.(datafield)(i).trial_info.latency       = outdata.(datafield)(i).trial_info.latency(trials{i});
      outdata.(datafield)(i).trial_info.badtrial      = outdata.(datafield)(i).trial_info.badtrial(trials{i});
      outdata.(datafield)(i).trial_info.event_code    = outdata.(datafield)(i).trial_info.event_code(trials{i});
      outdata.(datafield)(i).trial_info.duration      = outdata.(datafield)(i).trial_info.duration(trials{i});
      outdata.(datafield)(i).trial_info.datafile      = outdata.(datafield)(i).trial_info.datafile(trials{i});
      outdata.(datafield)(i).trial_info.events_fnames = outdata.(datafield)(i).trial_info.events_fnames(trials{i});
    end
    if islogical(outdata.(datafield)(i).(dat)) && ~parms.removebadchans      % mask
      outdata.(datafield)(i).(dat)(badchans,:,:,:) = 0;
    elseif ~parms.removebadchans
      if freq == 1 % TF data
        outdata.(datafield)(i).(dat)(badchans,:,:,:) = nan;
      else
        outdata.(datafield)(i).(dat)(badchans,:,:,:) = 0;
      end
    end
  end
  outdata.(datafield)(i).num_trials       = trialvals(i);
  outdata.(datafield)(i).time             = data.(datafield)(cond(i)).time(tidx{i});
  if parms.removebadchans
    outdata.sensor_info = parms.sensor_info(senschans);
    outdata.num_sensors = length(senschans);
  else
    [outdata.sensor_info(sensbadchans).badchan] = deal([1]);
  end
  if ~isempty(badtrials{i})
    outdata.(datafield)(i).num_rejects.manual = outdata.(datafield)(i).num_rejects.manual + length(badtrials{i});
    if parms.verbose
      mmil_logstr(parms,'event %g: %g trials removed (%s)\n',data.(datafield)(cond(i)).event_code,length(badtrials{i}),num2str(badtrials{i}));
%       fprintf('%s: event %g: %g trials removed (%s)\n',mfilename,data.(datafield)(cond(i)).event_code,length(badtrials{i}),num2str(badtrials{i}));
    end
  end
  if issubfield(data,'timefreq.labelcmb')
    outdata.timefreq(i).labelcmb = data.timefreq(i).labelcmb(chans,:);
  end
end
if ~isempty(sensbadchans)
  labels = {parms.sensor_info(sensbadchans).label};
  str    = labels{1}; 
  for k=2:length(labels), str=[str ' ' labels{k}]; end
  if parms.removebadchans
    if parms.verbose
      mmil_logstr(parms,'%g channels removed (%s)\n',length(sensbadchans),str);
%       fprintf('%s: %g channels removed (%s)\n',mfilename,length(badchans),str);
    end
  else
    if parms.verbose
      mmil_logstr(parms,'%g channels set to zero and marked bad (%s)\n',length(sensbadchans),str);
%       fprintf('%s: %g channels set to zero and marked bad (%s)\n',mfilename,length(badchans),str);
    end
  end
end

% update options structure
if ~isempty(parms.opt)
  opt = parms.opt;
%   opt.datafile = opt.datafile(cond);
end
  

function parms = backcompatible(parms,varargin)

opt = mmil_args2parms(varargin,{...
        'conditions',[],[],...
        'cond',[],[],...
        'events',[],[],...
        'event_codes',[],[],...
        'eventvals',[],[],...
        'channels',[],[],...
        'chantype','all',[],...
        'badchans',[],[],...
        'chanlabels',[],[],...
        'keepbadtrials_flag',[],[],...
        'keepbadchans_flag',[],[],...
        'badlabel',[],[],...
        'trial',[],[],...
        'trials',[],[],...
        'toilim',[],[],...
        'toi',[],[],...
        'foilim',[],[],...
        'foi',[],[],...
        'badchanfile',[],[],...
        'reject_file',[],[],...
        'opt',[],[],...
        'dataparam',[],[],...
        },false);

if ~isempty(opt.cond) && isempty(opt.conditions)
  opt.conditions = opt.cond;
end
if isempty(parms.condition) && ~isempty(opt.conditions)
  parms.condition = opt.conditions; 
end

if isempty(parms.event)
  if ~isempty(opt.events)
    parms.event = opt.events;
  elseif ~isempty(opt.event_codes)
    parms.event = opt.event_codes;
  elseif ~isempty(opt.eventvals)
    parms.event = opt.eventvals;
  end
end

if ~isempty(opt.keepbadtrials_flag)
  parms.keepbadtrials = opt.keepbadtrials_flag;
end
if ~isempty(opt.keepbadchans_flag)
  parms.keepbadchans = opt.keepbadchans_flag;
end

if isempty(parms.chanlabel) && ~isempty(opt.chanlabels)
  parms.chanlabel = opt.chanlabels;
end

if isempty(parms.badlabels) && ~isempty(opt.badlabel)
  parms.badlabels = opt.badlabel;
end

if isempty(parms.channel) && ~isempty(opt.channels)
  parms.channel = opt.channels;
end

if isempty(parms.rejectfile) && ~isempty(opt.reject_file)
  parms.rejectfile = opt.reject_file;
end

if isempty(parms.trial) && ~isempty(opt.trials)
  parms.trial = opt.trials;
end