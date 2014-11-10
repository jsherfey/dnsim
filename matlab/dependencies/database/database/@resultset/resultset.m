function r = resultset(c)
%RESULTSET Construct resultset object.
%   R = RESULTSET(C) returns a resultset object given a cursor object,
%   C.
%
%   See also GET, SET.

%   Author: C.F.Garvin, 07-09-98
%   Copyright 1984-2004 The MathWorks, Inc.
%   	%

%Create parent object for generic methods
dbobj = dbtbx;
if nargin == 0
  s.Handle = [];
  r = class(s,'resultset',dbobj);
  return
end
  
%Check for valid cursor input
if ~isa(c,'cursor')
  error(message('database:resultset:invalidCursor'))
end

%Build resultset structure
tmp = struct(c);
s.Handle = tmp.ResultSet;

%Set class
r = class(s,'resultset',dbobj);
