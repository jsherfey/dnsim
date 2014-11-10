function n = sql2native(c,s)
%SQL2NATIVE Convert JDBC SQL grammar into system's native SQL grammar.
%   N = SQL2NATIVE(C,S) converts the SQL statement string, S, into
%   the system's native SQL grammar.  The native SQL statement is 
%   returned.  C is the database connection.

%   Author(s): C.F.Garvin, 07-08-98
%   Copyright 1984-2003 The MathWorks, Inc.

%Test for valid and open connection
if ~isconnection(c)
  error(message('database:database:invalidConnection'))
end

%Java call to convert SQL statement
n = nativeSQL(c.Handle,s);
