function x = isnullcolumn(r)
%ISNULLCOLUMN Detect if last record read in resultset was null.
%   X = ISNULLCOLUMN(R) returns 1 if the last record of the resultset,
%   R, read was null and 0 otherwise.
%
%   See also GET, SET.

%   Author(s): C.F.Garvin, 07-09-98
%   Copyright 1984-2003 The MathWorks, Inc.

try
  
  %JAVA call to wasNull method
  x = wasNull(r.Handle);
  
catch
  
  error(message('database:resultset:invalidResultset'))
  
end
