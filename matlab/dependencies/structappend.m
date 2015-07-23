function base = structappend(base,dominant)
% call: s = structappend(base,dominant)
% purpose: add all fields in dominant to base and replace existing
% INCOMPLETE FUNCTION as of 21-Oct-2012

baseflds = fieldnames(base);
domflds = fieldnames(dominant);
for f = 1:numel(domflds)
  fld = domflds{f};
  if ~ismember(fld,baseflds)
    base.(fld) = dominant.(fld);
  elseif isstruct(dominant.(fld))
    base.(fld) = structappend(base.(fld),dominant.(fld));
  elseif iscell(base.(fld))
    % ...
  else
    base.(fld) = dominant.(fld);
  end
end
