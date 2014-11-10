function close(cursor)
%CLOSE Close cursor.
%   CLOSE(CURSOR) closes the database cursor.
%   CURSOR is a cursor structure with all elements defined.
%
%   See also FETCH.

%   Copyright 1984-2013 The MathWorks, Inc.
%
% function closes the cursor for the SQL statement

if(~isempty(cursor.Statement) && isa(cursor.Statement, 'database.internal.ODBCStatementHandle'))
    cursor.Statement.closeStatement();
end
    
end
    