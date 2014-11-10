function fastinsert(connect,tableName,fieldNames,data)
%FASTINSERT Export MATLAB cell array data into database table.
%   FASTINSERT(CONNECT,TABLENAME,FIELDNAMES,DATA). 
%   CONNECT is an ODBCConnection object, FIELDNAMES
%   is a cell array of database column names, TABLENAME is the 
%   database table and DATA is a cell array, numeric matrix, 
%   structure, dataset, or table.
%
%   If DATA is a structure, dataset, or table, it needs to be formatted in
%   a certain way. Each field in the structure or each variable in the
%   dataset or table must be a cell array or double vector of size m*1
%   where m is the number of rows to be inserted.
%
%   Example:
%
%   The following FASTINSERT command inserts the contents of
%   the cell array in to the database table yearlySales
%   for the columns defined in the cell array colNames.
%
% 
%   fastinsert(conn,'yearlySales',colNames,monthlyTotals);
%
%   where 
%
%   The cell array colNames contains the value:
%
%   colNames = {'salesTotal'};
%
%   monthlyTotals is a cell array containing the data to be
%   inserted into the database table yearlySales
%   
%   fastinsert(conn,'yearlySales',colNames,monthlyTotals);
%
%
%   See also INSERT.

%   Copyright 1984-2013 The MathWorks, Inc.

%Divert call to INSERT
insert( connect,tableName,fieldNames,data );