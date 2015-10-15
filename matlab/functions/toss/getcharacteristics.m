function [allresults,cellids,allparms,setfiles] = getcharacteristics(files,type,funlist,allparms)
% Purpose: extract features sets from a list of experimental and simulated
% data files.
if nargin<2, type='sim'; end
if nargin<3, funlist=[]; elseif ischar(funlist), funlist={funlist}; end
if nargin<4, allparms=[]; end
setfiles={};
if strcmpi(type,'exp') && ischar(allparms) && isdir(files)
  %  get list of files, load parameters, and match files w/ their params
  datapath = files;
  d = dir(datapath);
  d = {d(~[d.isdir]).name};
  datafiles = d(~cellfun(@isempty,regexp(d,'.mat$')));
  p = ParamXls1TA(allparms);
  parms = []; rm=[];
  for i=1:length(datafiles)
    cellidx=regexp(datafiles{i},'ci\d+','match');
    cellidx=str2num(cellidx{1}(3:end));
    tmp = p(cellfun(@(x)isequal(x,cellidx),{p.cell_idx}));
    if isempty(tmp)
      rm=[rm i]; 
      fprintf('skipping cell %g, param info not found\n',cellidx);
      continue; 
    end
    parms = [parms tmp(1)];
    datafiles{i} = fullfile(datapath,datafiles{i});
  end
  datafiles(rm)=[];
  cellids = [parms.cell_idx];
  [cellids,I] = sort(cellids);
  files = datafiles(I);  
  allparms = parms;
else
  cellids = [];
end
if ischar(files), files = {files}; end
% extract features
allresults = cell(1,length(files));
for i=1:length(files)
  file = files{i};
  if ischar(file) % this is a filename
    [fpath,fname] = fileparts(file);
    fprintf('file %g of %g. extracting characteristics from %s\n',i,length(files),file);
  elseif isstruct(file) && isfield(file,'rootoutdir') && isfield(file,'prefix');
    fpath = file.rootoutdir;
    fname = file.prefix;
    fprintf('data %g of %g: extracting characteristics...\n',i,length(files));
  else
    fpath=pwd;
    fname='proc_characterize';
  end
  if ~exist(fullfile(fpath,'cell_characteristics'),'dir')
    mkdir(fullfile(fpath,'cell_characteristics'));
  end
  setfile = fullfile(fpath,'cell_characteristics',[fname '_cell-characteristics.mat']);
  if exist(setfile,'file')
    fprintf('file %g of %g. loading characteristics from %s\n',i,length(files),setfile);
    load(setfile,'results');
  else
    if numel(allparms)>1, p=allparms(i); else p=allparms; end
    try
      [results,parms] = CharacterizeCells(file,type,funlist,p);
      fprintf('Saving characteristics to %s\n',setfile);
      if ischar(file)
        save(setfile,'results','parms','file','type','funlist');
      else
        save(setfile,'results','parms','type','funlist');
      end
    catch err
      if ischar(file)
        fprintf('Failed to characterize %s\n',file);
      else
        fprintf('Failed to characterize data %g of %g\n',i,length(files));
      end
      fprintf('Error: %s\n',err.message);
      for l=1:length(err.stack)
        fprintf('\t in %s (line %g)\n',err.stack(l).name,err.stack(l).line);
      end      
      results = [];
    end
  end
  allresults{i} = results;
  setfiles{i} = setfile;
end
