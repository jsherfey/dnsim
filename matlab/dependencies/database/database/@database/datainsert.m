function datainsert(connect,tableName,fieldNames,data)
%DATAINSERT Export MATLAB data into database table.
%   DATAINSERT(CONNECT,TABLENAME,FIELDNAMES,DATA) inserts data from the 
%   MATLAB workspace into a database table.  CONNECT is a database 
%   connection handle structure, TABLENAME is the database table, 
%   FIELDNAMES is a string array of database column names,  and DATA is a 
%   MATLAB cell array or numeric matrix. 
%
%   If DATA is a cell array containing MATLAB dates, times or timestamps, 
%   the dates must be date strings of the form YYYY-MM-DD, times must be
%   time strings of the form hh:mm:ss, and timestamps must be strings of
%   the form YYYY-MM-DD hh:mm:ss.s.  NULL entries must be empty strings
%   and any NaN's in the cell array must be converted to empty strings
%   before calling DATAINSERT.
%
%   MATLAB date numbers and NaNs are supported for insert when DATA is a
%   numeric array.    Date numbers inserted into database date and time
%   columns will be converted to java.sql.Date.
%
%   Examples:
%
%   DATAINSERT(CONNECT,'INSERTTABLE',{'COL1','COL2','COL3'},...
%              {33.5 8.77 '2010-07-04'})
%
%   DATAINSERT((CONNECT,'INSERTTABLE',{'COL1','COL2','COL3'},...
%              [33.5 8.77 734323]) 
%
%   See also INSERT, FASTINSERT, UPDATE, MSSQLSERVERBULKINSERT, MYSQLBULKINSERT, ORACLEBULKINSERT.	

%   Copyright 1984-2011 The MathWorks, Inc.
%   	%

%imports
import com.mathworks.toolbox.database.*;

if nargin < 4
  error(message('database:datainsert:notEnoughInputs'));
end

% Check for valid connection

if ~isconnection(connect)
   
    error(message('database:datainsert:invalidConnection'))
   
end

% Create start of the SQL insert statement
% First get number of columns in the cell array 

%Get dimensions of data
switch class(data)
    
  case {'cell','double','int32'}
    [numberOfRows,numberOfCols] = size(data);	%data dimensions
    
  otherwise
    error(message('database:datainsert:inputDataError'))
   
end

% Case 1 all fields are being written to in the target database table.
insertField = '';
tmpq = '';

% Create the field name string for the INSERT statement .. this defines the
% fields in the database table that will be receive data.
% Also build variable ?'s string for later set* commands

for i=1:numberOfCols,
  if ( i == numberOfCols),
    insertField = [ insertField fieldNames{i}];  %#ok
    tmpq = [tmpq '?)'];                          %#ok
  else
    insertField = [ insertField fieldNames{i} ',' ]; %#ok
    tmpq = [tmpq '?,'];                              %#ok
  end	
end

% Create the head of the SQL statement
startOfString = [ 'INSERT INTO '  tableName ' (' insertField ') ' 'VALUES ( ' ];

%Create prepared statement object and define cleanup
tmpConn = connect.Handle;
StatementObject = tmpConn.prepareStatement([startOfString tmpq]);
c = onCleanup(@()close(StatementObject));

%Get Database name
dMetaData = dmd(connect);
sDbName = get(dMetaData,'DatabaseProductName');

%Determine type values by fetching one row of data from table
switch sDbName  %Query only a single row where possible for speed   
  case {'MySQL'}
    e = exec(connect,['select ' insertField ' from ' tableName ' LIMIT 0']);
  case {'Microsoft SQL Server','ACCESS'}
    e = exec(connect,['select TOP 1 ' insertField ' from ' tableName]);
  case {'Oracle'}
    e = exec(connect,['select ' insertField ' from ' tableName ' where ROWNUM <= 1']);  
  otherwise
    e = exec(connect,['select ' insertField ' from ' tableName]);    
end
if ~isempty(e.Message)
  error(message('database:database:insertError', e.Message))
end

%Get fetchinbatches setting and turn off
pBatchs = setdbprefs('FetchInBatches');
setdbprefs('FetchInBatches','no');

%Retrieve a single record to get attributes of data
e = fetch(e,1);

%Reset fetchinbatches
setdbprefs('FetchInBatches',pBatchs);

if ~isempty(e.Message)
  error(message('database:database:insertError', e.Message))
end
a = attr(e);
close(e)

%Create write object and call insert method based input data type
writeObject = writeTheData;
switch class(data)
  case 'cell'
    outIndices = writeObject.cellWrite(StatementObject,numberOfCols,numberOfRows,[a.typeValue],data);
  otherwise
    outIndices = writeObject.doubleWrite(StatementObject,numberOfCols,numberOfRows,[a.typeValue],data);
end

%If non zero return values, show bad data in error message
if any(outIndices(1:2))
  if iscell(data)
    errorData = data{outIndices(1),outIndices(2)};
  else
    errorData = data(outIndices(1),outIndices(2));
  end
  error(message('database:database:insertDataError', outIndices( 1 ), outIndices( 2 ), num2str(errorData), char( writeObject.returnException )))
elseif (outIndices(3) == -1)
  %batch created but executeBatch failed
  error(message('database:database:insertExecuteError', char( writeObject.returnException )))
end