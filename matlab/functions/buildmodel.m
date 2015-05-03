function varargout = buildmodel(spec,varargin)
% 20150210 - modified: added option (coder) to construct ODEs containing parameter names and construct a parameter structure for all parameters (scope_mech*_param). add param struct to spec.

% NEED TO: assess whether the conditional at line ~519 is necessary to
% prevent mechanism parameters from overriding global entity parameters.
% i.e., check which value is used given conflict b/w entity and mech parms

% get input structure into the right form
if isempty(spec)
  model=[]; IC=[]; functions=[]; auxvars=[]; sys=[]; Sodes=[]; Svars=[]; txt=[];
  return;
end
if ~isfield(spec,'connections')
  if isfield(spec,'mechanisms')
    if isfield(spec,'N')
      for i=1:length(spec)
        spec(i).multiplicity = spec(i).N;
      end
      spec = rmfield(spec,'N');
    end
    tmp.entities = spec;
    if isfield(spec,'files')
      tmp.files = spec(1).files;
    end
    spec=tmp; clear tmp
  end
  spec.connections.label='';
  spec.connections.mechanisms={};
  spec.connections.parameters={};
end
nodefield='entities';
if isfield(spec,'cells') && ~isfield(spec,'entities')
  nodefield='cells';
  spec.entities = spec.cells;
  spec = rmfield(spec,'cells');
elseif isfield(spec,'nodes') && ~isfield(spec,'entities')
  nodefield='nodes';
  spec.entities = spec.nodes;
  spec = rmfield(spec,'nodes');
end
if isempty(spec.entities)
  model=[];
  IC=[];
  functions=[];
  auxvars=[];
  sys=spec;
  Sodes=[];
  Svars=[];
  txt='';
  return;
end
if isfield(spec,'connections') && any(size(spec.connections)<length(spec.entities))
  n=length(spec.entities);
  spec.connections(n,n)=spec.connections(1);
  spec.connections(n,n).label=[];
  spec.connections(n,n).mechanisms=[];
  spec.connections(n,n).parameters=[];
end
if ~isfield(spec.entities,'label')
  for i=1:length(spec.entities)
    spec.entities(i).label = sprintf('node%g',i);
  end
end
if ~isfield(spec.entities,'multiplicity')
  for i=1:length(spec.entities)
    spec.entities(i).multiplicity = 1;
  end
end
parms = mmil_args2parms( varargin, ...
                         {  ...
                            'logfid',1,[],...
                            'override',[],[],...
                            'dt',.01,[],...
                            'nofunctions',1,[],...
                            'verbose',1,[],...
                            'timelimits',[],[],...
                            'DBPATH',[],[],...
                            'couple_flag',0,[],...
                            'coder',0,[],...
                         }, false);
% note: override = {label,field,value,[arg]; ...}
fileID = parms.logfid;

if parms.coder==1 && exist('codegen')
  coderprefix = 'pset.p.';
  % (param struct in odefun).(param var below).(param name in buildmodel)
else
  coderprefix = '';
end

if ischar(spec)
  spec=loadspec(spec);
end
if isfield(spec,'files')
  spec.files = unique(spec.files);
else
  if isempty(parms.DBPATH)
    parms.DBPATH = '/space/mdeh3/9/halgdev/projects/jsherfey/code/modeler/database';
  end
  if ~exist(parms.DBPATH,'dir')
    parms.DBPATH = 'C:\Users\jsherfey\Desktop\My World\Code\modelers\database';
  end
  [allmechlist,allmechfiles]=get_mechlist(parms.DBPATH);
  % use stored mechs if user did not provide list of mech files
  spec.files = allmechfiles;
end

Elabels = {spec.entities.label}; % Entity labels
Clabels = {spec.connections.label};

% override parameters in specification
if ~isempty(parms.override)
  o = parms.override;
  [nover,ncols] = size(o);
  for k = 1:nover
    l = o{k,1}; f = o{k,2}; v = o{k,3};
    if ncols>3, a = o{k,4}; else a = []; end
    if ~ischar(l) || ~ischar(f), continue; end
    if ismember(l,Elabels), type='entities';
    elseif ismember(l,Clabels), type='connections';
    else continue;
    end
    n = strmatch(l,{spec.(type).label},'exact');
    if isequal(f,'N'), f='multiplicity'; end
    if isequal(f,'parameters')
      if isempty(spec.(type)(n).(f)), continue; end
      matched = find(cellfun(@(x)isequal(v,x),spec.(type)(n).(f)));
      if ~isempty(matched)
        spec.(type)(n).(f){matched+1} = a;
      else
        spec.(type)(n).(f){end+1} = v;
        spec.(type)(n).(f){end+1} = a;
      end
    else
      spec.(type)(n).(f) = v;
    end
  end
  clear o nover ncols l f v a n
end

I=find([spec.entities.multiplicity]~=0);
spec.entities = spec.entities(I);
spec.connections = spec.connections(I,I);
Elabels = {spec.entities.label}; % Entity labels
Clabels = {spec.connections.label};

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Load complete spec (including all mech structs)
% specpath='/space/mdeh3/9/halgdev/projects/jsherfey/model/adv/new_spec/pfc_nmda';
% spec=loadspec(specpath);

sys = spec;
NE = [spec.entities.multiplicity];
N = length(spec.entities);
if issubfield(spec,'simulation.sim_dt')
  dt=spec.simulation.sim_dt;
else
  dt=parms.dt;
end
if issubfield(spec,'simulation.timelimits')
  timelimits = spec.simulation.timelimits;
else
  timelimits = parms.timelimits;
end
if parms.coder==1 && exist('codegen')
  modelparams.dt = dt;
  modelparams.timelimits = timelimits;
end
% combine intrinsic and connection mechanisms per entity; load mech models
mechtype={}; % 0=connection, 1=intrinsic
mechsrc=[]; mechdst=[];
for i=1:N % loop over entities
  clear m1 m2 p1 p2 inp1 inp2
  if ~isfield(spec.entities,'mechanisms')
    spec.entities(i).mechanisms = [];
  end
  m1 = spec.entities(i).mechanisms;
  if length(m1)>0
    [p1{1:length(m1)}]=deal(spec.entities(i).parameters);
  else
    p1=spec.entities(i).parameters;
  end
  inp1=num2cell(i*ones(1,length(m1)));
  m2={spec.connections(:,i).mechanisms};
  p2={spec.connections(:,i).parameters};
  sel=find(~cellfun(@isempty,m2));
  inp2=num2cell(sel);
  m2=m2(sel);
  p2=p2(sel);
  mechtype{i}=ones(size(m1));
  mechsrc{i}=i*ones(size(m1)); mechdst{i}=i*ones(size(m1));
  if ~isempty(m2) % there are connections to this entity
    tmpm={}; tmpp={}; tmpinp={};
    for j=1:length(m2)
      if ~iscell(m2{j})
        tmp=strread(m2{j},'%s','delimiter',' '); % multiple mechanisms are separated by a space
      else
        tmp=m2{j};
      end
      if size(tmp,2)>1, tmp=tmp'; end
      tmpm=cat(2,tmpm,tmp');
      tmpp=cat(2,tmpp,cat(2,repmat(p2(j),[1 length(tmp)])));
      tmpinp=cat(2,tmpinp,cat(2,repmat(inp2(j),[1 length(tmp)])));
      mechtype{i} = [mechtype{i} zeros(1,length(tmp))];
      mechsrc{i} = [mechsrc{i} sel(j)*ones(1,length(tmp))];
      mechdst{i} = [mechdst{i} i*ones(1,length(tmp))];
    end
    m2=tmpm;
    p2=tmpp;
    inp2=tmpinp;
    %mechtype{i} = [mechtype{i} zeros(size(m2))];
  end
  if size(m2,1)>1, m2=m2'; end
  mechs=cat(2,m1,m2); % combine intrinsic and connection mechanisms
  sys.entities(i).mechanisms = mechs;
%   if isempty(p1) || (iscell(p1) && isempty([p1{:}])), p1={}; end % added 23-May-2014
%   if isempty(p2) || (iscell(p2) && isempty([p2{:}])), p2={}; end % added 23-May-2014

%   if ~isempty(p1) && iscell(p1)
%     p1=p1(~cellfun(@isempty,p1));
%   end
%   if ~isempty(p2) && iscell(p2)
%     p2=p2(~cellfun(@isempty,p2));
%   end

  sys.entities(i).parameters = cat(2,p1,p2);
%   if isempty(sys.entities(i).parameters)
%     sys.entities(i).parameters=[];
%   end
%   if ~isempty(sys.entities(i).parameters) && iscellstr(sys.entities(i).parameters(1:2:end))
%     sys.entities(i).parameters={sys.entities(i).parameters};     % added 23-May-2014
%   end
  sys.entities(i).inputs = cat(2,inp1,inp2);
  if ~iscell(sys.entities(i).dynamics) && ~isempty(sys.entities(i).dynamics)
    sys.entities(i).dynamics = strread(sys.entities(i).dynamics,'%s','delimiter',' ');
  end
  M=length(mechs);
  % load mechanism models from text files
  for j=1:M
    ML=mechs{j};
    % check for existing intrinsic mechanism
    if issubfield(sys.entities(i),'mechs.label')
      if ismember(ML,{sys.entities(i).mechs.label}) && length(sys.entities(i).mechs)>=j
        if isempty(parms.override)
          continue; % mechanism model already provided by user
        end
      end
    end
    % check for existing connection mechanism
    tmpc=sys.connections(mechsrc{i}(j),i);
    if issubfield(tmpc,'mechs.label') %any(arrayfun(@(x)issubfield(x,'mechs.label'),sys.connections(:,i))) %issubfield(sys.connections(i),'mechs.label')
      if any(cellfun(@(x)isequal(ML,x),{tmpc.mechs.label}))
        idx = find(cellfun(@(x)isequal(ML,x),{tmpc.mechs.label}));
        if isempty(sys.entities(i).mechs)
          sys.entities(i).mechs = tmpc.mechs(idx(1));
        else
          sys.entities(i).mechs(j) = tmpc.mechs(idx(1));
        end
        if isempty(parms.override)
          continue;
        end
      end
    end
    % load mechanism from file
    if exist(fullfile(pwd,[ML '.txt.']),'file')
      file = fullfile(pwd,[ML '.txt.']);
      if iscell(sys.files) && ~ismember(file,sys.files)
        idx = regexp(sys.files,sprintf('(^%s|/%s|\\\\%s).txt',ML,ML,ML));
        idx = find(~cellfun(@isempty,idx));
        if ~isempty(idx)
          sys.files(idx)=[];
        end
        sys.files{end+1} = file;
      end
    else
      idx = regexp(spec.files,sprintf('(^%s|/%s|\\\\%s).txt',ML,ML,ML));
      idx = find(~cellfun(@isempty,idx));
      if length(idx) ~= 1
        if exist(fullfile(pwd,[ML '.txt']),'file')
          file = fullfile(pwd,[ML '.txt']);
        else
          fprintf('Looking in known mech list for %s\n',ML);
          [jnk,knownfiles] = get_mechlist;
          idx = regexp(knownfiles,sprintf('(^%s|/%s|\\\\%s).txt',ML,ML,ML));
          idx = find(~cellfun(@isempty,idx));
          if length(idx) ~= 1
            error('Failed to find a distinct specification file for mechanism: %s',ML);
          else
            file = knownfiles{idx};
            fprintf('Found mech file. Using: %s\n',file);
          end
        end
      else
        file = spec.files{idx};
      end
    end
    this = parse_mech_spec(file,[]); % includes mech parameters
    try
      this.label = ML;
      sys.entities(i).mechs(j) = this;
    catch
      sys.entities(i).mechs(j) = this;
    end
  end
  % remove old mech models
  if issubfield(sys.entities(i),'mechs.label')
    test = setdiff({sys.entities(i).mechs.label},sys.entities(i).mechanisms);
    if ~isempty(test)
      sys.entities(i).mechs(ismember({sys.entities(i).mechs.label},test))=[];
    end
  end
end

% Compute total number of state vars, params, funcs, expressions
nGvar=sum(cellfun(@length,{sys.entities.dynamics}));
nMvar=0;
nGparm=0;
nMparm=0;
nfunc=0;
nexpr=0;
nsubst=0;
nmech=0;
for k=1:N
  if isfield(sys.entities(k),'mechs')
    nmech=nmech+length(sys.entities(k).mechs);
  else
    continue;
  end
  if issubfield(sys.entities(k),'mechs.params')
    if any(arrayfun(@(x)isempty(x.params),sys.entities(k).mechs))
      for i=1:length(sys.entities(k).mechs)
        if ~isempty(sys.entities(k).mechs(i).params)
          nMparm=nMparm+length(fieldnames(sys.entities(k).mechs(i).params));
        end
      end
    else
      nMparm=nMparm+sum(arrayfun(@(x)length(fieldnames(x.params)),sys.entities(k).mechs));
    end
  end
  if ~isempty(sys.entities(k).parameters) && ischar(sys.entities(k).parameters{1})
    nGparm=nGparm+length(sys.entities(k).parameters)/2;
  else
    nGparm=nGparm+sum(cellfun(@(x)length(x),sys.entities(k).parameters)/2);
  end
  if issubfield(sys.entities(k),'mechs.odes')
    nMvar=nMvar+sum(cellfun(@(y)size(y,1),{sys.entities(k).mechs.odes}));
  end
  if issubfield(sys.entities(k),'mechs.functions')
    nfunc=nfunc+sum(cellfun(@(y)size(y,1),{sys.entities(k).mechs.functions}));
  end
  if issubfield(sys.entities(k),'mechs.auxvars')
    nexpr=nexpr+sum(cellfun(@(y)size(y,1),{sys.entities(k).mechs.auxvars}));
  end
  if issubfield(sys.entities(k),'mechs.substitute')
    nsubst=nsubst+sum(cellfun(@(y)size(y,1),{sys.entities(k).mechs.substitute}));
  end
end

nvar=nGvar+nMvar;
nparm=nGparm+nMparm;
%[nGvar nMvar nvar nGparm nMparm nparm nfunc nexpr nmech]

% Preallocate indicator/mapping vectors
Svars = cell(nvar,3); % {label, prefix_label, indices, IC}
Sodes = cell(nvar,1); % F, var'=F (differential equation)
Spop = zeros(nvar,1);
Smech = zeros(nvar,1);
Stype = zeros(nvar,1);
Pdata = cell(nparm,2); % {label, value}
Ppop = zeros(nparm,1);
Pmech = zeros(nparm,1);
Ptype = zeros(nparm,1);
Cexpr = cell(nexpr,3); % {label, prefix_label, expression}
Cpop = zeros(nexpr,1);
Cmech = zeros(nexpr,1);
Hfunc = cell(nfunc,3); % {label, prefix_label, function}
Hpop = zeros(nfunc,1);
Hmech = zeros(nfunc,1);
Tsubst = cell(nsubst,2); % {entity ode label, mech term}
Tpop = zeros(nsubst,1);
Tmech = zeros(nsubst,1);
Minputs = cell(nmech,1); % entity #s of input mechs
Mlabels = cell(nmech,1);
Mid=zeros(nmech,1);
% Create list of state variables Svars (label, prefix_label, indices) & odes Sodes over all populations and mechanisms
%      Sg: pop_var. Smk: pop_mech_var. I=cnt+(1:NE). odes = Og & Fmk
%      + associated lists of entity ids Spop (entity indices), and vector Stype of type indicators (0 if in Sg; m if in Sm)
% Create list of parameters Pdata (label, value) over all populations and mechanisms
%      + associated lists of Ppop, Pmech, and Ptype (0 if in Pg; m if in Pm); note: do not explicitly store Pg & Pm separately
% Create list of expressions: Cexpr (LHS: label, prefix_label. RHS: expression) over all mechanisms|populations
%      Cmk: pop_mech_label
%      + associated lists of Cpop (entity index) and Cmech (mech index)
% Create list of functions: Hfunc (LHS: label, prefix_label, inputs) over all mechanisms|populations
%      Hmk: pop_mech_label
%      + associated lists of Hpop (entity index) and Hmech (mech index)

% COLLECT MODEL INFO
scnt=0; % state var label index
stateindx=0; % state var vector indices
pcnt=0; ccnt=0; hcnt=0; tcnt=0; mcnt=0;
EL = {sys.entities.label};
for i=1:N
  E=sys.entities(i); n=length(E.dynamics); I=scnt+(1:n);
%   % correct for savejson() effects (added 01-Aug-2014)
%   tmp=E.dynamics; if isempty(tmp), tmp={}; elseif ischar(tmp), tmp={tmp}; end; E.dynamics=tmp;
%   % -----
  % entity-level state variables
  tmp=regexp(E.dynamics,'\w+''','match');
  tmp=cellfun(@(x)x{1}(1:end-1),tmp,'unif',0);
  [Svars{I,1}]=deal(tmp{:});                % varlabel
  for j=1:length(I)
    Svars{I(j),2}=[EL{i} '_' tmp{j}];       % E_varlabel
    Svars{I(j),3}=stateindx+(1:NE(i));      % state vector indices
    Svars{I(j),4}= ['[' num2str(zeros(1,NE(i))) ']'];           % initial conditions
    stateindx=stateindx+NE(i);
  end
  % entity-level dynamics
  tmp=regexp(E.dynamics,'=(.)*','match');
  tmp=cellfun(@(x)x{1}(2:end),tmp,'unif',0);
  [Sodes{I}]=deal(tmp{:});                  % ODEs
  Spop(I)=i;
  Smech(I)=0;
  Stype(I)=0;                               % var scope (0=global)
  scnt=scnt+n;
  % store enitity-level parameters if no mechanisms
  if length(E.mechanisms)==0
    if ~isempty(E.parameters) && ~iscell(E.parameters{1})  % USER PARAMETERS
      n=length(E.parameters)/2; I=pcnt+(1:n);
      keys=E.parameters(1:2:end);
      vals=E.parameters(2:2:end);
      if parms.coder==0 || ~exist('codegen')
        [Pdata{I,1}]=deal(keys{:});
        [Pdata{I,2}]=deal(vals{:});
      else
        for j=1:length(I)
          newlabel=[EL{i} '_' keys{j}];
          Pdata{I(j),1} = keys{j};
          Pdata{I(j),2} = newlabel;
          modelparams.(newlabel) = vals{j};
        end
      end
      Ppop(I)=i;
      Pmech(I)=0;
      Ptype(I)=0;
      pcnt=pcnt+n;
    end
  end
  % store mechanism info
  for m=1:length(E.mechanisms)
    mcnt=mcnt+1;
    Mid(mcnt)=mcnt;
    M=E.mechs(m);
%     % correct for savejson() effects (added 01-Aug-2014)
%     tmp=M.statevars; if isempty(tmp), tmp={}; elseif ischar(tmp), tmp={tmp}; end; M.statevars=tmp;
%     tmp=M.odes; if isempty(tmp), tmp={}; elseif ischar(tmp), tmp={tmp}; end; M.odes=tmp;
%     tmp=M.ic; if isempty(tmp), tmp={}; elseif ischar(tmp), tmp={tmp}; end; M.ic=tmp;
%     % ------
    Minputs{mcnt}=E.inputs{m};
    Mlabels{mcnt}=E.mechanisms{m};
    if Minputs{mcnt}~=i || mechtype{i}(m)==0 % connection or input from another population
      prefix = [EL{Minputs{mcnt}} '_' EL{i} '_' Mlabels{mcnt}];
    else
      prefix = [EL{i} '_' Mlabels{mcnt}];
    end
    % entity-level parameters
    if ~isempty(E.parameters{m})  % USER PARAMETERS
      if numel(E.parameters)==numel(E.mechanisms)
        n=length(E.parameters{m})/2; I=pcnt+(1:n);
        keys=E.parameters{m}(1:2:end);
        vals=E.parameters{m}(2:2:end);
      else
        n=floor(length(E.parameters)/2); I=pcnt+(1:n);
        keys=E.parameters(1:2:2*n);
        vals=E.parameters(2:2:2*n);
      end
      if parms.coder==0 || ~exist('codegen')
        [Pdata{I,1}]=deal(keys{:});
        [Pdata{I,2}]=deal(vals{:});
      else
        for j=1:length(I)
          %newlabel=[EL{i} '_' keys{j}];
          newlabel=[prefix '_' keys{j}];
          Pdata{I(j),1} = keys{j};
          Pdata{I(j),2} = newlabel;
          modelparams.(newlabel) = vals{j};
        end
      end
      Ppop(I)=i;
      Pmech(I)=mcnt;
      Ptype(I)=0;
      pcnt=pcnt+n;
    end
    % mechanism-level state variables
    if ~isempty(M.statevars)      % MECH STATE VARS
      tmp=M.statevars;
      n=length(tmp); I=scnt+(1:n);
      [Svars{I,1}]=deal(tmp{:});                            % varlabel
      for j=1:length(I)
        Svars{I(j),2}=[prefix '_' tmp{j}]; % E_M_varlabel
        Svars{I(j),3}=stateindx+(1:NE(i));                  % state vector indices
        Svars{I(j),4}=M.ic{j};                              % initial conditions
        stateindx=stateindx+NE(i);
      end
      [Sodes{I}]=deal(M.odes{:});                           % ODEs
      Spop(I)=i;
      Smech(I)=mcnt;
      Stype(I)=1;                                           % var scope (0=global)
      scnt=scnt+n;
    end
    % mechanism-level parameters
    if ~isempty(M.params)         % DEFAULT MECH PARAMETERS
      keys=fieldnames(M.params);
      vals=struct2cell(M.params);
      n=length(keys); I=pcnt+(1:n);
      if parms.coder==0 || ~exist('codegen')
        [Pdata{I,1}]=deal(keys{:});
        [Pdata{I,2}]=deal(vals{:});
      else
        for j=1:length(I)
          %if ~isfield(modelparams,[EL{i} '_' keys{j}]) % use only if not specified at entity level
          if ~isfield(modelparams,[prefix '_' keys{j}]) % use only if not specified at entity level
            newlabel=[prefix '_' keys{j}];
            Pdata{I(j),1} = keys{j};
            Pdata{I(j),2} = newlabel;
            modelparams.(newlabel) = vals{j};
          end
        end
      end
      Ppop(I)=i;
      Pmech(I)=mcnt;
      Ptype(I)=1;
      pcnt=pcnt+n;
    end
    % mechanism-level auxiliary variables/expression
    if ~isempty(M.auxvars)        % MECH EXPRESSIONS (label,prefix_label,expression)
      LHS=M.auxvars(:,1); RHS=M.auxvars(:,2);
      n=length(LHS); I=ccnt+(1:n);
      [Cexpr{I,1}]=deal(LHS{:});              % exprlabel
      [Cexpr{I,3}]=deal(RHS{:});              % expression
      Cpop(I)=i;
      Cmech(I)=mcnt;
      for j=1:length(I)
        if ~any(regexp(LHS{j},'[\[\]\(\)]+')) % added 08-Jun-2014
          Cexpr{I(j),2}=[prefix '_' LHS{j}];    % E_M_exprlabel
        else
          tmps=regexp(LHS{j},'[a-z_A-Z]+','match');
          for jj=1:length(tmps)
            LHS{j}=strrep(LHS{j},tmps{jj},[prefix '_' tmps{jj}]);
          end
          Cexpr{I(j),2}=LHS{j};                 % exprlabel
        end
      end
      ccnt=ccnt+n;
    end
    % mechanism-level functions
    if ~isempty(M.functions)      % MECH FUNCTIONS  (label,prefix_label,function)
      LHS=M.functions(:,1); RHS=M.functions(:,2);
      n=length(LHS); I=hcnt+(1:n);
      [Hfunc{I,1}]=deal(LHS{:});              % funclabel
      [Hfunc{I,3}]=deal(RHS{:});              % function
      Hpop(I)=i;
      Hmech(I)=mcnt;
      for j=1:length(I)
        Hfunc{I(j),2}=[prefix '_' LHS{j}];    % E_M_exprlabel
      end
      hcnt=hcnt+n;
    end
    % mechanism-level interface statements
    if ~isempty(M.substitute)     % SUBSTITUTIONS {entity ode label, mech term}
      LHS=M.substitute(:,1); RHS=M.substitute(:,2);
      n=length(LHS); I=tcnt+(1:n);
      [Tsubst{I,1}]=deal(LHS{:});              % subst label
      [Tsubst{I,2}]=deal(RHS{:});              % term to insert
      Tpop(I)=i;
      Tmech(I)=mcnt;
      tcnt=tcnt+n;
    end
  end
end
% ----------------------------------
Stype(ismember(Svars(:,1),Tsubst(:,1)))=0; % make global if in substitution term
% ----------------------------------
% [Mid,Mlabels,Minputs] % mech ids, labels, input populations
% Sodes: (differential equation = F: var'=F )
% Svars: {label, prefix_label, indices, IC}
% Pdata: {label, value}
% [Stype  Spop Smech] % variables
% [Ptype  Ppop Pmech] % parameters
% Cexpr, [Cpop Cmech] % expressions:        {label, prefix_label, expression}
% Hfunc, [Hpop Hmech] % functions:          {label, prefix_label, function}
% Tsubst,[Tpop Tmech] % term substitutions: {label, mech_term}

% PERFORM SUBSTITUTIONS
% substitutions into mechanism data
Hfunc0=Hfunc; Cexpr0=Cexpr; Sodes0=Sodes; Tsubst0=Tsubst; Svars0=Svars;
for m=1:nmech
  f=Hfunc(Hmech==m,3);
  e=Cexpr(Cmech==m,3);
  o=Sodes(Smech==m);
  t=Tsubst(Tmech==m,2);
  ic=Svars(Smech==m,4);
  % substitute global user params: into (expressions, functions, odes, terms)
  old=Pdata(Pmech==m & Ptype==0,1); new=Pdata(Pmech==m & Ptype==0,2);
  if parms.coder==1 && exist('codegen')
    for k=1:length(new)
      if ischar(new{k}), new{k}=[coderprefix new{k}]; end;
    end
  end
  [f,e,o,t,ic]=substitute(old,new,f,e,o,t,ic);
  % substitute default mech params | same pop & mech: into (expressions, functions, odes, terms)
  old=Pdata(Pmech==m & Ptype==1,1); new=Pdata(Pmech==m & Ptype==1,2);
  if parms.coder==1 && exist('codegen')
    for k=1:length(new)
      if ischar(new{k}), new{k}=[coderprefix new{k}]; end;
    end
  end
  [f,e,o,t,ic]=substitute(old,new,f,e,o,t,ic);
  % substitute reserved keywords: into (expressions, functions, odes, terms)
  k0=unique(Tpop(Tmech==m));
  n0=NE(k0); % target pop size (postsynaptic)
  if m>0, k1=Minputs{m}(1); else k1=k0; end
  n1=NE(k1); % source pop size (presynaptic)
  if parms.coder==0 || ~exist('codegen')
    old={'Npre','N[1]','Npost','N[0]','Npop','dt'};
    new={n1,n1,n0,n0,n0,dt};
    if ~isempty(timelimits)
      old = {old{:},'timelimits(1)','timelimits(2)','timelimits'};
      new = {new{:},timelimits(1),timelimits(2),sprintf('[%g %g]',timelimits)};
    end
  else
    src=[EL{k1} '_Npop'];
    dst=[EL{k0} '_Npop'];
    old={'Npre','N[1]','Npost','N[0]','Npop','timelimits'};
    new={src,src,dst,dst,dst,'timelimits'};
    if ~isfield(modelparams,src), modelparams.(src)=n1; end
    if ~isfield(modelparams,dst), modelparams.(dst)=n0; end
    for k=1:length(new)
      if ischar(new{k}), new{k}=[coderprefix new{k}]; end;
    end
  end
  [f,e,o,t,ic]=substitute(old,new,f,e,o,t,ic);
  % ------------------------------------------------
  % go ahead and substitute values into ICs for coder
  if parms.coder==1 && exist('codegen')
    old2a=Pdata(Pmech==m & Ptype==0,2); % entity params
    old2b=Pdata(Pmech==m & Ptype==1,2); % mechanism params
    old2c={src,dst,dst}';               % reserved params
    old2=cat(1,old2a,old2b,old2c);
    new={}; old={};
    for k=1:length(old2)
      if ~isempty(old2{k})
        old{end+1}=[coderprefix old2{k}];
        new{end+1}=modelparams.(old2{k});
      end
    end
    ic=substitute(old,new,ic);
  end
  % ------------------------------------------------
  % substitute prefixed-auxvars/expressions: into (expressions, functions, odes, terms)
  old=Cexpr(Cmech==m,1); new=Cexpr(Cmech==m,2);
  tmpind=find(~cellfun(@isempty,regexp(old,'[\[\]\(\)]+')));
  if ~isempty(tmpind)
    tmpold=old; old={};
    tmpnew=new; new={};
    for k=1:length(tmpold)
      if ismember(k,tmpind)
        tmps=regexp(tmpold{k},'\w+','match');
        old=cat(2,old,tmps);
        tmps=regexp(tmpnew{k},'\w+','match');
        new=cat(2,new,tmps);
      else
        old{end+1}=tmpold{k};
        new{end+1}=tmpnew{k};
      end
    end
  end
  [f,e,o,t]=substitute(old,new,f,e,o,t);
  % substitute prefixed functions: into (functions, odes, terms)
  old=Hfunc(Hmech==m,1); new=Hfunc(Hmech==m,2);
  [f,o,t]=substitute(old,new,f,o,t);
  % substitute prefixed state vars (Sg(E) => Sg(~E) => Sm(E) => S~m(E)): into (odes, terms)
  E=unique(Tpop(Tmech==m));
  if isempty(E) % added 26-May-2014
    continue;
  end
  old=Svars(Spop==E & (Smech==m | Stype==0),1);
  new=Svars(Spop==E & (Smech==m | Stype==0),2);
  old2={}; new2={}; old3={}; new3={};
  for k=1:length(old), old2{k}=[old{k} '[0]']; new2{k}=new{k}; end
  for k=1:length(old)
    old3{k}=[old{k} '[1]'];
    new3{k}= [EL{k1} new{k}(find(new{k}=='_',1,'first'):end)];
  end
  [f,o,t]=substitute(old3,new3,f,o,t);
  [f,o,t]=substitute(old2,new2,f,o,t);
  [f,o,t]=substitute(old,new,f,o,t);
  for k=1:length(old), old2{k}=[old{k} 'post']; new2{k}=new{k}; end
  for k=1:length(old)
    old3{k}=[old{k} 'pre'];
    new3{k}= [EL{k1} new{k}(find(new{k}=='_',1,'first'):end)];
  end
  [o,t]=substitute(old3,new3,o,t);
  [o,t]=substitute(old2,new2,o,t);
  % substitute IN & OUT into (odes, interface terms)
  newOUT=Svars(Spop==E & Stype==0,2); if ~isempty(newOUT), newOUT=newOUT{1}; end
  newIN=Svars(Spop==k1 & Stype==0,2); if ~isempty(newIN), newIN=newIN{1}; end
  old={'IN','OUT','X'};
  new={newIN,newOUT,newOUT};
  [o,t]=substitute(old,new,o,t);
  % update model arrays
  Hfunc(Hmech==m,3)=f;
  Cexpr(Cmech==m,3)=e;
  Sodes(Smech==m)=o;
  Tsubst(Tmech==m,2)=t;
  Svars(Smech==m,4)=ic;
end
% substitutions into entity-level dynamics
E=unique(Spop(Stype==0));
for e=1:length(E)
  idx=(Stype==0 & Spop==E(e));
  o=Sodes(idx);
  % state variables into odes
  old=Svars(idx,1); new=Svars(idx,2);
  o=substitute(old,new,o);
  % parameters into odes
  old=Pdata(Ptype==0,1); new=Pdata(Ptype==0,2);
  if parms.coder==1 && exist('codegen')
    for k=1:length(new)
      if ischar(new{k}), new{k}=[coderprefix new{k}]; end;
    end
  end
  o=substitute(old,new,o);
  % reserve keywords into odes
  n0=NE(e);
  if parms.coder==0 || ~exist('codegen')
    old={'Npost','N[0]','Npop','dt'};
    new={n0,n0,n0,dt};
  else
    dst=[EL{e} '_Npop'];
    old={'Npost','N[0]','Npop'};
    new={dst,dst,dst};
    for k=1:length(new)
      if ischar(new{k}), new{k}=[coderprefix new{k}]; end;
    end
    if ~isfield(modelparams,dst), modelparams.(dst)=n0; end
  end
  o=substitute(old,new,o);
  % ----------------------------------
  % interface statements (functions only) into odes
  tmp=ismember(Tsubst(:,1),Hfunc(:,1))&(Tpop==E(e)); % limit to within-entity substitutions
  old=Tsubst(tmp,1); new=Tsubst(tmp,2);
  % ---
  % additive substitution (17-Oct-2014)
  for k=1:numel(new)
      new{k}=['((' new{k} ')+' old{k} ')'];
  end
  o=substitute(old,new,o);
  % remove function substitution placeholders (added 21-Feb-2015 to prevent another downstream substitution
  for k=1:numel(new)
      new{k}='0';
  end
  o=substitute(old,new,o);
  % ----------------------------------
  Sodes(idx)=o;
end

% ELIMINATE FUNCTION CALLS
Hfunc0=Hfunc; Sodes0=Sodes; Tsubst0=Tsubst;
if parms.nofunctions
  try
  % Substitute functions into functions
  keep_going=1; cnt=0;
  while keep_going
    keep_going=0; cnt=cnt+1;
    for t=1:size(Hfunc,1)
      target=Hfunc{t,3};
      % match function labels between functions and their dependencies
      pat = @(s)sprintf('(\\W+%s)|(^%s)\\(',s,s); % function label pattern
      funcinds=find(~cellfun(@isempty,cellfun(@(s)regexp(target,pat(s)),Hfunc(:,2),'unif',0)));
      for f=1:length(funcinds)
        keep_going=1;
        ind = funcinds(f);
        submatch = regexp(target,[Hfunc{ind,2} '\([\w\s,]*\)'],'match');
        %submatch = regexp(target,[Hfunc{ind,2} '[\w\s,]*'],'match');
        %submatch = regexp(target,[Hfunc{ind,2} '\(.*\)'],'match');
        %subvars = regexp(strrep(submatch,Hfunc{ind,2},''),'\([a-zA-Z]\w*\)','match');
        if ~isempty(submatch)
            subvars = regexp(strrep(submatch,Hfunc{ind,2},''),'[a-zA-Z]\w*','match');
            subvars = unique([subvars{:}]);
            subvars = cellfun(@(s)strrep(s,'(',''),subvars,'unif',0);
            subvars = cellfun(@(s)strrep(s,')',''),subvars,'unif',0);
            str = Hfunc{ind,3};
            vars = regexp(str,'@\([\s\w,]*\)','match');
            expr = strtrim(strrep(str,vars,''));
            vars = regexp(vars,'\w+','match');
            vars = [vars{:}];
            if length(vars)~=length(subvars)
              error('coding error in buildmodel2 when inserting full expressions into terms Tmk');
            end
            expr = substitute(vars,subvars,expr);
            target = strrep(target,submatch{1},['(' expr{1} ')']);
        end
      end
      Hfunc{t,3}=target;
    end
  end

  % Substitute functions into ODEs
  for t=1:size(Sodes,1)
    target=Sodes{t,1};
    % match function labels between functions and their dependencies
    pat = @(s)sprintf('(\\W+%s)|(^%s)\\(',s,s); % function label pattern
    funcinds=find(~cellfun(@isempty,cellfun(@(s)regexp(target,pat(s)),Hfunc(:,2),'unif',0)));
    for f=1:length(funcinds)
      ind = funcinds(f);
      submatch = regexp(target,[Hfunc{ind,2} '\([\w\s,]*\)'],'match');       %submatch = regexp(target,[Hfunc{ind,2} '\(.*\)'],'match');
%       if isempty(submatch), continue; end
      %subvars = regexp(strrep(submatch,Hfunc{ind,2},''),'\([a-zA-Z]\w*\)','match');
      if ~isempty(submatch)
          subvars = regexp(strrep(submatch,Hfunc{ind,2},''),'[a-zA-Z]\w*','match');
          subvars = [subvars{:}];
          subvars = cellfun(@(s)strrep(s,'(',''),subvars,'unif',0);
          subvars = cellfun(@(s)strrep(s,')',''),subvars,'unif',0);
          str = Hfunc{ind,3};
          vars = regexp(str,'@\([\s\w,]*\)','match');
          expr = strtrim(strrep(str,vars,''));
          vars = regexp(vars,'\w+','match');
          vars = [vars{:}];
          if length(vars)~=length(subvars)
            error('coding error in buildmodel2 when inserting full expressions into terms Tmk');
          end
          expr = substitute(vars,subvars,expr);
          target = strrep(target,submatch{1},['(' expr{1} ')']);
      end
    end
    Sodes{t,1}=target;
  end

  % Substitute functions into enitity-dynamic-substitution terms
  for t=1:size(Tsubst,1)
    % match function labels to substitution terms
    %pat = @(s)sprintf('(\\W+%s)|(^%s\\W+)',s,s);
    pat = @(s)sprintf('(\\W+%s)|(^%s)\\(',s,s); % function label pattern
    funcinds=find(~cellfun(@isempty,cellfun(@(s)regexp(Tsubst{t,2},pat(s)),Hfunc(:,2),'unif',0)));
    for f=1:length(funcinds)
      ind = funcinds(f);
      submatch = regexp(Tsubst{t,2},[Hfunc{ind,2} '\(.*\)'],'match');
%       if isempty(submatch), continue; end
      if ~isempty(submatch)
          subvars = regexp(strrep(submatch,Hfunc{ind,2},''),'[a-z_A-Z]\w*','match');
          %subvars = regexp(strrep(submatch,Hfunc{ind,2},''),'\w+','match');
          subvars = [subvars{:}];
          str = Hfunc{ind,3};
          vars = regexp(str,'@\([\s\w,]*\)','match');
          expr = strtrim(strrep(str,vars,''));
          vars = regexp(vars,'\w+','match');
          vars = [vars{:}];
          if length(vars)~=length(subvars)
            error('coding error in buildmodel2 when inserting full expressions into terms Tmk');
          end
          expr = substitute(vars,subvars,expr);
          Tsubst{t,2} = strrep(Tsubst{t,2},submatch{1},['(' expr{1} ')']);
      end
    end
  end
  catch
    Hfunc=Hfunc0;
    Sodes=Sodes0;
    Tsubst=Tsubst0;
  end
end

% Insert terms Tmk into entity dynamics
for t=1:size(Tsubst,1)
  idx = (Stype==0 & Spop==Tpop(t));
  o = Sodes(idx);
  old=Tsubst{t,1}; new=['((' Tsubst{t,2} ')+' old ')'];
  Sodes(idx)=substitute(old,new,o);
  o = Sodes0(idx);
  old=Tsubst0{t,1}; new=['((' Tsubst0{t,2} ')+' old ')'];
  Sodes0(idx)=substitute(old,new,o);
end

% Insert global entity state vars into other entity dnamics
% ADDED: 21-May-2014 (trial code - if broken, check here or where handling for no mechs was added)
alloldvars=Svars(:,1);
allnewvars=Svars(:,2);
if parms.couple_flag==1
  for i=1:nvar % loop over all state vars
    if Stype(i)==1 % skip intrinsic variables
      continue;
    end
    str=Sodes{i};
    for j=1:N % loop over all populations
      if Spop(i)==j % do not substitute this var's label here
        continue;
      end
      % get state vars for this population
      vars=alloldvars(Spop==j);
      newvars=allnewvars(Spop==j);
      types=Stype(Spop==j);
      if isempty(vars), continue; end
      for k=1:length(vars)
        if types(k)==1
          continue;
        end
        var=vars{k};
        subvar=newvars{k};
  %       var='U'; subvar='y_U';
  %       str='V./ U+E_V';%'E_V+U./';
        ops='+-/^\.\s\*';
        pat1=['^' var '$'];
        pat2=['^' var '[' ops ']'];
        pat3=['[' ops '\(]' var '[' ops '\)]'];
        pat4=['[' ops ']' var '$'];
        pat=sprintf('(%s|%s|%s|%s)',pat1,pat2,pat3,pat4);
        matches=regexp(str,pat,'match');
        for l=1:length(matches)
          newsub=strrep(matches{l},var,subvar);
          str=strrep(str,matches{l},newsub);
        end
      end
    end
    Sodes{i}=str;
  end
end

% -------------------------------------------------------
% TODO: Substitute other expressions into IC expressions
% ...
% -------------------------------------------------------

% Evaluate ICs and determine state vector indices
stateindx=0;
for i=1:nvar
  s=Svars{i,1};
  ic=Svars{i,4};
  Pg=Pdata(Ptype==0 & Ppop==Spop(i),:);
  if any(find(cellfun(@(x)isequal(x,[s '_IC']),Pg(:,1))))
    ind2=find(cellfun(@(x)isequal(x,[s '_IC']),Pg(:,1)));
    if parms.coder==0 || ~exist('codegen')
      icval=Pg{ind2(1),2};
    else
      icval=modelparams.(Pg{ind2(1),2});
    end
    if numel(icval)==1
      ic = sprintf('[%s]',num2str(ones(1,NE(Spop(i)))*icval));
    elseif numel(icval)==NE(Spop(i))
      ic = sprintf('[%s]',num2str(icval));
    elseif ischar(icval)
      ic = eval(icval);
    end
  end
  if ischar(ic) %&& (parms.coder==0 || ~exist('codegen'))
    ic=eval(ic);
  elseif numel(ic)==1
    ic=repmat(ic,[NE(Spop(i)) 1]);
  end
  if size(ic,1)<size(ic,2), ic=ic'; end
%   if any(find(cellfun(@(x)isequal(x,[s '_IC_noise']),Pg(:,1))))
%     ind2=find(cellfun(@(x)isequal(x,[s '_IC_noise']),Pg(:,1)));
%     if parms.coder==0 || ~exist('codegen')
%       icnoise=Pg{ind2(1),2};
%       ic=ic+icnoise.*rand(size(ic));
%     else
%       icnoise=modelparams.(Pg{ind2(1),2});
%       ic=ic+icnoise.*rand(size(ic));
%     end
%   end
  Svars{i,4}=ic;
  Svars{i,3}=stateindx+(1:length(ic));
  stateindx=stateindx+length(ic);
  if parms.coder==1 && exist('codegen')
    % store ICs for setting in odefun file using params.mat
    fld=sprintf('IC_%s',Svars{i,2});
    modelparams.(fld) = ic;
  end
end
IC=cat(1,Svars{:,4});

% Substitute state vector indices
old=Svars(:,2);
new=cell(size(old));
for k=1:length(new)
  new{k}=sprintf('X(%g:%g)',Svars{k,3}(1),Svars{k,3}(end));
end
SodesVec=substitute(old,new,Sodes);
old=unique(Tsubst(:,1)); clear new
[new{1:length(old)}]=deal('0');
SodesVec=substitute(old,new,SodesVec);%,Sodes
Sodes=substitute(old,new,Sodes);%,Sodes
Sodes0=substitute(old,new,Sodes0);%,Sodes

% Prepare model string for evaluation
model = SodesVec;
for k=1:nvar, if model{k}(end) ~= ';', model{k} = [model{k} ';']; end; end
model = ['@(t,X) [' [model{:}] '];'];

% How to use:
if 0
  for k = 1:size(Cexpr,1)
    eval( sprintf('%s = %s;',Cexpr{k,2},Cexpr{k,3}) );
  end
  for k = 1:size(Hfunc,1)
    eval( sprintf('%s = %s;',Hfunc{k,2},Hfunc{k,3}) );
  end
  model = eval(model);
  Y=model(0,IC);
end

functions=Hfunc(:,[2 3 1]);
auxvars=Cexpr(:,[2 3 1]);

% Collect equations in system struct
% For spec.entities(i) & spec.connections(i,j): auxvars=Cexpr(:,2:3); functions=Hfunc(:,2:3)
% Set spec.variables.entity=Spop; spec.variables.labels=Svars(:,2)
% For each entity i:
% 	spec.entities(i).var_index=cat(1,Svars{Spop==i,3})
% 	spec.entities(i).var_list=cat(1,Svars{Spop==i,2})
% 	spec.entities(i).orig_var_list=cat(1,Svars{Spop==i,1})
% 	also update: odes, ode_labels
sys.variables.entity=[];
sys.connections=[];
sys.connections.label = [];
sys.connections.mechanisms=[];
sys.connections.parameters=[];
sys.connections.mechs=[];
sys.connections(1:N,1:N)=sys.connections;
for i=1:N
  if isfield(sys.entities,'mechs')
    for j=1:length(sys.entities(i).mechs)
      p=sys.entities(i).parameters{j};
      if isempty(p), continue; end
      m=sys.entities(i).mechs(j);
      if ~isstruct(m.params), continue; end
      flds=fieldnames(m.params);
      if isempty(flds), continue; end
      [s1,s2]=match_str(flds,p(1:2:end));
      for k=1:length(s1)
        m.params.(flds{s1(k)}) = p{2*s2(k)};
      end
      sys.entities(i).mechs(j) = m;
    end
  end
  sys.entities(i).auxvars = auxvars(Cpop==i,:);
  sys.entities(i).functions = functions(Hpop==i,:);
  sys.entities(i).odes = Sodes(Spop==i);
  sys.entities(i).odes_str = Sodes0(Spop==i);
  sys.entities(i).ode_labels = Svars(Spop==i,2);
  sys.entities(i).var_index=cat(2,Svars{Spop==i,3});
  nhere=length(sys.entities(i).var_index);
  sys.entities(i).var_list={};%cell(1,length(sys.entities(i).var_index));
  sys.entities(i).orig_var_list={};%cell(1,length(sys.entities(i).var_index));
  ind=find(Spop==i);
  for j=1:length(ind)
    k=ind(j); nthis=length(Svars{ismember(Svars(:,2),Svars(k,2)),3});
    tmp=repmat(Svars(k,2),[1 nthis]);
    sys.entities(i).var_list      = {sys.entities(i).var_list{:} tmp{:}}; %repmat( Svars(Spop==i,2);
    tmp=repmat(Svars(k,1),[1 nthis]);
    sys.entities(i).orig_var_list = {sys.entities(i).orig_var_list{:} tmp{:}}; %sys.entities(i).orig_var_list=Svars(Spop==i,1);
  end
  sys.variables.entity=[sys.variables.entity i*ones(1,nhere)];
  if any(mechtype{i}==0) % connection mechanisms
    sys.entities(i).connection_mechanisms = sys.entities(i).mechanisms(mechtype{i}==0);
    if iscell(sys.entities(i).parameters) && ~isempty(sys.entities(i).parameters) && iscell(sys.entities(i).parameters{1})
      sys.entities(i).connection_parameters = sys.entities(i).parameters(mechtype{i}==0);
    else
      sys.entities(i).connection_parameters = [];
    end
    sys.entities(i).connection_mechs = sys.entities(i).mechs(mechtype{i}==0);
    connis=find(mechtype{i}==0);
    for j=1:length(connis)
      ii=mechsrc{i}(connis(j));
      jj=mechdst{i}(connis(j));
      sys.connections(ii,jj).label=[EL{ii} '-' EL{jj}];
      if ~isempty(sys.entities(i).connection_parameters)
        sys.connections(ii,jj).parameters = sys.entities(i).connection_parameters{j};
      else
        sys.connections(ii,jj).parameters = [];
      end
      if 0%isempty(sys.connections(ii,jj).parameters) % pull default params from mech structure
        p = sys.entities(i).connection_mechs(j).params;
        keys = fieldnames(p);
        vals = struct2cell(p);
        tmp=[keys(:) vals(:)]';
        sys.connections(ii,jj).parameters = [tmp(:)]';
      end
      if ~isfield(sys.connections,'mechs') || isempty(sys.connections(ii,jj).mechs)
        sys.connections(ii,jj).mechs = sys.entities(i).connection_mechs(j);
        sys.connections(ii,jj).mechanisms=sys.entities(i).mechanisms(connis(j));
      else
        sys.connections(ii,jj).mechs(end+1) = sys.entities(i).connection_mechs(j);
        sys.connections(ii,jj).mechanisms{end+1}=sys.entities(i).mechanisms{connis(j)};
      end
    end
  else
    sys.entities(i).connection_mechanisms = [];
    sys.entities(i).connection_parameters = [];
    sys.entities(i).connection_mechs = [];
  end
  if any(mechtype{i}==1) % intrinsic mechanisms
    sys.entities(i).intrinsic_parameters = sys.entities(i).parameters(mechtype{i}==1);
    sys.entities(i).mechanisms = sys.entities(i).mechanisms(mechtype{i}==1);
    sys.entities(i).parameters = sys.entities(i).parameters{find(mechtype{i}==1,1,'first')};
    sys.entities(i).mechs = sys.entities(i).mechs(mechtype{i}==1);
  else
    sys.entities(i).mechanisms = {};
    sys.entities(i).mechs = [];
  end
  if iscell(sys.entities(i).parameters) && ~isempty(sys.entities(i).parameters) && isempty(sys.entities(i).parameters{1})
    sys.entities(i).parameters=[];
  end
end
tmp={sys.entities.var_list};
sys.variables.labels = [tmp{:}];
sys.variables.global_entity=Spop(Stype==0);
sys.variables.global_oldlabel=alloldvars(Stype==0)';
sys.variables.global_newlabel=allnewvars(Stype==0)';
sys.model.functions = functions;
sys.model.auxvars = auxvars;
sys.model.ode = model;
sys.model.IC = IC;
sys.model.parms = parms;
if parms.coder==1 && exist('codegen')
  sys.model.parameters = modelparams;
end

if parms.verbose
  % Print model info
  sgind=find(Stype==0);
  fprintf(fileID,'\nModel Description\n----------------------------------\n\n');
  fprintf(fileID,'Specification files:\n');
  for f = 1:length(spec.files)
    fprintf(fileID,'%s\n',spec.files{f});
  end
  fprintf(fileID,'\nPopulations:');
  for i = 1:N
    fprintf(fileID,'\n%-6.6s (n=%g):\n',EL{i},NE(i));
    ind=find(Spop==i & Stype==0);
    for j=1:length(ind)
      fprintf(fileID,'\tdynamics: %s'' = %s\n',Svars{ind(j),1},Sodes0{ind(j)});
    end
    M=spec.entities(i).mechanisms;
    P=spec.entities(i).parameters;
    if ~isempty(M)
      fprintf(fileID,'\tmechanisms: %s',M{1});
      for j = 2:length(M)
        fprintf(fileID,', %s',M{j});
      end
    end
    if length(P)>=2
      fprintf(fileID,'\n\tparameters: %s=%g',P{1},P{2});
      for j = 2:length(P)/2
        fprintf(fileID,', %s=%g',P{2*j-1},P{2*j});
      end
    end
  end
  fprintf(fileID,'\n\nConnections:\n');
  fprintf(fileID,'%-10.6s\t',' ');
  for i = 1:N, fprintf(fileID,'%-10.6s\t',EL{i}); end; fprintf(fileID,'\n');
  for i = 1:N
    fprintf(fileID,'%-10.6s\t',EL{i});
    for j = 1:N
      if isempty(spec.connections(i,j).mechanisms)
        fprintf(fileID,'%-10.6s\t','-');
      else
        try
          fprintf(fileID,'%-10.10s\t',[spec.connections(i,j).mechanisms{:}]);
        catch
          fprintf(fileID,'%-10.10s\t',spec.connections(i,j).mechanisms);
        end
      end
    end
    fprintf(fileID,'\n');
  end
  fprintf(fileID,'\nConnection parameters:');
  CL={spec.connections.label};
  CP={spec.connections.parameters};
  for i = 1:length(CL)
    if isempty(CP{i}), continue; end
    fprintf(fileID,'\n%s: ',strrep(CL{i},'-','->'));
    if length(CP{i})>=2
      fprintf(fileID,'\n\tparameters: %s=%g',CP{i}{1},CP{i}{2});
      for j = 2:length(CP{i})/2
        fprintf(fileID,', %s=%g',CP{i}{2*j-1},CP{i}{2*j});
      end
    end
  end
  fprintf(fileID,'\n\nModel Equations:\n----------------------------------\n');
  fprintf(fileID,'ODEs:\n');
  for i = 1:nvar
    fprintf(fileID,'\t%-20s = %s\n',[Svars{i,2} ''''],Sodes{i});
  end
  fprintf(fileID,'\nInitial Conditions:\n');
  for i = 1:nvar
    for j=1:length(Svars{i,4})
      if j==1
        fprintf(fileID,'\t%-20s=[',[Svars{i,2} '(0)']);
      end
      fprintf(fileID,'%.4g, ',Svars{i,4}(j));
    end
    fprintf(fileID,']\n');
  end
  fprintf(fileID,'\n');
  fprintf(fileID,'\nMatlab-formatted (copy and paste to repeat simulation):\n%%-----------------------------------------------------------\n');
  fprintf(fileID,'%% Auxiliary variables:\n');
  for i = 1:size(Cexpr,1)
    fprintf(fileID,'\t%-20s = %s;\n',Cexpr{i,2},Cexpr{i,3});
  end
  fprintf(fileID,'\n%% Anonymous functions:\n');
  for i = 1:size(Hfunc,1)
    %fprintf(fileID,'\t%-20s = %-40s\t%% (%-9s)\n',Hfunc{i,2},[Hfunc{i,3} ';'],functions{i,3});
    fprintf(fileID,'\t%-20s = %-40s\n',Hfunc{i,2},[Hfunc{i,3} ';']);
  end
  fprintf(fileID,'\n%% ODE Handle, ICs, integration, and plotting:\nODEFUN = %s\n',model);
  fprintf(fileID,'IC = [%s];\n',num2str(IC'));
  %fprintf(fileID,'IC = [%s];\n',num2str(IC'));
  fprintf(fileID,'\n[t,y]=ode23(ODEFUN,[0 100],IC);   %% numerical integration\nfigure; plot(t,y);           %% plot all variables/functions\n');
  if nvar>=1,fprintf(fileID,'try legend(''%s''',strrep(Svars{1,2},'_','\_')); end
  if nvar>=2,for k=2:nvar,fprintf(fileID,',''%s''',strrep(Svars{k,2},'_','\_')); end; end
  if nvar>=1,fprintf(fileID,'); end\n'); end
  fprintf(fileID,'%%-----------------------------------------------------------\n\n');
end
txt={};
if nargout>7
  % Print model info
  sgind=find(Stype==0);
  txt{end+1}=sprintf('Model Description\n----------------------------------\n');
%   txt{end+1}=sprintf('Specification files:\n');
%   for f = 1:length(spec.files)
%     txt{end+1}=sprintf('%s\n',spec.files{f});
%   end
  txt{end+1}=sprintf('Populations:');
  for i = 1:N
    txt{end+1}=sprintf('\n%-6.6s (n=%g):\n',EL{i},NE(i));
    ind=find(Spop==i & Stype==0);
    for j=1:length(ind)
      txt{end+1}=sprintf('\tdynamics: %s'' = %s\n',Svars{ind(j),1},Sodes0{ind(j)});
    end
    M=spec.entities(i).mechanisms;
    P=spec.entities(i).parameters;
    if ~isempty(M)
      txt{end+1}=sprintf('\tmechanisms: %s',M{1});
      for j = 2:length(M)
        txt{end+1}=sprintf(', %s',M{j});
      end
      txt{end+1}=sprintf('\n');
    end
    if length(P)>=2
      txt{end+1}=sprintf('\tparameters: %s=%g',P{1},P{2});
      for j = 2:length(P)/2
        txt{end+1}=sprintf(', %s=%g',P{2*j-1},P{2*j});
      end
    end
  end
  txt{end+1}=sprintf('\n\nConnections:\n');
  txt{end+1}=sprintf('%-10.6s\t',' ');
  for i = 1:N, txt{end+1}=sprintf('%-10.6s\t',EL{i}); end; txt{end+1}=sprintf('\n');
  for i = 1:N
    txt{end+1}=sprintf('%-10.6s\t',EL{i});
    for j = 1:N
      if isempty(spec.connections(i,j).mechanisms)
        txt{end+1}=sprintf('%-10.6s\t','-');
      else
        try
          txt{end+1}=sprintf('%-10.10s\t',[spec.connections(i,j).mechanisms{:}]);
        catch
          txt{end+1}=sprintf('%-10.10s\t',spec.connections(i,j).mechanisms);
        end
      end
    end
    txt{end+1}=sprintf('\n');
  end
  txt{end+1}=sprintf('\nConnection parameters:');
  CL={spec.connections.label};
  CP={spec.connections.parameters};
  for i = 1:length(CL)
    if isempty(CP{i}), continue; end
    txt{end+1}=sprintf('\n%s: ',strrep(CL{i},'-','->'));
    if length(CP{i})>=2
      txt{end+1}=sprintf('\n\tparameters: %s=%g',CP{i}{1},CP{i}{2});
      for j = 2:length(CP{i})/2
        txt{end+1}=sprintf(', %s=%g',CP{i}{2*j-1},CP{i}{2*j});
      end
    end
  end
  txt{end+1}=sprintf('\n\nModel Equations:\n----------------------------------\n');
  txt{end+1}=sprintf('ODEs:\n');
  for i = 1:nvar
    txt{end+1}=sprintf('\t%-20s = %s\n',[Svars{i,2} ''''],Sodes{i});
  end
  txt{end+1}=sprintf('\nInitial Conditions:\n');
  for i = 1:nvar
    for j=1:length(Svars{i,4})
      if j==1
        txt{end+1}=sprintf('\t%-20s=[',[Svars{i,2} '(0)']);
      end
      txt{end+1}=sprintf('%.4g, ',Svars{i,4}(j));
    end
    txt{end+1}=sprintf(']\n');
  end
  txt{end+1}=sprintf('\n');
  txt{end+1}=sprintf('\nMatlab-formatted (copy and paste to repeat simulation):\n%%-----------------------------------------------------------\n');
  txt{end+1}=sprintf('%% Auxiliary variables:\n');
  for i = 1:size(Cexpr,1)
    txt{end+1}=sprintf('\t%-20s = %s;\n',Cexpr{i,2},Cexpr{i,3});
  end
  txt{end+1}=sprintf('\n%% Anonymous functions:\n');
  for i = 1:size(Hfunc,1)
    %txt{end+1}=sprintf('\t%-20s = %-40s\t%% (%-9s)\n',Hfunc{i,2},[Hfunc{i,3} ';'],functions{i,3});
    txt{end+1}=sprintf('\t%-20s = %-40s\n',Hfunc{i,2},[Hfunc{i,3} ';']);
  end
  txt{end+1}=sprintf('\n%% ODE Handle, ICs, integration, and plotting:\nODEFUN = %s\n',model);
  txt{end+1}=sprintf('IC = [%s];\n',num2str(IC'));
  txt{end+1}=sprintf('\n[t,y]=ode23(ODEFUN,[0 100],IC);   %% numerical integration\nfigure; plot(t,y);           %% plot all variables/functions\n');
  if nvar>=1,txt{end+1}=sprintf('try legend(''%s''',strrep(Svars{1,2},'_','\_')); end
  if nvar>=2,for k=2:nvar,txt{end+1}=sprintf(',''%s''',strrep(Svars{k,2},'_','\_')); end; end
  if nvar>=1,txt{end+1}=sprintf('); end\n'); end
  txt{end+1}=sprintf('%%-----------------------------------------------------------\n\n');
  txt{end+1}=sprintf('Specification files:\n');
  for f = 1:length(spec.files)
    txt{end+1}=sprintf('%s\n',spec.files{f});
  end
  txt=[txt{:}];
end

if ~strcmp(nodefield,'entities')
  sys.(nodefield) = sys.entities;
  sys = rmfield(sys,'entities');
end
if nargout==1
  varargout{1}=sys;
elseif nargout>0
  varargout{1}=model;
  if nargout>1, varargout{2}=IC; end
  if nargout>2, varargout{3}=functions; end
  if nargout>3, varargout{4}=auxvars; end
  if nargout>4, varargout{5}=sys; end
  if nargout>5, varargout{6}=Sodes; end
  if nargout>6, varargout{7}=Svars; end
  if nargout>7, varargout{8}=txt; end
end

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PARAMETERS
% default mech params | same pop & mech
  % expressions, functions, odes, terms
% reserved keywords
  % expressions, functions, odes, terms
% prefixes: expressions
  % expressions, functions, odes, terms
% prefixes: functions
  % functions, odes, terms
% prefixes: vars (Sg(E) => Sg(~E) => Sm(E) => S~m(E))
  % odes, terms

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% VARIABLES & EQUATIONS

% Substitution procedure:
% During substitution, to avoid overwriting by substituting labels that are substrings of other labels: use substitution map by (1) finding matches, (2) storing the string to insert, (3) a unique identifier id, (4) and temporarily substituting the match by @(id). Then, after finding all do substitutions.

% Hfunc(:,3),Cexpr(:,3),Tsubst(:,2),Sodes
% [Stype  Spop Smech] % variables
% [Ptype  Ppop Pmech] % parameters
% Cexpr, [Cpop Cmech] % expressions:        {label, prefix_label, expression}
% Hfunc, [Hpop Hmech] % functions:          {label, prefix_label, function}
% Tsubst,[Tpop Tmech] % term substitutions: {label, mech_term}

% Substitute state vars into mech expression/functions/odes/substitution terms:
% 1. any E:Sg in E expression/function/ode/term without brackets is replaced by E_label (E_s)
%      (global var: within-entity)
% 2. any var[#] in E expression/function/ode/term is replaced by inputPop(#)_var if var in inputPop(#):Sg
%      note: not an option to substitute inputPop(#):Smk into different pop. (i.e. mech vars between-entity)
%      (global var: between-entity)
% 3. in E:m, any E:Sm (same mechanism) in expression/function/ode/term is replaced by E_m_label
%      (mech var: within-entity & within-mech)
% 4. in E:m, any var label (exposed in different mechanism E:Smk) in expression/function/ode/term is replaced by E_mk_label
%      (mech var: within-entity & between-mech)

% Update mech function/expression labels (within-E): substitute Cmk-label & Hmk-label by prefix_label in Cmk(RHS) & Hmk(RHS)
%      E:Cmk LHS prefix_label into Cmk(RHS), Hmk(RHS), Fmk, Tmk(?)
%      E:Hmk LHS prefix_label into Hmk(RHS), Fmk, Tmk(?)

% Insert terms Tmk into entity dynamics
% Prepare model string for evaluation
% Prepare expressions/functions for evaluation: insert prefix_label in Cmk(LHS) and Hmk(LHS)

function varargout = substitute(old,new,varargin)
  % INPUTS:
  % old = cell array of keys (strings)
  % new = cell array of strings or numeric values
  % cellmats: {cellmat, cellmat, ...}
  %   where cellmat: {x11,x12,x13,...; x21,x22,x23,...; ...}, x*=string
  varargout = varargin;
  if isempty(old) || isempty(new) || isempty(varargin), return; end
  cellmats = varargin;
  if ~iscell(old), old = {old}; end
  if ~iscell(new), new = {new}; end
  if size(old,1)>1, old = old'; end
  if iscellstr(old)
    [l,I] = sort(cellfun(@length,old),2,'descend');
    old = old(I);
    new = new(I);
  end
  % loop over cellmat elements: replace old=>new
  for i = 1:numel(cellmats)
    cellmat = cellmats{i};
    if ~iscell(cellmat), cellmat={cellmat}; end
    cells = cellmat(:);
    for j = 1:numel(cells)
      if ~ischar(cells{j}), continue; end
      for k = 1:numel(old)
        this = cells{j};
        % handle reserved words first
        if isequal(old{k},'Npre') && isempty(regexp(cells{j},'[^A-Za-z]+Npre')), continue; end
        if isequal(old{k},'Npost') && isempty(regexp(cells{j},'[^A-Za-z]+Npost')), continue; end
        key = old{k};
        if isempty(key)
          continue;
        end
        l = length(key);
        key = strrep(key,'[','\[');
        key = strrep(key,']','\]');
        if isnumeric(new{k})
          val=sprintf('(%g)',new{k});
        elseif ischar(new{k})
          val=new{k};
        end
        inds=regexp(this,['\<' key '\>']);
        if isempty(inds), continue; end
        if inds(1)>1
          tmp=this(1:inds(1)-1);
        else
          tmp='';
        end
        for c=1:length(inds)
          tmp=[tmp val];
          if c<length(inds) && length(this)>=(inds(c)+l)
            tmp=[tmp this(inds(c)+l:inds(c+1)-1)];
          end
        end
        if inds(c)+l<=length(this)
          tmp=[tmp this(inds(c)+l:end)];
        end
        cells{j}=tmp;
      end
    end
    cellmats{i} = reshape(cells,size(cellmat));
  end
  varargout = cellmats;

