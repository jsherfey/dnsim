function MechanismBrowser(src,evnt)
global cfg allmechs

if isempty(allmechs)
  if exist('startup.m')
    [BIOSIMROOT,o]=fileparts(which('startup.m'));
  else
    BIOSIMROOT=pwd;
  end  
  if ischar(BIOSIMROOT)
    DBPATH = fullfile(BIOSIMROOT,'database');
  else
    DBPATH = '';
  end
  if ~exist(DBPATH,'dir')
    DBPATH = pwd;
  end  
  [allmechlist,allmechfiles]=get_mechlist(DBPATH);
  % load all mech data
  global allmechs
  cnt=1;
  for i=1:length(allmechfiles)
    this = parse_mech_spec(allmechfiles{i},[]);
    [fpath,fname,fext]=fileparts(allmechfiles{i});
    this.label = fname;
    this.file = allmechfiles{i};
    if cnt==1
      allmechs = this;
    else
      allmechs(cnt) = this;
    end
    cnt=cnt+1;
  end  
end

% get list of local mechanisms
localmechs = {allmechs.label};
localfiles = {allmechs.file};

% get list of remote mechanisms
try
  err=mym('open', cfg.webhost,cfg.dbuser,cfg.dbpassword);
  mym(['use ' cfg.dbname]);
  level = 'mechanism';
  % if cfg.is_authenticated
  %   q = mym(sprintf('select id,name,level,notes from modeldb_model where user_id=%g and level=''%s''',cfg.user_id,level));
  % else
    q = mym(sprintf('select id,name,level,notes from modeldb_model where level=''%s''',level));
  % end
  remotemechs = q.name';   % todo: sort so that mechs of an authenticated user are listed first
  remoteids=q.id';
  remotenotes=q.notes';
  mym('close');    
catch
  remotemechs = '';
  remoteids=[];
  remotenotes='';
end

% find "files" elements that are actually primary keys of remote mech models prefixed by "#"
localremote_ind = find(~cellfun(@isempty,regexp(localfiles,'^#\d+'))); 
% remove remote mechs that are already present in the local allmechs struct
if any(localremote_ind)
  redundant_ids = cellfun(@(x)strrep(x,'#',''),localfiles(localremote_ind),'unif',0);
  redundant_ids = cellfun(@str2num,redundant_ids);
  rmidx = ismember(remoteids,redundant_ids);
  remotemechs(rmidx)=[];
  remoteids(rmidx)=[];
  remotenotes(rmidx)=[];
end

% prepare table data
header = {'name','site','description','local','id'};%{'name','local','site','id','notes'};%{'id','name','local','site'};
format= {'char','char','char','logical','numeric'};%{'numeric','char','logical','char'};
editable=[1 0 1 0 0]==1;%[0 1 0 0]==1;
localnotes=repmat({''},[1 length(localmechs)]);
localids=zeros(1,length(localmechs));
if any(localremote_ind)
  localids(localremote_ind)=redundant_ids;
end
ids=[remoteids localids];
names=cat(2,remotemechs,localmechs);
local=[zeros(1,length(remoteids)) ones(1,length(localmechs))]==1;
gosite=repmat({'link'},[1 length(local)]);
[gosite{ids==0}]=deal(''); % remove links for mechs without key in DB (ie, w/o Django site)
allnotes=cat(2,remotenotes,localnotes);
data=cat(2,names',gosite',allnotes',num2cell(local'),num2cell(ids'));%data=cat(2,num2cell(ids'),names',num2cell(local'),gosite');
%data=cat(2,names',num2cell(local'),gosite',num2cell(ids'),allnotes');%data=cat(2,num2cell(ids'),names',num2cell(local'),gosite');
ud.storage=cat(2,num2cell(remoteids),localfiles);
ud.mechindex=cat(2,zeros(1,length(remoteids)),(1:length(localmechs)));

% draw figure
% pos=get(findobj('tag','mainfig'),'position');
% if iscell(pos), pos=pos{1}; end
% pos(4)=.8*pos(4); % [10 30 800 510]
pos=[7 30 1354 522];
bgcolor=[204 204 180]/255;
h=findobj('tag','mechbrowser');
if any(h)
  figure(h(end));
else
  h=figure('tag','mechbrowser','position',pos,'color',bgcolor,'name','Browse Mechanisms','NumberTitle','off','MenuBar','none');
end
% draw controls
% mechanism table
uitable('parent',h,'units','normalized','position',[0 0 .35 1],'tag','mechtable','userdata',ud,...
  'ColumnName',header,'ColumnFormat',format,'ColumnEditable',editable,'data',data,'CellSelectionCallback',@BrowserSelection,'CellEditCallback',@BrowserChange);
% mechanism text box
uicontrol('parent',h,'style','text','units','normalized','position',[.38 0 .59 .9],'tag','mechtext','BackgroundColor',[.9 .9 .9],'string','','FontName','Monospaced','FontSize',10,'HorizontalAlignment','Left');
% -------------------------------------------------------------------------
function BrowserSelection(src,evnt)
if isempty(evnt.Indices)
  return;
end
global allmechs cfg
row=evnt.Indices(1);
col=evnt.Indices(2);
dat=get(src,'Data'); % {name,site,notes,local,id}
if col==2 % site
  if dat{row,5}>0 % has a primary key to a DB mech model in InfiniteBrain
    % goto model detail page
    web(sprintf('http://infinitebrain.org/models/%g/',dat{row,5}));
  end
end
if isequal(row,get(findobj('tag','mechtext'),'userdata'))
  return;
end
ud=get(src,'userdata'); % storage (sql:id, disk:file), mechindex (index into allmechs struct)
store=ud.storage{row}; % numeric id or filename
index=ud.mechindex(row); % index in allmechs or 0

id=dat{row,5};
name=dat{row,1};
islocal=(dat{row,4}==true);
if islocal
  mech = allmechs(index);
  if exist(mech.file)
    fid=fopen(mech.file); % open local mechanism file
    txt={};
    while (~feof(fid))
      this = fgetl(fid);
      if this == -1, break; end      
      txt{end+1}=this;
    end
    fclose(fid); % close mech file
    set(findobj('tag','mechtext'),'string',txt,'userdata',row);
  else
    set(findobj('tag','mechtext'),'string',mech_spec2str(mech),'userdata',row);
  end  
%   mech = allmechs(index);
%   set(findobj('tag','mechtext'),'string',mech_spec2str(mech),'userdata',row);
else
  % download & convert mech.txt to mech structure; add to allmechs
  %mech = getmechfromdb(id);
  mech = download_get_models(id,cfg);
  if iscell(mech), mech = mech{1}; end
  mech.label = name;
  mech.file = sprintf('#%g',id);
  allmechs(end+1)=mech;
  set(findobj('tag','mechtext'),'string',mech_spec2str(mech),'userdata',row);
  ud.mechindex(row)=length(allmechs);
  set(src,'userdata',ud);
  dat{row,4}=true;
  set(src,'Data',dat);
end
% -------------------------------------------------------------------------
function BrowserChange(src,evnt)
global allmechs
row=evnt.Indices(1);
col=evnt.Indices(2);
dat=get(src,'Data'); 
ud=get(src,'userdata');
switch col % {name,site,notes,local,id}
  case 1 % mechanism name column
    ind=ud.mechindex(row);
    if ind>0
      allmechs(ind).label = dat{row,col};
    end
  case 2
    if dat{row,5}>0 % has a primary key to a DB mech model in InfiniteBrain
      % goto model detail page
      web(sprintf('http://infinitebrain.org/models/%g/',dat{row,5}));
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
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
  if i==1, n=n+1; txt{n}=sprintf('%% Substitution:'); end%Expose and/or insert into compartment dynamics:'); end
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
function specs = download_get_models(ModelIDs,cfg)
% -- prepare list of model specs from list of Model IDs
target = pwd; % local directory for temporary files
specs={};
% Open MySQL DB connection
err=mym('open', cfg.webhost,cfg.dbuser,cfg.dbpassword);
if err
  disp('there was an error opening the database.'); 
  return;
else
  mym(['use ' cfg.dbname]);
end
% Open ftp connection
try
  f=ftp([cfg.webhost ':' num2str(cfg.ftp_port)],cfg.xfruser,cfg.xfrpassword);
  pasv(f);
catch err
  mym('close');
  disp('there was an error connecting (ftp) to the server.');
  rethrow(err);
end
% Get models from server
for i = 1:length(ModelIDs)
  ModelID=ModelIDs(i);
  % get file names of spec files on server
  fprintf('Model(uid=%g): getting file name and file from server\n',ModelID);
  q = mym(['select file from modeldb_modelspec where model_id=' num2str(ModelID)]);
  jsonfile = q.file{1};
  % retrieve json spec file
  [usermedia,modelfile,ext] = fileparts(jsonfile); % remote server media directory
  if isempty(ext)
    ext='.json';
  end
  usermedia=fullfile(cfg.MEDIA_PATH,usermedia);
  modelfile=[modelfile ext];%'.json'];
  cd(f,usermedia);
  mget(f,modelfile,target);
  % convert json spec to matlab spec structure
  fprintf('Model(uid=%g): converting model specification to matlab structure\n',ModelID);
  tempfile = fullfile(target,modelfile);
  if isequal(ext,'.json')
    [spec,jsonspec] = json2spec(tempfile);
    spec.model_uid=ModelID;
  elseif isequal(ext,'.txt')
    spec = parse_mech_spec(tempfile,[]);
  else
    spec = [];
  end
  specs{end+1}=spec;
  % clean up
  delete(tempfile);
end
close(f);
mym('close');
