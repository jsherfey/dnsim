function close(cursor)
%CLOSE Close cursor.
%   CLOSE(CURSOR) closes the database cursor.
%   CURSOR is a cursor structure with all elements defined.
%
%   See also FETCH.

%   Copyright 1984-2010 The MathWorks, Inc.
%   	%

% function closes the cursor for the SQL statement

% if input passed is an array of cursors
if(length(cursor) > 1)
    for i = 1:length(cursor)
        close(cursor(i))
    end
    
    return;
end

if ~isa(cursor.ResultSet,'double')
  try
    close(cursor.ResultSet);
  catch exception %#ok
    %Trap exception in case ResultSet is already closed
  end
end

% clean up the statement object
if isa(cursor.Cursor,'com.mathworks.toolbox.database.sqlExec') && ...
  ~isa(cursor.Statement,'double')
  closeSqlStatement(cursor.Cursor,cursor.Statement);
end
