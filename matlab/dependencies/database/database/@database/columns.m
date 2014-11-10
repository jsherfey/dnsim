function p = columns(conn,c,s,t)
%COLUMNS Get database table column names.
%   P = COLUMNS(CONN,C,S,T) returns the columns for the given database 
%   connection CONN, the catalog C, the schema S, and the table T.
%
%   P = COLUMNS(CONN,C,S) returns the columns for all tables for the given
%   catalog and schema.
%
%   P = COLUMNS(CONN,C) returns all columns for all tables of all schemas for the 
%   given catalog.
%
%   P = COLUMNS(CONN) returns all columns for all tables given the database 
%   connection CONN.
%
%   See also GET, COLUMNNAMES.

%   Copyright 1984-2009 The MathWorks, Inc.

%Create com.mathworks.toolbox.database.databaseDMD instance handle
a = com.mathworks.toolbox.database.databaseDMD;
d = dmd(conn);

%Set schema and catalog to null if not entered
if nargin < 3 || isempty(s)
  s = {};
end
if nargin < 2 || isempty(c)
  c = {};
end

%Get the list of tables and columns, trap null schema entry
if iscell(c) && (length(c) > 1)
  error(message('database:dmd:tooManyCatalogs'))
end
ncols = 14;    % getColumns method returns 14 columns of data
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
  x{i,1} = z{i}; 
  x{i,2} = y(strcmp(y(:,3),z(i)),4)';
end

%Return columns for given table or else return all table information
if nargin == 4 & ~isempty(t)   %#ok
  try
    p = x{strcmpi(x(:,1),t),2};
  catch exception
    error(message('database:database:invalidTable'))
  end
else
  p = x;
end