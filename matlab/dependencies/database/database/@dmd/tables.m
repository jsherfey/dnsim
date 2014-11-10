function t = tables(d,c,s,x)
%TABLES Get database table names.
%   T = TABLES(D,C,S) returns the list of tables and table types for the 
%   database with the catalog name C and schema name S.  D is the database 
%   metadata object resulting  from a database connection object. 
%
%   T = TABLES(D,C) returns all tables and table types for all schemas of the
%   given catalog.
%
%   See also GET, TABLEPRIVILEGES.

%   Copyright 1984-2012 The MathWorks, Inc.

%Create com.mathworks.toolbox.database.databaseDMD instance handle
a = com.mathworks.toolbox.database.databaseDMD;

%Check for valid connection
tmp = d.DMDHandle;
conn = tmp.getConnection;
if conn.isClosed
  error(message('database:dmd:closedConnection'))
end

%Set return data indices, must be < 6
if nargin < 4
  x = [3 4];
end
if nargin < 3 || isempty(s)
  s = {};
end

%Get the list of tables
tmp = dmdTables(a,d.DMDHandle,c,s);
if ~(tmp.size)    %Some databases use null catalogs and key off schemas
  tmp = dmdTables(a,d.DMDHandle,{},s);
end

%Trap connection with associate tables
if ~(tmp.size)
  error(message('database:dmd:noTablesFound'))
end

%Tables returned as vector, parse it
ncols = 5;   %Table result set has 5 columns
z = system_dependent(44,tmp,tmp.size/ncols)';

%Find schema match if given
if isempty(z)
  t = z;
else
  if ~isempty(s)
    i = strcmp(s,z(:,2));
    t = z(i,x);
  else
    t = z(:,x);
  end  
end
