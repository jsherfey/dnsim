function v = versioncolumns(d,c,s,t,x)
%VERSIONCOLUMNS Get automatically updated table columns.
%   P = VERSIONCOLUMNS(D,C,S,T) returns the table's columns that are 
%   automatically updated when any row value is updated given the database metadata
%   object, catalog C, schema S and table T. 
%   
%   P = VERSIONCOLUMNS(D,C,S) returns the information for all tables associated 
%   with the given catalog and schema.
%
%   P = VERSIONCOLUMNS(D,C) returns the information for all tables of all schemas
%   of the given catalog.
%
%   See also GET, PROCEDURECOLUMNS.

%   Copyright 1984-2008 The MathWorks, Inc.

%Create com.mathworks.toolbox.database.databaseDMD instance
a = com.mathworks.toolbox.database.databaseDMD;

%Initiate column argument for return data, default is 2, must be < 9
if nargin < 5
  x = 2;
end

%Initialize schema if not input
if nargin < 3
  s = {};
end

%Get all tables if none given
if nargin < 4
  t = tables(d,c,s);
elseif ischar(t)
  t = {t};
end

%Get column information
tmp = [];
for i = 1:length(t)
  tmp = [tmp dmdVersionColumns(a,d.DMDHandle,c,s,t{i,1})];
end
j = (tmp == '''');
tmp(j) = [];
if isempty(tmp)
  v = {};
  return
end
p = textscan(tmp,'%s%s%s%s%s%s%s%s','delimiter',',');
if isempty(p)
  v = p;
else
  v = p{:,x};
end
