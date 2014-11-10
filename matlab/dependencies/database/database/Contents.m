% Database Toolbox
% Version 5.1 (R2014a) 27-Dec-2013
%
%  General functions:
%
%  chkprops      - Database object properties.
%  logintimeout  - Set or get time allowed to establish database connection.
%  setdbprefs    - Set preferences for database actions for handling null values.
%  dexplore      - Configure, explore and import database data using Database Explorer
%
%  Database Access functions:
%
%  /database/catalogs           - Get database catalog names.
%  /database/clearwarnings      - Clear warnings for database connection.
%  /database/close              - Close database connection.
%  /database/columns            - Get database table column names.
%  /database/commit             - Make database changes permanent.
%  /database/database           - Connect to database.
%  /database/exec               - Execute SQL statement and open cursor.
%  /database/fetch              - Import data into MATLAB using connection handle.
%  /database/get                - Get database property.
%  /database/insert             - Export MATLAB cell array data to database table.
%  /database/isconnection       - Detect if database connection is valid.
%  /database/isreadonly         - Detect if database connection is read-only.
%  /database/ping               - Get status information about database connection.
%  /database/rollback           - Undo database changes.
%  /database/runstoredprocedure - Stored procedures with input and output parameters.
%  /database/schemas            - Get database schema names.
%  /database/set                - Set properties for database connection.
%  /database/sql2native         - Convert JDBC SQL grammar into system's native SQL grammar.
%  /database/tables             - Get database table names.
%  /database/update             - Replace data in database table with data from MATLAB cell array.
%
%  Database Cursor Access functions:
%
%  /cursor/attr         - Get attributes of columns in fetched data set.
%  /cursor/close        - Close cursor.
%  /cursor/cols         - Get number of columns in fetched data set.
%  /cursor/columnnames  - Get names of columns in fetched data set.
%  /cursor/fetch        - Import data into MATLAB.
%  /cursor/get          - Get property of cursor object.
%  /cursor/querytimeout - Get time allowed for a database SQL query to succeed.
%  /cursor/rows         - Get number of rows in fetched data set.
%  /cursor/set          - Set RowLimit for cursor fetch.
%  /cursor/width        - Get width of column in fetched data set.
%
%  Database Toolbox Object functions:
%
%  /dbtbx/dbtbx      - Construct Database Toolbox object.
%  /dbtbx/display    - Database Toolbox object display method.
%  /dbtbx/subsasgn   - Subscripted assignment for Database Toolbox object.
%  /dbtbx/subsref    - Subscripted reference for Database Toolbox object.
%
%  Database Toolbox Database MetaData functions:
%
%  /dmd/bestrowid         - Get database table unique row identifier.
%  /dmd/columnprivileges  - Get database column privileges.
%  /dmd/columns           - Get database table column names.
%  /dmd/crossreference    - Get information about primary and foreign keys.
%  /dmd/dmd               - Construct database metadata object.
%  /dmd/exportedkeys      - Get information about exported foreign keys.
%  /dmd/get               - Get database metadata properties.
%  /dmd/importedkeys      - Get information about imported foreign keys.
%  /dmd/indexinfo         - Get indices and statistics for database table.
%  /dmd/primarykeys       - Get primary key information for database table or schema.
%  /dmd/procedurecolumns  - Get catalog's stored procedure parameters and result columns.
%  /dmd/procedures        - Get catalog's stored procedures.
%  /dmd/supports          - Detect if property is supported by database metadata.
%  /dmd/tableprivileges   - Get database table privileges.
%  /dmd/tables            - Get database table names.
%  /dmd/versioncolumns    - Get automatically updated table columns.
%
%  Database Toolbox Driver functions:
%
%  /driver/driver     - Construct database driver object.
%  /driver/get        - Get database driver properties.
%  /driver/isdriver   - Detect if driver is a valid JDBC driver object.
%  /driver/isjdbc     - Detect if driver is JDBC-compliant.
%  /driver/isurl      - Detect if database URL is valid.
%  /driver/register   - Load database driver.
%  /driver/unregister - Unload database driver.
%
%  Database Toolbox Drivermanager functions:
%
%  /drivermanager/drivermanager  - Construct database drivermanager object.
%  /drivermanager/get            - Get database drivermanager properties.
%  /drivermanager/set            - Set database drivermanager properties.
%
%  Database Toolbox Resultset functions:
%
%  /resultset/clearwarnings  - Clear the warnings for the resultset.
%  /resultset/close          - Close resultset object.
%  /resultset/get            - Get resultset properties.
%  /resultset/isnullcolumn   - Detect if last record read in resultset was null.
%  /resultset/namecolumn     - Map resultset column name to resultset column index.
%  /resultset/resultset      - Construct resultset object.
%
%  Database Toolbox Resultset MetaData functions:
%
%  /rsmd/rsmd  - Construct resultset metadata object.
%  /rsmd/get   - Get resultset metadata properties.
%
%  Database Toolbox bulk insert examples:
%
%  /dbdemos/mssqlserverbulkinsert  - MS SQL Server bulk insert example. 
%  /dbdemos/mysqlbulkinsert  - MySQL bulk insert example.
%  /dbdemos/oraclebulkinsert - Oracle bulk insert example.
% 
%  Visual Query Builder functions:
%
%  /vqb/confds              - Configure data source (UNIX only).
%  /vqb/getdatasources      - Return valid data sources on system.
%  /vqb/loginconnect        - Datasource connection.
%  /vqb/parsebinary         - Write binary object to disk.
%  /vqb/qbhelp              - Query Builder help string.
%  /vqb/querybuilder        - Start visual SQL query builder.
%  /vqb/showdata            - Display data in interactive window.
%  /vqb/showdatacallbacks   - Visual Query Builder data display callbacks.
%  /vqb/vqbdemo             - Visual Query Builder demonstrations.
%
% Native ODBC Interface classes and methods:
%
% /+database/DatabaseConnection					- Abstract class definition for the connection object
% /+database/DatabaseCursor						- Abstract class definition for the cursor object
% /+database/DatabaseUtils                      - Static utility methods
% /+database/ODBCConnection/ODBCConnection		- Open connection to an ODBC data source using native ODBc interface
% /+database/ODBCConnection/exec				- Execute a SQL query
% /+database/ODBCConnection/insert				- Insert MATLAB variable into the database
% /+database/ODBCConnection/fastinsert			- Insert MATLAB variable into the database
% /+database/ODBCConnection/close				- Close database connection
% /+database/ODBCCursor/ODBCCursor				- Open a cursor object
% /+database/ODBCCursor/fetch					- Import data into a MATLAB variable
% /+database/ODBCCursor/close					- Close cursor object

% Copyright 1984-2013 The MathWorks, Inc.
