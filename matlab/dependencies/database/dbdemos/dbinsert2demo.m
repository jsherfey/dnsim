%% DBINSERT2DEMO Inserts rows into a database table.

%   Copyright 1984-2002 The MathWorks, Inc.

%% Open a connection.

drfpref = setdbprefs('DataReturnFormat');
setdbprefs('DataReturnFormat','cellarray');

conn=database('dbtoolboxdemo','','');

%% Null numbers should be read as zeros and data returned should be numeric
setdbprefs({'NullNumberRead';'DataReturnFormat'},{'0';'numeric'})

%% Open a cursor and execute a fetch.

curs=exec(conn,'select * from salesVolume');
curs=fetch(curs);

%% Get size of cell array

[m,n]=size(curs.Data);

%% Calculate monthly totals for the product entries.

for i = 2:n
  monthly(i-1,1) = sum(curs.Data(:,i));
end
colNames{1,1} = 'salesTotal';

%% Convert to cell array

monthlyTotals=num2cell(monthly)

%% insert the data.

fastinsert(conn,'yearlySales',colNames,monthlyTotals);

%% Close the cursor and the connection.

close(curs);
close(conn);

setdbprefs('DataReturnFormat',drfpref);
