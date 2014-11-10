function cursor = fetchmulti(initialCursor)
%FETCHMULTI Import data into MATLAB from multiple resultsets.
%   CURSOR = FETCHMULTI(INITIALCURSOR) returns a cursor 
%   object with values for all five elements of the structure
%   if successful otherwise returns the input cursor unchanged. 
%   INITIALCURSOR  is a cursor object that has values for defined 
%   for the first three elements from the sqlexec function.  CURSOR.DATA
%   will contain the data from each resultset associated with
%   CURSOR.STATEMENT.   CURSOR.DATA will be a cell array of cell arrays,
%   structures or numeric matrices depending on the setting of the
%   preference DataReturnFormat set by SETFBPREFS.
%
%  Example:
%
%  cursor = fetchmulti(cursor)
%
%  returns the data for all resultsets associated with cursor.
%
%  See also EXEC, FETCH, SETDBPREFS

%   Copyright 1984-2005 The MathWorks, Inc.
%   	%

%Method not supported for cursor array
if(length(initialCursor) > 1)
    error(message('database:cursor:unsupportedFeature'));
end


%fetch the data for the first resultset
tmpCursor = fetch(initialCursor);
cursor = tmpCursor;
cursor.Data = [];
cursor.Data{1} = tmpCursor.Data;


%Check if more resultsets are being returned. When all results have been 
%exhausted, the method getMoreResults returns false, and the method 
%getUpdateCount returns -1. 
rsstat = 1;
ucstat = 1;

while(rsstat ~= 0 || ucstat ~= -1)
    
    rsstat = initialCursor.Statement.getMoreResults;
    if(~rsstat)
        ucstat = initialCursor.Statement.getUpdateCount();
    else
        initialCursor.ResultSet = initialCursor.Statement.getResultSet;
        tmpCursor = fetch(initialCursor);
        cursor.Data{end+1} = tmpCursor.Data;
        
    end
end