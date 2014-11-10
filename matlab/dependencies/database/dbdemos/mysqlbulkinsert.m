%% MySQL Bulk Insert Example

% Make connection
% For JDBC driver use, add the jar file to the MATLAB javaclasspath.
javaaddpath '<path to jar file>\mysql-connector-java-5.1.5-bin.jar';
conn = database('databasename', 'user', 'password','com.mysql.jdbc.Driver','jdbc:mysql://<machine>:<port>/databasename');

% Sample table creation
e = exec(conn,'create table BULKTEST (salary decimal, player varchar(25), signed_date varchar(25), team varchar(25))');
close(e)

% Sample data record
A = {100000.00,'KGreen','09/16/2009','Challengers'};

% A expanded to 10k record dataset
A = A(ones(10000,1),:);

% Write data to file for bulk insert
fid = fopen('c:\temp\tmp.txt','wt');
for i = 1:size(A,1)
  fprintf(fid,'%10.2f \t %s \t %s \t %s \n',A{i,1},A{i,2},A{i,3},A{i,4});
end
fclose(fid);

% bulk insert
% Note use of local infile
e = exec(conn,'load data local infile ''C:\\temp\\tmp.txt'' into table BULKTEST fields terminated by ''\t'' lines terminated by ''\n''');
close(e)

% close connection
close(conn)