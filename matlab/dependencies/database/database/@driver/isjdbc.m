function x = isjdbc(d)
%ISJDBC Detect if driver is JDBC-compliant.
%   X = ISJDBC(D) returns 1 if D is JDBC compliant. 
%
%   See also GET, ISURL.

%   Author(s): C.F.Garvin, 06-30-98
%   Copyright 1984-2003 The MathWorks, Inc.

%Validate driver object
if ~isdriver(d)
  error(message('database:driver:invalidObject'))
end

%Establish JAVA instance handle
a = com.mathworks.toolbox.database.databaseDrivers;

%Test driver for jdbc compliance
x = driverJdbc(a,d.DriverHandle);
