function s = set(h,p,v)
%SET Set RowLimit for cursor fetch.
%   SET(H, 'PROPERTY', 'VALUE') sets the VALUE of the given PROPERTY for the
%   Database Cursor object, H.
%
%   S = SET(H) returns the list of valid properties.
%
%   See also GET.

% Copyright 1984-2005 The MathWorks, Inc.

%Method not supported for cursor array
if(length(h) > 1)
    error(message('database:cursor:unsupportedFeature'));
end

%Call builtin/set if object not a cursor
if ~isa(h,'cursor')
  builtin('set',h,p,v)
  return
end

%Build property list
prps = {'Attributes';...
    'Data';...
    'DatabaseObject';...
    'RowLimit';...
    'SQLQuery';...
    'Message';...
    'Type';...
    'ResultSet';...
    'Cursor';...
    'Statement';...
    'Fetch';...
  };

%Determine which properties are requested
if nargin == 1
  s = prps;
  return
else
  p = chkprops(h,p,prps);
end

for i = 1:length(p)
  if any(strcmp(p{i},{'Attributes';'Data';'DatabaseObject';'SQLQuery';'Message';'Type';...
        'ResultSet';'Cursor';'Statement';'Fetch'}))
    error(message('database:cursor:readOnlyProperty', p{ i }))
  elseif strcmp(p{i},'RowLimit')
    if ~iscell(v)
      v = num2cell(v);
    end
    setMaxRows(h.Statement,v{i})
  end
end
