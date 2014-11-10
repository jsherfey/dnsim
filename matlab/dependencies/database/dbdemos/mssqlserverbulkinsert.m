%% MS SQL Server Bulk Insert Example

% Make connection
% For JDBC driver use, add the jar file to the MATLAB javaclasspath.
javaaddpath '<path to jar file>\sqljdbc.jar';
conn = database('databasename','user','password','com.microsoft.sqlserver.jdbc.SQLServerDriver','jdbc:sqlserver://<machine>:<port>;database=databasename');

% Sample table creation
e = exec(conn,'create table BULKTEST (salary decimal(10,2), player varchar(25), signed_date datetime, team varchar(25))');
close(e)

% Sample data record
A = {100000.00,'KGreen','09/16/2009','Challengers'};

% A expanded to 10k record dataset
A = A(ones(10000,1),:);

% Write data to file for bulk insert
fid = fopen('\\temp\tmp.txt','wt'); 
for i = 1:size(A,1)
  fprintf(fid,'%10.2f \t %s \t %s \t %s \n',A{i,1},A{i,2},A{i,3},A{i,4});
end

% bulk insert
% Note that it's safest to use networked (UNC for DOS) pathnames.  MS SQL
% Server will have problems trying to read files that are not on the same
% machine as the instance of the database
e = exec(conn,'bulk insert BULKTEST from ''\\temp\tmp.txt'' with (fieldterminator = ''\t'', rowterminator = ''\n'')');

% close connection
close(conn)