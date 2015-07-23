function [allspecs] = studydriver(specpath,logfile,keep_flag)
% [a,b]=studydriver(specpath,1,1);
% note: rename this to studywrapper. studydriver should be an optional
% script then that uses this function or others directly.
if nargin<3, keep_flag = 1; end
if nargin<2 || ~ischar(logfile), logfid = 1; logfile=''; else logfid = fopen(logfile,'w'); end

% Load spec
spec = loadspec(specpath);

% parse sim-space-spec
allspecs = get_search_space(spec);

cluster_flag = str2num(spec.simulation.sim_cluster_flag); % 1
cluster      = spec.simulation.sim_cluster;   if isempty(cluster), cluster='mmilcluster.ucsd.edu'; end
qsubscript   = spec.simulation.sim_qsubscript;if isempty(qsubscript), qsubscript='qmatjobs2'; end

if cluster_flag % process on cluster
  cnt = 0;
  for k = 1:length(allspecs)
    cnt = cnt + 1;
  % set up batch directory for cluster jobs
  batchname = sprintf('%s_%s_%s',spec.simulation.ProjName,spec.simulation.StudyName,datestr(now,30)); 
  batchdir = sprintf('/home/jsherfey/batchdirs/%s',batchname);
  mkdir(batchdir);
  driverscript = which(spec.simulation.sim_driver);
  [fpath,scriptname,fext] = fileparts(driverscript);
  allfiles = {driverscript spec.files{:}};
  cwd = pwd; cd(batchdir);
  for i = 1:length(allfiles)
    unix(sprintf('cp %s .',allfiles{i}));
  end
  mfiles = {};
  % loop over elements of search space
%   for k = 1:length(allspecs)
    spec = allspecs{k};
    fprintf(logfid,'writing simulation job...');
    % save this spec
    try
      spec.simulation.SetName = spec.simulation.description;
    catch
      try
        a = regexp(spec.simulation.scope,'[\w,]+','match');
        b = regexp(spec.simulation.variable,'[\w,]+','match');
        c = regexp(spec.simulation.values,'\d+','match');
        spec.simulation.SetName = strrep(sprintf('%s_%s_%s',a{1},b{1},c{1}),',','_');
      catch
        spec.simulation.SetName = num2str(k);
      end
    end
    specfile = sprintf('spec%g.mat',k);
    save(specfile,'spec');
    % write cluster job: simdriver(spec)
    mfiles{end+1} = sprintf('val%g.m',k);
    fileID = fopen(mfiles{end},'wt');
%     fprintf(fileID,'%s(''%s'');\n',specfile);
    fprintf(fileID,'load(''%s'',''spec''); %s(spec);\n',specfile,scriptname);
    fprintf(fileID,'exit');
    fclose(fileID);
    fprintf('done (%g of %g)\n',cnt,length(allspecs));
%   end  
  % write scriptlist.txt (list of jobs)
  fileID = fopen('scriptlist.txt', 'wt');
  for i = 1:length(mfiles)
    [a,this] = fileparts(mfiles{i});
    fprintf(fileID,'%s\n',this);
  end
  fclose(fileID);
  % submit the jobs
  cmd = [qsubscript ' ' batchname];
  fprintf(logfid,'executing: ssh %s "%s"\n',cluster,cmd);
  [s,m] = unix(sprintf('ssh %s "%s"',cluster,cmd));
  if s, fprintf(logfid,'%s',m); end
  cd(cwd);
  end
  fprintf(logfid,'Done!\n');    
else % process on local workstation
  % loop over elements of search space
  for specnum = 1:length(allspecs)
    spec = allspecs{specnum};
    try
      spec.simulation.SetName = spec.simulation.description;
    catch
      try
      a = regexp(spec.simulation.scope,'[\w,]+','match');
      b = regexp(spec.simulation.variable,'[\w,]+','match');
      c = regexp(spec.simulation.values,'\d+','match');
      spec.simulation.SetName = strrep(sprintf('%s_%s_%s',a{1},b{1},c{1}),',','_');
      catch
        spec.simulation.SetName = num2str(specnum);
      end
    end
    fprintf(logfid,'processing simulation...');
    simdriver(spec);
    fprintf(logfid,'done (%g of %g)\n',specnum,length(allspecs));
  end
end

if ~keep_flag
  fprintf(logfid,'Removing specification directory: %s\n',specpath);
  [s,m] = unix(sprintf('rm -rf %s',specpath));
else
  fprintf(logfid,'Adding parse-complete indicator file ''parsed'' to %s\n',specpath);
  [s,m] = unix(sprintf('echo "studydriver(''%s'',''%s'',%g);" > %s/parsed',specpath,logfile,keep_flag,specpath));
end
if s
  fprintf(logfid,'%s',m);
end

fprintf(logfid,'Parsing complete.\n');

end % end main function


