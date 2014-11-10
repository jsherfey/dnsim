function p = procedures(d,c,s,x)
%PROCEDURES Get catalog's stored procedures.
%   P = PROCEDURES(D,C,S) returns stored procedure information for the given
%   database metadata D, catalog C, and schema S.
%
%   P = PROCEDURES(D,C) returns stored procedure information for all schemas of 
%   the given catalog.
%
%   See also GET, PROCEDURECOLUMNS.

%   Author(s): C.F.Garvin, 08-07-98
%   Copyright 1984-2002 The MathWorks, Inc.

%Create com.mathworks.toolbox.database.databaseDMD instance
a = com.mathworks.toolbox.database.databaseDMD;

%Set default index for return columns, 3 is the procedure name, must be < 9
if nargin < 4
  x = 3;
end

%Initialize s to empty if not input
if nargin < 3
  s = {};
end

%Get and parse procedure information
tmp = dmdProcedures(a,d.DMDHandle,c,s);
j = (tmp == '''');
tmp(j) = [];
allinfo = textscan(tmp,'%s%s%s%s%s%s%s%s','delimiter',',');
if isempty(allinfo)
  p = allinfo;
else
  p = allinfo{:,x};
end
