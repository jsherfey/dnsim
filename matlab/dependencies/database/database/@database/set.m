function x = set(varargin)
%SET Set properties for database connection.
%   SET(H, 'PROPERTY', 'VALUE') sets the VALUE of the given PROPERTY for the
%   Database object, H. 
%
%   SET(H) returns the list of properties that can be modified.
%
%   See also GET.

% Copyright 1984-2006 The MathWorks, Inc.

if nargin == 1
  x = {...
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
  return
end

H=varargin{1};

if ~isa(H,'database')
  builtin('set',varargin{:})
  return
end

% Check for valid database object handle .. should not be empty.

if (isempty(H.Handle) == 0),
   
   switch lower(varargin{2}),
      
   case 'autocommit',
      
     constructor = com.mathworks.toolbox.database.databaseConnect;
   
     % Convert the flag returned from the driver .. true = on & false = off.
   
     switch lower(varargin{3}),
       case 'on',
      
         toggle = 'true';
      
       case 'off',
      
         toggle = 'false';
      
       otherwise,
      
         error(message('database:database:invalidAutoCommitValue', varargin{ 3 }));
      
     end
   
     autoC = toggleAutoCommit(constructor,H.Handle,toggle);	
   
     % Convert the flag returned from the driver .. true = on & false = off.
      
      
     if (strcmp(autoC,'true') == 1)
      
      	autoC = 'on';
      
     else
      
      	autoC = 'off';
      
     end
   
   case 'readonly'
     
     setReadOnly(H.Handle,varargin{3})
     
   case 'transactionisolation'
     
     setTransactionIsolation(H.Handle,varargin{3})
     
   case 'timeout',
   
 	   error(message('database:database:useLogintimeout', varargin{ 2 }));

	 case {'driver','instance','handle','message','warnings','username','url',...
   	   'type','catalog'}

	   % Users not allowed to set/reset the following properties of a connection.

	   error(message('database:database:readOnlyProperty', varargin{ 2 }));
   
	otherwise,
   
  		error(message('database:database:invalidProperty', varargin{ 2 }));
  
	end % switch    
   
else
   
   error(message('database:database:invalidConnection'))
   
end 

