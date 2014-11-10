classdef ODBCCursor < database.DatabaseCursor
%ODBCCursor class represents the cursor object for an open statement or
%resultset created by the ODBCConnection object. This class should only be
%instantiated using EXEC or FETCH on the ODBCConnection object
        
methods
    
    %Constructor
    function cursorObj = ODBCCursor()
        cursorObj = cursorObj@database.DatabaseCursor();
        cursorObj.RowLimit = 0;
        cursorObj.Data = 0;
        cursorObj.Type = 'ODBCCursor Object';
        
    end
    
end
end

