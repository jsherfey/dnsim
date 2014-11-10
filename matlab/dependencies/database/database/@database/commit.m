function commit(c) 
%COMMIT Make database changes permanent.
%   COMMIT(C) makes all changes since the previous commit or rollback
%   permanent and releases connection's database locks.   C is the
%   database connection.
%
%   See also ROLLBACK.

%   Author(s): C.F.Garvin, 07-08-98
%   Copyright 1984-2003 The MathWorks, Inc.

%Test for valid and open connection
if ~isconnection(c)
  error(message('database:database:invalidConnection'))
end

%Commit connection changes
a = com.mathworks.toolbox.database.databaseConn;
x = connCommit(a,c.Handle);

%Check for exception
if x == -1
  error(message('database:database:commitFailure'))
end
