function [list,files]=get_mechlist(DBPATH)
if nargin<1
  global BIOSIMROOT
  if ischar(BIOSIMROOT)
    DBPATH = fullfile(BIOSIMROOT,'database');
  else
    DBPATH = '~/research/modeling/database';
  end
end
if ~exist(DBPATH,'dir')
  DBPATH = '/space/mdeh3/9/halgdev/projects/jsherfey/code/modeler/database';
end
if ~exist(DBPATH,'dir')
  DBPATH = 'C:\Users\jsherfey\Desktop\My World\Code\modelers\database';
end
if ~exist(DBPATH,'dir')
  DBPATH = '/project/crc-nak/sherfey/code/research/modeling/database';
end
d=dir(DBPATH);
list = {d(cellfun(@(x)any(regexp(x,'.txt$')),{d.name})).name};
files = cellfun(@(x)fullfile(DBPATH,x),list,'unif',0);
