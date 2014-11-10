function dbupdatedemo()
%DEMOUPDATE	 Updates a row in a database table.

%   Version 1.0  21-Oct-1997
%   Author(s): E.F. McGoldrick, S. Cockrell, 12/5/1997
%   Copyright 1984-2012 The MathWorks, Inc.


% Connect to a database.

conn = database('dbtoolboxdemo', '', '')

% Define a string array of column names in table where data will be exported.

colnames={'Month', 'salesTotal'}

% Assign a month to D.

D='March'

% Assign a value to the variable sumA.

sumA =  14606

% Put the month in the first cell and the sum in the second cell.

C={D,sumA}

% Change the value of D.

D='March2010'

% Put the new value into cell array C.

C(1,1)={D}

% Identify the record to be updated.

whereclause='where Month = ''March'''

% Export the data.

update(conn,'yearlySales', colnames, C, whereclause)

% Close the cursor and the connection.

close(conn)



