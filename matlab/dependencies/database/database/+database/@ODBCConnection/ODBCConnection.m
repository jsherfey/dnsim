%This class represents a connection object established using the ODBC C API
%Before trying to instantiate an ODBC connection, it is required to install
%the correct ODBC driver and set up an ODBC data source. You may set up an
%ODBC data source from the system ODBC administrator or Database Explorer
%
%CONN = DATABASE.ODBCCONNECTION(INSTANCE, USERNAME, PASSWORD) returns an
%object of type ODBCConnection. INSTANCE is the name of the ODBC data
%source set up, USERNAME and PASSWORD are the required credentials for
%access to the database.

classdef ODBCConnection < database.DatabaseConnection
    
    methods
        function connectObj = ODBCConnection(instance, username, password)
            
            %ODBC not supported on Unix
            if isunix
                m = message('database:database:unixODBC');
                
                %Throw if errorhandling is set to report
                if strcmpi(setdbprefs('ErrorHandling'), 'report')
                    error(m);
                end
                connectObj.Message = m.getString;
                connectObj.Handle = 0;
                
                return;
            end
            
            %Validate inputs
            %Allow for empty [] username and password
            if isempty(username)
                username = '';
            end
            if isempty(password)
                password = '';
            end
            
            if(~ischar(instance) || ~ischar(username) || ~ischar(password))
                m = message('database:database:invalidDataType');
                
                %Throw if errorhandling is set to report
                if strcmpi(setdbprefs('ErrorHandling'), 'report')
                    error(m);
                end
                
                connectObj.Message = m.getString;
                connectObj.Handle = 0;
                
                return;
            end
            
            
            %Assign to object properties
            connectObj.Instance = instance;
            connectObj.UserName = username;
            connectObj.TimeOut = 0;
            connectObj.AutoCommit = 0;
            connectObj.Type = 'ODBCConnection Object';
            
            %Create a connection using the ODBC C API
            connHandle = database.internal.ODBCConnectHandle();
            try
                connHandle.openConnection(instance, username, password);
                connectObj.Handle = connHandle;
                
            catch e
                %connection error
                
                %Throw if errorhandling is set to report
                if strcmpi(setdbprefs('ErrorHandling'), 'report')
                    e.rethrow();
                end
                
                connectObj.Message = e.message;
                connectObj.Handle = 0;
            end
            
        end
    end
end