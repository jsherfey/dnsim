function y = dbtbx()
%DBTBX Construct Database Toolbox object.

%   Author(s): C.F.Garvin, 10-30-98
%   Copyright 1984-2002 The MathWorks, Inc.

x.dumfld = [];             %Need field placeholder to create object
y = class(x,'dbtbx');
