function A = subsasgn(A,S,B)
%SUBSASGN Assign a value to an an Database object.
%  SUBSASGN is currently only implemented for dot assignment.
%  For example:
%    H.PROPERTY=VALUE
%
%  See also SET.

%  Copyright 1984-2004 The MathWorks, Inc.

if strcmp(S.type,'.')
  A = set(A,S.subs,B);
else,
  error(message('database:database:subsasgnFailure'));     
end % switch
