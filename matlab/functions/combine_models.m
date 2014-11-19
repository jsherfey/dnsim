function spec = combine_models(models)
% -- combine cell array of models
if isempty(models), spec=[]; return; end
if ~iscell(models), models={models}; end
for i=1:numel(models)
  % standardize model spec structure
  this=standardize_model_spec(models{i});
  % combine models
  if i==1
    spec=this;
  else
    spec=combine_model_pair(spec,this);
  end
end
function spec = combine_model_pair(a,b)
% -- combine two models (and track model relations)
spec=a; 
if isempty(spec) || isempty(spec.cells)
  trouble = 0;
else
  trouble = ismember({b.cells.label},{a.cells.label});
end
if any(trouble)
  dup={b.cells.label};
  dup=dup(test);
  str=''; for i=1:length(dup), str=[str dup{i} ', ']; end
  fprintf('failed to concatenate models. duplicate cell names found: %s. rename cells and try again.\n',str(1:end-2));
  return;
end
if isfield(a,'cells') && ~isempty(a.cells)
  n=length(b.cells);
  [addflds,I]=setdiff(fieldnames(a.cells),fieldnames(b.cells));
  [jnk,I]=sort(I);
  addflds=addflds(I);
  for i=1:length(addflds)
    b.cells(1).(addflds{i})=[];
  end
  b.cells=orderfields(b.cells,a.cells);
  b.connections=orderfields(b.connections,a.connections);
  spec.cells(end+1:end+n) = b.cells;
  for i=1:n
    spec.connections(end+i,end+1:end+n) = b.connections(i,:);
  end
  if isfield(b,'files')
    spec.files = unique({spec.files{:},b.files{:}});
  end
else
  spec = b;
end
function spec = standardize_model_spec(spec)
if isfield(spec,'entities')
  if ~isfield(spec,'cells')
    spec.cells=spec.entities;
  end
  spec=rmfield(spec,'entities');
end
if ~isfield(spec,'history')
  spec.history=[];
end
if ~isfield(spec,'model_uid')
  spec.model_uid=[];
end
if ~isfield(spec,'parent_uids');
  spec.parent_uids=[];
end
if ~isfield(spec.cells,'parent')
  for j=1:length(spec.cells)
    spec.cells(j).parent=spec.cells(j).label;
  end
end
