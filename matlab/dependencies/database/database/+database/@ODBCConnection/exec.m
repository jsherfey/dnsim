function curs = exec( conn, sqlQuery, varargin )
%EXEC Execute SQL statement and open Cursor
%   CURSOR = EXEC(CONNECT,SQLQUERY,QTIMEOUT) returns a cursor object
%   CONNECT is a database object returned by DATABASE.ODBCCONNECTION.
%   SQLQUERY is a valid SQL statement. Use FETCH to retrieve data
%   associated with CURSOR.
%
%   Example:
%
%   cursor = exec(connect,'select * from emp')
%
%   where:
%
%   connect is a valid database object.
%
%   'select * from emp' is a valid SQL statement that selects all
%   columns from the emp table.
%
%   See also FETCH.

%   Copyright 1984-2013 The MathWorks, Inc.

%Check number of input arguments
narginchk(2, 3);

% Create a cursor object
curs = database.ODBCCursor();

% Check for valid connection
if(~isempty(conn.Message))
    
    m = message('database:database:connectionFailure', conn.Message);
    
    %Throw if errorhandling is set to report
    if strcmpi(setdbprefs('ErrorHandling'), 'report')
        error(m);
    end
    
    curs.Message = m.getString();
    
    return;
end

%Input validation
p = inputParser;

p.addRequired('sqlQuery', @ischar);
p.addOptional('qTimeOut', 0, @qtimeoutCheck);

try 
    %Catch Input Validation errors
    p.parse(sqlQuery, varargin{:});
    
    %Set SQL Query
    curs.SQLQuery = sqlQuery;
    
    %Create ODBCStatementHandle object
    connHandle = conn.Handle;
    stmtObj = connHandle.createStatement();
    curs.Statement = stmtObj;
    
    %Execute query
    stmtObj.executeQuery(p.Results.sqlQuery, p.Results.qTimeOut);

catch e
    
    %Throw if errorhandling is set to report
    if strcmpi(setdbprefs('ErrorHandling'), 'report')
        e.rethrow();
    end
    curs.Message = e.message;
    
    return;
    
end


end

function OK = qtimeoutCheck(QTimeOut)

if(~isnumeric(QTimeOut) || ~isscalar(QTimeOut) || mod(QTimeOut, 1) ~= 0 )
    error(message('database:runsqlscript:inputParameterError', 'qTimeOut'))
else
    OK = true;
end

end

