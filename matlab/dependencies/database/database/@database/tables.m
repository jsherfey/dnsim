function t = tables(conn,c,s,x)
%TABLES Get database table names.
%   T = TABLES(CONN,C,S) returns the list of tables and table types for the 
%   database with the catalog name C and schema name S.  CONN is the database 
%   metadata object resulting from a database connection object. 
%
%   T = TABLES(CONN,C) returns all tables and table types for all schemas of the
%   given catalog.
%
%   T = TABLES(CONN) returns all tables and table types for the given
%   connection, CONN.
%
%   See also GET.

%   Copyright 1984-2009 The MathWorks, Inc.


%Check for valid connection
if ~isconnection(conn)
  error(message('database:database:closedConnection'))
end

%Set return data indices, must be < 6
if nargin < 4
  x = [3 4];
end
if nargin < 3 || isempty(s)
  s = {};
end
if nargin < 2
  c = {};
end

%Create com.mathworks.toolbox.database.databaseDMD instance handle and
%metadataobject
a = com.mathworks.toolbox.database.databaseDMD;
d = dmd(conn);

%Get the list of tables
tmp = dmdTables(a,d.DMDHandle,c,s);
if ~(tmp.size)    %Some databases use null catalogs and key off schemas
  tmp = dmdTables(a,d.DMDHandle,{},s);
end

%Trap connection with associate tables
if ~(tmp.size)
  error(message('database:database:noTablesFound'))
end

%Tables returned as vector, parse it
ncols = 5;   %Table result set has 5 columns
z = system_dependent(44,tmp,tmp.size/ncols)';

%Find schema match if given
if isempty(z)
  t = z;
else
  if ~isempty(s)
    t = z(strcmp(s,z(:,2)),x);
  else
    t = z(:,x);
  end  
end