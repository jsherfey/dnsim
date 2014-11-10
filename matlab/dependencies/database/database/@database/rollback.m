function rollback(c) 
%ROLLBACK Undo database changes.
%   ROLLBACK(C) drops all changes since the previous commit or rollback
%   and releases connection's database locks.   C is the database connection.
%
%   See also COMMIT.

%   Author(s): C.F.Garvin, 07-08-98
%   Copyright 1984-2003 The MathWorks, Inc.

%Test for valid and open connection
if ~isconnection(c)
  error(message('database:database:invalidConnection'))
end

%Rollback connection changes
a = com.mathworks.toolbox.database.databaseConn;
x = connRollback(a,c.Handle);

%Check for exception
if x == -1
  error(message('database:database:rollbackFailure'))
end
