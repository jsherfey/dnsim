function [simdata,spec,parms] = biosim(varargin)

% ----------------------------------------------------------
% get specification
if nargin>0 && isstruct(varargin{1}) % biosim(spec,...)
  spec = varargin{1};
  if nargin>1, varargin = varargin(2:end); end
elseif nargin>0
  if isstr(varargin{1}) && exist(varargin{1},'file')
    spec = loadspec(varargin{1});
    if nargin>1, varargin = varargin(2:end); end
  elseif isstr(varargin{1}) && exist(varargin{1},'dir')
    if nargin>1 && isstr(varargin{2}) % biosim(fpath,prefix,...)
      spec = loadspec(varargin{1},varargin{2});
      if nargin>2, varargin = varargin(3:end); end
    else
      spec = loadspec(varargin{1});
      if nargin>1, varargin = varargin(2:end); end
    end    
  else
    spec = loadspec(varargin{:});
  end
else
  error('You must supply at least one input.');
end
if isfield(spec,'cells') && ~isfield(spec,'entities')
  spec.entities = spec.cells;
  spec = rmfield(spec,'cells');
end
if ~isfield(spec,'files') || isempty(spec.files)
  DBPATH = '/space/mdeh3/9/halgdev/projects/jsherfey/code/modeler/database';
  d=dir(DBPATH);
  spec.files = {d(cellfun(@(x)any(regexp(x,'.txt$')),{d.name})).name};
  spec.files = cellfun(@(x)fullfile(DBPATH,x),spec.files,'unif',0);
end

% ----------------------------------------------------------
% prepare parameters
if nargin <= 1, varargin = {}; end
parms = mmil_args2parms( varargin, ...
                           {  'Iext',@(t) 0,[],...
                              'timelimits',[0 40],[],...
                              'dsfact',1,[],...
                              'logfid',1,[],...
                              'SOLVER','euler',[],...
                              'dt',.01,[],...
                              'output_list',[],[],...
                              'override',[],[],...
                              'IC',[],[],...
                              'verbose',1,[],...
                           }, false);

% ----------------------------------------------------------
% get model
%[model,ic,functions,auxvars,spec,readable,StateIndex] = buildmodel(spec,'logfid',parms.logfid,'override',parms.override);
[model,ic,functions,auxvars,spec,readable,StateIndex] = buildmodel2(spec,'logfid',parms.logfid,'override',parms.override,'dt',parms.dt,'verbose',parms.verbose);
if ~isempty(parms.IC) && numel(parms.IC)==numel(ic)
  ic = parms.IC;
end
% ----------------------------------------------------------
% run simulation
tstart = tic;
try args = mmil_parms2args(parms); catch args = {}; end
[data,t] = biosimulator(model,ic,functions,auxvars,args{:});%'Iext',Iext,'timelimits',tspan);
toc(tstart);

% ----------------------------------------------------------
% prepare results (downsample/postprocess data, organize data structure):
if parms.dsfact > 1
  parms.dsfact = round(parms.dsfact);
  t = t(1:parms.dsfact:end);
  data = data(1:parms.dsfact:end,:);
end

[ntime,nvar] = size(data);
Elabels = {spec.entities.label}; % Entity labels
Esizes = [spec.entities.multiplicity]; % Entity population sizes (multiplicities)

% evaluate auxiliary variables to get adjacency matrices
if issubfield(spec,'connections.auxvars')
  for i = 1:length(spec.entities)
    for j = 1:length(spec.entities)
      aux = spec.connections(i,j).auxvars;
      for k = 1:size(aux,1)
        try % TEMPORARY TRY STATEMENT
            % added to catch mask=mask-diag(diag(mask)) when mask is not square
            % WARNING: this is a dangerous TRY statement that should be removed!
            % also in biosimulator() at line 20
          eval( sprintf('%s = %s;',aux{k,1},aux{k,2}) );
        end
      end
      if ~isempty(aux)
        try spec.connections(i,j).matrix = eval(aux{k,1}); end
      end
    end
  end
end
% precompute mechanism interface functions (ie, output functions):
if ~isempty(parms.output_list)
  flds = fieldnames(parms);
  for f=1:length(flds)
    eval(sprintf('%s = parms.%s;',flds{f},flds{f}));
  end
  fprintf(parms.logfid,'Calculating additional function values from simulation results.\n');
  if ischar(parms.output_list), parms.output_list = {parms.output_list}; end  
  % construct list of functions to evaluate
  list = {};
  for i = 1:length(parms.output_list)
    this = parms.output_list{i};
    switch this
      case 'all'
        list = functions(:,1);
        break;
      case 'output' % IMPORTANT!! this is the only working case
        tmp = functions(strcmp('output',functions(:,3)),1);
        list = {list{:} tmp{:}};
      case 'auxiliary'
        tmp = functions(strcmp('auxiliary',functions(:,3)),1);
        list = {list{:} tmp{:}};
      otherwise
        list{end+1} = this;
    end
  end
    % TODO: add case for using regexp to match entity or mech label (much
    % like how they can be specified for plotting in biosim_plots.m)  
  for k = 1:size(auxvars,1)
    eval( sprintf('%s = %s;',auxvars{k,1},auxvars{k,2}) );
  end
  % evaluate anonymous functions
  for k = 1:size(functions,1)
    eval( sprintf('%s = %s;',functions{k,1},functions{k,2}) );
  end
  % get the multiplicity of each new variable for preallocation
  NV = []; failed = {}; srctype = {}; srcidx = [];
  for k = 1:length(list)
    found_flag = 0;
    if isfield(spec.connections,'matrix') && found_flag==0
      for c = 1:length(spec.connections(:))
        if ~isempty(spec.connections(c).mechanisms) && ismember(list{k},spec.connections(c).functions(:,1))
          NV = [NV size(spec.connections(c).matrix,2)];
          srctype = {srctype{:} 'connections'};
          srcidx = [srcidx c];
          found_flag = 1;
          break;
        end
      end
    end
    if found_flag==0
      for e = 1:length(spec.entities)
        if ismember(list{k},spec.entities(e).functions(:,1))
          NV = [NV spec.entities(e).multiplicity];
          srctype = {srctype{:} 'entities'};
          srcidx = [srcidx e];
          found_flag = 1;
          break;
        end
      end
    end
    if found_flag==0
      fprintf(parms.logfid,'Failed to find vars to calculate %s\n',list{k});
      failed = {failed{:} list{k}};
    end
  end
  list = list(~ismember(list,failed));
  
  % preallocate matrix for calculation
  outdata = nan(ntime,sum(NV));        
  % ------------------
  % IMPORTANT!! (again) this only works for 'output' at this time
  % evaluate auxiliary vars & functions to get calculate output functions for storage
  % ------------------  
  % calculate time courses for desired functions
  last = 0; newvar = []; MAXITER=1e3;
  for k = 1:length(list)
    dstidx = [];
    fprintf(parms.logfid,'%g of %g: %s\n',k,length(list),list{k});
    ind = last + (1:NV(k));
    src = spec.(srctype{k})(srcidx(k));
    src_orig = src;
    mechlist = src.mechanisms; 
    srclabel = strrep(src.label,'-','_');
    if ischar(mechlist),mechlist={mechlist};end
    if k==28
      tmp='y3eah';
    end
    for j = 1:length(mechlist)
      prefix = sprintf('%s_%s_',srclabel,mechlist{j});
      if isempty(strmatch(prefix,list{k})), continue; end
      old_func = strrep(list{k},prefix,'');
      arg_str = regexp(src.mech(j).substitute{1,2},'\(.+\)','match');
      arg_str = arg_str{1};
      if strcmp(srctype{k},'connections')
        tmp = splitstr(spec.(srctype{k})(srcidx(k)).label,'-');
        tmpsrc=tmp{1}; tmpdst=tmp{2};
        % switch src and dst b/c of structure vs algorithm organization
          srcidx(k) = find(strcmp(tmpsrc,{spec.entities.label})); 
          % srcidx => dst/post
          dstidx = find(strcmp(tmpdst,{spec.entities.label}));
          % dstidx => src/pre
        srctype{k} = 'entities';        
        src = spec.(srctype{k})(srcidx(k));
          % src = dst/post structure
        dst = spec.(srctype{k})(dstidx);
        origvars = unique(dst.orig_var_list);
      else
        dst = src;
        origvars = unique(src.orig_var_list);
      end    
      for v = 1:length(origvars)
        old = origvars{v}; cntwhile = 0; skipflag=0;
        while any(regexp(arg_str,['[^a-zA-Z]' old '([^a-zA-Z]|post|pre)']))
          s1=regexp(arg_str,['[^a-zA-Z]' old 'pre[^a-zA-Z]']);
          s2=regexp(arg_str,['[^a-zA-Z]' old '[^a-zA-Z]']);
          %if any(s1) || (any(findstr('pre',old)) && any(s2))
          if any(findstr([old 'pre'],arg_str)) || (any(findstr('pre',old)) && any(findstr(old,arg_str)))
              dstlabel = spec.(srctype{k})(dstidx).label;
              dstoriglist = spec.(srctype{k})(dstidx).orig_var_list;
              dstcurrlist = spec.(srctype{k})(dstidx).var_list;
              sel = find(strcmp(old,dstoriglist));
              jointsel = find(strcmp([prefix old],dstcurrlist));
              solosel = find(strcmp([dstlabel '_' old],dstcurrlist));
              sel = union(intersect(sel,jointsel),intersect(sel,solosel));
              datvarind = spec.(srctype{k})(dstidx).var_index(sel);
              if ~isempty(datvarind)
                %if any(s1)
                if any(findstr([old 'pre'],arg_str))
                  arg_str = strrep(arg_str,[old 'pre'],sprintf('data(TIMESTEP,%g:%g)''',datvarind(1),datvarind(end)));
                else
                  arg_str = strrep(arg_str,old,sprintf('data(TIMESTEP,%g:%g)''',datvarind(1),datvarind(end)));
                end
              end 
            else 
              src=dst;
              sel = find(strcmp(old,src.orig_var_list));
                % recall: src here actually refers to the destination
              jointsel = find(strcmp([prefix old],src.var_list));
              solosel = find(strcmp([src.label '_' old],src.var_list));
              sel = union(intersect(sel,jointsel),intersect(sel,solosel));
              datvarind = src.var_index(sel);
              if isfield(StateIndex,[prefix old])
                datvarind = StateIndex.([prefix old]);
              elseif isfield(StateIndex,[src.label '_' old])
                datvarind = StateIndex.([src.label '_' old]);
              else
                datvarind = [];
              end
              if ~isempty(datvarind)
                s3=regexp(arg_str,['[^a-zA-Z]' old 'post[^a-zA-Z]']);
                %if any(s3)%findstr([old 'post'],arg_str))
                if any(findstr([old 'post'],arg_str))
                  arg_str = strrep(arg_str,[old 'post'],sprintf('data(TIMESTEP,%g:%g)''',datvarind(1),datvarind(end)));
                else
                  arg_str = strrep(arg_str,old,sprintf('data(TIMESTEP,%g:%g)''',datvarind(1),datvarind(end)));
                end
              end
            end
            if cntwhile > MAXITER
              fprintf(parms.logfid,'Skipping function: search for definition exceeded max iterations.\n');
              skipflag = 1;
              break;
            else
              cntwhile = cntwhile + 1;
            end
        end
      end
      if skipflag==0
        tmpstr1 = regexp(arg_str,'(\(t\)|,t\)|\(t,|,t,)','match');
        if ~isempty(tmpstr1)
          tmpstr1 = tmpstr1{1};
          tmpstr2 = strrep(tmpstr1,'t','t(TIMESTEP)');
          arg_str = strrep(arg_str,tmpstr1,tmpstr2);      
        end        
        tmp_arg_str = arg_str;
        tmp_arg_str = strrep(tmp_arg_str,'post','');
        tmp_arg_str = strrep(tmp_arg_str,'pre','');
        for n = 1:ntime
          evalstr = strrep(tmp_arg_str,'TIMESTEP',num2str(n));
          evalstr = [prefix old_func evalstr];
          outdata(n,ind) = eval(evalstr);
        end
      end
      clear old sel src
      break;
    end
    last = last + NV(k); 
    dstidx = find(strcmp(dst.label,{spec.entities.label}));
    if isfield(newvar,srctype{k}) && length(newvar.(srctype{k}))>=dstidx%srcidx(k)
      newvar.(srctype{k})(dstidx).var_list = cat(2,newvar.(srctype{k})(dstidx).var_list,repmat(list(k),[1 NV(k)]));
      newvar.(srctype{k})(dstidx).var_index = cat(2,newvar.(srctype{k})(dstidx).var_index,size(data,2)+ind);
    else
      newvar.(srctype{k})(dstidx).var_list = repmat(list(k),[1 NV(k)]);
      newvar.(srctype{k})(dstidx).var_index = size(data,2) + ind;
    end
  end   
  % add calculated results to data
  data = cat(2,data,outdata);
  clear outdata
  for k=1:length(spec.entities)
      spec.entities(k).var_list = cat(2,spec.entities(k).var_list,newvar.entities(k).var_list);
      spec.entities(k).var_index = cat(2,spec.entities(k).var_index,newvar.entities(k).var_index);
  end
  if isfield(spec.connections,'var_list')
    for k=1:length(spec.connections(:))
        spec.connections(k).var_list = cat(2,spec.connections(k).var_list,newvar.connections(k).var_list);
        spec.connections(k).var_index = cat(2,spec.connections(k).var_index,newvar.connections(k).var_index);
    end    
  end
end

% store result in timesurfer format
clear simdata
if isfield(spec,'entities')
  simfield='entities';
else
  simfield='cells';
end
datafield = 'epochs';% 'studies';
maxN = max(Esizes);
try
  for i = 1:length(spec.(simfield))
    EN = Esizes(i);
    varlist = unique(spec.(simfield)(i).var_list);
    VN = length(varlist);
    dat = zeros(VN,ntime,maxN);%EN); % vars x time x cells
    for v = 1:length(varlist)
      index = spec.(simfield)(i).var_index(strmatch(varlist{v},spec.(simfield)(i).var_list,'exact'));
      dat(v,:,1:length(index)) = data(:,index);
    end
    if ndims(dat)==2
      tmpdata = ts_matrix2data(single(dat),'time',t/1000,'datafield',datafield,'continuous',1);
    elseif ndims(dat)==3
      tmpdata = ts_matrix2data(single(dat),'time',t/1000,'datafield',datafield);
    end
    [tmpdata.sensor_info.label] = deal(varlist{:});
    [tmpdata.sensor_info.kind] = deal(i);
    if issubfield(spec,'simulation.scope');
      tmpdata.(datafield).cond_label = sprintf('%s.%s=%s',spec.simulation.scope,spec.simulation.variable,spec.simulation.values);
    else
      tmpdata.(datafield).cond_label = 'simulation';
    end
    simdata(i) = tmpdata;
    clear tmpdata dat
  end
catch
  simdata = single(data);
end
clear data

parms.IC = ic;

%% NOTES:
% entities => separate structures w/ sensor_info.kind = entity ID
  % state vars => "sensors" with sensor_info.label = varlabel or interface function label (=LHS)
  % entity instances => "trials"
  % elements of a simulation study => "conditions"
  % therefore:
    % data(entity).sensor_info(:).kind = entityID
    % data(entity).sensor_info(var).label = varlabel/mech_interface
    % data(entity).epochs(sim).cond_label = (scope,variable,value)
    % data(entity).epochs(sim).num_trials = Npop
    % [data(entity).epochs(sim).data] = vars x time x cells
  % example usage:
  % ts_ezplot(data(1),'chanlabels',varlist,'events',simarray)
  %   => compare population averages b/w study simulations
  % ts_ezplot(data(1),'chanlabels',varlist,'trials_flag',1)
  %   => overlay waveforms from all cells of an entity for a given var
  