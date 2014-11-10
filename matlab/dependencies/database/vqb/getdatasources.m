function [d,jdbcinfo] = getdatasources()
%GETDATASOURCES Return valid data sources on system.
%   D = GETDATASOURCES returns the valid data sources on the system.
%   If D is empty, the ODBC.INI file is valid but no data sources have been 
%   defined.  If D equals -1, the ODBC.INI file could not be opened.
%   D is returned as a cell array of strings containing the data source names
%   if any are present on the system.

%   Copyright 1984-2006 The MathWorks, Inc.

d = [];

%Run specific to PC versions of MATLAB
if ispc
    
  %Sources being read from ODBC.INI file, find it
  windir = getenv('WINDIR');
  fid = fopen([windir(1:length(windir)) '\odbc.ini']); 
  if fid == -1
    d = fid;
  end

  if fid > -1   %Found ODBC.INI system file
      
    %Parse file line by line searching for string ODBC 32 bit [Data Sources]
    hdr = '';
    while ~strcmpi(hdr,'[ODBC 32 BIT DATA SOURCES]')
      hdr = fgetl(fid);
    end

    %Found data sources, parse them
    tmp = fgetl(fid);
    i = 1;
    while ~isempty(tmp) && (~strcmp(tmp(1),'[') && ~isempty(strfind(tmp,'=')))
      j = find(tmp == '=');  %Find = that end of source name
      d{i} = tmp(1:j-1);     %#ok, Store source name
      tmp = fgetl(fid);      %Read next line of file
      i = i+1;
    end
    fclose(fid);

  end
  
  %If odbc.ini could not be opened, reinitialize d
  if ~iscell(d) & (d ==  -1)    %#ok
    d = [];
  end
  
  %Should registry be checked for data sources?
  if strcmpi('yes',setdbprefs('UseRegistryForSources'))
    
    %Try registry for ODBC data sources as well
    regloc = {'HKEY_LOCAL_MACHINE','HKEY_CURRENT_USER'};
    for n = 1:length(regloc) 
        try
          d = [d winqueryreg('name',regloc{n}, 'SOFTWARE\ODBC\ODBC.INI\ODBC Data Sources')']; %#ok
        catch    %#ok
          % Need entry for 64 bit machines
        end
    end
    
    %Remove any duplicate names
    d = unique(d);
    
  end
   
end

%Initialize JDBC data source driver and URL variable
jdbcinfo = [];

%Get JDBC data sources from confds configuration file
jdbcfile = setdbprefs('JDBCDataSourceFile');
if ~isempty(jdbcfile)
  if (exist(jdbcfile,'file') ~= 2)
    errordlg(['Specified JDBC data source file does not exist.   Please ',...
              'see the help for the function setdbprefs or respecify the',...
              ' correct location of the file under File -> Preferences',...
              ' in the Visual Query Builder.  If no JDBC data sources are ',...
              'being used, the file specification should be empty.'],'JDBC data source file error')
    jdbcinfo = -1;
    return
  end
else
  return  %No JDBC sources exist, do nothing
end

load(jdbcfile,'-mat')
if exist('srcs','var')
  jdbcinfo = srcs;
  d = [d jdbcinfo(:,1)'];

  %Remove any duplicate names
  d = unique(d);
else
  errordlg(['Specified JDBC data source file is invalid.   Please ',...
              'see the help for the function setdbprefs or respecify the',...
              ' correct location of the file under File -> Preferences',...
              ' in the Visual Query Builder.  If no JDBC data sources are ',...
              'being used, the file specification should be empty.'],'JDBC data source file error')
  jdbcinfo = -1;
  return
end


  