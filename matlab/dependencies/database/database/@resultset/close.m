function close(r)
%CLOSE Close resultset object.
%   CLOSE(R) closes the resultset object, R, and frees its associated resources.
%
%   See also GET, RESULTSET.

%   Author(s): C.F.Garvin, 07-09-98
%   Copyright 1984-2003 The MathWorks, Inc.

try
  
  close(r.Handle);
  
catch
  
  error(message('database:resultset:invalidResultset'))
  
end
