%An abstract class to declare the common properties and methods of an ODBC
%connection object and a JDBC connection object. This class cannot be
%instantiated and is used only for inheritance
classdef (Abstract) DatabaseConnection < handle
    
    %These properties cannot be set publicly from outside
    properties (SetAccess = protected)
        Instance
        UserName
        Message
        Handle
        TimeOut
        AutoCommit
        Type
    end
    
    
    methods (Abstract)
        %Connection object methods
        exec(connect, sqlquery, varargin);
        insert(connect,tableName,fieldNames,data);
        close(connect);
        
    end
    
end