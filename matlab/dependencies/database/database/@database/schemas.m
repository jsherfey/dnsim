function p = schemas(conn)
%SCHEMAS Get database schema names.
%   P = SCHEMAS(CONN) returns the schema names for the database 
%   connection CONN.
%
%   See also GET, CATALOGS, COLUMNS, TABLES.

%   Copyright 1984-2009 The MathWorks, Inc.

%create database metadata object
d = dmd(conn);

%get catalogs
p = get(d,'Schemas');