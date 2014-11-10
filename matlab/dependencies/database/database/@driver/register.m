function register(d)
%REGISTER Load database driver.
%   REGISTER(D) loads the database driver D.
%
%   See also UNREGISTER.

%   Author(s): C.F.Garvin, 06-30-98
%   Copyright 1984-2003 The MathWorks, Inc.

if ~isdriver(d)
  error(message('database:driver:invalidObject'))
end

%Establish JAVA instance handle
a = com.mathworks.toolbox.database.databaseDrivers;

%Load driver
driversRegisterDriver(a,d.DriverHandle);
