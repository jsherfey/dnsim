function txt = mech_spec2str(mech)
% Purpose: prepare text to display mech model parameters and equations
txt = {}; n=0;
if isempty(mech)
  return;
end
% print parameters
if ~isempty(mech.params)
  keys=fieldnames(mech.params);
  vals=struct2cell(mech.params);
  for i=1:length(keys)
    if i==1, n=n+1; txt{n}=sprintf('%% Parameters:'); end
    n=n+1; txt{n}=sprintf('%s = %s',keys{i},dat2str(vals{i}));
    if i==length(keys), n=n+1; txt{n}=sprintf(' '); end
  end
end
% print auxiliary functions
for i=1:size(mech.auxvars,1)
  if i==1, n=n+1; txt{n}=sprintf('%% Auxiliary variables:'); end
  n=n+1; txt{n}=sprintf('%s = %s',mech.auxvars{i,1},dat2str(mech.auxvars{i,2}));
  if i==size(mech.auxvars,1), n=n+1; txt{n}=sprintf(''); end
end
% print functions
for i=1:size(mech.functions,1)
  if i==1, n=n+1; txt{n}=sprintf('%% Functions:'); end
  % put in a form that parse_mech_spec() can process
  tmp = sprintf('%s = %s',mech.functions{i,:});
  lhs = regexp(tmp,'^\w+','match'); lhs=lhs{1};
  var = regexp(tmp,'@\([\w,]+\)','match'); var=var{1};
  rhs = regexp(tmp,'@\([\w,]+\).+$','match'); rhs=rhs{1};
  rhs = strtrim(strrep(rhs,var,''));
  var = var(2:end);
  tmp = sprintf('%s%s = %s',lhs,var,rhs);
  n=n+1; txt{n}=tmp;%sprintf('%s = %s',tmp);
  if i==size(mech.functions,1), n=n+1; txt{n}=sprintf(' '); end
end
% print odes
for i=1:size(mech.odes,1)
  if i==1, n=n+1; txt{n}=sprintf('%% ODEs:'); end
  n=n+1; txt{n}=sprintf('%s'' = %s',mech.statevars{i},mech.odes{i});
  n=n+1; txt{n}=sprintf('%s(0) = %s',mech.statevars{i},dat2str(mech.ic{i}));
  if i==size(mech.odes,1), n=n+1; txt{n}=sprintf(' '); end
end
% print interface statements
for i=1:size(mech.substitute,1)
  if size(mech.substitute,1)==1 && strcmp(mech.substitute{i,1},'null') && strcmp(mech.substitute{i,2},'null')
    break;
  end
  if i==1, n=n+1; txt{n}=sprintf('%% Interface:'); end%Expose and/or insert into compartment dynamics:'); end
  n=n+1; txt{n}=sprintf('%s => %s',mech.substitute{i,:});
  if i==size(mech.substitute,1), n=n+1; txt{n}=sprintf(' '); end
end
function val=dat2str(val)
% purpose: convert various data classes into a character form for readable display
if isnumeric(val)
  val = ['[' num2str(val) ']'];
elseif ischar(val)
  % do nothing
else
  val = 'unrecognized';
end