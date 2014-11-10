function v = get(c,p)
%GET Get property of database connection.
%   VALUE = GET(HANDLE, PROPERTY) will return the VALUE of the PROPERTY 
%   specified for the given HANDLE to a Database object.
%
%   VALUE = GET(HANDLE) returns VALUE as a structure containing all the
%   property values of the Database object.
%
%   See also SET.

% Copyright 1984-2011 The MathWorks, Inc.

%Build property list 
prps = {...
      'AutoCommit';...
      'Catalog';...
      'Constructor';...
      'Driver';...
      'Handle';...
      'Instance';...
      'Message';...
      'ReadOnly';...
      'TimeOut';...
      'TransactionIsolation';...
      'Type';...
      'URL';...
      'UserName';...
      'Warnings';...
    };
  
%Set return property list or validate given properties
if nargin == 1
  p = prps;
else
  p = chkprops(c,p,prps);
end

%Initialize v to a 1 by 1 struct
v = struct;

%Get property values
for i = 1:length(p)
      
    switch p{i}
      case {'Catalog', 'AutoCommit', 'TransactionIsolation', 'Warnings'}
          
         %Check if we have a valid connection
         if(isa(c.Handle, 'double'))
             error(message('database:database:invalidConnection'));
         end
        
        %Call the appropriate Java method for these properties
        connObj = com.mathworks.toolbox.database.databaseConn;
        connMethodName = ['conn' p{i}];
        ret_vals = javaMethod(connMethodName, connObj, c.Handle);
                   
        error_msg = ret_vals.elementAt(1);
        
        if(~isempty(error_msg))
            error(message('database:database:javaError', error_msg));
        end
        
        propValue = ret_vals.elementAt(0);
        v.(p{i}) = propValue;
        
                
      case 'ReadOnly'
        v.ReadOnly = isreadonly(c); 
      otherwise
        v.(p{i}) = c.(p{i});
    end
  
end

%Do not return structure if only one property is requested
if length(p) == 1
   v = v.(p{1});
end
