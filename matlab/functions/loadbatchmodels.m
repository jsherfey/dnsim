function [allspecs,allspaces,allscopes,allvariables,uniq_allscopes,uniq_allvars, allfiles,uniq_allvals] = loadbatchmodels(batchdirs)
% purpose: load specs and (scope,var,val) across simstudy batches into paramspaces
% example:
% batchdirs{1}='/projectnb/crc-nak/sherfey/20140316-193925_CBsynparams/CB-multiplicity__CB-Ed-span-tauDx-gSYN__I-multiplicity__I-E-gSYN';
% batchdirs{2}='/projectnb/crc-nak/sherfey/20140316-224054_gSYNstoEcell/CB-multiplicity__CB-Ed-gSYN__E+Ed-multiplicity__E-Ed-gSYN__I-E-gSYN';
% [specs,spaces,scopes,vars,uscope,uvars]=loadbatchmodels(batchdirs);
if ~iscell(batchdirs), batchdirs={batchdirs}; end
batchdirs=unique(batchdirs);
nbatches=length(batchdirs);

% load paramspaces from all simstudy batches
allspecs={}; allspaces={}; allscopes={}; allvariables={}; allfiles={};
for d=1:nbatches
  fprintf('loading batch dir %g of %g: %s\n',d,nbatches,batchdirs{d});
  specdir=fullfile(batchdirs{d},'model');
  D=dir(specdir); files={D(~[D.isdir]).name}; nfiles=length(files);
  nvars=0; paramspace={}; clear specs
  for f=1:nfiles
    if mod(f,25)==0, fprintf('file %g of %g\n',f,nfiles); end
    r=load(fullfile(specdir,files{f}));
    allfiles{d}{f,1}=fullfile(specdir,files{f});
    if ~isfield(r.spec,'entities') && isfield(r.spec,'cells')
        r.spec.entities=r.spec.cells;
    end
    l={r.spec.entities.label};
    scope   =regexp(r.spec.simulation.scope,'([\w-,]+)','match');
    variable=regexp(r.spec.simulation.variable,'([\w-,]+)','match');
    value   =regexp(r.spec.simulation.values,'([\w-,.]+)','match');
    if nvars==0
      nvars=length(scope);
      paramspace=cell(nfiles,nvars);
      allscopes{d}=scope;
      allvariables{d}=variable;
    end
    if isfield(r.spec,'history')
      r.spec=rmfield(r.spec,'history');
    end
    if f==2
      specs = repmat(specs,nfiles,1);
      fld1=fieldnames(specs(1,1)); 
    end
    if f>=2
      fld2=fieldnames(r.spec);
      if ~isequal(fld1,fld2)
        r.spec=rmfield(r.spec,setdiff(fld2,fld1));
      end
    end
    paramspace(f,:)=value;
    specs(f,1)=r.spec;
  end
  allspecs{d} = specs;
  allspaces{d}=paramspace;
end

% display param space info
uniq_allscopes={}; uniq_allvars={}; allassign={};
for d=1:nbatches
  fprintf('batch %g\n',d);
  for i=1:length(allscopes{d})
    fprintf('\t%-10s.%-20s = ',allscopes{d}{i},allvariables{d}{i});
    assign=sprintf('%s.%s',allscopes{d}{i},allvariables{d}{i});
    if ~ismember(assign,allassign)
      allassign{end+1}=assign;
      uniq_allscopes{end+1}=allscopes{d}{i};
      uniq_allvars{end+1}=allvariables{d}{i};
    end
    for j=1:size(allspaces{d},1)
      fprintf('%-5s ',[allspaces{d}{j,i} ',']);
    end
    fprintf('\n');
  end
end
uniq_allvals={};
for i=1:nvars
  uniq_allvals{i}=unique(paramspace(:,i));
  uniq_allvals{i}=cellfun(@(x)[x ','],uniq_allvals{i},'uni',0);
  uniq_allvals{i}=[uniq_allvals{i}{:}];
  uniq_allvals{i}=uniq_allvals{i}(1:end-1);
end
  
%uniq_allscopes = unique([allscopes{:}]);
%uniq_allvars = unique([all
fprintf('unique things varied across batches:\n');
for i=1:length(uniq_allscopes)
  fprintf('%s.%s [%s]\n',uniq_allscopes{i},uniq_allvars{i},uniq_allvals{i});
end
