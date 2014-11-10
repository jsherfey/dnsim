function results = runsqlscript (connect, sqlfilename, varargin)
%RUNSQLSCRIPT Run SQL script on a database and return results
%   RESULTS = RUNSQLSCRIPT(CONNECT, SQLFILENAME) executes the SQL commands 
%   in file SQLFILENAME on the database connected to by CONNECT and stores 
%   the results in RESULTS, an array of type CURSOR.
%
%   The number of elements in RESULTS is equal to the number of batches in
%   the file SQLFILENAME. A 'batch' is identified as one or more SQL
%   statements terminated by either a semi-colon or the keyword 'GO'.
%
%   RESULTS(M) contains the results of execution of the Mth SQL batch in
%   the SQL script. If the batch returned a resultset it will be stored in
%   RESULTS(M).Data. See example below.
%
%   RESULTS = RUNSQLSCRIPT(CONNECT, SQLFILENAME, 'PARAM', VALUE) accepts
%   one or more comma-separated parameter name/value pairs. Here is a list 
%   of Parameter Options:
%
%   Parameter Options:
%
%        Parameter      Value                               Default
%        ---------      -----                               -------
%        RowInc         Number of rows to be retrieved      0
%                       at a time. Use RowInc when          (implies all
%                       importing large amounts of data.    rows)
%                       Retrieving data in increments, as
%                       specified by RowInc, helps reduce
%                       overall retrieval time.
%
%        QTimeOut       Query Time Out value                0
%                                                           (implies
%                                                           unlimited time)
%
%
%   EXAMPLES:
%
%   sqlfilename = 'C:\work\sql_scripts\get_revenue.sql';
%   results = runsqlscript(conn, sqlfilename);
%
%   Runs the script get_revenue.sql on the database and returns results in
%   cursor array results.
%
%   results = runsqlscript(conn, sqlfilename, 'RowInc', 5);
%   Runs the script get_revenue.sql on the database and returns at most 5 
%   rows at a time for each resultset produced by the script
%
%   Copyright 1984-2011 The MathWorks, Inc.
%   	%



%
% Test for valid connection handle .. non empty value.
%

if (~isconnection(connect))
    error(message('database:runsqlscript:invalidConnection'));
end

% Test for valid file

fid = fopen(sqlfilename);

if(fid < 0)
    error(message('database:runsqlscript:invalidFileID', sqlfilename));
end

%Clean up file handle after function exits
c = onCleanup(@()fclose(fid));

%Initialize the output data

results = cursor();
error_messages = '';


try
    
    % Parse Input Arguments
    
    parseObj = inputParser;
    parseObj.addParamValue('RowInc',0,@rowincCheck);
    parseObj.addParamValue('QTimeOut',0,@qtimeoutCheck);
    
    parseObj.parse(varargin{:});
    
    row_inc = parseObj.Results.RowInc;
    q_timeout = parseObj.Results.QTimeOut;
    
    
    %Initialize instance of Java Class Runner
    
    if(q_timeout > 0 )
        Runner = com.mathworks.toolbox.database.sqlScriptRunner(connect.Handle, sqlfilename, q_timeout);
    else
        Runner = com.mathworks.toolbox.database.sqlScriptRunner(connect.Handle, sqlfilename);
    end
    
    ret_values = executeScript(Runner);
    success_status = ret_values.elementAt(0);
    
    
    if (~success_status)
        error(message('database:runsqlscript:executionError', ret_values.elementAt(1)));
    end
    
    
    % Get results of the script
    
    out_data = getSqlOut(Runner);
    
    %Need to create results array of cursor objects
    
    num_results = out_data.size();
    
    
    % Preallocate results
    
    results(num_results) = results;
    
    
    for i = 0:num_results-1
        
        fet = out_data.elementAt(i);
        
        if(isempty(fet))
            m = message('database:runsqlscript:noData');
            results(i+1).Message = m.getString();
        else
            
            %initialize cursor object
            results(i+1) = cursor(connect, fet);
            
            
            if (~isempty(results(i+1).ResultSet))
                % The query returned a resultset which needs to be fetched
                
                results(i+1) = fetch(results(i+1), row_inc);
            end
        end
    end
    
    % Collect all error messages to print to display if errorhandling =
    % report
    
    if(strcmpi(setdbprefs('ErrorHandling'), 'report'))
        m = message('database:runsqlscript:staticText');
        for i = 0:num_results-1
            if(~isempty(results(i+1).Message))
                error_messages = [error_messages char(10) m.getString() ' ' num2str(i+1) ': ' results(i+1).Message]; %#ok
            end
        end
    end
    
    
    
catch e
    
    %If script errors out, close the cursors and the file identifier
    
    close(results);
       
    if strcmp(e.identifier, 'database:runsqlscript:executionError')
        throw(e);
    else
        error(message('database:runsqlscript:matlabError', e.message));
    end
    
end


%ERRORHANDLING Error processing based on preference setting.

switch lower((setdbprefs('ErrorHandling')))
    
    case 'report'
        
        %close all cursor objects when throwing error
        close(results);
        
        %Throw error
        if ~isempty(error_messages)
            error(message('database:runsqlscript:fetchError', error_messages));
        end
        
    case {'store','empty'}
        
        %Message field is populated, do nothing else
        
end
end


% function to check row count param

function OK = rowincCheck(RowInc)

if(~isnumeric(RowInc) || ~isscalar(RowInc) || mod(RowInc, 1) ~= 0 )
    error(message('database:runsqlscript:inputParameterError', 'RowInc'))
else
    OK = true;
end

end

function OK = qtimeoutCheck(QTimeOut)

if(~isnumeric(QTimeOut) || ~isscalar(QTimeOut) || mod(QTimeOut, 1) ~= 0 )
    error(message('database:runsqlscript:inputParameterError', 'QTimeOut'))
else
    OK = true;
end

end

