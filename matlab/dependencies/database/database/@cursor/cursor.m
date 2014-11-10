function curs = cursor(connect, varargin)
%CURSOR Cursor constructor.
%   CURS = CURSOR(CONNECT,SQLQUERY,QTIMEOUT) returns a cursor object.
%   CONNECT is a database connection object, QUERY is a valid SQL query,
%   and QTIMEOUT is the query timeout value.
%
%   This function is called by EXEC and never invoked directly from
%   the MATLAB command line.
%
%   See also FETCH.

%   Copyright 1984-2010 The MathWorks, Inc.
%   	%

%Create parent object for generic methods
dbobj = dbtbx;

% Initialize all the elements of the structure.

curs.Attributes     = [];
curs.Data           = 0 ;
curs.DatabaseObject = [];
curs.RowLimit       = 0;
curs.SQLQuery       = [];
curs.Message        = [];

% These fields will be invisible to the user
curs.Type = 'Database Cursor Object';
curs.ResultSet      = 0 ;
curs.Cursor         = 0 ;
curs.Statement      = 0 ;
curs.Fetch          = 0 ;

if nargin < 2
    m = message('database:cursor:missingInputArg');
    curs.Message = m.getString;
    curs=class(curs,'cursor',dbobj);
    return
end

%Process inputs
%First argument must be a connection object and second must be either a SQL
%query or an object of class sqlOutput as required by the runsqlscript
%function

if(~isa(connect, 'database'))
    m = message('database:cursor:incorrectFirstArg');
    curs.Message = m.getString;
    curs=class(curs,'cursor',dbobj);
    return
end

if((~isa(varargin{1}, 'char') && (~isa(varargin{1}, 'java.lang.String')) && ~(strcmp(class(varargin{1}), 'com.mathworks.toolbox.database.sqlOutput'))))
    m = message('database:cursor:incorrectSecondArg');
    curs.Message = m.getString;
    curs=class(curs,'cursor',dbobj);
    return
end

curs.DatabaseObject = connect;

if(isa(varargin{1}, 'char') || isa(varargin{1}, 'java.lang.String'))
    sqlQuery = varargin{1};
    curs.SQLQuery       = strtrim(char(sqlQuery));
end


%
% Test for valid connection handle .. non empty value.
%

if (~isconnection(connect)),
    
    m = message('database:database:invalidConnection');
    curs.Message = m.getString;
    curs=class(curs,'cursor',dbobj);
    return;
    
end

% Call Constructor
%

% Fetch all rows matching the SQL query.

curs.Cursor = com.mathworks.toolbox.database.sqlExec(curs.SQLQuery ,connect.Handle);

   
    
    if(strcmp(class(varargin{1}), 'com.mathworks.toolbox.database.sqlOutput'))
        
        sqlOut = varargin{1};
        curs.SQLQuery = char(sqlOut.getQuery());
        curs.Message = char(sqlOut.getErrorMessage());
        curs.ResultSet = sqlOut.getResult();
        curs.Statement = sqlOut.getStmt();
        curs=class(curs,'cursor',dbobj);
        return;
        
    end
    
    
    % Now execute the sql statement and returns the result set for
    % the open cursor
    
    statementVector = createTheSqlStatement(curs.Cursor);
    status = validStatement(curs.Cursor,statementVector);
    
    % Test for error condition .. if SQL statement is invalid then zero
    % value object handle is returned.
    
    if (status ~= 0)
        
        % Return the valid SQL statement object
        curs.Statement = getValidStatement(curs.Cursor,statementVector);
        
        % Set the query timeout value if given
        if(nargin == 3)
            qTimeOut = varargin{2};
            curs.Statement.setQueryTimeout(qTimeOut)
        end
        
        % convert string to same case for testing if SELECT present in the
        % SQL command string
        
        if any(cellfun(@(str) strncmpi(str, curs.SQLQuery, length(str)), ...
                {'UPDATE ', 'DELETE ', 'INSERT ', 'COMMIT ', 'CREATE ', ...
                'DROP ', 'ALTER ', 'TRUNCATE ', 'ROLLBACK '}))
            
            % Doing an INSERT, UPDATE, DELETE,Commit or Rollback operation.
            
            rowsAltered = executeTheSqlStatement(curs.Cursor,curs.Statement);
            
            % Check to see if an error value has been returned .. if so get
            % the error message.
            
            if (rowsAltered == -5555)
                
                theMessage = statementErrorMessage(curs.Cursor,curs.Statement);
                try   %Close statement object if it was created to free resources
                    close(curs.Statement);
                catch exception %#ok
                end
                curs.Cursor         = 0;
                curs.Statement      = 0;
                curs.Message = theMessage;
                curs=class(curs,'cursor',dbobj);
                return;
                
            end
            
            if (rowsAltered == 0)
                
                if (isempty(strfind('COMMIT',upper(curs.SQLQuery))) ~= 0) && ...
                        (isempty(strfind('ROLLBACK',upper(curs.SQLQuery))) ~= 0) && ...
                        (isempty(strfind('UPDATE',upper(curs.SQLQuery))) ~= 0)
                    
                    try   %Close statement object if it was created to free resources
                        close(curs.Statement);
                    catch exception %#ok
                    end
                    curs.Message = statementErrorMessage(curs.Cursor,curs.Statement);
                end
                
            else
                
                % Delete, insert and update SQL operations.
                % Set the resultSet object element to be zero as these operations
                % do not return a result set.
                curs.ResultSet = 0;
                
            end
            
        else
            
            % Doing a Select, stored procedure or DML query.
            
            % Get the result set.
            
            resultSetVector = executeTheSelectStatement(curs.Cursor,curs.Statement);
            status = validResultSet(curs.Cursor,resultSetVector);
            
            % Test for error condition on SQL select statements .. result set
            % object handle has a zero value.
            
            if (status == 0)
                
                % Reset the elements to 0
                
                theMessage = statementErrorMessage(curs.Cursor,curs.Statement);
                try   %Close statement object if it was created to free resources
                    close(curs.Statement);
                catch exception %#ok
                end
                curs.Cursor         = 0 ;
                curs.Statement      = 0 ;
                curs.Message        = theMessage;
                curs=class(curs,'cursor',dbobj);
                return;
                
            else
                
                curs.ResultSet = getValidResultSet(curs.Cursor,resultSetVector);
                
            end
            
            
        end
        
        
    else
        
        
        % Reset the elements to 0
        
        theMessage = errorCreatingStatement(curs.Cursor);
        
        curs.Cursor         = 0 ;
        curs.Statement      = 0 ;
        curs.Message        = theMessage;
        curs=class(curs,'cursor',dbobj);
        return;
    end
    
curs = class(curs,'cursor',dbobj);
