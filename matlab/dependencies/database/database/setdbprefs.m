function h = setdbprefs(p,v)
%SETDBPREFS Set preferences for database actions for handling null values.
%   SETDBPREFS(P,V) sets the preferences for database actions.  P is the 
%   list of properties to be set and V is the corresponding value list.
%
%   SETDBPREFS(P) returns the property with its current setting.
%
%   SETDBPREFS returns the property list with all current values.
%
%   The valid properties are NullNumberRead, NullNumberWrite, NullStringRead,
%   NullStringWrite, DataReturnFormat, ErrorHandling and JDBCDataSourceFile.
%   The value for each property is entered as a string.
%
%   For example, the command
%
%      setdbprefs('NullStringRead','null')
%  
%   translates all NULL strings read from the database into the string
%   'null'.
%
%   The command
% 
%      setdbprefs({'NullStringRead';'NullStringWrite';'NullNumberRead';'NullNumberWrite'},...
%                 {'null';'null';'NaN';'NaN'})
%
%   translates NULL strings read into the string 'null', NULL values to NaN.  A NaN in the 
%   data written to the database is translated to a NULL and a 'null' string is translated to
%   NULL.
%
%   The command setdbprefs('DataReturnFormat','cellarray') returns the data 
%   in the cursor Data field as a cell array which is the default behavior.   
%   Other values for DataReturnFormat are 'numeric' which returns the data 
%   as a matrix of doubles and 'structure' which returns the data as a structure 
%   with the fieldnames corresponding to the fetched fields.
%
%   The command setdbprefs('ErrorHandling','store') returns any error messages 
%   to the object Message field and will cause the next function that uses the 
%   object to return an error.   This is the default behavior.   Other values 
%   for ErrorHandling are 'report' which causes any function encountering an error
%   to report the error and stop processing and 'empty' which causes the fetch 
%   command to return the cursor Data field as [] when given a bad cursor object 
%   resulting from exec.
%
%   The command setdbprefs('JDBCDataSourceFile','d:\work\datasource.mat')
%   sets the location of the JDBC data source information to the file
%   d:\work\datasource.mat.  This enables the Visual Query Builder to use
%   both ODBC and JDBC data sources.   The command setdbprefs('JDBCDataSourceFile','') 
%   specifies that no JDBC data sources are being used by the Visual Query Builder.
%
%   A single input can be used if it is a structure with fields corresponding to the valid 
%   preference names.   Each field should contain a valid preference setting.   For example,
%
%     p.DataReturnFormat = 'cellarray';
%     setdbprefs(p)

%   Copyright 1984-2010 The MathWorks, Inc.

DatabasePrefs = javaObject('com.mathworks.toolbox.database.databasePrefs');

%Build property list
prps = {'DataReturnFormat';...
    'ErrorHandling';...
    'NullNumberRead';...
    'NullNumberWrite';...
    'NullStringRead';...
    'NullStringWrite';...
    'JDBCDataSourceFile';...
    'UseRegistryForSources';...
    'TempDirForRegistryOutput';...
    'DefaultRowPreFetch';...
    'FetchInBatches';...
    'FetchBatchSize';
  };

%Validate properties
if nargin > 0
  if ischar(p) %Convert property list to cell string array
    p = cellstr(p);
  elseif isstruct(p) %Set properties based on values in structure
    flds = fieldnames(p);
    vals = cell(length(flds),1);
    for i = 1:length(flds)
      vals{i} = p.(flds{i});
    end
    setdbprefs(flds,vals)
    return
  end
  p = chkprops(DatabasePrefs,p,prps);
else
  p = prps;
end

%Return values for given properties if no values given
L = length(p);
if nargin <= 1
  for i = 1:L
    getprefstr = ['get' p{i}];
    x.(p{i}) = javaMethodEDT(getprefstr,DatabasePrefs);   
  end
end

%Set properties to given values
if nargin == 2
  if ischar(v)  %Convert values list to cell string array
    v = cellstr(v);
  elseif ~iscellstr(v)
    error(message('database:setdbprefs:valueFormatNotChar'))
  end
  
  %Validate settings for properties with fixed value choices
  i = find(strcmp(p,'DataReturnFormat'));
  if ~isempty(i) && nargin == 2
  
    fmts = {'cellarray','numeric','structure','dataset','table'};
    j = find(strcmpi(v{i},fmts)); %#ok
    if isempty(j)
      error(message('database:setdbprefs:invalidDataReturnFormatValue'))
    else
      v{i} = lower(v{i});
    end
    if ~license('test','statistics_toolbox') && strcmpi(v{i},'dataset')
      error(message('database:setdbprefs:datasetUnavailable'))
    end
   
  end
  
  i = find(strcmp(p,'ErrorHandling'));
  if ~isempty(i) && nargin == 2
    j = find(strcmpi(v{i},{'store','report','empty'}));   %#ok
    if isempty(j)
      error(message('database:setdbprefs:invalidErrorHandlingValue'))
    else
      v{i} = lower(v{i});
    end
  end
  
  i = find(strcmp(p,'UseRegistryForSources'));
  if ~isempty(i) && nargin == 2
    j = find(strcmpi(v{i},{'yes','no'}));   %#ok
    if isempty(j)
      error(message('database:setdbprefs:invalidRegistryForSourcesValue', 'UseRegistryForSources'))
    else
      v{i} = lower(v{i});
    end
  end
  
  i = find(strcmp(p,'FetchInBatches'));
  if ~isempty(i) && nargin == 2
    j = find(strcmpi(v{i},{'yes','no'}));   %#ok
    if isempty(j)
      error(message('database:setdbprefs:invalidRegistryForSourcesValue', 'FetchInBatches'))
    else
      v{i} = lower(v{i});
    end
  end
  
  i = strcmp(p,'FetchBatchSize');
  if any(i) && nargin == 2
    batchSize = str2double(v{i});
    
    if(isnan(batchSize) || mod(batchSize, 1) ~= 0 || batchSize < 1 || batchSize > 1000000)
        error(message('database:setdbprefs:invalidBatchSizeValue'));
    end
  end
  
  %Make 'NullNumberRead' and 'NullNumberWrite' case-insensitive to NaN and Inf
  i = find(strcmp(p,'NullNumberRead'));
  if ~isempty(i) && nargin == 2
      j = find(strcmpi(v{i},{'NaN'}));   %#ok
      if ~isempty(j)
          v{i} = 'NaN';
      end
      
      j = find(strcmpi(v{i},{'Inf'}));   %#ok
      if ~isempty(j)
          v{i} = 'Inf';
      end
  end
  
  i = find(strcmp(p,'NullNumberWrite'));
  if ~isempty(i) && nargin == 2
      j = find(strcmpi(v{i},{'NaN'}));   %#ok
      if ~isempty(j)
          v{i} = 'NaN';
      end
      
      j = find(strcmpi(v{i},{'Inf'}));   %#ok
      if ~isempty(j)
          v{i} = 'Inf';
      end
  end
  
  %Set properties
  for i = 1:L
    prefstr = ['set' p{i}];
    javaMethodEDT(prefstr,DatabasePrefs,v{i})
  end
  
  if nargout > 0
    error(message('database:setdbprefs:tooManyOutputs'))
  end
  return
end

%Use windows temporary directory if TempDirForRegistryOutput is empty or
%set to Windows directory
if isfield(x,'TempDirForRegistryOutput')
  tmpdir = x.TempDirForRegistryOutput;
  if ispc && (isempty(tmpdir) || strcmpi(tmpdir,getenv('windir')))
    setdbprefs('TempDirForRegistryOutput',getenv('temp'))
    x = setdbprefs;
  end
end

if nargout == 0   %Display if no output argument
  disp(' ')
  disp(x)
end

if nargout == 1   %Return structure if output argument
  if L == 1
    h = x.(p{1});
  else
    h = x;
  end
end
