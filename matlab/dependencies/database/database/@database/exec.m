function curs = exec(connect,sqlQuery,qTimeOut)
%EXEC Execute SQL statement and open Cursor
%   CURSOR = EXEC(CONNECT,SQLQUERY,QTIMEOUT) returns a cursor object
%   CONNECT is a database object returned by DATABASE. sqlQuery
%   is a valid SQL statement. Use FETCH to retrieve data associated
%   with CURSOR.
%
%   Example:
%
%   cursor = exec(connect,'select * from emp')
%
%   where:
%
%   connect is a valid database object.
%
%   'select * from emp' is a valid SQL statement that selects all
%   columns from the emp table.
%
%   See also FETCH.
 
%   Copyright 1984-2008 The MathWorks, Inc.
%   	%

% Check for valid connection handle.

if isconnection(connect)
   
  if exist('qTimeOut','var')     %Set query timeout of statement if given
    
    curs=cursor(connect,sqlQuery,qTimeOut);
    
  else
    
    curs=cursor(connect,sqlQuery);

  end
  
else

    m = message('database:database:invalidConnection');
  curs.Message = m.getString;
   
end

%Handle error based on ErrorHandling preference setting
switch (setdbprefs('ErrorHandling'))
  
  case 'report' 
        
    %Throw error
    if ~isempty(curs.Message)
      error(message('database:database:cursorError', curs.Message));
    end
        
  case {'store','empty'}
        
    %Message field is populated, do nothing else
      
end
