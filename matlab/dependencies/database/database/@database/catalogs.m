function p = catalogs(conn)
%CATALOGS Get database catalog names.
%   P = CATALOGS(CONN) returns the catalogs for the database 
%   connection CONN.
%
%   See also GET, COLUMNS, SCHEMAS, TABLES.

%   Copyright 1984-2009 The MathWorks, Inc.

%create database metadata object
d = dmd(conn);

%get catalogs
p = get(d,'Catalogs');