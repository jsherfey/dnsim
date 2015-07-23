
function report=modeldiff(m1,m2)
% Purpose: gather diffs in m2 wrt m1
% m1=CURRSPEC.history(1).spec;
% m2=CURRSPEC.history(end).spec;

report={};
% standardize structures before comparison
if isfield(m1,'entities'), m1.cells=m1.entities; end
if isfield(m2,'entities'), m2.cells=m2.entities; end
if isfield(m1,'nodes'), m1.cells=m1.nodes; end
if isfield(m2,'nodes'), m2.cells=m2.nodes; end
if ~issubfield(m1,'cells.mechs') [a,b,c,d,m1]=buildmodel2(m1,'verbose',0); m1.cells=m1.entities; m1=rmfield(m1,'entities'); end
if ~issubfield(m2,'cells.mechs') [a,b,c,d,m2]=buildmodel2(m2,'verbose',0); m2.cells=m2.entities; m2=rmfield(m2,'entities'); end
m1=rmfield(m1,setdiff(fieldnames(m1),{'cells','connections'}));
m2=rmfield(m2,setdiff(fieldnames(m2),{'cells','connections'}));

% compare models
if isequal(m1.cells,m2.cells) && isequal(m1.connections,m2.connections)
  report{end+1} = 'same model';
  return;
end

% entity labels
EL1={m1.cells.label}; 
EL2={m2.cells.label};
% connection labels
CL1={m1.connections.label}; CL1(cellfun(@isempty,CL1))=[];
CL2={m2.connections.label}; CL2(cellfun(@isempty,CL2))=[];

% indices to cell and connection matches
[ei1,ei2]=match_str(EL1,EL2); 
[ci1,ci2]=match_str(CL1,CL2);
% indices to cell mismatches
nei1=setdiff(1:numel(EL1),ei1);
nei2=setdiff(1:numel(EL2),ei2);
nci1=setdiff(1:numel(CL1),ci1);
nci2=setdiff(1:numel(CL2),ci2);

% report matches and mismatches in cells and connections
if ~isempty(nei1) || ~isempty(nei2)
  report{end+1} = 'COMPARTMENTS/ENTITIES';
end
if ~isempty(nei1)
  report{end+1} = sprintf('  [-] %s',cell2strlist(EL1(nei1)));
end
if ~isempty(nei2)
  report{end+1} = sprintf('  [+] %s',cell2strlist(EL2(nei2)));
end
if ~isempty(nci1) || ~isempty(nci2)
  report{end+1} = 'CONNECTIONS';
end
if ~isempty(nci1)
  report{end+1} = sprintf('  [-] %s',cell2strlist(CL1(nci1)));
end
if ~isempty(nci2)
  report{end+1} = sprintf('  [+] %s',cell2strlist(CL2(nci2)));
end

% modify structure for combining entities and connections
keepfields={'label','multiplicity','dynamics','mechanisms','mechs','parameters'};
rmfields=setdiff(fieldnames(m1.cells),keepfields);
m1.cells=rmfield(m1.cells,rmfields);
rmfields=setdiff(fieldnames(m2.cells),keepfields);
m2.cells=rmfield(m2.cells,rmfields);
keepfields={'label','mechanisms','parameters','mechs'};
rmfields=setdiff(fieldnames(m1.connections),keepfields);
m1.connections=rmfield(m1.connections,rmfields);
if ~isfield(m1.connections,'mechs'), m1.connections(1).mechs=[]; end
m1.connections(1).multiplicity=[];
m1.connections(1).dynamics=[];
m1.connections=orderfields(m1.connections,m1.cells);
rmfields=setdiff(fieldnames(m2.connections),keepfields);
m2.connections=rmfield(m2.connections,rmfields);
if ~isfield(m2.connections,'mechs'), m2.connections(1).mechs=[]; end
m2.connections(1).multiplicity=[];
m2.connections(1).dynamics=[];
m2.connections=orderfields(m2.connections,m2.cells);
% combine entity and connection structures and process together as "entities"
CL1={m1.connections.label}; CL1keep=(~cellfun(@isempty,CL1));
CL2={m2.connections.label}; CL2keep=(~cellfun(@isempty,CL2));
m1.cells = cat(2,m1.cells,m1.connections(CL1keep));
m2.cells = cat(2,m2.cells,m2.connections(CL2keep));
% update pseudo-entity labels
EL1={m1.cells.label}; 
EL2={m2.cells.label};
% update indices to matches
[ei1,ei2]=match_str(EL1,EL2);

% look for mismatched properties in matching cells
for a=1:length(ei1)
  % this matching cell
  i=ei1(a); E1=m1.cells(i);
  j=ei2(a); E2=m2.cells(j);
  if isequal(E1,E2)
    %report{end+1} = sprintf('%s: same',E1.label);
    continue; 
  else
    report{end+1} = sprintf('%s:',E1.label);
  end
  if ~isempty(E1.multiplicity) && ~isequal(E1.multiplicity,E2.multiplicity)
    report{end+1} = sprintf('  %s.N: %g => %g',E1.label,E1.multiplicity,E2.multiplicity);
  end
  if ~isempty(E1.dynamics) && ~isequal(E1.dynamics,E2.dynamics)
    report{end+1} = sprintf('  %s.dynamics: %s => %s',E1.label,[E1.dynamics{:}],[E2.dynamics{:}]);
  end
  if ~isempty(E1.parameters) && ~isequal(E1.parameters,E2.parameters)
    report{end+1}=sprintf('  OVERRIDE PARAMETERS (user-specified)');
    report = cat(2,report,compareparamlist(E1.parameters,E2.parameters,[E1.label '.']));
  end
  % find match/mismatch intrinsic mechanisms
  if isequal(E1.mechs,E2.mechs), continue; end
  ML1=E1.mechanisms;
  ML2=E2.mechanisms;
  [mi1,mi2]=match_str(ML1,ML2);
  nmi1=setdiff(1:numel(ML1),mi1);
  nmi2=setdiff(1:numel(ML2),mi2);
  % report matches and mismatches in cell mechanisms
  report{end+1} = '  MECHANISMS';
  if ~isempty(nmi1)
    report{end+1} = sprintf('    [-] %s.%s',E1.label,cell2strlist(ML1(nmi1)));
    %report{end+1} = sprintf('    - %s',cell2strlist(ML1(nmi1)));
  end
  if ~isempty(nmi2)
    report{end+1} = sprintf('    [+] %s.%s',E2.label,cell2strlist(ML2(nmi2)));
    %report{end+1} = sprintf('    + %s',cell2strlist(ML2(nmi2)));
  end  
  % look for mismatched properties in matching mechanisms
  for b=1:length(mi1)
    ii=mi1(b); M1=E1.mechs(ii);
    jj=mi2(b); M2=E2.mechs(ii);
    if isequal(M1,M2)
      %report{end+1} = sprintf('%s.%s: same',E1.label,M1.label);
      continue; 
    else
      % find mismatched parameters, functions, auxvars, and odes
      % parameters
      if ~isequal(M1.params,M2.params)
        report = cat(2,report,compareparamstruct(M1.params,M2.params,[ML1{ii} '.']));
      end 
      % functions
      if ~isequal(M1.functions,M2.functions)
        report = cat(2,report,comparefuncs(M1.functions,M2.functions,[ML1{ii} '.']));
      end
      % auxvars
      if ~isequal(M1.auxvars,M2.auxvars)
        report = cat(2,report,comparefuncs(M1.auxvars,M2.auxvars,[ML1{ii} '.']));
      end 
      % odes
      if ~isequal(M1.odes,M2.odes)
        report = cat(2,report,comparefuncs(cat(2,M1.statevars,M1.odes),cat(2,M2.statevars,M2.odes),[ML1{ii} '.']));
      end 
      if ~isequal(M1.ic,M2.ic)
        for c=1:length(M1.statevars)
          if ~isequal(M1.ic{c},M2.ic{c})
            report{end+1} = sprintf('    %s.%s.%s: different specification of initial conditions',E1.label,M1.label,M1.statevars{c});
          end
        end
      end % end ic diffs
    end % end mech diffs
  end % end common mechs
end % end entity diffs
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTIONS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function txt=comparefuncs(x,y,l)
if nargin<3, l=''; end
txt={};
if isempty(x)
  keys1={};
  vals1={};
else
  keys1=x(:,1);
  vals1=x(:,2);
end
if isempty(y)
  keys2={};
  vals2={};
else
  keys2=y(:,1);
  vals2=y(:,2);
end
% keys1=x(:,1); keys2=y(:,1);
% vals1=x(:,2); vals2=y(:,2);
% look at function names for differences
[ki1,ki2]=match_str(keys1,keys2);
nki1=setdiff(1:numel(keys1),ki1);
nki2=setdiff(1:numel(keys2),ki2);
if ~isempty(nki1)
  txt{end+1} = sprintf('    [-] func: %s',cell2strlist(keys1(nki1)));
end
if ~isempty(nki2)
  txt{end+1} = sprintf('    [+] func: %s',cell2strlist(keys2(nki2)));
end
% look at function expressions of matches
for i=1:length(ki1)
  if ~isequal(vals1(ki1(i)),vals2(ki2(i)))
    txt{end+1} = sprintf('    %s%s: %s',l,keys1{ki1(i)},vals1{ki1(i)});
    txt{end+1} = sprintf('          => %s',vals2{ki2(i)});
    %txt{end+1} = sprintf('    %s%s: %s => %s',l,keys1{ki1(i)},vals1{ki1(i)},vals2{ki2(i)});
  end
end

function txt=compareparamstruct(x,y,l)
keys1=fieldnames(x); vals1=struct2cell(x);
keys2=fieldnames(y); vals2=struct2cell(y);
[ki1,ki2]=match_str(keys1,keys2);
x=cellfun(@(a,b){a,b},keys1,vals1,'uni',0); x=[x{:}];
y=cellfun(@(a,b){a,b},keys2,vals2,'uni',0); y=[y{:}];
txt=compareparamlist(x,y,l);

function txt=compareparamlist(x,y,l)
if nargin<3, l=''; end
txt={};
keys1=x(1:2:end); vals1=x(2:2:end);
keys2=y(1:2:end); vals2=y(2:2:end);
[ki1,ki2]=match_str(keys1,keys2);
nki1=setdiff(1:numel(keys1),ki1);
nki2=setdiff(1:numel(keys2),ki2);
if ~isempty(nki1)
  txt{end+1} = sprintf('    [-] %s%s',l,parms2strlist(keys1(nki1),vals1(nki1)));
end
if ~isempty(nki2)
  txt{end+1} = sprintf('    [+] %s%s',l,parms2strlist(keys2(nki2),vals2(nki2)));
end  
if ~isempty(ki1)
  diffs=find(cellfun(@(i,j)i~=j,vals1(ki1),vals2(ki2)));
  for i=1:length(diffs)
    txt{end+1}=sprintf('    %s%s: %g => %g',l,keys1{ki1(diffs(i))},vals1{ki1(diffs(i))},vals2{ki2(diffs(i))});
  end
end

function S=cell2strlist(C)
S='';
for i=1:length(C)
  S=[S C{i} ', '];
end
S=S(1:end-2);

function S=parms2strlist(K,V)
S='';
for i=1:length(K)
  if ischar(V{i})
    S=[S K{i} '=' V{i} ', '];
  elseif isnumeric(V{i})
    S=[S K{i} '=' num2str(V{i}) ', '];
  else
    S=[S K{i} ', '];
  end
end
S=S(1:end-2);

function [sel1, sel2] = match_str(a, b)
% MATCH_STR looks for matching labels in two listst of strings
% and returns the indices into both the 1st and 2nd list of the matches.
% They will be ordered according to the first input argument.
%  
% [sel1, sel2] = match_str(strlist1, strlist2)
%
% The strings can be stored as a char matrix or as an vertical array of
% cells, the matching is done for each row.

% Copyright (C) 2000, Robert Oostenveld

% ensure that both are cell-arrays
if isempty(a)
  a = {};
elseif ~iscell(a)
  a = cellstr(a);
end
if isempty(b)
  b = {};
elseif ~iscell(b)
  b = cellstr(b);
end

% ensure that both are column vectors
a = a(:);
b = b(:);

% replace all unique strings by a unique number and use the fact that
% numeric comparisons are much faster than string comparisons
[dum1, dum2, c] = unique([a; b]);
a = c(1:length(a));
b = c((length(a)+1):end);

sel1 = [];
sel2 = [];
for i=1:length(a)
  % s = find(strcmp(a(i), b));  % for string comparison
  s = find(a(i)==b);            % for numeric comparison
  sel1 = [sel1; repmat(i, size(s))];
  sel2 = [sel2; s];
end
