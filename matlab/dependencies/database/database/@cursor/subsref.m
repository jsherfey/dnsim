function varargout = subsref(A,S)
%SUBSREF Reference a value for a Database Cursor object.
%  
%  VALUE = A.PROPERTY assigns the value of PROPERTY of cursor object A to 
%  the variable VALUE
%  
%  PROPERTY can be any of:
%   Attributes
%   Data
%   DatabaseObject
%   RowLimit
%   SQLQuery
%   Message
%   Type
%   ResultSet
%   Cursor
%   Statement
%   Fetch
%  
%  If A is an array of cursor, the above statement assigns the value of 
%  A(1).PROPERTY to VALUE
%
%  VALUE = A(i) assigns to VALUE the ith element of the cursor array A
%   
%
%  See also GET.

% Copyright 1984-2006 The MathWorks, Inc.

% dot indexing is not case sensitive
flds = fieldnames(A);
for idx = 1:length(S)
    if strcmp(S(idx).type,'.')
        i = find(strcmpi(flds,S(idx).subs));
        if ~isempty(i)
            S(idx).subs = flds{i};
        end
    end
end

[varargout{1:nargout}] = builtin('subsref',A,S);
end 