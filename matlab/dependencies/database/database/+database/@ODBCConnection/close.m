function close(connect)
%CLOSE Close database connection.
%   CLOSE(CONNECT) closes the database connection.
%   CONNECT is a database connection object of type ODBCConnection


%Check if handle is valid
if ~isempty(connect.Handle) && connect.Handle ~= 0 
    %call close method on the handle
    connect.Handle.closeConnection();
end

