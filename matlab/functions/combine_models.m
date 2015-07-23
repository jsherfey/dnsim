function spec = combine_models(models)
% -- combine cell array of models
if isempty(models), spec=[]; return; end
if ~iscell(models), models={models}; end
% get nodefield
if isfield(models{1},'entities'), nodefield='entities';
elseif isfield(models{1},'cells'), nodefield='cells';
elseif isfield(models{1},'nodes'), nodefield='nodes';
end
for i=1:numel(models)
  % standardize model spec structure
  this=standardize_model_spec(models{i},nodefield);
  % combine models
  if i==1
    spec=this;
  else
    spec=combine_model_pair(spec,this,nodefield);
  end
end
function spec = combine_model_pair(a,b,nodefield)
% -- combine two models (and track model relations)
spec=a; na=length(a.(nodefield));
if isempty(spec) || isempty(spec.(nodefield))
  trouble = 0;
else
  trouble = ismember({b.(nodefield).label},{a.(nodefield).label});
end
if any(trouble)
  dup={b.(nodefield).label};
  dup=dup(test);
  str=''; for i=1:length(dup), str=[str dup{i} ', ']; end
  fprintf('failed to concatenate models. duplicate cell names found: %s. rename cells and try again.\n',str(1:end-2));
  return;
end
if isfield(a,nodefield) && ~isempty(a.(nodefield))
  n=length(b.(nodefield));
  [addflds,I]=setdiff(fieldnames(a.(nodefield)),fieldnames(b.(nodefield)));
  [jnk,I]=sort(I);
  addflds=addflds(I);
  for i=1:length(addflds)
    b.(nodefield)(1).(addflds{i})=[];
  end
  b.(nodefield)=orderfields(b.(nodefield),a.(nodefield));
  b.connections=orderfields(b.connections,a.connections);
  spec.(nodefield)(end+1:end+n) = b.(nodefield);
  for i=1:n
    spec.connections(na+i,na+1:na+n) = b.connections(i,:);
  end
  if isfield(b,'files')
    spec.files = unique({spec.files{:},b.files{:}});
  end
else
  spec = b;
end
function spec = standardize_model_spec(spec,nodefield)
if ~isfield(spec,nodefield)
  if isfield(spec,'entities'), oldfield='entities';
  elseif isfield(spec,'nodes'), oldfield='nodes';
  elseif isfield(spec,'cells'), oldfield='cells';
  end
  spec.(nodefield)=spec.(oldfield);
  spec=rmfield(spec,oldfield);
end
% if isfield(spec,'entities')
%   if ~isfield(spec,nodefield)
%     spec.(nodefield)=spec.entities;
%   end
%   spec=rmfield(spec,'entities');
% end
if ~isfield(spec,'history')
  spec.history=[];
end
if ~isfield(spec,'model_uid')
  spec.model_uid=[];
end
if ~isfield(spec,'parent_uids');
  spec.parent_uids=[];
end
if ~isfield(spec.(nodefield),'parent')
  for j=1:length(spec.(nodefield))
    spec.(nodefield)(j).parent=spec.(nodefield)(j).label;
  end
end
