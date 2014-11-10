function fieldString = columnnames(cursor,bCellArray)
%COLUMNNAMES Get names of columns in fetched data set.
%   FIELDSTRING = columnnames(CURSOR) returns the column names 
%   of the data selected from database table. The column names 
%   are enclosed in quotes and separated by commas.
%
%   FIELDSTRING = COLUMNNAMES(CURSOR,BCELLARRAY) returns the column names
%   as a cell array of strings when BCELLARRAY is set to true.
%
%   For example, issuing the SQL query, against the Microsoft
%   Access database Northwind. 
%
%   'select * from employees'
%
%   returns all columns from the database table employees.
%
%   Invoking the columnnames function as follows:
%
%   fieldString = columnnames(cursor) 
%
%   returns a string that contains all the column names for
%   the columns selected.
% 
%   fieldString = 'EmployeeID','LastName','FirstName','Title',
%                 'TitleOfCourtesy','BirthDate','HireDate','Address',
%                 'City','Region','PostalCode','Country','HomePhone',
%                 'Extension','Photo','Notes','ReportsTo'
%
%   See also FETCH.

%   Copyright 1984-2008 The MathWorks, Inc.
%   	%
% 

%Method not supported for cursor array
if(length(cursor) > 1)
    error(message('database:cursor:unsupportedFeature'));
end

fieldString = [];

if ~isa(cursor.Cursor, 'com.mathworks.toolbox.database.sqlExec')
   
   % cursor Problem return empty string.
   
   return;
   
end

if isa(cursor.Fetch,'com.mathworks.toolbox.database.fetchTheData')
  
  md = getTheMetaData(cursor.Fetch);
  status = validResultSet(cursor.Fetch,md);
  if ~status
    error(message('database:cursor:invalidResultSet'))
  end
  resultSetMetaData = getValidResultSet(cursor.Fetch,md);      
       
else
   
   % cursor Problem return empty string.

   return;
   
end

fieldString = columNames(cursor.Fetch,resultSetMetaData);

if exist('bCellArray','var') && bCellArray
  i = (fieldString == '''');
  fieldString(i) = [];
  tmpStr = textscan(fieldString,'%s','delimiter',',');
  fieldString = tmpStr{:};
end
