function prps = chkprops(x,p,kp)
%CHKPROPS Database object properties.
%   PRPS = CHKPROPS(X,P) validates and returns the given set of properties, P,
%   for the database object, X.  KP is the set of known properties for the
%   given object.

%   Copyright 1984-2003 The MathWorks, Inc.

if ischar(p)   %Convert string input to cell array
  p = {p};
end

for i = 1:length(p)  %Validate each given property
  try
    c(i) = find(strcmp(upper(p(i)),upper(kp)));
  catch
    error(message('database:chkprops:invalidDatabaseObjectProperty', class( x ), p{ i }))
  end
end

prps = kp(c);   %Return properties converted from given to known props (case sen)
