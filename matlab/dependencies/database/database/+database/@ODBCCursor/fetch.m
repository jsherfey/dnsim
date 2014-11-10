function varargout = fetch( cursor, varargin )
%FETCH Import data into MATLAB.
%   FETCH(CURSOR) gets the results of the query run by EXEC into the 'Data'
%   property of the CURSOR object. CURSOR is an object of type ODBCCursor
%   which is created by running EXEC. Data returned can be a matrix, cell,
%   struct, dataset or table depending on the value of the setting
%   'DataReturnFormat'
%
%   FETCH(CURSOR, ROWLIMIT) retrieves the first ROWLIMIT number of rows of
%   the resultset created after running the query using EXEC.
%
%   This function incrementally fetches the number of rows specified in the
%   'FetchBatchSize' setting until all the rows returned by the query are
%   fetched or until ROWLIMIT number of rows are fetched if ROWLIMIT is
%   specified. The value of this setting will most likely impact the
%   performance of FETCH. A good place to start would be approximately a
%   tenth of the total number of rows expected.
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

%   Copyright 1984-2013 The MathWorks, Inc.

%Check for output variable. Need to support the old syntax of curs =
%fetch(curs)

nargoutchk(0, 1);
narginchk(1, 2);

if nargout == 1
    varargout{1} = cursor;
end

%Check if a valid query was run
if(~isempty(cursor.Message) || isempty(cursor.Statement))
    m = message('database:cursor:invalidInputCursor',cursor.Message);
    
    %Throw if errorhandling is set to report
    if strcmpi(setdbprefs('ErrorHandling'), 'report')
        error(m);
    end
    
    cursor.Message = m.getString;
    
    return;
end

%Get Settings
p = setdbprefs({'NullStringRead';'NullNumberRead';'DataReturnFormat'; 'FetchInBatches'; 'FetchBatchSize'});

%Check if null number setting is incorrect
if ~strcmpi(p.DataReturnFormat, 'cellarray') && isempty(str2num(p.NullNumberRead)) %#ok
    m = message('database:cursor:invalidNullNumber');
    
    %Throw if errorhandling is set to report
    if strcmpi(setdbprefs('ErrorHandling'), 'report')
        error(m);
    end
    
    cursor.Message = m.getString;
    
    return;
end

%Assign output to input
%Input validation
p = inputParser;

p.addOptional('rowLimit', 0, @rowLimCheck);

try
    %Catch Input Validation errors
    p.parse(varargin{:});
    
    %Get Preferences
    dataReturnFormat = setdbprefs('DataReturnFormat');
    
    %Fetch data
    cursor.Data = cursor.Statement.fetchData(p.Results.rowLimit);
    
    %convert to dataset or table if required
    if(~(iscell(cursor.Data) && strcmpi('No Data', cursor.Data{1, 1})))
        switch lower(dataReturnFormat)
            case 'dataset'
                cursor.Data = dataset(cursor.Data);
            case 'table'
                cursor.Data = struct2table(cursor.Data);
        end
    end
    
catch e
    
    %Throw if errorhandling is set to report
    if strcmpi(setdbprefs('ErrorHandling'), 'report')
        e.rethrow();
    end
    
    cursor.Message = e.message;
    cursor.Data = 0;
    
    return;
    
end
end

function OK = rowLimCheck(rowLimit)

if(~isnumeric(rowLimit) || ~isscalar(rowLimit) || mod(rowLimit, 1) ~= 0 )
    error(message('database:runsqlscript:inputParameterError', 'rowLimit'))
else
    OK = true;
end

end


