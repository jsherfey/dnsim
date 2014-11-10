function connection = database(instance,username, password, varargin)
%DATABASE Connect to database.
%   CONNECT = DATABASE(INSTANCE,USERNAME,PASSWORD)
%   returns a database connection object. Connection is established using 
%   an ODBC driver. INSTANCE is the name of the ODBC data source set up,
%   USERNAME and PASSWORD are the required credentials for access to the 
%   database.
%
%   CONNECT = DATABASE(INSTANCE,USERNAME,PASSWORD,DRIVER,DATABASEURL) 
%   returns a database connection object. Connection is established using a 
%   JDBC driver. INSTANCE is the name of the database, USERNAME and 
%   PASSWORD are the required credentials for access to the database.
%   DRIVER is a JDBC driver name and DATABASEURL is the connection URL for 
%   the database. 
%
%   CONNECT = DATABASE(INSTANCE,USERNAME,PASSWORD,'PARAM','VALUE')
%   returns a database connection object. Connection is established using a 
%   JDBC driver. PARAM-VALUE pairs are:
%
%   Parameter      Value                                        Default
%   ---------      -----                                        -------
%   VENDOR         Must be provided. Needs to be one of:        None 
%                  'MySQL','Oracle','Microsoft SQL Server', 
%                  'PostGreSQL'. Use this along with zero or 
%                  more of the following params as required 
%                  to establish a connection. If connecting 
%                  to a database system not listed here,
%                  use the DRIVER and DATABASEURL syntax
%
%   SERVER         Name/Address of the database server          localhost
%
%   PORTNUMBER     number of the port that the server           vendor 
%                  is listening on                              specific 
%
%   AUTHTYPE       one of:'Server','Windows'. Only valid        Server
%                  for SQL Server. Specify 'Windows'
%                  for Windows Authentication.
%
%   DRIVERTYPE     one of: 'thin','oci'. Only valid for         None
%                  Oracle.
%
%   URL            Connection URL.If URL is specified,          None
%                  no other properties may be required
%                  
%
%   
%   Use LOGINTIMEOUT before DATABASE to set the maximum time for a
%   connection attempt.
%
%   Example:
%
%   JDBC-ODBC connection:
%
%   conn=database('oracle','scott','tiger')
%
%   where:
%
%   'oracle' is the ODBC datasource name for an ORACLE database.
%   'scott'  is the user name.
%   'tiger'  is the password.
%
%
%   JDBC connection:
%
%   conn=database('oracle','scott','tiger',
%                'oracle.jdbc.driver.OracleDriver','jdbc:oracle:oci7:')
%
%   where:
%
%   'oracle' is the database name.
%   'scott'  is the user name.
%   'tiger'  is the password.
%   'oracle.jdbc.driver.OracleDriver' is the JDBC driver to be used
%                                     to make the connection.
%   'jdbc:oracle:oci7:' is the URL as defined by the Driver vendor
%                       to establish a connection with the database.
% 
%   Using Param-Value pairs:
%
%   conn=database('oracle','scott','tiger','Vendor', 'Oracle',
%   'DriverType', 'oci', 'Server', 'remotehost', 'PortNumber', 1234)
%
%   where:
%
%   remotehost: Database Server machine name
%   1234: Port Number which the server is listening on
%
%   See also CLOSE.

%
%   Copyright 1984-2010 The MathWorks, Inc.

%Create parent object for generic methods
dbobj = dbtbx;

% This function makes the connection to a Database using the JAVA built-in functionality.

connection.Instance	= [];
connection.UserName = [];
connection.Driver		= [];
connection.URL	    = [];
connection.Constructor = [];
connection.Message = [];
connection.Handle=[];
connection.TimeOut=[];
connection.AutoCommit=[];
connection.Type=[];


numinputs = nargin;

switch numinputs,
    
    case {0, 1, 2, 4}
        
        m = message('database:database:invalidNumInputs');
        connection.Message = m.getString;
        errorhandling(connection.Message);
        connection=class(connection,'database',dbobj);
        return;
        
    case 3
        
        % Using the JDBC/ODBC Bridge as the connection mechanism.
        
        if isunix
            m = message('database:database:unixODBC');
            connection.Message = m.getString;
            errorhandling(connection.Message);
            connection=class(connection,'database',dbobj);
            return;
        end
        
        %inputs must be empty strings if empty
        if isempty(username)
            username = '';
        end
        if isempty(password)
            password = '';
        end
    
        if(~ischar(instance) || ~ischar(username) || ~ischar(password))
            m = message('database:database:invalidDataType');
            connection.Message = m.getString;
            errorhandling(connection.Message);
            connection=class(connection,'database',dbobj);
            return;
        end
               
        conn=com.mathworks.toolbox.database.databaseConnect(instance,username,password);
        
        connection.Instance = instance;
        connection.UserName	= username;
        % The following elements are set as empty in this case.
        connection.Driver   = [];
        connection.URL      = [];
        connection.Constructor = conn;
        
    otherwise,
        
        if(mod(numinputs,2) == 0)
            m = message('database:database:invalidNumInputs');
            connection.Message = m.getString;
            errorhandling(connection.Message);
            connection=class(connection,'database',dbobj);
            return;
        end
        
        params = {'DRIVER', 'URL', 'VENDOR', 'SERVER', 'DRIVERTYPE', 'AUTHTYPE', 'PORTNUMBER'};
        
        if (~ismember(upper(varargin{1}), params))
            
            %Old syntax using Driver & URL
            connection = database(instance, username, password, 'Driver', varargin{1}, 'URL', varargin{2});
            return;
        else
            
             p = inputParser;
             
             %inputs must be empty strings if empty
             if isempty(username)
                 username = '';
             end
             if isempty(password)
                 password = '';
             end
             
             p.addRequired('instance', @ischar);
             p.addRequired('username', @ischar);
             p.addRequired('password', @ischar);
             
             %Param-values when using a JDBC driver
             
             p.addParamValue('Driver', '', @ischar);
             p.addParamValue('URL', '', @ischar);
             p.addParamValue('Vendor', '', @vendorCheck);
             p.addParamValue('Server', '', @ischar);
             p.addParamValue('DriverType', '', @ischar);
             p.addParamValue('PortNumber', '', @(x)validateattributes(x, {'numeric'}, {'nonempty', 'scalar', 'nonnegative'}));
             p.addParamValue('AuthType', 'Server', @(x)strcmpi(x,'Server')|| strcmpi(x,'Windows'));
              
             try %Catch Input Validation errors
                 p.parse(instance, username, password, varargin{:});
             catch e
                 connection.Message = e.message;
                 errorhandling(connection.Message);
                 connection=class(connection,'database',dbobj);
                 return;
                 
             end
             
             
             Driver = p.Results.Driver;
             URL = p.Results.URL;
             
             Vendor = p.Results.Vendor;
             
             %Usage errors            
             if(isempty(Driver) && isempty(Vendor))
              
                 m = message('database:database:requiredInput');
                 connection.Message = m.getString;
                 errorhandling(connection.Message);
                 connection=class(connection,'database',dbobj);
                 return;
            
             elseif (isempty(Vendor) && ~isempty(Driver) && isempty(URL))
             
                 m = message('database:database:missingURL');
                 connection.Message = m.getString;
                 errorhandling(connection.Message);
                 connection=class(connection,'database',dbobj);
                 return;
             
             elseif (~isempty(Driver))
             
                 %Make a connection using driver and URL
                 
                 conn=com.mathworks.toolbox.database.databaseConnect(instance,username,password,Driver,URL);
                 
                 connection.Instance = instance;
                 connection.UserName = username;
                 connection.Driver   = Driver;
                 connection.URL      = URL;
                 connection.Constructor = conn;
                 
             else
                 %Make a connection using individual connection properties
                 
                   %Get Vendor to DataSource class mapping. 
                                     
                   v2smap = mapVendorToSource();
                  
                   DataSourceClass = v2smap(upper(Vendor));
                   
                   
                   %Set Connection Properties
                   
                   %DriverType is only valid for Oracle
                   
                   DriverType = p.Results.DriverType;
                   
                   if(~strcmpi(Vendor, 'Oracle') && ~isempty(DriverType))
                       warning(message('database:database:ignoreParameter', 'DriverType', 'Oracle')) ;
                       DriverType = '';
                   end
                   
                   %AuthType is only valid for Microsoft SQL Server
                   
                   AuthType = p.Results.AuthType;
                   
                   if(~strcmpi(Vendor, 'Microsoft SQL Server') && strcmpi(AuthType, 'Windows'))
                       warning(message('database:database:ignoreParameter', 'AuthType', 'Microsoft SQL Server')) ;
                       AuthType = 'Server';
                   end
                   
                   props = java.util.Properties;
                   
                   props.setProperty('DataSourceClass', DataSourceClass);
                   props.setProperty('Vendor', Vendor);
                   props.setProperty('URL', URL);
                   props.setProperty('Server', p.Results.Server);
                   props.setProperty('PortNumber', num2str(p.Results.PortNumber));
                   props.setProperty('DriverType', DriverType);
                   props.setProperty('AuthType', AuthType);
                   
                                      
                   conn=com.mathworks.toolbox.database.databaseConnect(instance,username,password, props);
                   
                   connection.Instance = instance;
                   connection.UserName	= username;
                   
                   % The following elements are set as empty in this case.
                   connection.Driver   = [];
                   connection.URL      = [];
                   connection.Constructor = conn;
             end
            
            
        end %end if
                
      
        
end % switch

connection.Message  = [];
connection.Handle=[];

connectionVector = makeDatabaseConnection(conn);

% Check to see if the connection is valid .. must get the status element
% of the connection vector.

status = validConnectionMade(conn,connectionVector);

if (status == 1)
    
    % Valid connection has been established
    
    connection.Handle = getValidConnection(conn,connectionVector);
    
else
    
    connection.Handle = 0;
    
end

% Check to see if the connection has been made successfully .. non zero value returned.
% Issue a warning if connection has not been made.


if (strcmp(class(connection.Handle),'double')),
    
    theMessage = getConnectionMessage(conn, connectionVector);
 
    m = message('database:database:javaError',theMessage);
    
    connection.Instance	= instance;
    connection.UserName = username;
    connection.Driver		= [];
    connection.URL	      = [];
    connection.Message   = m.getString;
    
    
end

connection.TimeOut=[];
connection.AutoCommit='off';
connection.Type='Database Object';
connection=class(connection,'database',dbobj);

%Trap logintimeout error under Linux (method not supported)
try
    connection.TimeOut=logintimeout;
catch exception %#ok
    connection.TimeOut = 0;
end

if ~isempty(connection.Message),
    errorhandling(connection.Message);
    return;
end

end

%%Subfunctions

function OK = vendorCheck(Vendor)

supportedVendors = {'MYSQL', 'MICROSOFT SQL SERVER', 'ORACLE', 'POSTGRESQL'};

if(~ismember(upper(Vendor), supportedVendors))
    error(message('database:database:invalidVendor'))
else
    OK = true;
end

end

function v2smap = mapVendorToSource()

        keySet = {'MYSQL','MICROSOFT SQL SERVER','ORACLE', 'POSTGRESQL'};
        valueSet = {'com.mysql.jdbc.jdbc2.optional.MysqlDataSource',...
                    'com.microsoft.sqlserver.jdbc.SQLServerDataSource',...
                    'oracle.jdbc.pool.OracleDataSource',...
                    'org.postgresql.ds.PGSimpleDataSource',...
                    };

        v2smap = containers.Map(keySet,valueSet);
end


function errorhandling(s)
%ERRORHANDLING Error processing based on preference setting.
%   ERRORHANDLING(S) performs error processing based on the
%   SETDBPREFS property ErrorHandling.  S is the contents
%   of the connection.Message field.

switch lower((setdbprefs('ErrorHandling')))
    
    case 'report'
        
        %Throw error
        error(message('database:database:connectionFailure', s));
        
    case {'store','empty'}
        
        %Message field is populated, do nothing else
        
end
end
