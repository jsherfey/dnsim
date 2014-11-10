function x = isreadonly(c)
%ISREADONLY Detect if database connection is read-only.
%   X = ISREADONLY(C) returns 1 if the database connection, C, is
%   read-only and 0 otherwise.
%
%   See also ISCONNECTION.

%   Author(s): C.F.Garvin, 07-08-98
%   Copyright 1984-2003 The MathWorks, Inc.

%Test for valid and open connection
if ~isconnection(c)
  error(message('database:database:invalidConnection'))
end

%Check for read-only connection
a = com.mathworks.toolbox.database.databaseConn;
x = connIsReadOnly(a,c.Handle);
