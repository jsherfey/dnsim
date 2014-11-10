function maxRows = rowlimit(cursor,nrows)
% ROWLIMIT Maximum number of rows retrieved by a fetch.
%   MAXROWS = ROWLIMIT(CURSOR,NROWS) returns the maximum number of 
%   rows retrieved by a fetch. CURSOR is a cursor object. When 
%   NROWS, an optional argument, is defined then this is the number 
%   of rows that are returned by a fetch. If NROWS is not defined 
%   then the function returns the current value.
%
%   Example:
%
%   This function can be used to retrieve the current maximum number
%   of rows returned by a database fetch. To return this value type
%
%   maxrows = rowlimit(cursor)
%
%   and maxrows contains the current value.
%
%   To set a new maximum value the function is invoked as follows:
%
%   maxrows = rowlimit(cursor,100)
%
%   where 100 is the new maximum value for the number of rows
%   retrieved by a fetch.
%
%   See also FETCH.

%   Copyright 1984-2009 The MathWorks, Inc.
%   	%

%Method not supported for cursor array
if(length(cursor) > 1)
    error(message('database:cursor:unsupportedFeature'));
end

if (nargin == 1)
	
  % Check to see if the arguments are in the correct order ..
  % cursor followed by the number of rows.

  if(isa(cursor,'cursor') == 1),
    
    % function is retrieving the maximum number of rows
    % for a database fetch operation.
    
    maxRows = maxRowsInFetch(cursor.Cursor,cursor.Statement);
    
  else

    error(message('database:cursor:unchangedRowLimit'))

  end
  
else
  
  % Function is redefining the maximum number of rows
  % retrieved by a database fetch operation.
  
  % Check to see if the arguments are in the correct order ..
  % cursor followed by the number of rows.
  
  if((isa(cursor,'cursor') == 1) & ...
      (isa(nrows,'double') == 1)),
    
    maxRows = maxRowsInFetch(cursor.Cursor,cursor.Statement,nrows);
    
    if (maxRows == 0),
      
      error(message('database:cursor:unchangedRowLimit'))
      
    end

  else

    error(message('database:cursor:unchangedRowLimit'))

  end

end
