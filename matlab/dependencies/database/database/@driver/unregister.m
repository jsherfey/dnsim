function unregister(d)
%UNREGISTER Unload database driver.
%   REGISTER(D) unloads the database driver D.
%
%   See also REGISTER.

%   Author(s): C.F.Garvin, 06-30-98
%   Copyright 1984-2003 The MathWorks, Inc.

if ~isdriver(d)
  error(message('database:driver:invalidObject'))
end

%Establish JAVA instance handle
a = com.mathworks.toolbox.database.databaseDrivers;

%Load driver
driversDeregisterDriver(a,d.DriverHandle);
