function d = dmd(c)
%DMD    Construct database metadata object.
%   D = DMD(C) constructs a database metadata object.  The metadata
%   object is used to call methods that return the properties of the 
%   database connection's metadata.  C is a database connection object.
%
%   See also GET, SUPPORTS.

%   Author(s): C.F.Garvin, 07-09-98
%   Copyright 1984-2004 The MathWorks, Inc.

%Create parent object for generic methods
dbobj = dbtbx;

if nargin == 0
  o.DMDHandle = [];
  d = class(o,'dmd',dbobj);
  return
end

if isa(c,'dmd')    %Pass through object if already dmd object
  d = c;
  return
end

if ~isconnection(c)
  error(message('database:database:invalidConnection'))
end

%Retrieve meta data object from connection
o.DMDHandle = getMetaData(c.Handle);
d = class(o,'dmd',dbobj);
