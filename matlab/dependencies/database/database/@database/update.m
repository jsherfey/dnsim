function update(connect,tableName,fieldNames,data,whereClause)
%UPDATE Replace data in database table with data from MATLAB cell array.
%   UPDATE(CONNECT,TABLENAME,FIELDNAMES,DATA,WHERECLAUSE).
%   CONNECT is a database connection object, FIELDNAMES
%   is a string array of database column names, TABLENAME is the
%   database table, DATA is a MATLAB cell array and WHERECLAUSE
%   is a SQL where clause used to specify the row(s) to be updated.
%   If WHERECLAUSE is a cell array of SQL where clauses, there should be
%   one record of data for each entry in WHERECLAUSE.
%
%   Examples:
%
%   The following UPDATE command updates the contents of
%   the cell array in to the database table yearlySales
%   for the columns defined in the cell array colNames.
%
%
%   update(conn,'yearlySales',colNames,monthlyTotals,whereClause);
%
%   where
%
%   The cell array colNames contains the value:
%
%   colNames = {'salesTotal'};
%
%   monthlyTotals is a cell array containing the data to be
%   used in updating the appropriate rows of the database table
%   yearlySales.
%
%   whereClause is a string that contains the where condition
%   that must be satisfied for a row in the table to be updated.
%
%   whereClause = 'where month = ''Nov'''
%
%   is an example of a valid whereClause.
%
%   update(conn,'yearlySales',colNames,monthlyTotals,whereClause);
%
%   To specify multiple constraints, use the following syntax:
%
%   update(conn,'Table1',{'FloatColumn','realfloatcolumn'},{4,7.8;5,33.5},{'where One = true';'where One = false'});
%
%   The columns FloatColumn and realfloatcolumn will be updated accordingly
%   depending on the value of the column One in the corresponding record.
%
%  See also FASTINSERT, INSERT.


%   Copyright 1984-2010 The MathWorks, Inc.

% Check for valid connection

if iscell(whereClause)
    numwheres = length(whereClause);
    switch class(data)
        case 'struct'
          numdata = unique(structfun(@numel,data));
          if length(numdata) > 1
            error(message('database:update:writeMismatch'))
          end
        otherwise
          numdata = size(data,1);
    end
    if numwheres == numdata
        for i = 1:numwheres
          switch class(data)
            case 'struct'
              subdata = structfun(@(s)s(i,:),data,'UniformOutput',false);
            otherwise
              subdata = data(i,:);
          end
          update(connect,tableName,fieldNames,subdata,whereClause{i})
        end
    else
        error(message('database:update:writeMismatch'))
    end
    return
end

if ~isconnection(connect)
    
    error(message('database:update:invalidConnection'))
    
end

%Get dimensions of data
switch class(data)
    
  case {'cell','double'}
        [numberOfRows,cols] = size(data);	%data dimensions
        
  case 'struct'
    sflds = fieldnames(data);
    fchk = setxor(sflds,fieldNames);
    if ~isempty(fchk)
      error(message('database:database:writeMismatch'))
    end
    numberOfRows = size(data.(sflds{1}),1);
    cols = length(sflds);
   
  otherwise
    error(message('database:database:invalidWriteDataType'))
        
end

% Create the head of the SQL statement
startOfString = [ 'UPDATE '  tableName ' SET ' ];

% Get NULL string and number preferences
prefs = setdbprefs;
nsw = prefs.NullStringWrite;
nnw = str2double(prefs.NullNumberWrite);

% Add the data for all the columns in the cell array.
for i = 1:numberOfRows,
    
    dataString ='';
    updateFields = '';
    
    for j = 1:cols,
        
        if (j == cols), % Last column in the cell array.
            
            % The final comma in the field string is not required.
            updateFields = [updateFields fieldNames{j}]; %#ok
            dataString= [ dataString fieldNames{j} ' = ? ' whereClause]; %#ok
            
        else
            
            updateFields = [updateFields fieldNames{j} ',' ];  %#ok
            dataString= [ dataString fieldNames{j} ' = ?,'];   %#ok
            
        end
        
    end
    
end % End of numberOfRows loop

%Create prepared statement object
tmpConn = connect.Handle;
StatementObject = tmpConn.prepareStatement([startOfString dataString]);
c = onCleanup(@()close(StatementObject));

%Get Database name
dMetaData = dmd(connect);
sDbName = get(dMetaData,'DatabaseProductName');

%Determine type values by fetching one row of data from table
switch sDbName  %Query only a single row where possible for speed
    
    case {'MySQL'}
        e = exec(connect,['select ' updateFields ' from ' tableName ' LIMIT 0']);
    case {'Microsoft SQL Server','ACCESS'}
        e = exec(connect,['select TOP 1 ' updateFields ' from ' tableName]);
    case {'Oracle'}
        e = exec(connect,['select ' updateFields ' from ' tableName ' where ROWNUM <= 1']);
    otherwise
        e = exec(connect,['select ' updateFields ' from ' tableName]);
end
if ~isempty(e.Message)
    error(message('database:update:updateError',e.Message))
end
e = fetch(e,1);
if ~isempty(e.Message)
    error(message('database:update:updateError',e.Message))
end
a = attr(e);
close(e)


for i = 1:numberOfRows,
    
    for j = 1:cols
        
        switch class(data)
        
          case {'cell','double'}

            try, tmp = data{i,j}; catch, tmp = data(i,j); end    %#ok Index as cell array, or matrix, if not cell array
        
          case 'struct'
          
            try
              tmp = data.(sflds{j}){i};
            catch %#ok
              tmp = data.(sflds{j})(i,:);
            end
        
        end  
        
        %Check for null values and setNull if applicable
        if (isa(tmp,'double')) & ...
                ((isnan(tmp) | (isempty(tmp) & isempty(nnw))) | (~isempty(nnw) & ~isempty(tmp) & tmp == nnw) | (isnan(tmp) & isnan(nnw)))  %#ok
            
            StatementObject.setNull(j,a(j).typeValue)
            
        elseif (isnumeric(tmp) && isempty(tmp))
            
            % Insert numeric null (for binary objects), using -4 fails
            StatementObject.setNull(j,7)
            
        elseif (isa(tmp,'char')) && ...
                ((isempty(tmp) && isempty(nsw)) || strcmp(tmp,nsw))
            
            StatementObject.setNull(j,a(j).typeValue)
            
        else
            
            % The input data should not contain vectors except when
            % the table field accepts a byte array, for example, an image
            
            bytearray_typeValues = [-4, -3, 2004];
            
            if (isempty(find (bytearray_typeValues==a(j).typeValue, 1)) && (size(tmp,1) > 1 || (~ischar(tmp) && size(tmp,2) > 1)))
                error (message('database:update:dataStructureError')) ;
            end
            
            
            switch a(j).typeValue
                
                case -7
                    StatementObject.setBoolean(j,tmp)  %BIT
                case -6
                    StatementObject.setByte(j,tmp)  %TINYINT
                case -5
                    StatementObject.setLong(j,tmp)  %BIGINT
                case {-4, -3, 2004}
                    StatementObject.setBytes(j,tmp)  %LONGVARBINARY, VARBINARY
                case {-16, -15, -10, -9, -8, -1, 1, 12}
                    StatementObject.setString(j,java.lang.String(tmp))  %CHAR, LONGVARCHAR, VARCHAR
                case {2, 3, 7}
                    StatementObject.setDouble(j,tmp)  %NUMERIC, DECIMAL, REAL
                case 4
                    StatementObject.setInt(j,tmp)  %INTEGER
                case 5
                    StatementObject.setShort(j,tmp)  %SMALLINT
                case 6
                    StatementObject.setDouble(j,tmp)  %FLOAT
                case 8
                    StatementObject.setDouble(j,tmp)  %DOUBLE
                case 91
                    dt = datevec(tmp);
                    StatementObject.setDate(j,java.sql.Date(dt(1)-1900,dt(2)-1,dt(3)))  %DATE
                case 92
                    tt = datevec(tmp);
                    StatementObject.setTime(j,java.sql.Time(tt(4),tt(5),tt(6)))  %TIME
                case 93
                    ts = datevec(tmp);
                    %Need whole second value to calculate nanosecond value
                    secs = floor(ts(6));
                    nanosecs = (ts(6) - secs) * 1000000000;
                    StatementObject.setTimestamp(j,java.sql.Timestamp(ts(1)-1900,ts(2)-1,ts(3),ts(4),ts(5),secs,nanosecs))  %TIMESTAMP
                case {-2,1111}
                    error(message('database:update:unsupportedDatatype',fieldNames{j}))
                otherwise
                    StatementObject.setObject(j,tmp);   %OBJECT
                    
            end   %End of switch
        end  %End of datatype and null value check
    end  %End of j loop
    
    % Add parameters to statement object
    StatementObject.addBatch;
    
end  % End of numberOfRows loop

%Execute prepared statement batch
StatementObject.executeBatch;