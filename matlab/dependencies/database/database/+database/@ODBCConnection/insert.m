function insert( connect,tableName,fieldNames,data )
%INSERT Export MATLAB data into database table.
%   INSERT(CONNECT,TABLENAME,FIELDNAMES,DATA).
%   CONNECT is an object of type database.ODBCConnection, FIELDNAMES
%   is a cell array of database column names, TABLENAME is the
%   database table and DATA is a cell array, numeric matrix,
%   structure, dataset, or table.
%
%   If DATA is a structure, dataset, or table, it needs to be formatted in
%   a certain way. Each field in the structure or each variable in the
%   dataset or table  must be a cell array or double vector of size m*1
%   where m is the number of rows to be inserted.
%
%   Example:
%
%   The following INSERT command inserts the contents of
%   the cell array in to the database table yearlySales
%   for the columns defined in the cell array colNames.
%
%
%   insert(conn,'yearlySales',colNames,monthlyTotals);
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
%   insert(conn,'yearlySales',colNames,monthlyTotals);
%

%   Copyright 1984-2013 The MathWorks, Inc.

% Check for valid connection
if(~isempty(connect.Message))
    error(message('database:database:connectionFailure', connect.Message));
end

%Input validation
p = inputParser;

p.addRequired('tablename', @database.DatabaseUtils.tablenameCheck);
p.addRequired('fieldnames', @database.DatabaseUtils.fieldnamesCheck);
p.addRequired('data', @database.DatabaseUtils.insertDataCheck);

%Catch Input Validation errors
p.parse(tableName,fieldNames,data);

%Get size of data
switch class(data)
    
    case {'cell','double'}
        numberOfCols = size(data, 2);	%data dimensions
        
    case 'struct'
        sflds = fieldnames(data);
        fchk = setxor(sflds,fieldNames);
        if ~isempty(fchk)
            error(message('database:fastinsert:fieldMismatch'))
        end
        
        numberOfCols = length(sflds);
        
        data = database.DatabaseUtils.validateStruct(data);
        
    case 'dataset'
        dSummary = summary(data);
        sflds = {dSummary.Variables.Name};
        fchk = setxor(sflds,fieldNames);
        if ~isempty(fchk)
            error(message('database:database:writeMismatch'))
        end
        
        numberOfCols = length(sflds);
        
        
        %convert dataset to struct before pushing to the C API
        data = dataset2struct(data, 'AsScalar', true);
        
        data = database.DatabaseUtils.validateStruct(data);
        
    case 'table'
        sflds = data.Properties.VariableNames;
        fchk = setxor(sflds,fieldNames);
        
        if ~isempty(fchk)
            error(message('database:database:writeMismatch'))
        end
        
        numberOfCols = length(sflds);
        
        %convert table to struct before pushing to the C API
        data = table2struct(data, 'ToScalar',true);
        
        data = database.DatabaseUtils.validateStruct(data);
        
    otherwise
        error(message('database:fastinsert:inputDataError'))
        
end

%Verify that size of field names is the same as no of cols in data
if(length(fieldNames) ~= numberOfCols)
    error(message('database:fastinsert:inputFieldsDataMismatch'))
end

% Create INSERT query to be prepared.
fieldNamesString = '';
parameterString = '';

% Create the field name string for the INSERT statement .. this defines the
% fields in the database table that will be receive data.
% Also build variable ?'s string for later set* commands

for i=1:numberOfCols,
    if ( i == numberOfCols),
        fieldNamesString = [ fieldNamesString fieldNames{i}];  %#ok
        parameterString = [parameterString '?)'];                          %#ok
    else
        fieldNamesString = [ fieldNamesString fieldNames{i} ',' ]; %#ok
        parameterString = [parameterString '?,'];                              %#ok
    end
end

try
    %Get Database Product name
    dbProdName = connect.Handle.getInfoChar('DATABASE_PRODUCT');
    
    %Using the faster ODBC API method for MySQL 
    if(strcmpi(dbProdName, 'MySQL') || strcmpi(dbProdName, 'Access'))
      
        %Create SELECT string
        selectString = ['select ' fieldNamesString ' from ' tableName ' where 1=2'];
        
        %Create new statement for INSERT
        insertStmt = connect.Handle.createStatement;
        insertStmt.insertData(dbProdName, selectString, data);
        
        %close both statements
        insertStmt.closeStatement;
        
    else
        
        % Create the SQL statement
        parameterizedInsertString = [ 'INSERT INTO '  tableName ' (' fieldNamesString ') ' 'VALUES ( ' parameterString ];
        
        %Need to run exec query to get column attributes
        curs = exec(connect,['select ' fieldNamesString ' from ' tableName ' where 1=2']);
        
        if ~isempty(curs.Message)
            error(message('database:database:insertError', curs.Message))
        end
        
        %Get fetchinbatches setting and turn off
        pBatchs = setdbprefs('FetchInBatches');
        setdbprefs('FetchInBatches','no');

        curs = fetch(curs, 1);
        
        %Reset fetchinbatches
        setdbprefs('FetchInBatches',pBatchs);

        if ~isempty(curs.Message)
            error(message('database:database:insertError', curs.Message))
        end
        
        %Create new statement for INSERT
        insertStmt = connect.Handle.createStatement;
        insertStmt.insertData(curs.Statement, parameterizedInsertString, data);
        
        %close both statements
        insertStmt.closeStatement;
        close(curs);        
        
    end
    
catch e
    %close statements and then throw error
    
    if(exist('curs', 'var'))
        close(curs);
    end
    if(exist('insertStmt', 'var'))
        insertStmt.closeStatement;
    end
    throw(e);
end

end

