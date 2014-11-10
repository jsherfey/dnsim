function b = bestrowid(d,c,s,t,n,x)
%BESTROWID Get database table unique row identifier.
%   B = BESTROWID(D,C,S,T) returns the set of table columns that 
%   uniquely identifies a row.  D is the database metadata object, C is the
%   catalog, S is the schema, and T is the table.
%
%   B = BESTROWID(D,C,S) returns the unique row identifier for all tables
%   associated with the given catalog and schema.
%
%   See also COLUMNS, GET, TABLES.

%   Copyright 1984-2011 The MathWorks, Inc.

%Create com.mathworks.toolbox.database.databaseDMD instance handle
a = com.mathworks.toolbox.database.databaseDMD;

%Set return index, must be less than 9, for all data, set x = 1:8.
if nargin < 6
  x = 1:8;
end

%Set default scope argument (hidden input)
if nargin < 5
  n = 0;
end

%Create empty S is not entered
if nargin < 3
  s = [];
end

%Get table list if no table input, include type TABLE only
if nargin < 4 || isempty(t)
  y = tables(d,c,s);
  t = y(strcmp(y(:,2),'TABLE'),1);
elseif ischar(t)
  t = {t};
end

%Get column information
L = length(t);
y = cell(L,1);
for i = 1:L
  tmp = dmdBestRowIdentifier(a,d.DMDHandle,c,s,t{i},n);
  if ~isempty(tmp)
    eval(['y{i} = {' tmp '};']) 
    tmp = y{:};
    y{i} = tmp(:,x);
  end
end

if isempty(y)
  b = [];
elseif L == 1
  b = y{:};
else
  b = [t y];
end

