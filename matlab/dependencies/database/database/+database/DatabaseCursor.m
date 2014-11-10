classdef (Abstract) DatabaseCursor < handle
%An abstract class to declare the common properties and methods of an ODBC
%cursor object and a JDBC cursor object. This class cannot be
%instantiated and is used only for inheritance
    
    properties (SetAccess = protected)
        %Common properties
        Data = 0;
        RowLimit = 0;
    end
    
    properties (SetAccess = {?database.DatabaseCursor, ?database.DatabaseConnection})
        SQLQuery       
        Message        
    end
    
    properties (SetAccess = protected)
        Type
    end
    
    properties (SetAccess = {?database.DatabaseCursor, ?database.DatabaseConnection})
       Statement
    end
    
    methods
        varargout = fetch(cursor, varargin);
        close(cursor);
    end
    
end

