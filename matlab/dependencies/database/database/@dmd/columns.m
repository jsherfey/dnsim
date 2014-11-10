function p = columns(d,c,s,t)
%COLUMNS Get database table column names.
%   P = COLUMNS(D,C,S,T) returns the columns for the given database metadata D, 
%   the catalog C, the schema S, and the table T.
%
%   P = COLUMNS(D,C,S) returns the columns for all tables for the given
%   catalog and schema.
%
%   P = COLUMNS(D,C) returns all columns for all tables of all schemas for the 
%   given catalog.
%
%   See also GET, COLUMNNAMES, COLUMNPRIVILEGES.

%   Copyright 1984-2012 The MathWorks, Inc.

%Create com.mathworks.toolbox.database.databaseDMD instance handle
a = com.mathworks.toolbox.database.databaseDMD;

%Set schema to null if not entered
if nargin < 3
  s = {};
end

%Get the list of tables and columns, trap null schema entry
if iscell(c) && (length(c) > 1)
  error(message('database:dmd:tooManyCatalogs'))
end
ncols = 14;   %Columns result set has 14 columns
tmp = dmdColumns(a,d.DMDHandle,c,s);

%Return if no table columns found
if ~(tmp.size)
  p = [];
  return
end

%Parse vector of columns info
y = system_dependent(44,tmp,tmp.size/ncols)';
z = unique(y(:,3));
x = cell(length(z),2);

%Return table and corresponding column information
for i = 1:length(z)
  j = strcmp(y(:,3),z(i));
  x{i,1} = z{i};
  x{i,2} = y(j,4)';
end

%Return columns for given table or else return all table information
if nargin == 4 && ~isempty(t)
  j = strcmpi(x(:,1),t);
  try
    p = x{j,2};
  catch %#ok
    error(message('database:dmd:invalidTable'))
  end
else
  p = x;
end