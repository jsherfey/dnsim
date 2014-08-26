function allspecs = get_search_space(spec,scope,variable,values)
% % List of changes for each iteration (example)
%   objs = {'connections','entities'    ,'entities'  ,'entities'  ,'simulation'};
%   inds = {[i,j]        ,[i]           ,[i]         ,[i2]        ,[1]};
%   flds = {'fanout'     ,'multiplicity','mechanisms','parameters','sim-input'};
%   keys = {[]           ,[]            ,[],         ,paramlabel  ,[]};
%   vals = { #            #             cellarrstr    #           #/func/str  };
%   % notes: 
%   % - each column is one change to one element; 
%   % - multiple elements can be changed in one run;
%   % - all changes are specified by (scope,var,val) information.
%   % assignment:
%   %   key==[]: spec.(obj)(ind).(fld) = val        obj in objs, ind in inds, etc
%   %   else:    spec.(obj)(ind).(fld)[key] = val
%   % strategy:
%   % - parse (scope,var,val) to determine iterable sets
%   % - construct lists of changes from iterable sets
%   % - create one copy of spec for each iteration and apply changes to each
%   % - loop over set of specs and pass each to simdriver
%   
% for each (scope,var,val):
%   scope => (objs, inds) for nscope >= 1 iterations
%   var => (flds, keys) for nvar >=1 iteration
%   val => (vals) for nval > 1 iterations
%   niter = nscope*nvar*nval
if ~isfield(spec,'entities') && isfield(spec,'cells')
  entityfield='cells';
  spec.entities = spec.cells;
  spec = rmfield(spec,'cells');
else
  entityfield='entities';
end

if nargin<4
  try 
    spec.simulation.values = correct_loadjson_arrstr(spec.simulation.values); 
  catch
    error('must specify values to simulate.');
  end
else
  spec.simulation.values = values;
end
if nargin<3
  try 
    spec.simulation.variable = correct_loadjson_arrstr(spec.simulation.variable); 
  catch
    error('must specify variable to adjust.');
  end
else
  spec.simulation.variable = variable;
end
if nargin<2
  try 
    spec.simulation.scope = correct_loadjson_arrstr(spec.simulation.scope); 
  catch
    error('must specify scope of variable to adjust.');
  end
else
  spec.simulation.scope = scope;
end
if ~iscell(spec.simulation.scope), spec.simulation.scope={spec.simulation.scope}; end
if ~iscell(spec.simulation.variable), spec.simulation.variable={spec.simulation.variable}; end
if ~iscell(spec.simulation.values), spec.simulation.values={spec.simulation.values}; end

if length(spec.simulation.scope) > 1
  tmpspec = spec;
  tmp = spec.simulation;
  tmp.scope = tmp.scope(2:end); tmp.variable = tmp.variable(2:end); tmp.values = tmp.values(2:end);
  tmpspec.simulation = tmp;
  tmpspecs = get_search_space(tmpspec);
  allspecs = {}; cnt = 0;
  for s = 1:length(tmpspecs)
    tmpspec = tmpspecs{s};
    try s1=tmpspec.simulation.scope{1}; catch s1=tmpspec.simulation.scope; end
    try s2=tmpspec.simulation.variable{1}; catch s2=tmpspec.simulation.variable; end
    try s3=tmpspec.simulation.values{1}; catch s3=tmpspec.simulation.values; end
    tmpspec.simulation.scope = spec.simulation.scope(1);
    tmpspec.simulation.variable = spec.simulation.variable(1);
    tmpspec.simulation.values = spec.simulation.values(1);
    tmp = get_search_space(tmpspec);
    for ss = 1:length(tmp)
      cnt = cnt + 1;
      descstr = sprintf('%g_%s-%s%s',cnt,s1,s2,s3);
      descstr = strrep(strrep(descstr,'(',''),')','');
      s4=tmp{ss}.simulation.scope; if iscell(s4), s4=s4{1}; end
      s5=tmp{ss}.simulation.variable; if iscell(s5), s5=s5{1}; end
      s6=tmp{ss}.simulation.values; if iscell(s6), s6=s6{1}; end
      tmp{ss}.simulation.scope = [s1 s4];
      tmp{ss}.simulation.variable = [s2 s5];
      tmp{ss}.simulation.values = [s3 s6];
      descstr = sprintf('%s_%s-%s%s',descstr,s4,s5,s6);
      tmp{ss}.simulation.description = strrep(strrep(descstr,'(',''),')','');
    end
    allspecs = {allspecs{:} tmp{:}};
  end
  return;
end  

allspecs = {};
base = spec;
% for each (scope,var,val) (s of nspec):
for s = 1:length(spec.simulation.scope)
  % set scope,var,val = {this study spec}
  scope = spec.simulation.scope{s};
  var = spec.simulation.variable{s};
  val = spec.simulation.values{s};
  scopelist = parse_spec('scope',scope,base); % list w/ {i} = scope iter, {i}{j} = sync scope elem in iter i
  varlist = parse_spec('variable',var,base);
  vallist = parse_spec('value',val,base);
  modspecs = {};
  % for each iter i of nscope defined by scope
  for i = 1:length(scopelist)
    % set objs,inds = {sync scope elems}
    scope_elems = scopelist{i};    
    % for each iter j of nvar defined by var
    for j = 1:length(varlist)
      % set flds,keys = {sync var elems}
      var_elems = varlist{j};
      % for each iter k of nval 
      for k = 1:length(vallist)
        val = vallist{k};
        temp = base;
        str1 = ''; str2 = '';
        temp.simulation.scope = {};
        temp.simulation.variable = {};
        temp.simulation.values = {};
        % for each (obj,ind) in (objs,inds)
        for ii = 1:length(scope_elems)
          selem = scope_elems{ii};
          obj = selem{1};
          ind = selem{2};
          objlabel = base.(obj)(ind).label;
          if ii==1, str1=objlabel; else str1=sprintf('%s-%s',str1,objlabel); end
          % for each (fld,key) in (flds,keys)
          for jj = 1:length(var_elems)
            velem = var_elems{jj};
            fld = velem{1}; svar = fld;
            key = velem{2}; if ischar(key), svar = key; end
            if ~strcmp(fld,'mechanisms') && iscell(val)
              val = val{1}; % values are singular if not mech list
            end
            if jj==1, str2=svar; else str2=sprintf('%s-%s',str2,svar); end
%             % todo: ADD HANDLING FOR INTERACTION WHEN >1 (scope,var,val)-spec
%             if last_scope==scope && last_var==var
%             ...
            temp.simulation.scope{end+1} = base.(obj)(ind).label;
            temp.simulation.values{end+1} = val;
            if isempty(key)
              temp.simulation.variable{end+1} = fld;
              if strcmp(fld,'mechanisms')
                if ischar(val)
                  mechval={val}; 
                elseif iscell(val) && iscellstr(val{1})
                  mechval=[val{:}];
                else
                  mechval=val; 
                end
                temp.(obj)(ind).(fld) = {base.(obj)(ind).(fld){:} mechval{:}};
              else
                temp.(obj)(ind).(fld) = val;
              end
            else
              if isempty(temp.(obj)(ind).(fld))
                keyind=[];
              else
                keyind = find(cellfun(@(x)isequal(key,x),temp.(obj)(ind).(fld)));
              end
              temp.simulation.variable{end+1} = key; %[fld '.' key];
              if isempty(keyind)
                if isfield(temp.(obj),key)
                  temp.(obj)(ind).(key) = val;
                else
                  temp.(obj)(ind).(fld){end+1} = key;
                  temp.(obj)(ind).(fld){end+1} = val;
                end
              else
                valind = keyind + 1;
                temp.(obj)(ind).(fld){valind} = val;
              end
            end
          end
        end
        if isnumeric(val), vs=['_' num2str(val)];
        elseif iscell(val), vs=['_' [val{:}]]; 
        elseif ischar(val), vs=['_' val]; 
        else vs=''; end
        if iscell(vs), vs=[vs{:}]; end
        str = sprintf('%g_%s-%s%s',k,str1,str2,vs);
        str = strrep(strrep(str,'.','pt'),' ','');
        str(regexp(str,'[\(\)\[\]\{\}]+')) = 'o';
        temp.simulation.description = str;
        if iscell(temp.simulation.scope)
          tmpstrs = unique(temp.simulation.scope);
          tmpstr = '(';
          for ii=1:length(tmpstrs)
            tmpstr = [tmpstr tmpstrs{ii} ','];
          end
          tmpstr = [tmpstr(1:end-1) ')'];
          temp.simulation.scope = tmpstr;
        end
        if iscell(temp.simulation.variable)
          tmpstrs = unique(temp.simulation.variable);
          tmpstr = '(';
          for ii=1:length(tmpstrs)
            tmpstr = [tmpstr tmpstrs{ii} ','];
          end
          tmpstr = [tmpstr(1:end-1) ')'];
          temp.simulation.variable = tmpstr;
        end
        if iscell(temp.simulation.values)
          tmpstrs=temp.simulation.values;
          for ii=1:length(tmpstrs)
            if iscell(tmpstrs{ii})
              tmpstrs{ii}=[tmpstrs{ii}{:}];
            end
            if isnumeric(tmpstrs{ii})
              tmpstrs{ii}=num2str(tmpstrs{ii}); 
            end
          end
          for ii=1:length(tmpstrs),if isnumeric(tmpstrs{ii}),tmpstrs{ii}=num2str(tmpstrs{ii}); end; end
          if ~iscellstr(tmpstrs) && iscell(tmpstrs)
            tmpstrs=[tmpstrs{:}];
          end
          tmpstrs = unique(tmpstrs);
          tmpstr = '(';
          for ii=1:length(tmpstrs)
            tmpstr = [tmpstr tmpstrs{ii} ','];
          end
          tmpstr = [tmpstr(1:end-1) ')'];
          temp.simulation.values = tmpstr;
        end        
        modspecs = {modspecs{:} temp}; % each modspec is a different run
      end
    end
  end
  if s == 1
    last_spec = modspecs;
    last_scope = scope;
    last_var = var;
  else
    % todo: ADD HANDLING FOR INTERACTION WHEN >1 (scope,var,val)-spec
  end
  allspecs = {allspecs{:} modspecs{:}}; % add the set of runs specified by this (scope,var,val)
end

if isequal(entityfield,'cells')
  for k=1:length(allspecs)
    allspecs{k}.cells = allspecs{k}.entities;
    allspecs{k} = rmfield(allspecs{k},'entities');
  end
end
end

% ----------------------------------------------------------
function list = parse_spec(type,str,spec)
  % type: {'scope','variable','value'}
  % str: parseable string with mod spec info
  % list: 
  %   list{i} = list of sync elems in iter i
  %   list{i}{j} = single elem j
  %   for scope: list contains {objecttype,index}
  %   for var: list contains {field,key}
  %   for val: list contains value (numeric, cellarrstr, string, ...)

  %   % test strings
  %   str = {};
  %   str{end+1} = 'a';
  %   str{end+1} = 'a.x';
  %   str{end+1} = '.x';
  %   str{end+1} = 'a-b';
  %   str{end+1} = 'a-b.x';
  %   str{end+1} = '[X,Y,Z]';
  %   str{end+1} = '(X,Y,Z)';
  %   str{end+1} = '{X,Y,Z}';
  %   str{end+1} = '[(X,Y) (X,Z)]';
  %   str{end+1} = 'mechanisms';
  %   str{end+1} = '[80:10:140]';
  %   str{end+1} = '[0 .2 .5]';
  %   str{end+1} = '[exp(-V/a),exp(-a*V),sin(V).*exp(-V/a)]';
  %   str{end+1} = 'aM(v)';
  %   str{end+1} = '3';
  
  % special cases:
  if isequal(str,'N'), str = 'multiplicity'; end
  
  list = {};
  pat = {}; lab = {};
  lab{end+1} = 'reserved';
  pat{end+1} = '(mechanism[s]?)|(connection[s]?|multiplicity)'; % reserved literal strings
  lab{end+1} = 'numeric_array';
  pat{end+1} = '^([-+]?\[)[\d\s:-+]*\]$';   % numeric array
  lab{end+1} = 'bracketed_equations';
  pat{end+1} = '^\[.*([-+]?[a-z_A-Z]+\()+[\w-,*\(\)/\s]*\]$';   % bracketed equations
  lab{end+1} = 'braced_equations';
  pat{end+1} = '^\{.*([-+]?[a-z_A-Z]+\()+[\w-,*\(\)/\s]*\}$';   % equations in braces
  lab{end+1} = 'single_equation';
  pat{end+1} = '^[^\[\{]*([-+]?[a-z_A-Z]+\()+[\w-,*\(\)/\s]*';  % single equation
  lab{end+1} = 'bracketed_parentheses';
  pat{end+1} = '^\[(\(.*\))+\]$';           % => BP=bracketed_parentheses
  lab{end+1} = 'bracketed_strings';
  pat{end+1} = '^\[[\w\s,-+*/\.]*\]$';        % => Bs=bracketed_strings
  lab{end+1} = 'parenthetical_strings';
  pat{end+1} = '^\([\w\s,\-\.]*\)$';          % => Ps=parenthetical_strings
  lab{end+1} = 'braced-strings';
  pat{end+1} = '^\{[\w\s,\-]*\}$';          % => Rs=braced-strings (permute set)
  lab{end+1} = 'string';
  pat{end+1} = '^[\w\.-]+$';                % => S=string

  %   for scope = str, (~cellfun(@isempty,regexp(scope,pat))), end
  %   for scope = str, fprintf('%d ',sum(~cellfun(@isempty,regexp(scope,pat)))), end; disp(' ');

  switch type
    case 'scope' % Scope %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      
      % Prepare: list{iter}{syncelems} = {objecttype, index}
      
      ind = find(~cellfun(@isempty,regexp(str,pat)));
      if length(ind)>1
        ind = ind(1); % only keep the first match
        %error('string matched >1 regexp: %s',scope); 
      end
      switch lab{ind}
        case 'string'                   % apply to one element
          s = check_scope(str,spec);
          list{1}{1} = {s.objecttype{1},s.index};
        case 'bracketed_strings'        % iterate over elements
          % get elements
          elems = regexp(str,'[\w\.-]+','match'); % '[X,Y,Z]' or '[X Y Z]' => {X,Y,Z}
          % loop over elements
          for k = 1:length(elems)
            s = check_scope(elems{k},spec);
            list{k}{1} = {s.objecttype{1},s.index};
          end
        case 'parenthetical_strings'    % change elements together
          % get elements
          elems = regexp(str,'[\w\.-]+','match');
          % add each to list of sync elements
          for k = 1:length(elems)
            s = check_scope(elems{k},spec);
            list{1}{k} = {s.objecttype{1},s.index};
          end
        case 'braced-strings'           % permute elements
%           error('permuting sets delimited by braces not yet implemented.');
          % get elements
          elems = regexp(str,'[\w\.-]+','match');
          inds = permutesets(length(elems));
          for l = 1:size(inds,1)
            ind = unique(inds(l,:));
            tmp = elems(ind);
            for m = 1:length(tmp)
              s = check_scope(tmp{m},spec);
              list{l}{m} = {s.objecttype{1},s.index};%tmp{m};
            end
          end
        case 'bracketed_parentheses'    % iterate over sets of elements to change together
          % get elements
          elems = regexp(str,'\([\w\.,]+\)','match');
          for l = 1:length(elems)
            subelems = regexp(elems{l},'[\w\.-]+','match');
            for m = 1:length(subelems)
              s = check_scope(subelems{m},spec);
              list{l,m} = {s.objecttype{1},s.index};
            end
          end
        otherwise
      end
% c=1; for k=1:length(list),list{k}{c}, end
    case 'variable' % Variable %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      
      % Prepare: list{iter}{syncelems} = {field, key}
      
      ind = find(~cellfun(@isempty,regexp(str,pat)));
      if length(ind)>1, ind = ind(1); end
      switch lab{ind}
        case 'reserved'         % vary model composition
                                % 'mechanisms' => for values, loop over mechanism sets
                                % 'connections'=> for values, loop over rules defining connectivity matrices
          if strmatch(str,'mechanisms')
            list{1}{1} = {'mechanisms',[]};
          elseif strmatch(str,'connections')
            error('variable connection formalisms have not been implemented yet');
            % TODO: implement it
          else
            list{1}{1} = {str,[]}; % e.g., multiplicity
          end
        case 'string'                   % single parameter to vary
          list{1}{1} = {'parameters',str};
        case 'parenthetical_strings'    % change parameters together
          % get elements
          elems = regexp(str,'[\w\.]+','match');
          % add each to list of sync elements
          for k = 1:length(elems)
            list{1}{k} = {'parameters',elems{k}};
          end          
        case 'bracketed_strings'        % iterate over parameters
          % get elements
          elems = regexp(str,'[\w\.]+','match'); % '[X,Y,Z]' or '[X Y Z]' => {X,Y,Z}
          % loop over elements
          for k = 1:length(elems)
            list{k}{1} = {'parameters',elems{k}};
          end
        case {'bracketed_equations','braced_equations','single_equations'}
                                        % function to vary
          error('equation variables not denoted by parameter labels have not been implemented yet.');
          % TODO: implement it
        otherwise
          fprintf('simulation space specification not recognized.\n');
      end      
    case 'value' % Value %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      
      % Prepare: list{iter}{1} = value (numeric, list of labels, string, etc)
      
      ind = find(~cellfun(@isempty,regexp(str,pat)));
      if length(ind)>1, ind = ind(1); end
      switch lab{ind}
        case 'numeric_array'
          elems = parsecell({str});
          elems = elems{1};
          for k = 1:length(elems)
            list{k}{1} = elems(k);
          end
        case 'bracketed_equations'    % ex. set of equation RHS for LHS variable label
          str = strrep(str,'[','');
          str = strrep(str,']','');
          elems = regexp(str,',','split');
          for k = 1:length(elems)
            list{k}{1} = elems(k);
          end          
        case 'braced-strings'         % ex. list of mechanisms to permute
          elems = regexp(str,'[\w\.]+','match');
          inds = permutesets(length(elems));
          tmp=cellfun(@(x)unique(inds(x,:)),num2cell(1:size(inds,1)),'uni',0);
          tmp=cellfun(@num2str,tmp,'uni',0);
          [tmp,I,J] = unique(tmp);
          inds = inds(I,:);
          for l = 1:size(inds,1)
            ind = unique(inds(l,:));
            tmp = elems(ind);
            for m = 1:length(tmp)
              list{l}{m} = tmp{m};
            end
          end
        case 'bracketed_parentheses'  % ex. list of mechanisms to iterate
          % get elements
          elems = regexp(str,'\([\w\.,]+\)','match');
          for l = 1:length(elems)
            subelems = regexp(elems{l},'[\w\.]+','match'); 
              % Note: leave "." for now in case it is useful for defining  
              % namespaces for mechanisms in the future
            tmp = {};
            for m = 1:length(subelems)
              tmp = {tmp{:} subelems{m}};
            end
            list{l}{1} = tmp;
          end
        case 'bracketed_strings'        % iterate over parameters
          % get elements
          elems = regexp(str,'[\w\.]+','match'); % '[X,Y,Z]' or '[X Y Z]' => {X,Y,Z}
          % loop over elements
          for k = 1:length(elems)
            list{k}{1} = elems{k};
          end          
        otherwise
      end
  end
  % Thoughts:
  % if param || function for connections, entities, and/or mechanisms:
  %   set spec.(objecttype).parameters.(key) = value
  %   exceptions:
  %     spec.entities(e).multiplicity = value
  %     spec.connections(c).fanout = value
  % if 'mechanisms'
  %   set spec.(objecttype).mechanisms = value (set of labels)
  % if 'connections'
  %   TBD
end

% ----------------------------------------------------------
function res = check_scope(str,spec)
  res = { 'objecttype',{'entities','connections'}; % {'entities','connections','simulation','all'}
          'index',[]; % index of object in spec
          'label',''; % entity or connection label (empty for all)
          'entities',''; % entity labels (list 2 for connection, empty for all)
          'mechanisms', '';  % mechanism label (empty for all)
        };
  res = cell2struct(res(:,2),res(:,1));
  pieces = regexp(str,'\.','split');            % a-b.c :=> {a-b,c}
  lhs = pieces{1}; rhs = '';                    % grab a-b
  if numel(pieces)==2, rhs = pieces{2}; end     % a-b.c => grab c
  if ~isempty(rhs), res.mechanisms = rhs; end   % c != ''
  if ~isempty(lhs) % connection or entity       % a-b != ''
    parts = regexp(lhs,'-','split');            % a-b :=> {a,b}
    if numel(parts)==1                          % a-b => a
      if strmatch(parts{1},'simulation')
        res.objecttype = {'simulation'};
        res.index = 1;
        if isfield(spec.simulation,'sim_0x2D_label')
          res.label = spec.simulation.sim_0x2D_label;
        elseif isfield(spec.simulation,'label')
          res.label = spec.simulation.label;
        else
          res.label = 'simulation';
          spec.simulation.label = 'simulation';
        end
        res.entities = [];
      else
        res.objecttype = {'entities'};
        res.index = objind(parts{1},spec);
        res.label = parts{1};
        res.entities = parts(1);
      end      
    else                                        % a-b => {a,b}
      res.objecttype = {'connections'};
      res.index = objind(lhs,spec);
      res.label = lhs;
      res.entities = {parts{1},parts{2}};
    end
  end
end

% ----------------------------------------------------------
function ind = objind(label,spec)
  ind = find(cellfun(@(x)isequal(x,label),{spec.entities.label}));
  if isempty(ind)
    ind = find(cellfun(@(x)isequal(x,label),{spec.connections.label}));
  end
end

function result = cartesianProduct(sets)
% source: http://stackoverflow.com/questions/4165859/matlab-generate-all-possible-combinations-of-the-elements-of-some-vectors
  c = cell(1, numel(sets));
  [c{:}] = ndgrid( sets{:} );
  result = cell2mat( cellfun(@(v)v(:), c, 'UniformOutput',false) );
end
  
% Note that if you prefer, you can sort the results:
% cartProd = sortrows(cartProd, 1:numel(sets));
% Also, the code above does not check if the sets have no duplicate values (ex: {[1 1] [1 2] [4 5]}). Add this one line if you want to:
% sets = cellfun(@unique, sets, 'UniformOutput',false);

function result = permutesets(n)
  %res = cartesianProduct({1:n,1:n});
  res = cartesianProduct(repmat({1:n},[1 n]));
  res = sort(res,2);
  str = cellfun(@(k)num2str(res(k,:)),num2cell(1:size(res,1)),'uniformoutput',false);
  [str,I,J] = unique(str);
  result = res(I,:);  
end

function val = correct_loadjson_arrstr(this)
if size(this,1)>1 && ndims(this)==2
  val = cellfun(@(i)this(i,:),num2cell(1:size(this,1)),'uniformoutput',false);
elseif length(unique(this))==1 && ischar(this)
  val = repmat({this(1)},[1 numel(this)]);
elseif ~iscell(this)
  val = {this};
else
  val = this;
end
end

%% 
%     
% JSON format for (scope,variable,value) specification:
% simspec.values'
% ans = 
%     '[80:10:140]'           % 
%     '[0 .2 .5]'
%     '-[80:10:140]'
%     '[(iNa) (iNa,iK) (iK)]'
%     '[(iNa) (iNa,iK) (iK)]'
%     '{iNa,iK}'
%     '{iNa,iK}'
%     '[80:10:140]'
%     '[exp(-V/a),exp(-a*V),sin(V).*exp(-V/a)]'
%  simspec.scope',simspec.variable',simspec.values'
% ans = 
%     'E.iNa'           % literalstring
%     'E'               % literalstring
%     'E-PY.iSYN'       % literalstring
%     'E'               % literalstring
%     '(E,PY)'          
%     '(E,PY)'
%     '[E,PY]'
%     '[E.iNa, PY.iNa]'
%     'E.iNa'
% ans = 
%     'gNa'
%     'V_noise'
%     'E_SYN'
%     'mechanisms'
%     'mechanisms'
%     'mechanisms'
%     'mechanisms'
%     'gNa'
%     'bM(V)'
% ans = 
%     '[80:10:140]'
%     '[0 .2 .5]'
%     '-[80:10:140]'
%     '[(iNa) (iNa,iK) (iK)]'
%     '[(iNa) (iNa,iK) (iK)]'
%     '{iNa,iK}'
%     '{iNa,iK}'
%     '[80:10:140]'
%     '[exp(-V/a),exp(-a*V),sin(V).*exp(-V/a)]'
% 