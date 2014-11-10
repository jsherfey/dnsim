function outCursor = fetch(initialCursor,rowLimit)
%FETCH Import data into MATLAB.
%   OUTCURSOR = FETCH(INITIALCURSOR,ROWLIMIT) returns a cursor
%   object with values for all five elements of the structure
%   if successful otherwise returns the input cursor unchanged.
%   INITIALCURSOR  is a cursor object that has values defined for the
%   first three elements from the sqlexec function. ROWLIMIT
%   is an optional argument that specifies the maximum  number of
%   rows returned by a database fetch.
%
%   If 'FetchInBatches' is set to 'yes' in the preferences, this function
%   incerementally fetches the number of rows specified in the
%   'FetchBatchSize' setting until all the rows returned by the query are
%   fetched or until ROWLIMIT number of rows are fetched if ROWLIMIT is
%   specified. Use this method when fetching a large number of rows from
%   the database.
%
%  Example:
%
%  When all data satisfying the SQL query are to be returned at one
%  time FETCH is used as follows:
%
%  cursor = fetch(cursor)
%
%  When the data satisfying the SQL query are to be returned using the
%  ROWLIMIT argument then FETCH is used as follows:
%
%  cursor = fetch(cursor,10)
%
%  This returns 10 rows of data to MATLAB. Repeating the command will
%  return the next 10 rows. This process can be repeated until all
%  data are returned.
%
%  See also EXEC

%   Copyright 1984-2012 The MathWorks, Inc.

if (length(initialCursor) > 1)
    
    %Initialize cursor
    outCursor = cursor();
    
    %Reshape outCursor to length of input cursor
    outCursor(length(initialCursor)) = cursor();
    
    for ind = 1: length(initialCursor)
        
        if (exist ('rowLimit', 'var'))
            outCursor(ind) = fetch(initialCursor(ind), rowLimit);
        else
            outCursor(ind) = fetch(initialCursor(ind));
        end
    end
    return;
end

if isempty(initialCursor.Cursor) || isa(initialCursor.Cursor,'double')
    
    m = message('database:cursor:invalidInputCursor',initialCursor.Message);
    initialCursor.Message = m.getString;
    errorhandling(initialCursor.Message);
    
    % Return input cursor.
    outCursor = initialCursor;
    
    %Modify Data field based on ErrorHandling preference
    switch setdbprefs('ErrorHandling')
        case 'empty'
            outCursor.Data = [];
        case {'store','report'}
            %Do not change Data field
    end
    
    return;
    
end

if isempty(initialCursor.ResultSet) || isa(initialCursor.ResultSet,'double')
    
    m = message('database:cursor:noResultSet');
    initialCursor.Message = m.getString;
    errorhandling(initialCursor.Message);
    
    % Return input cursor.
    
    outCursor = initialCursor;
    return;
    
else
    
    %Get Settings
    p = setdbprefs({'NullStringRead';'NullNumberRead';'DataReturnFormat'; 'FetchInBatches'; 'FetchBatchSize'});
    
    %Check if null number setting is incorrect
    if ~strcmpi(p.DataReturnFormat, 'cellarray') && isempty(str2num(p.NullNumberRead))
        m = message('database:cursor:invalidNullNumber');
        initialCursor.Message = m.getString;
        errorhandling(initialCursor.Message);
        
        % Return input cursor.
        
        outCursor = initialCursor;
        return;
    end
    
    %Initialize ignore batching flag to false
    ignoreBatching = false;
    
    switch(lower(p.FetchInBatches))
        case 'no' %Do not fetch in batches, fetch everything at once
            
            if (nargin == 1),
                
                rowLimit = get(initialCursor,'Rowlimit');
                if rowLimit > 0
                    fet = com.mathworks.toolbox.database.fetchTheData(initialCursor.DatabaseObject.Handle,...
                        initialCursor.ResultSet, ...
                        initialCursor.SQLQuery,rowLimit);
                else
                    fet = com.mathworks.toolbox.database.fetchTheData(initialCursor.DatabaseObject.Handle,...
                        initialCursor.ResultSet, ...
                        initialCursor.SQLQuery);
                end
                
            elseif (nargin == 2),
                
                fet = com.mathworks.toolbox.database.fetchTheData(initialCursor.DatabaseObject.Handle,...
                    initialCursor.ResultSet, ...
                    initialCursor.SQLQuery,rowLimit);
            end
            
        case 'yes' %Fetch in batches
            
            %check if the query is a valid string
            query = initialCursor.SQLQuery;
            
            if(isempty(query) || ~ischar(query))
                m = message('database:cursor:noQueryString');
                initialCursor.Message = m.getString;
                errorhandling(initialCursor.Message);
                
                % Return input cursor.
                
                outCursor = initialCursor;
                return;
                
            end
            
            
            
            %Need to find the total number of rows using COUNT query when 
            %rowLimit is not specified or is specified as zero. To avoid
            %recursion, do not run if the query itself is a count query
            if(nargin == 1 || (nargin == 2 && rowLimit == 0))
                
                initRowLimit = get(initialCursor,'Rowlimit');
                
                if(initRowLimit == 0)
                    
                    %Check if query is a SELECT query. If not, then cannot run
                    %in batches
                    if(isempty(regexpi(query, '^SELECT')) || ~isempty(regexpi(query, '^SELECT COUNT')) || any(strfind(upper(query),'GROUP BY')))
                        warning(message('database:cursor:fetchInBatchesWarning', message('database:cursor:countQueryError').getString()));
                        fet = com.mathworks.toolbox.database.fetchTheData(initialCursor.DatabaseObject.Handle,...
                            initialCursor.ResultSet, ...
                            initialCursor.SQLQuery);
                        ignoreBatching = true;
                        rowLimit = 0;
                        
                    else
                        %Form the count query from the given query
                        countQuery = ['SELECT COUNT(1)' query(regexpi(query, '\s+FROM\s+'):end)];
                        
                        %Strip off ORDER BY clause
                        if(any(strfind(upper(countQuery), 'ORDER BY')))
                            countQuery = countQuery(1:regexpi(countQuery, 'ORDER BY')-1);
                        end
                        
                        try
                            %Execute COUNT query
                            connHandle = initialCursor.DatabaseObject.Handle;
                            countStatement = javaMethod('createStatement', connHandle);
                            countRS = javaMethod('executeQuery', countStatement, countQuery);
                            
                            while(countRS.next)
                                rowLimit = countRS.getInt(1);
                            end
                            
                            close(countRS);
                            close(countStatement);
                            
                            %If the count is zero
                            if(rowLimit == 0)
                                fet = com.mathworks.toolbox.database.fetchTheData(initialCursor.DatabaseObject.Handle,...
                                    initialCursor.ResultSet, ...
                                    initialCursor.SQLQuery);
                                ignoreBatching = true;
                            end
                            
                        catch e %Throw a warning but continue processing
                            warning(message('database:cursor:fetchInBatchesWarning', message('database:cursor:countQueryJavaError').getString()));
                            fet = com.mathworks.toolbox.database.fetchTheData(initialCursor.DatabaseObject.Handle,...
                                initialCursor.ResultSet, ...
                                initialCursor.SQLQuery);
                            ignoreBatching = true;
                            rowLimit = 0;
                            
                            %Close statement
                            close(countStatement);
                            
                        end
                        
                    end
                    
                else
                    rowLimit = initRowLimit;
                end
                
            end
            
            %If rowLimit is smaller than the batch size, ignore batching
            if(~ignoreBatching)
                if(rowLimit < str2double(p.FetchBatchSize))
                    warning(message('database:cursor:fetchInBatchesWarning', message('database:cursor:batchSizeError').getString()));
                    fet = com.mathworks.toolbox.database.fetchTheData(initialCursor.DatabaseObject.Handle,...
                        initialCursor.ResultSet, ...
                        initialCursor.SQLQuery, rowLimit);
                    ignoreBatching = true;
                else
                    fet = com.mathworks.toolbox.database.fetchTheData(initialCursor.DatabaseObject.Handle,...
                        initialCursor.ResultSet, ...
                        initialCursor.SQLQuery,str2double(p.FetchBatchSize));
                end
            end
            
            
    end
    
    if ~isempty(fet),
        
        % Copy the input cursor element values into the output cursor structure.
        
        outCursor = initialCursor;
        
        % Set the fetch element of the cursor structure.
        
        outCursor.Fetch = fet;
        
        % Get Metadata so that all the data can be retrieved and parsed
        
        md = getTheMetaData(fet);
        status = validResultSet(fet,md);
        
        % Return the data as a long string vector
        
        if (status ~= 0)
            
            %Get metadata information for return formats structure and dataset
            if (any(strcmpi(p.DataReturnFormat, {'structure','dataset','table'})))
                rs = rsmd(outCursor);
                
                %Get data types and field names
                x = get(rs,{'ColumnName';'ColumnType'});
            end
            
            
            % Valid cursor .. valid MetaData object returned to MATLAB.
            resultSetMetaData = getValidResultSet(fet,md);
            batchCount = 0;
            
            %Need to keep a count of total number of rows fetched so as to
            %discard the empty rows in the output
            totalNumberOfRows = 0;
            
            while(1)
                
                %For every subsequent batch, need to check if the number of
                %rows left to be fetched is less than the batchsize
                if (batchCount > 0 && (str2double(p.FetchBatchSize) > (rowLimit - str2double(p.FetchBatchSize) * batchCount)))
                    javaMethod('updateRowLimit', fet,  rowLimit - (str2double(p.FetchBatchSize) * batchCount));
                end
                
                dataFetched = dataFetch(fet,resultSetMetaData,p.NullStringRead,p.NullNumberRead); %tmpNullNumberRead);
                
                
                % First .. check to see if error message has been returned by the fetch.
                % If there is a problem print the message to MATLAB session window otherwise
                % process the data.
                
                if isa(dataFetched,'java.util.Vector')
                    
                    %Find number of rows and columns in returned data
                    
                    numberOfRows = double(lastBatchRowsFetched(outCursor.Fetch));
                    
                    % Check for 'No Data' message.
                    
                    if  (numberOfRows == 0),
                        
                        if(batchCount == 0)
                            outCursor.Data = {'No Data'};
                        end
                        
                        break;
                        
                    else
                        
                        %Determine number of columns in resultset
                        numberOfColumns = double(dataFetched.size)/numberOfRows;
                        
                        %Non integer number of columns indicates problem
                        %with data
                        if (floor(numberOfColumns) ~= numberOfColumns)
                          warning(message('database:cursor:resultsetDimError'))
                        end
                        
                        %Calculate start and end of increment based on
                        %batchsize and numberOfRows
                        if(~ignoreBatching && strcmpi(p.FetchInBatches, 'yes'))
                            incSize = min(str2double(p.FetchBatchSize), numberOfRows);
                            startRow = str2double(p.FetchBatchSize)*batchCount + 1;
                        else
                            incSize = numberOfRows;
                            startRow = 1;
                        end
                        
                        endRow = startRow + incSize - 1;
                        
                        switch lower(p.DataReturnFormat)
                            
                            case 'cellarray'
                                
                                %Preallocate variable for speed only for
                                %the first batch
                                if(batchCount == 0)
                                    outCursor.Data = cell(rowLimit, floor(numberOfColumns));
                                end
                                
                                %Convert java.util.vector to cell array
                                outCursor.Data(startRow:endRow, :) = system_dependent(44,dataFetched,numberOfRows)';
                                
                                
                            case 'numeric'
                                
                                
                                %Preallocate variable for speed
                                if(batchCount == 0)
                                    outCursor.Data = zeros(rowLimit, numberOfColumns);
                                end
                                
                                %java method VectorToDouble converts java.util.vector to matrix of doubles
                                outCursor.Data(startRow:endRow, :) = fet.VectorToDouble(dataFetched,numberOfRows,numberOfColumns, str2num(p.NullNumberRead));
                                
                                
                            case {'structure','dataset','table'}
                                
                                nc = length(x.ColumnName);
                                fnames = cell(nc,1);
                                for i = 1:nc
                                    colName = toCharArray(x.ColumnName{i})';
                                    if any(strcmp(colName,fnames))
                                        fnames{i} = [colName '_' num2str(i)];
                                    else
                                        fnames{i} = colName;
                                    end
                                end
                                
                                %Initialize structure
                                for i = 1:length(x.ColumnType)
                                    
                                    colName = genvarname(fnames{i});
                                    
                                    %Initialize Data as structure if necessary
                                    if ~isstruct(outCursor.Data)
                                        outCursor.Data = [];
                                    end
                                    
                                    switch x.ColumnType{i}
                                        
                                        case {-6,-5,2,3,4,5,6,7,8}
                                            
                                            
                                            %Preallocate
                                            if(batchCount == 0)
                                                outCursor.Data.(colName) = zeros(rowLimit, 1);
                                            end
                                            
                                            %Numerics
                                            outCursor.Data.(colName)(startRow:endRow, :)  = fet.VectorToNumber(dataFetched,numberOfRows,numberOfColumns,str2num(p.NullNumberRead), i-1);
                                            
                                            
                                            
                                        otherwise
                                            
                                            if(batchCount == 0)
                                                outCursor.Data.(colName) = cell(rowLimit, 1);
                                            end
                                            
                                            %Strings or other data types, create vector of strings and convert to cell array
                                            outCursor.Data.(colName)(startRow:endRow, :) = system_dependent(44,fet.VectortoStringVector(dataFetched,numberOfRows,numberOfColumns,i-1,java.lang.String(p.NullStringRead)),numberOfRows)';
                                            
                                    end
                                end
                                
                                
                                
                        end
                        
                    end
                    
                    
                    
                else
                    
                    
                    % Problem with data returned.
                    
                    outCursor.Message = dataFetched;
                    errorhandling(outCursor.Message);
                    return;
                    
                end
                
                batchCount = batchCount + 1;
                totalNumberOfRows = totalNumberOfRows + numberOfRows;
                
                %break out of loop if no batching is to be used or if this
                %is the last batch
                if(strcmp(p.FetchInBatches, 'no') || ignoreBatching ||  numberOfRows < str2double(p.FetchBatchSize)...
                        || (str2double(p.FetchBatchSize) * batchCount) == rowLimit)
                    break;
                end
                
                dataFetched.clear;
                dataFetched = [];
                clear dataFetched ;
            end
            
            %Clear the empty rows in the end
            if(rowLimit > totalNumberOfRows && totalNumberOfRows > 0)
                if (isstruct(outCursor.Data))
                    names = fieldnames(outCursor.Data);
                    for i=1:length(names)
                        outCursor.Data.(names{i})(totalNumberOfRows + 1:end, :) = [];
                    end
                    
                else
                    outCursor.Data(totalNumberOfRows + 1:end, :) = [];
                end
            end
            if totalNumberOfRows > 0
              switch lower(p.DataReturnFormat)
                case 'dataset'
                  outCursor.Data = dataset(outCursor.Data);
                case 'table'
                  outCursor.Data = struct2table(outCursor.Data);
              end
               
            end
            
            clear x rs;
            
        else
            
            % Invalid cursor use must return adjusted cursor structure and message.
            
            outCursor.ResultSet = 0;
            outCursor.Cursor = 0;
            outCursor.Data = 0;
            m = message('database:cursor:invalidFetchCursor');
            outCursor.Message = m.getString;
            errorhandling(outCursor.Message);
            return;
            
        end
        
        
    else
        
        m = message('database:cursor:fetchFailure');
        outCursor.Message = m.getString;
        
    end
end

errorhandling(outCursor.Message);


%%Subfunctions

function errorhandling(s)
%ERRORHANDLING Error processing based on preference setting.
%   ERRORHANDLING(S) performs error processing based on the
%   SETDBPREFS property ErrorHandling.  S is the contents
%   of the cursor.Message field.

switch lower((setdbprefs('ErrorHandling')))
    
    case 'report'
        
        %Throw error
        if ~isempty(s)
            error(message('database:cursor:fetchError', s));
        end
        
    case {'store','empty'}
        
        %Message field is populated, do nothing else
        
end
