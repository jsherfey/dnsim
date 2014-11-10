function x = runstoredprocedure(c,spcall,inarg,typeout)
%RUNSTOREDPROCEDURE Stored procedures with input and output parameters.
%   X = RUNSTOREDPROCEDURE(C,SPCALL,INARG,TYPEOUT) calls a stored procedure given
%   input parameters and returns output parameters.   C is the database
%   connection handle, SPCALL is the stored procedure to be run, INARG is a
%   cell array containing the stored procedure's input parameters and
%   TYPEOUT is the list of data types of the output parameters.
%
%   For example, the call syntax may appear as
%
%   x = runstoredprocedure(c,'myproc',{2500,'Jones'},{java.sql.Types.NUMERIC}) 
%
%   which means that the stored procedure myproc will be run given the
%   input parameters 2500 and 'Jones'.   It will return an output parameter
%   of type java.sql.Types.NUMERIC which could be any numeric Java data
%   type.
%
%   x = runstoredprocedure(c,'myprocinonly',{2500,'Jones'}) runs a stored
%   procedure given the input parameters 2500 and 'Jones' and returns no
%   output parameters.
% 
%   x = runstoredprocedure(c,'myprocnoparams') runs a stored procedure
%   that has no input or output parameters.
%
%   For stored procedures that return resultsets, use the methods
%   DATABASE/EXEC and CURSOR/FETCH to process the return data.
%   
%   See also EXEC, FETCH.

%   Copyright 1984-2006 The MathWorks, Inc.

%Set defaults for inarg and typeout
if nargin < 3
  inarg = [];
end
if nargin < 4
  typeout = [];
end

%Get JDBC connection Handle
h = c.Handle;

%Get Database name
dMetaData = dmd(c);
sDbName = get(dMetaData,'DatabaseProductName');

%Build stored procedure call
spcall = [spcall '('];
for i = 1:length(inarg)
  if isnumeric(inarg{i}) || islogical(inarg{i})
    inarg{i} = num2str(inarg{i},17);
  elseif strcmp(sDbName,'MySQL') || strcmp(sDbName,'Microsoft SQL Server')
    inarg{i} = ['''' inarg{i} ''''];
  end
  spcall = [spcall inarg{i} ','];    %#ok, not sure how long spcall will be
end
numout = length(typeout);
for i = 1:numout
  spcall = [spcall '?,']; %#ok, not sure how long spcall will be
end

%Allow for procedures with no inputs or outputs
if ~(isempty(inarg) && isempty(typeout))  
  spcall(end) = ')';
else
  spcall(end) = [];
end
spcall = ['{call ' spcall '}'];

%Create callable statement
csmt = h.prepareCall(spcall);

%Register output parameters
for i = 1:numout
  csmt.registerOutParameter(i,typeout{i});
end

%Execute callable statement, method depends on output parameters 
if ~isempty(typeout)  
  csmt.executeUpdate;
else
  try  
    x = csmt.execute;
  catch exception 
    error(message('database:runstoredprocedure:returnedResultSet', exception.message));
  end
  close(csmt);
  return
end

%Return output parameters as native data types
x = cell(numout,1);
for i = 1:numout
  x{i} = csmt.getObject(i);
end

%Close callable statement
close(csmt)
