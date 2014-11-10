function dbinsertdemo()
%DBINSERTDEMO Inserts rows into a database table.

%   Version 1.0  21-Oct-1997
%   Author(s): E.F. McGoldrick, 12/5/1997
%   Copyright 1984-2012 The MathWorks, Inc.

% Connect to a database.

conn=database('dbtoolboxdemo','','')

% Set data return format to numeric

setdbprefs('DataReturnFormat','numeric')

% Open cursor and execute a SQL statement.

curs=exec(conn,'select March from salesVolume')

% Import data.

curs=fetch(curs)

% View the data you imported.

AA=curs.Data

% Calculate the sum of all March sales.

sumA = sum(AA(:))

% Assign a month.

month='March'

% Create a cell array for the data to be exported.

exdata=cell(1,2)

% Put the month in the first cell and the sum of sales in the second cell.

exdata(1,1)={month}
exdata(1,2)={sumA}

% Define a string array of column names in table where data will be exported.

colnames={'Month','salesTotal'}

% Determine autocommit status.

get(conn, 'autocommit')

% Export data into yearlySales table.

fastinsert(conn, 'yearlySales', colnames, exdata)

% Close the cursor and the connection.

close(curs)
close(conn)
