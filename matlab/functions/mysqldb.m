function result=mysqldb(query,fields)
global cfg
if isempty(cfg)
  cfg.webhost = '104.131.218.171'; % 'infinitebrain.org','104.131.218.171'
  cfg.dbname = 'modulator';
  cfg.dbuser = 'querydb'; % have all users use root to connect to DB and self to transfer files
  cfg.dbpassword = 'publicaccess'; % 'publicaccess'
end
[BIOSIMROOT,o]=fileparts(which('startup.m'));
result=[];
% check for database connector type and set cfg.mysql_connector
if strcmp(query,'setup')
  % determine connection type
  if exist('database.m')==2 % check for database toolbox
    % MySQL JAR file
    if exist('mysql-connector-java.jar')
      jarfile = which('mysql-connector-java.jar');
    elseif exist('mysql.jar')
      jarfile = which('mysql.jar');
    elseif exist('/usr/share/java/mysql-connector-java.jar')
      jarfile = '/usr/share/java/mysql-connector-java.jar';
    elseif exist(fullfile(BIOSIMROOT,'matlab','dependencies','mysql-connector-java-5.1.28.jar'))
      jarfile = fullfile(BIOSIMROOT,'matlab','dependencies','mysql-connector-java-5.1.28.jar');
    else
      result='none';%cfg.mysql_connector = 'none';
      msgbox('Database toolbox failed because of missing mysql-connector-java.jar');
      return;        
    end
    % Set this to the path to your MySQL Connector/J JAR
    javaaddpath(jarfile); % WARNING: this might clear global variables
    result='database'; %cfg.mysql_connector = 'database';
  elseif exist('mym.m')==2  % check for mym
    try
      err=mym('open', cfg.webhost,cfg.dbuser,cfg.dbpassword);
      mym('close');
      result='mym';%cfg.mysql_connector = 'mym';
    catch
      result='none';%cfg.mysql_connector = 'none';
    end  
  else
    result='none';%cfg.mysql_connector = 'none';
  end
  if strcmp(result,'none')%strcmp(cfg.mysql_connector,'none')
    %msgbox('Database connection cannot be established.');
  end
  return;
end
% query the DB
try
  switch cfg.mysql_connector
    case 'database'
      % JDBC Parameters
      jdbcString = sprintf('jdbc:mysql://%s/%s',cfg.webhost,cfg.dbname);
      jdbcDriver = 'com.mysql.jdbc.Driver';
      % Create the database connection object
      dbConn = database(cfg.dbname,cfg.dbuser,cfg.dbpassword,jdbcDriver,jdbcString);
      if isconnection(dbConn)
        data = get(fetch(exec(dbConn,query)), 'Data');
      else
        disp(sprintf('Connection failed:&nbsp;%s', dbConn.Message));
      end
      if isequal(data{1},'No Data')
        result = [];
      else
        % convert result to structure
        for i=1:numel(fields)
          if isnumeric(data{1,i}) || islogical(data{1,i})
            result.(fields{i}) = [data{:,i}]';
          elseif ischar(data{1,i})
            result.(fields{i}) = {data{:,i}}';
          end
        end
      end
      close(dbConn); % Close the connection so we don't run out of MySQL threads
    case 'mym'
      err=mym('open', cfg.webhost,cfg.dbuser,cfg.dbpassword);
      if err
        %disp('there was an error opening the database.'); 
      else
        mym(['use ' cfg.dbname]);
        result = mym(query);
      end
      mym('close');      
    case 'mysql'
    otherwise
  end
catch
  result = [];
  disp('Database query failed.');
end
