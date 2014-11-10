function x = fetch(conn,sqlstring,fetchbatchsize)
%FETCH Import data into MATLAB using connection handle.
%   X = FETCH(CONN,SQLSTRING,FETCHBATCHSIZE) imports database data into 
%   MATLAB given the connection handle, CONN, the SQL string, SQLSTRING.
%   Optionally, a batch size can be specified to retrieve the data in
%   FETCHBATCHSIZE records at a time.
%
%   For example,
%
%   x = fetch(conn,'select * from tablename')
%
%   will return the requested data as a cell array, numeric matrix or
%   structure depending on the setting of the DataReturnFormat preference.
%
%   See also database/exec, cursor/fetch, database/runstoredprocedure,
%   setdbprefs

%   Copyright 1984-2012 The MathWorks, Inc.

%Validate connection handle
if ~isempty(conn.Message)
    error(message('database:fetch:connectionError', conn.Message))
end

if (nargin == 3 && (~isnumeric(fetchbatchsize) ||... 
    ~isscalar(fetchbatchsize) || mod(fetchbatchsize, 1) ~= 0 || ...
    fetchbatchsize < 1 || fetchbatchsize > 1000000))
    error(message('database:fetch:rowIncError'));
end

%Set record increment if not given, default is the value set for
%'FetchBatchSize' preference
if nargin < 3
    fetchbatchsize = str2double(setdbprefs('FetchBatchSize'));
end

%Execute the SQL statement and validate cursor
e = exec(conn,sqlstring);
if ~isempty(e.Message)
    error(message('database:fetch:execError', e.Message))
end

%Set batchsize
oldPrefs = setdbprefs({'FetchBatchSize', 'FetchInBatches'});
setdbprefs('FetchInBatches', 'yes');
setdbprefs('FetchBatchSize', num2str(fetchbatchsize));

%Turn Warning off
w = warning('query', 'database:cursor:fetchInBatchesWarning');
warning('off', 'database:cursor:fetchInBatchesWarning');
 
%Retrieve the data
x = [];

try
    e = fetch(e);
catch exception
    setdbprefs(oldPrefs);
    warning(w);
    error(message('database:fetch:fetchError', exception.message));
end

if ~isempty(e.Message)
    setdbprefs(oldPrefs);
    warning(w);
    error(message('database:fetch:fetchError', e.Message));
end

if ~strcmp(e.Data,'No Data')
    x = e.Data;
end

%Close the cursor
close(e)

%Restore batchsize & warning
setdbprefs(oldPrefs);
warning(w);
