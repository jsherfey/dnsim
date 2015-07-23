function [allfeatures,cellids] = getfeatures(files,type,funlist,allparms)
% Purpose: extract features sets from a list of experimental and simulated
% data files.
if nargin<2, type='sim'; end
if nargin<3, funlist=[]; elseif ischar(funlist), funlist={funlist}; end
if nargin<4, allparms=[]; end
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
% extract features
allfeatures = cell(1,length(files));
for i=1:length(files)
  file = files{i};
  [fpath,fname] = fileparts(file);
  setfile = fullfile(fpath,[fname '_features.mat']);
  if exist(setfile,'file')
    fprintf('file %g of %g. loading features for %s\n',i,length(files),file);
    load(setfile,'features');
  else
    fprintf('file %g of %g. extracting features from %s\n',i,length(files),file);
    if numel(allparms)>1, p=allparms(i); else p=allparms; end
    [features,parms] = CharacterizeCells(file,type,funlist,p);
    fprintf('saving features to %s\n',setfile);
    save(setfile,'features','parms','file','type','funlist');
  end
  allfeatures{i} = features;
end
