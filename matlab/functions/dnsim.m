function varargout=dnsim(varargin)
%modeler(varargin);
varargout={};

if nargin<1
  dnsim_loader;
else
  if nargout>0
    varargout{1}=modeler(varargin{:});
  else
    modeler(varargin{:});
  end
end

function dnsim_loader
global cfg
% server info
cfg.webhost = '104.131.218.171'; % 'infinitebrain.org','104.131.218.171'
cfg.dbname = 'modulator';
cfg.dbuser = 'querydb'; % have all users use root to connect to DB and self to transfer files
cfg.dbpassword = 'publicaccess'; % 'publicaccess'
cfg.xfruser = 'publicuser';
cfg.xfrpassword = 'publicaccess';
cfg.ftp_port=21;
cfg.MEDIA_PATH = '/project/infinitebrain/media';
% user info
cfg.username = 'anonymous';
cfg.password = '';
cfg.user_id = 0;
cfg.is_authenticated = 0;
cfg.email = '';

% get list of local models
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

% % load all mechanism data
% if ~exist('allmechs')
%   [allmechlist,allmechfiles]=get_mechlist(DBPATH);
%   global allmechs
%   cnt=1;
%   for i=1:length(allmechfiles)
%     this = parse_mech_spec(allmechfiles{i},[]);
%     [fpath,fname,fext]=fileparts(allmechfiles{i});
%     this.label = fname;
%     this.file = allmechfiles{i};
%     if cnt==1
%       allmechs = this;
%     else
%       allmechs(cnt) = this;
%     end
%   end  
% end

d=dir(DBPATH);
files={d.name};
files=files(~cellfun(@isempty,regexp(files,'\w*.mat$','match')));
local_specfiles=cellfun(@(x)fullfile(DBPATH,x),files,'unif',0);
local_list_of_models=cellfun(@(x)strrep(x,'.mat',''),files,'unif',0);

% get list of remote models
% remote connection
try
  err=mym('open', cfg.webhost,cfg.dbuser,cfg.dbpassword);
catch
  err=1;
end
if err
  %disp('there was an error opening the database.'); 
  remote_list_of_models='';
  remote_ids=[];
else
  mym(['use ' cfg.dbname]);
  r = mym('select id,name from modeldb_model where level=''node'' and privacy=''public''');% and privacy=''public''');
  q = mym('select id,name from modeldb_model where level=''network'' and privacy=''public''');% and privacy=''public''');
  remote_list_of_models = cat(1,q.name,r.name);  
  remote_ids=[q.id; r.id];
  %remote_notes=cat(1,q.notes,r.notes);
  mym('close');
end; 

%% draw figure
bgcolor=[204 204 180]/255;
fontsize=12; 
fontweight='normal';
hfig=figure('tag','loader','color',bgcolor,'name','','NumberTitle','off','MenuBar','none');
% draw controls:
uicontrol('style','text','string','Dynamic Neural Simulator','fontsize',19,'units','normalized','position',[.1 .895 .8 .07],'backgroundcolor',bgcolor);
% build model
% uicontrol callback: @builmodel
uicontrol('style','pushbutton','units','normalized','position',[.1 .75 .375 .1],'string','New model','callback','modeler; close(findobj(''tag'',''loader''));','fontsize',fontsize,'fontweight',fontweight);
uicontrol('style','pushbutton','units','normalized','position',[.525 .75 .375 .1],'string','Load File(s)','Callback','modeler(''load_models''); close(findobj(''tag'',''loader''));','fontsize',fontsize,'fontweight',fontweight);
% load model from disk
% uicontrol callback: @loadmodel
uicontrol('style','text','string','local models','units','normalized','position',[.1 .6 .35 .07],'backgroundcolor',bgcolor,'fontweight','normal','fontsize',fontsize);
uicontrol('style','listbox','tag','locallist','units','normalized','position',[.1 .2 .35 .4],'string',local_list_of_models,'userdata',local_specfiles);
uicontrol('style','pushbutton','units','normalized','position',[.1 .1 .35 .09],'string','Load','callback',@loadmodel,'fontsize',fontsize,'fontweight',fontweight);

% download model from DB
% uicontrol callback: @downloadmodel
uicontrol('style','text','string','remote models','units','normalized','position',[.55 .6 .35 .07],'backgroundcolor',bgcolor,'fontweight','normal','fontsize',fontsize);
uicontrol('style','listbox','tag','remotelist','units','normalized','position',[.55 .2 .35 .4],'string',remote_list_of_models,'userdata',remote_ids,'ButtonDownFcn','i=get(gcbo,''userdata''); v=get(gcbo,''value''); web(sprintf(''http://infinitebrain.org/models/%g/'',i(v(1))));','TooltipString','right-click to open model web page for discussion');
uicontrol('style','pushbutton','units','normalized','position',[.55 .1 .35 .09],'string','Download','callback',@downloadmodel,'fontsize',fontsize,'fontweight',fontweight);
cb='web(''http://infinitebrain.org/models/'');';
uicontrol('style','pushbutton','units','normalized','position',[.55 .02 .35 .06],'string','@ infinitebrain.org','callback',cb,'fontsize',fontsize,'fontweight',fontweight,'ForegroundColor','b','backgroundcolor',bgcolor);
%uicontrol('style','text','units','normalized','position',[.55 .05 .35 .05],'string','(infinitebrain.org)','callback',cb,'ButtonDownFcn',cb,'fontsize',fontsize,'fontweight',fontweight,'backgroundcolor',bgcolor,'ForegroundColor','b','TooltipString','right-click to open model database at infinitebrain.org');

% % prepare table data
% header = {'name','local','site','id','notes'};%{'id','name','local','site'};
% format= {'char','logical','char','numeric','char'};%{'numeric','char','logical','char'};
% editable=[1 0 0 0 1]==1;%[0 1 0 0]==1;
% ud=remote_ids;
% data=cat(2,
% % remote model table
% uitable('parent',hfig,'units','normalized','position',[0 0 .35 1],'tag','mechtable','userdata',ud,...
%   'ColumnName',header,'ColumnFormat',format,'ColumnEditable',editable,'data',data,'CellSelectionCallback',@BrowserSelection);

% control to open Mechanism Browser:
uicontrol('style','pushbutton','units','normalized','position',[.1 .02 .35 .06],'string','Browse Mechanisms','callback',@MechanismBrowser,'ForegroundColor','b','backgroundcolor',bgcolor);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CALLBACKS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function loadmodel(src,evnt)
% load model => spec
h=findobj('tag','locallist');
data=get(h,'userdata');
value=get(h,'value');
if numel(value)<=0
  return;
end
file=data{value};
if exist(file)
  data=load(file);
  flds=fieldnames(data);
  try
    spec=data.(flds{1});
    if isstruct(spec)
      %[model,IC,functions,auxvars,spec] = buildmodel2(spec,'verbose',0);
%       for i=1:length(spec.cells)
%         if isempty(spec.cells(i).mechanisms) && iscell(spec.cells(i).mechanisms)
%           spec.cells(i).mechanisms=[];
%         end
%       end
      modeler(spec);
      close(findobj('tag','loader'));
    end
  end
end

% function webmodel(src,evnt)
% ids = get(findobj('tag','remotelist'),'userdata');
% v = get(findobj('tag','remotelist'),'value');
% ModelID = ids(v);
% web(sprintf('http://infinitebrain.org/models/%g/',ModelID));

function downloadmodel(src,evnt)
% download model => spec
% try
  spec=DB_LoadModel;
  modeler(spec);
  close(findobj('tag','loader'));
% end

function spec=DB_LoadModel
global cfg 

% what models to load:
ids = get(findobj('tag','remotelist'),'userdata');
v = get(findobj('tag','remotelist'),'value');
ModelID = ids(v);

% get file names of spec files on server
fprintf('getting file name on server...\n');
err=mym('open', cfg.webhost,cfg.dbuser,cfg.dbpassword);
if err
  disp('there was an error opening the database.'); 
  return;
else
  mym(['use ' cfg.dbname]);
  q = mym(['select file from modeldb_modelspec where model_id=' num2str(ModelID)]);
  jsonfile = q.file{1};
end
mym('close');

% retrieve spec file
fprintf('retrieving full model specification from server...\n');
% temp dir
target = pwd;
% remote info
[usermedia,modelfile] = fileparts(jsonfile);
usermedia = strrep(usermedia,cfg.MEDIA_PATH,'');
usermedia=fullfile(cfg.MEDIA_PATH,usermedia);
modelfile=[modelfile '.json'];
% ftp
f=ftp([cfg.webhost ':' num2str(cfg.ftp_port)],cfg.xfruser,cfg.xfrpassword); 
pasv(f);
cd(f,usermedia); 
mget(f,modelfile,target); 
close(f);

% convert to DNSim spec
fprintf('processing model specification and updating active model...\n');
tempfile = fullfile(target,modelfile);
[spec,jsonspec] = json2spec(tempfile);
delete(tempfile);
