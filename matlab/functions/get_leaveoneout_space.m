function allspecs=get_leaveoneout_space(spec,scope)
npop=numel(spec.cells);
if isfield(spec,'entities')
  nodetype='entities';
elseif isfield(spec,'cells')
  nodetype='cells';
else
  return;
end
if nargin<2 || isempty(scope) || isequal(scope,'*') || (iscell(scope) && isequal(scope{1},'*'))
  scope={spec.(nodetype).label}; 
elseif ischar(scope)
  scope={scope};
end
if ~ischar(spec.simulation.scope) || isempty(spec.simulation.scope)
  spec.simulation.scope = [scope{:}];%spec.simulation.scope{1};
end
if iscell(spec.simulation.variable)
  spec.simulation.variable = spec.simulation.variable{1};
end

% create copies of spec for each simulation
nmint=0; % # of intrinsic mechanisms
nmcon=0; % # of connection mechanisms
for i=1:npop
  if ~ismember(spec.(nodetype)(i).label,scope)
    continue;
  end
  nmint=nmint+numel(spec.(nodetype)(i).mechanisms);
  for j=1:npop
    if ~ismember(spec.(nodetype)(j).label,scope)
      continue;
    end    
    nmcon=nmcon+numel(spec.connections(i,j).mechanisms);
  end
end
nspec=nmint+nmcon+1; % # of models to simulate
[allspecs{1:nspec}]=deal(spec);

% remove one mechanism from each model
cnt=1;
for i=1:npop
  if ~ismember(spec.(nodetype)(i).label,scope)
    continue;
  end
  nmech=numel(spec.(nodetype)(i).mechanisms);
  for j=1:nmech
    allspecs{cnt}.(nodetype)(i).mechanisms(j)=[];
    allspecs{cnt}.(nodetype)(i).mechs(j)=[];
    if nmech==1
      allspecs{cnt}.(nodetype)(i).mechanisms=[];
      allspecs{cnt}.(nodetype)(i).mechs=[];
    end    
    allspecs{cnt}.simulation.values = sprintf('-%s-%s',...
      spec.(nodetype)(i).label,...
      spec.(nodetype)(i).mechanisms{j});
    allspecs{cnt}.simulation.description = sprintf('%g_mechanisms%s',cnt,allspecs{cnt}.simulation.values);
    cnt=cnt+1;
  end
end
for i=1:npop
  if ~ismember(spec.(nodetype)(i).label,scope)
    continue;
  end  
  for j=1:npop
    if ~ismember(spec.(nodetype)(j).label,scope)
      continue;
    end   
    nmech=numel(spec.connections(i,j).mechanisms);
    for k=1:nmech
      allspecs{cnt}.connections(i,j).mechanisms(k)=[];
      allspecs{cnt}.connections(i,j).mechs(k)=[];
      if nmech==1
        allspecs{cnt}.connections(i,j).mechanisms=[];
        allspecs{cnt}.connections(i,j).mechs=[];
      end
      allspecs{cnt}.simulation.values = sprintf('-%s-%s-%s',...
        spec.(nodetype)(i).label,...
        spec.(nodetype)(j).label,...
        spec.connections(i,j).mechanisms{k});
      allspecs{cnt}.simulation.description = sprintf('%g_mechanisms%s',cnt,allspecs{cnt}.simulation.values);
      cnt=cnt+1;
    end
  end
end
allspecs{end}.simulation.values = 'ALL';
allspecs{end}.simulation.description = sprintf('%g_mechanismsALL',cnt);



