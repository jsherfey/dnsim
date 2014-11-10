function v = get(d,p)
%GET Get property of cursor object.
%   VALUE = GET(HANDLE, PROPERTY) will return the VALUE of the PROPERTY 
%   specified for the given HANDLE to a Cursor object.
%
%   If HANDLE is an array of cursor objects and PROPERTY contains a single
%   property, VALUE is a cell array containing the value of PROPERTY of 
%   each of the objects in HANDLE. If PROPERTY contains multiple 
%   properties, VALUE is a struct array.
%
%   VALUE  = GET(HANDLE) returns a structure where each field name is the
%   name of a property of HANDLE and each field contains the value of that
%   property.
%
%   If HANDLE is an array of cursor objects, VALUE is an array of struct
%   with size equal to size of the cursor array.
%   
%   See also SET.

% Copyright 1984-2002 The MathWorks, Inc.

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

if nargin == 1
  p = prps;
else
  p = chkprops(d,p,prps);
end

if(length(d) > 1)
    
    %If a single property name is passed, return output as a cell array,
    %else return output as an array of struct
    if(length(p) == 1)
        v = cell(length(d), 1);
        for ind = 1: length(d)
            v(ind) = {get(d(ind), p)};
        end
    else
        v = struct([]);
        for ind = 1: length(d)
            if ind == 1
                v = get(d(ind), p);
                v = repmat(v, length(d), 1);
            else
                v(ind) = get(d(ind), p);
            end
        end 
    end
    return;
end
%Get property values
for i = 1:length(p)
  if strcmp(p{i},'RowLimit')
    v.RowLimit = getMaxRows(d.Statement);
  else
    eval(['v.' p{i} ' = d.' p{i} ';'])
  end
end

if length(p) == 1
  eval(['v = v.' char(p) ';'])
end
