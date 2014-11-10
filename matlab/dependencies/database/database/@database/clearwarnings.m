function clearwarnings(c)
%CLEARWARNINGS Clear warnings for database connection.
%   CLEARWARNINGS(C) clears the warnings reported for the database
%   connection, C.
%
%   See also GET.

%   Author(s): C.F.Garvin, 07-08-98
%   Copyright 1984-2003 The MathWorks, Inc.

%Test for valid and open connection
if ~isconnection(c)
  error(message('database:database:invalidConnection'))
end

%Clear connection warnings
a = com.mathworks.toolbox.database.databaseConn;
x = connClearWarnings(a,c.Handle);

%Check for exception
if x == -1
  error(message('database:database:clearWarningsFailure'))
end
  
