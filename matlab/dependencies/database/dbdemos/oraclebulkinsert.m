%% Oracle Bulk Insert Example

% Make connection
javaaddpath '<path to jar file>\ojdbc6.jar';
conn = database('databasename','user','password','Vendor', 'Oracle','Server', '<machine>', 'PortNumber', 1521, 'DriverType', 'thin');

% Sample table creation
e = exec(conn,'create table BULKTEST (salary number, player varchar2(25), signed varchar2(25), team varchar2(25))');
close(e)

% Sample data record
A = {100000.00,'KGreen','09/16/2009','Challengers'};

% A expanded to 10k record dataset
A = A(ones(10000,1),:);

fid = fopen('c:\temp\tmp.txt', 'w');
for i = 1:size(A,1)
  fprintf(fid,'%10.2f \t %s \t %s \t %s \n',A{i,1},A{i,2},A{i,3},A{i,4});
end
fclose(fid);

% bulk insert
% Note this example uses a data file on the local machine where Oracle is installed  
e = exec(conn,'create or replace directory ext as ''C:\\Temp''');
close(e)

% Drop temporary table if it exists
e = exec(conn,'drop table testinsert');
try,close(e),end
e = exec(conn,'create table testinsert (salary number, player varchar2(25), signed varchar2(25), team varchar2(25)) organization external ( type oracle_loader default directory ext access parameters ( records delimited by ''\n'' fields terminated by ''\t'') location (''tmp.txt'')) reject limit 10000');
close(e)
e = exec(conn,'insert into BULKTest select * from testinsert');
close(e)

% close connection
close(conn)