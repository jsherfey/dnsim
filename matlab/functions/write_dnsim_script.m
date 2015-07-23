function outfiles=write_dnsim_script(spec,modelname,mechfile_flag,overwrite_flag)
% Usage:
% write_dnsim_script(spec,0); % print script to command window
% write_dnsim_script(spec,[],0); % ask for modelname and write script to modelname.m
% write_dnsim_script(spec,[],1); % ask for modelname and write script and mech files to directory modelname
% write_dnsim_script(spec,modelanme,0); % write script to modelname.m
% write_dnsim_script(spec,modelanme,1); % write script and mech files to directory modelname
% Inputs:
% spec = model specification from dnsim
% modelname = name of model (if excluded or [], ask user to model name)
% mechfile_flag = {0 or 1}, whether to write separate mech .txt files
% Outputs:
% outfiles = cell array of strings listing files that were created
% -------------------------------------------------------------------------
if nargin<4, overwrite_flag=1; end
if nargin<3, mechfile_flag=1; end
if nargin<2 || isempty(modelname)
  answer = inputdlg('Model name:','Enter name');
  if isempty(answer), return; end
  modelname = answer{1};
end
if isfield(spec,'cells')
  spec.nodes=spec.cells;
  spec=rmfield(spec,'cells');
end
outfiles={};
cwd=pwd;

if mechfile_flag
  outdir=modelname;
  if exist(outdir,'dir') && ~overwrite_flag
    fprintf('model directory already exists: %s.\n',outdir);
    return;
  elseif exist(outdir,'dir') && overwrite_flag
    fprintf('overwriting model directory: %s.\n',outdir);
  end
  mkdir(outdir);
  cd(outdir);
else
  outdir=pwd;
end

if ischar(modelname)
  modelscript=[modelname '_dnsim.m'];
  fid=fopen(modelscript,'wt');
else
  modelscript=1;
  fid=1;
end
outfiles{end+1}=modelscript;

fprintf(fid,'%% Model: %s\n',modelname);
if mechfile_flag
  fprintf(fid,'cd %s;\n',pwd);
end
fprintf(fid,'spec=[];\n');

Nnodes=length(spec.nodes);
for i=1:Nnodes
  fprintf(fid,'spec.nodes(%g).label = ''%s'';\n',i,spec.nodes(i).label);
  fprintf(fid,'spec.nodes(%g).multiplicity = %g;\n',i,spec.nodes(i).multiplicity);
  fprintf(fid,'spec.nodes(%g).dynamics = {',i);
  ndyn=length(spec.nodes(i).dynamics);
  for j=1:ndyn
    fprintf(fid,'''%s''',strrep(spec.nodes(i).dynamics{j},'''',''''''));
    if j<ndyn
      fprintf(fid,',');
    end
  end
  fprintf(fid,'};\n');
  mechfiles=print_mechanism(spec.nodes(i),'nodes',i,fid,mechfile_flag,overwrite_flag);
  print_parameters(spec.nodes(i),'nodes',i,fid);
  if ~isempty(mechfiles), outfiles=cat(2,outfiles,mechfiles); end
end
if isfield(spec,'connections')
  for i=1:Nnodes
    for j=1:Nnodes
      if isempty(spec.connections(i,j).mechanisms)
        continue;
      end
      fprintf(fid,'spec.connections(%g,%g).label = ''%s-%s'';\n',i,j,spec.nodes(i).label,spec.nodes(j).label);
      mechfiles=print_mechanism(spec.connections(i,j),'connections',[i j],fid,mechfile_flag,overwrite_flag);
      print_parameters(spec.connections(i,j),'connections',[i j],fid);
      if ~isempty(mechfiles), outfiles=cat(2,outfiles,mechfiles); end
    end
  end
end

% % process specification and simulate model
% model=dnsim(spec); % dnsim(spec);
% data = biosim(model,'timelimits',[0 5000],'dt',.01,'dsfact',10);
% plotv(data,model,'varlabel','V');
% title(sprintf('stim=%g',stimLTS));

fprintf(fid,'%%dnsim(spec); %% open model in DNSim GUI\n\n');
try  
  [ODEFUN,IC,functions,auxvars,FULLSPEC,Sodes,Svars,txt]=buildmodel(spec,'verbose',0);
  vars=FULLSPEC.variables.global_oldlabel;
catch
  txt='';
end
fprintf(fid,'%% DNSim simulation and plots:\n');
fprintf(fid,'data = runsim(spec,''timelimits'',[0 100],''dt'',.02,''SOLVER'',''euler''); %% simulate DNSim models\n');
if ~isempty(txt) % got vars from buildmodel
  fprintf(fid,'plotv(data,spec,''varlabel'',''%s''); %% quickly plot select variables\n',vars{1});
end
fprintf(fid,'%%visualizer(data); %% ugly interactive tool hijacked to visualize sim_data\n');
if ~isempty(txt) % got vars from buildmodel
  fprintf(fid,'\n%% Sweep over parameter values:\n');
  fprintf(fid,'model=buildmodel(spec); %% parse DNSim spec structure\n');
  fprintf(fid,'simstudy(model,{''%s''},{''N''},{''[1 2]''},''timelimits'',[0 100],''dt'',.02,''SOLVER'',''euler''); %% N = # of cells\n\n',spec.nodes(1).label);
  fprintf(fid,'\n%% Manual simulation and plots:\n');
  %fprintf(fid,'[t,y]=ode23(ODEFUN,[0 100],IC); %% numerical integration\n');
  %fprintf(fid,'figure; plot(t,y); %% plot all variables/functions\n');
  fprintf(fid,'%%{\n');
  txt=regexp(txt,'%-.*%-','match');
  fprintf(fid,'%s\n',txt{:});
  fprintf(fid,'%%}\n');
end
cd(cwd);

function outfiles=print_mechanism(s,type,i,fid,mechfile_flag,overwrite_flag)
  outfiles={};
  if numel(i)==1
    ii=num2str(i);
  else
    ii=sprintf('%g,%g',i);
  end
  if mechfile_flag
    prefix=[strrep(s.label,'-','_') '_'];
  else
    prefix='';
  end
  nmechs=length(s.mechanisms);
  if nmechs==0
    fprintf(fid,'spec.%s(%s).mechanisms = [];\n',type,ii);
  else
    fprintf(fid,'spec.%s(%s).mechanisms = {',type,ii);
    for j=1:nmechs
      fprintf(fid,'''%s%s''',prefix,s.mechanisms{j});
      if j<nmechs
        fprintf(fid,',');
      end
    end
    fprintf(fid,'};\n');
  end
  if mechfile_flag
    for j=1:nmechs
      tmpfile=[prefix s.mechanisms{j} '.txt']; %fullfile(pwd,[prefix s.mechanisms{j}]);
      if exist(tmpfile,'file') && ~overwrite_flag
        fprintf('skipping mech file, already exists: %s\n',tmpfile);
        continue;
      elseif exist(tmpfile,'file') && overwrite_flag
        fprintf('overwriting mech file: %s\n',tmpfile);
      end        
      outfiles{end+1}=tmpfile;
      txt = mech_spec2str(s.mechs(j));
      fid2=fopen(tmpfile,'wt');
      for k=1:length(txt)
        fprintf(fid2,[txt{k} '\n']);
      end
      fclose(fid2);
      fprintf('mechanism written to file: %s\n',tmpfile);
    end
  end

function print_parameters(s,type,i,fid)
  if numel(i)==1
    ii=num2str(i);
  else
    ii=sprintf('%g,%g',i);
  end
  nparms=length(s.parameters);
  if nparms==0
    fprintf(fid,'spec.%s(%s).parameters = [];\n',type,ii);
  else
    fprintf(fid,'spec.%s(%s).parameters = {',type,ii);
    for j=1:nparms
      parm=s.parameters{j};
      if ischar(parm)
        fprintf(fid,'''%s''',parm);
      elseif isnumeric(parm)
        fprintf(fid,'%g',parm);
      end
      if j<nparms
        fprintf(fid,',');
      end
    end
    fprintf(fid,'};\n');
  end

function txt = mech_spec2str(mech)
% Purpose: prepare text to display mech model parameters and equations
txt = {}; n=0;
if isempty(mech)
  return;
end
% print parameters
if ~isempty(mech.params)
  keys=fieldnames(mech.params);
  vals=struct2cell(mech.params);
  for i=1:length(keys)
    if i==1, n=n+1; txt{n}=sprintf('%% Parameters:'); end
    n=n+1; txt{n}=sprintf('%s = %s',keys{i},dat2str(vals{i}));
    if i==length(keys), n=n+1; txt{n}=sprintf(' '); end
  end
end
% print auxiliary functions
for i=1:size(mech.auxvars,1)
  if i==1, n=n+1; txt{n}=sprintf('%% Auxiliary variables:'); end
  n=n+1; txt{n}=sprintf('%s = %s',mech.auxvars{i,1},dat2str(mech.auxvars{i,2}));
  if i==size(mech.auxvars,1), n=n+1; txt{n}=sprintf(''); end
end
% print functions
for i=1:size(mech.functions,1)
  if i==1, n=n+1; txt{n}=sprintf('%% Functions:'); end
  % put in a form that parse_mech_spec() can process
  tmp = sprintf('%s = %s',mech.functions{i,:});
  lhs = regexp(tmp,'^\w+','match'); lhs=lhs{1};
  var = regexp(tmp,'@\([\w,]+\)','match'); var=var{1};
  rhs = regexp(tmp,'@\([\w,]+\).+$','match'); rhs=rhs{1};
  rhs = strtrim(strrep(rhs,var,''));
  var = var(2:end);
  tmp = sprintf('%s%s = %s',lhs,var,rhs);
  n=n+1; txt{n}=tmp;%sprintf('%s = %s',tmp);
  if i==size(mech.functions,1), n=n+1; txt{n}=sprintf(' '); end
end
% print odes
for i=1:size(mech.odes,1)
  if i==1, n=n+1; txt{n}=sprintf('%% ODEs:'); end
  n=n+1; txt{n}=sprintf('%s'' = %s',mech.statevars{i},mech.odes{i});
  n=n+1; txt{n}=sprintf('%s(0) = %s',mech.statevars{i},dat2str(mech.ic{i}));
  if i==size(mech.odes,1), n=n+1; txt{n}=sprintf(' '); end
end
% print interface statements
for i=1:size(mech.substitute,1)
  if size(mech.substitute,1)==1 && strcmp(mech.substitute{i,1},'null') && strcmp(mech.substitute{i,2},'null')
    break;
  end
  if i==1, n=n+1; txt{n}=sprintf('%% Interface:'); end%Expose and/or insert into compartment dynamics:'); end
  n=n+1; txt{n}=sprintf('%s => %s',mech.substitute{i,:});
  if i==size(mech.substitute,1), n=n+1; txt{n}=sprintf(' '); end
end
function val=dat2str(val)
% purpose: convert various data classes into a character form for readable display
if isnumeric(val)
  val = ['[' num2str(val) ']'];
elseif ischar(val)
  % do nothing
else
  val = 'unrecognized';
end

% s=[];
% s.nodes.label='test';
% s.nodes.multiplicity=1;
% s.nodes.dynamics='v''=current';
% s.nodes.mechanisms={'iNa','iK','itonic'};
% s.nodes.parameters={'stim',15};
% dnsim(s);
% 
% s=[];
% s.nodes.label='test';
% s.nodes.multiplicity=1;
% s.nodes.dynamics='v''=current';
% s.nodes.mechanisms={'iNa','iK','itonic'};
% s.nodes.parameters={'stim',15};
% s.connections.label='test-test';
% s.connections.mechanisms={'iSYN'};
% dnsim(s);









