function varargout = parse_mech_spec(fname,key,val)
if nargin < 1
  error('Must specify a mech name');
end

isfile=1;
if iscell(fname)
  isfile=0; mechtext=fname;
elseif ischar(fname) && ~exist(fname,'file')
  if exist([fname '.txt'],'file')
    fname = [fname '.txt'];
  else
    error('File not found: %s',fname);
  end
end

params = struct;
precalcs = {};
funcs = {};
subst = {};
odes = {};
vars = {};
ickey = {};
icval = {};%[];
Vin = {};
VinFunc = {};
aux_Vin = {};

if isfile
  %fprintf('reading %s\n',fname);
  fid=fopen(fname,'rt'); % open mech file
  while (~feof(fid))
    % read line & split by semicolon-delimiter
    str = fgetl(fid);
    if str == -1, break; end
    parse_text;
  end
  fclose(fid); % close mech file
else
  for line=1:length(mechtext)
    str = mechtext{line};
    parse_text;
  end
end
if ~isempty(Vin)
  if ~isempty(subst)
    Vin = Vin(~ismember(VinFunc,subst(:,2)));
  end
  Vin = unique({Vin{:} aux_Vin{:}});
  try
    tmp=cellfun(@(x)strread(x,'%s','delimiter',','),Vin,'uniformoutput',false);
    tmp=unique(cat(1,tmp{:}))';
    Vin = tmp;
  end
end

% organize parameter info
if nargin==3
  cfg = check_user_params(key,val);
elseif nargin==2 && iscell(key)
  val = key(2:2:end);
  key = key(1:2:end);
  cfg = check_user_params(key,val);
elseif nargin==2 && isstruct(key)
  cfg = key;
else
  cfg = [];
end

% Set user-specified parameters & ICs
% if all(cellfun(@isnumeric,icval))
%   icval = [icval{:}];
% end
IC = cell(size(vars));
for k = 1:length(ickey)
  idx = strcmp(ickey{k},vars);
  if length(find(idx))==1
    IC(idx) = icval(k);
  end
end
if nargin>1 && ~isempty(cfg)
  [params,IC] = update(params,IC,vars,cfg);
end
for k=1:length(IC)
  if isempty(IC{k})
    IC{k}=0;
  end
end
sub = {};
for k = 1:size(subst,1)
  sub{k,1} = subst{k,1};
  sub{k,2} = [subst{k,2} subst{k,3}];
end
if isempty(sub)
  sub = {'null','null'};
end
out.params = params;
out.auxvars = precalcs; %out.precalcs = precalcs;
out.functions = funcs; %out.funcs = funcs;
out.statevars = vars'; %out.varlabels = vars';
out.odes = odes;
out.ic = IC';
out.substitute = sub;
out.inputvars = Vin;

if nargout == 1
  varargout{1} = out;
else
  varargout = struct2cell(out);
end

  function parse_text
    % get rid of comments
    comment = regexp(str,'(#|%)+.*','match');
    for c = comment
      str = deblank(strrep(str,[c{:}],''));
    end
    % correct for web unicode stuff
    str = strrep(str,'&gt;','>');
    str = strrep(str,'&lt;','<');
    if isempty(str) || strcmp(str(1),'#') || strcmp(str(1),'%')
      return;
    end
    % parse expressions
    if isempty(regexp(str,'\[.+;.+\]'))
      expr = strtrim(strread(str,'%s','delimiter',';'));
    else
      expr = strtrim(str);
    end
    if ischar(expr), expr = {expr}; end
    for s = 1:length(expr)
      eqn = expr{s};
      if isempty(eqn), continue; end
      % remove trailing semicolon if present
      if isequal(eqn(end),';'), eqn(end)=[]; end
      idx = find(eqn=='=',1,'first');
      eqn = strtrim({eqn(1:idx-1),eqn(idx+1:end)});
      lhs = eqn{1};
      rhs = eqn{2};
      % determine equation type and process
      if ~isempty(regexp(lhs,'\w+''','match')) % ODE: x' = ..., var: x
        odes{end+1,1} = rhs;
        vars{end+1} = lhs(1:end-1);
        if ~isequal(';',odes{end,1}(end))
          odes{end,1} = [odes{end,1} ';'];
        end
      elseif ~isempty(regexp(lhs,'\w+\(0\)','match')) % IC: x(0) = ...
        tmp = strtrim(strread(lhs,'%s','delimiter','('));
        ickey{end+1} = tmp{1};
        if isempty(regexp(rhs,'[^\d\.\-+\\]+','match'))
          icval{end+1} = str2num(rhs);
        else
          icval{end+1} = rhs;
        end
      elseif ~isempty(regexp(lhs,'\w+\([\(\[?[\d\s,]+\]?\) | \(\[?\d+:[\(\d+\)|\(end\)]\]?\)]+\)','match'))
        % case1='\[?[\d\s,]+\]?';          % var(#), var([#]), var([# #]), var([#,#])
        % case2='\[?\d+:[(\d+)|(end)]\]?'; % var(#:#), var(#:end), var([#:#]), var([#:end])
        % pat=['\w+\([(' case1 ')|(' case2 ')]+\)'];
        % pat='\w+\([(\[?[\d\s,]+\]?)|(\[?\d+:[(\d+)|(end)]\]?)]+\)';
        precalcs{end+1,1} = strtrim(lhs);
        precalcs{end,2} = strtrim(rhs);
      elseif ~isempty(regexp(lhs,'\w+\([\w,]+\)','match')) % function: x(v) = ...
        tmp = strtrim(strread(lhs,'%s','delimiter','('));
        funcs{end+1,1} = tmp{1};
        funcs{end,2} = ['@(' tmp{2} ' ' rhs];
        Vin{end+1} = tmp{2}(1:end-1);
        VinFunc{end+1} = tmp{1};
      elseif numel(regexp(expr{s},'=>'))==1 % function substitution
        subst{end+1,1} = lhs;
        tmp = strtrim(strread(rhs,'%s','delimiter','('));
        subst{end,2} = strtrim(tmp{1}(2:end));
        try tmp = ['(' tmp{2}]; catch tmp = '()'; end
        tmp1 = regexp(tmp,'\([\[\]\S\s]+\)','match');%regexp(tmp,'\(\S+\)\[\]','match');
        if ~isempty(tmp1)
          subst{end,3} = tmp1{1};
        else
          subst{end,3} = '';
        end
        tmp2 = regexp(tmp,'\[\S+\]','match');
        if ~isempty(tmp2)
          tmp2 = regexp(tmp2{1},'[^\[\],]+','match');
          aux_Vin(end+1:end+length(tmp2)) = tmp2;
        end
      elseif ~isempty(regexp(lhs,'(\w+)|(\[\w+\])','match')) % expression: x = ...
        if ~isempty(regexp(rhs,'.*[a-z_A-Z,<>(<=)(>=)]+.*','match')) && ... % rhs contains: []{}(),<>*/|          % function to evaluate & store
            isempty(regexp(rhs,'^\d+e[\-\+]?\d+$')) % check not scientific notation
        %   store this as an expression to evaluate before anonymous functions
          precalcs{end+1,1} = strtrim(lhs);
          precalcs{end,2} = strtrim(rhs);
        else                                   % constant: x = ...
          params.(lhs) = str2num(rhs);%str2double(rhs);
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      else % invalid format
        try
          error('Invalid mechanism specification: %s\n',eqn);
        catch
          error('Invalid mechanism specification: %s\n',fname);
        end
      end
    end
  end

end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% SUBFUNCTIONS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  function cfg = check_user_params(key,val)
    % Prepare optional, user-supplied parameters & ICs
    if isempty(key) || isempty(val)
      key = {};
      val = {};
      cfg = struct;
      return;
    end
    if ~iscell(key), key = {key}; end
    if ~iscell(val), val = {val}; end
    if numel(key) ~= numel(val)
      error('the number of keys must equal the number of vals.');
    else
      if isnumeric(val)
        val = num2cell(val);
      elseif ischar(val)
        val = {val};
      end
      if ischar(key)
        key = {key};
      elseif isnumeric(key) && isempty(key)
        key = {};
      end
      dim = find(max(size(val))==size(val),1,'first');
      cfg = cell2struct(val,key,dim);
    end
  end
  function [P,IC] = update(P,IC,Veq,cfg)
    fld    = fieldnames(P);
    cfgfld = fieldnames(cfg);
    % update constant parameters
    ind    = find(ismember(cfgfld,fld));
    for k  = 1:length(ind)
      this = cfgfld{ind(k)};
      P.(this) = cfg.(this);
    end
    % update initial conditions with strings
    for j = 1:length(IC)
      if ~ischar(IC{j}), continue; end
      if ~isempty(regexp(IC{j},'[^\W-_]*IC[\s\+-/*]'))
        icflag=1;
        icind = regexp(IC{j},'[^\W-_]*IC[\s\+-/*]');
      else
        icflag=0;
      end
      for k  = 1:length(cfgfld)
        IC{j} = strrep(IC{j},cfgfld{k},num2str(cfg.(cfgfld{k})));
      end
      if icflag && ismember(Veq{j},cfgfld)
        for k=1:length(icind)
          IC{j} = [IC{j}(1:icind(k)-1) num2str(cfg.(cfgfld{strcmp(Veq{j},cfgfld)})) IC{j}(icind(k)+2:end)];
%           IC{j} = strrep(IC{j},'IC',num2str(cfg.(cfgfld{strcmp(Veq{j},cfgfld)})));
        end
      end
      for k  = 1:length(fld)
        IC{j} = strrep(IC{j},fld{k},num2str(P.(fld{k})));
      end
      if icflag && ismember(Veq{j},fld)
        for k=1:length(icind)
          IC{j} = [IC{j}(1:icind(k)-1) num2str(cfg.(cfgfld{strcmp(Veq{j},cfgfld)})) IC{j}(icind(k)+2:end)];
%           IC{j} = strrep(IC{j},'IC',num2str(cfg.(cfgfld{strcmp(Veq{j},cfgfld)})));
        end
      end
      try IC{j} = eval(IC{j}); end
    end
    % update initial conditions
    ind     = find(ismember(cfgfld,Veq));
    for k   = 1:length(ind)
      this  = cfgfld{ind(k)};
      j     = strmatch(this,Veq,'exact');
      if isnumeric(IC{j})
        IC{j} = cfg.(this);
      end
    end
    if all(cellfun(@isnumeric,IC))
      IC = [IC{:}];
    end
      % convert non-numeric values to NaNs
%       [IC{~cellfun(@isnumeric,IC)}] = deal(nan);
%     end
    if isfield(P,'IC'), P=rmfield(P,'IC'); end
    for k = 1:length(Veq)
      if isfield(P,Veq{k}), P = rmfield(P,Veq{k}); end
    end
  end