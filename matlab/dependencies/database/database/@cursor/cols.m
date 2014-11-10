function columns = cols(cursor)
%COLS Get number of columns in fetched data set.
%   COLUMNS = COLS(CURSOR) returns the number of columns 
%   in a database table. CURSOR is a cursor structure in 
%   which all elements have values. 
%
%   Example:
%
%   columns = cols(cursor)
%
%   Function returns the number of columns selected in the
%   SQL query to columns.
%
%   For example, issuing the SQL query, against the Microsoft
%   Access database Northwind. 
%
%   'select * from employees'
%
%   returns all columns from the database table employees.
%
%   Invoking the sqlcols command as follows:
%
%   columns = cols(cursor)
%
%   returns the following value to the variable columns:
%
%   columns = 17
%
%   indicating there are 17 fields in cursor.
%
%   See also FETCH.

    
%   Copyright 1984-2005 The MathWorks, Inc.
%   	%

%Method not supported for cursor array
if(length(cursor) > 1)
    error(message('database:cursor:unsupportedFeature'));
end

status = 0;

if isa(cursor.Fetch,'com.mathworks.toolbox.database.fetchTheData')
  
  md = getTheMetaData(cursor.Fetch);
  status = validResultSet(cursor.Fetch,md);
    
end

if (status ~= 0)
  
  resultSetMetaData = getValidResultSet(cursor.Fetch,md);
  columns = double(maximumColumns(cursor.Fetch,resultSetMetaData));
      
else
   
  columns = -1;
   
end   
