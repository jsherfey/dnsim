function A = subsasgn(A,S,B)
%SUBSASGN Assign a value to a Database Cursor object.
%  
%  A.PROPERTY = VALUE assigns VALUE to the property PROPERTY of cursor
%  object A, only if PROPERTY is not read-only. 
%
%  RowLimit being the only writable property of cursor objects, it is 
%  recommended that you set it using SET or via appropriate input 
%  parameters of FETCH or RUNSQLSCRIPT rather than use an assignment 
%  expression as the one above. 
%
%  A(i) = B assigns cursor object B to the ith element of cursor array A.
%
%  See also SET,FETCH, RUNSQLSCRIPT.


% Copyright 1984-2004 The MathWorks, Inc.

if strcmp(S.type,'.')
  A = set(A,S.subs,B);
elseif strcmp(S.type, '()')
   A = builtin('subsasgn', A, S, B);
else,
  error(message('database:cursor:subsasgnFailure'))     
end % switch
