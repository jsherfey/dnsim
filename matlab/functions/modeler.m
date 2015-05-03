function varargout=modeler(varargin)
clear global cfg H CURRSPEC BACKUPFILE
cfg.mysql_connector = mysqldb('setup'); % call this first b/c javaaddpath clears global variables (see: http://www.mathworks.com/matlabcentral/newsreader/view_thread/163362)
% if ~isdeployed && nargout==0
%   try
%     if ~exist('ganymed-ssh2-build250','dir')
%       sshfrommatlabinstall(1); % run at tool launch before setting global vars
%     else
%       sshfrommatlabinstall;
%     end
%   end
% end
global cfg H CURRSPEC LASTSPEC BIOSIMROOT BACKUPFILE
% Path to local models on disk
if isempty(BIOSIMROOT)
  [BIOSIMROOT,o]=fileparts(which('startup.m'));
end
if ischar(BIOSIMROOT)
  DBPATH = fullfile(BIOSIMROOT,'database');
else
  DBPATH = '';
end
if ~exist(DBPATH,'dir')
  DBPATH = pwd;
end
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
cfg.uploadname='';
cfg.uploadnotes='';
cfg.uploadtags='';
cfg.projectname='';
cfg.citationtitle='';
cfg.citationstring='';
cfg.citationurl='';
cfg.citationabout='';

% local user info
[o,r]=system('echo $HOME'); % get home directory
if numel(r)>1
  r=r(1:end-1);
elseif isempty(r)
  r=pwd;
end
tempdir=fullfile(r,'.dsim');
if ~exist(tempdir,'dir')
  try
    mkdir(tempdir);
  catch
    tempdir=pwd;
  end
end
cfg.tempdir=tempdir;
BACKUPFILE=fullfile(tempdir,['autodsim_' datestr(now,'yyyymmdd-HHMMSS') '.mat']);
% if nargin==0 && exist(BACKUPFILE,'file')
                  % NOTE: this will never exist as long as the backup filename is uniquely timestamped
%   try
%     load(BACKUPFILE,'spec');
%     varargin{1}=spec;
%   end
% end

warning off

if (nargin<1 && isempty(varargin)) || ischar(varargin{1})
  net=[];
else
  net = varargin{1};
end
if ~isempty(varargin) && ischar(varargin{1}) && strcmp(varargin{1},'load_models')
  load_models_flag=1;
else
  load_models_flag=0;
end
% ----------------------------------
if isfield(net,'nodes')
  net.cells=net.nodes;
  net=rmfield(net,'nodes');
end
if ~isfield(net,'cells')
  if isfield(net,'entities')
    net.cells = net.entities;
    net = rmfield(net,'entities');
  else
    tmpnet.cells=net;
    net=tmpnet;
    clear tmpnets
  end
end
if isfield(net.cells,'files'), net.files = net.cells(1).files; end
if ~isfield(net.cells,'label')
  for i=1:length(net.cells)
    net.cells(i).label=sprintf('cell%g',i);
  end
end
if ~isfield(net.cells,'multiplicity')
  for i=1:length(net.cells)
    net.cells(i).multiplicity = 1;
  end
end
if ~isfield(net.cells,'parameters')
  for i=1:length(net.cells)
    net.cells(i).parameters = [];
  end
end
if ~isfield(net.cells,'parent') && isfield(net.cells,'label')
  for i=1:length(net.cells)
    net.cells(i).parent=net.cells(i).label;
  end
end
if ~isfield(net,'connections')
  net.connections.mechanisms=[];
  net.connections.parameters=[];
  net.connections.label = [];
  [net.connections(1:numel(net.cells),1:numel(net.cells))] = deal(net.connections);
end
if ~isfield(net.connections,'parameters')
  for i=1:numel(net.connections)
    net.connections(i).parameters = [];
  end
end
% get list of all known mechs (stored in DB)
% TODO: read list fom MySQL DB (see http://introdeebee.wordpress.com/2013/02/22/connecting-matlab-to-mysql-database-using-odbc-open-database-connector-for-windows-7/)
[allmechlist,allmechfiles]=get_mechlist(DBPATH);
allmechfiles_db=allmechfiles;
% use stored mechs if user did not provide list of mech files
if ~isfield(net,'files') || isempty(net.files)
  selmechlist=allmechlist;
  selmechfiles=allmechfiles;
elseif ischar(net.files) && exist(net.files,'dir')
  % user provided a directory that contains the user mech files
  d=dir(net.files);
  selmechlist = {d(cellfun(@(x)any(regexp(x,'.txt$')),{d.name})).name};
  allmechlist = {selmechlist{:} allmechlist{:}}; % prepend user mechs
  selmechfiles = cellfun(@(x)fullfile(DBPATH,x),net.files,'unif',0);
  allmechfiles = {selmechfiles{:} allmechfiles{:}};
elseif iscellstr(net.files)
  % todo: get mechs from spec
  selmechfiles = net.files(cellfun(@(x)any(regexp(x,'.txt$')),net.files));
  allmechfiles = unique({selmechfiles{:} allmechfiles{:}});
  selmechlist = cell(size(selmechfiles));
  for i=1:length(selmechfiles)
    [fpath,fname]=fileparts(selmechfiles{i});
    selmechlist{i}=fname;
  end
end
% only keep mech selection matching those included in the cell
if isfield(net.cells,'mechanisms')
  cellmechs={net.cells.mechanisms}; cellmechs=[cellmechs{:}];
  connmechs={net.connections.mechanisms};
  connmechs=connmechs(~cellfun(@isempty,connmechs));
  if ~iscell(cellmechs), cellmechs={cellmechs}; end
  if ~iscell(connmechs), connmechs={connmechs}; end
  if any(cellfun(@iscell,connmechs))
    connmechs=[connmechs{:}];
  end
  cellmechs={cellmechs{:} connmechs{:}};
  selmechlist = cellfun(@(x)strrep(x,'.txt',''),selmechlist,'unif',0);
  sel=cellfun(@(x)any(strmatch(x,cellmechs,'exact')),selmechlist);
  selmechlist = selmechlist(sel);
  selmechfiles = selmechfiles(sel);
  net.files = selmechfiles;
end
if ~isfield(net,'history')
  net.history=[];
end
if ~isfield(net,'model_uid')
  net.model_uid=[];
end
if ~isfield(net,'parent_uids');
  net.parent_uids=[];
end
if isempty(net.cells)
  net.cells.label='node';
  net.cells.multiplicity=1;
  net.cells.dynamics={};%'';%'V''=0';
  net.cells.mechanisms={};
  net.cells.parameters=[];
  net.cells.parent='x';
  net.cells.mechs=[];
  focusmech=[];
else
  focusmech=1;
end
% load all mech data
global allmechs
cnt=1; rmsel=[];
for i=1:length(allmechfiles)
  try
    this = parse_mech_spec(allmechfiles{i},[]);
    [fpath,fname,fext]=fileparts(allmechfiles{i});
    this.label = fname;
    this.file = allmechfiles{i};
    if cnt==1, allmechs = this;
    else allmechs(cnt) = this;
    end
    cnt=cnt+1;
  catch
    fprintf('removing mech. failed to load: %s\n',allmechfiles{i});
    rmsel=[rmsel i];
  end
end
if ~isempty(rmsel)
  allmechfiles(rmsel)=[];
end
% global allmechs
% for i=1:length(allmechfiles)
%   this = parse_mech_spec(allmechfiles{i},[]);
%   [fpath,fname,fext]=fileparts(allmechfiles{i});
%   this.label = fname;
%   this.file = allmechfiles{i};
%   if i==1, allmechs = this;
%   else allmechs(i) = this;
%   end
% end
% initialize config
cfg.focuscomp = 1; % index to component-of-focus in spec.cells (start w/ root)
cfg.focusconn = 1;
cfg.focustype = 'cells';
cfg.focus=1;
cfg.focuscolor = [.7 .7 .7];
cfg.pauseflag = -1;
cfg.quitflag = 1;
cfg.plotchange = 0;
cfg.plottype = 'trace'; % 'trace' or 'image'
cfg.changeflag = -1;
cfg.publish = 0;
cfg.tlast=-inf;
cfg.buffer = 20000;%10000;
cfg.dt = .01;
for i=1:length(net.cells), cfg.userparams{i} = net.cells(i).parameters; end
cfg.changes = {};
cfg.lastchanges = {};
cfg.allmechfiles = allmechfiles;
cfg.allmechfiles_db = allmechfiles_db;
cfg.DBPATH = DBPATH;
cfg.T=(0:cfg.buffer-1)*cfg.dt; % ms
cfg.V=linspace(-100,100,cfg.buffer); % mV
cfg.colors  = 'kbrgmy';
cfg.lntype  = {'-',':','-.','--'};
cfg.newmechs={};
cfg.modeltext='';

% cfg.bgcolor=[204 204 153]/255;
% cfg.bgcolor=[204 204 168]/255;
cfg.bgcolor=[204 204 180]/255;

% bgcolor=[204 204 255]/255;
% [0.701961 0.701961 0.701961]

LASTSPEC = net;
CURRSPEC = net;

% prepare_spec;
updatemodel(CURRSPEC);
CURRSPEC = trimparams(CURRSPEC);

if nargout>0
  varargout{1}=CURRSPEC;
  return
else
  varargout={};
end

%% set up GUI

% bgcolor=[204 204 255]/255;
% bgcolor=[204 204 153]/255;
% [0.701961 0.701961 0.701961]
bgcolor = cfg.bgcolor;

% main figure
sz = get(0,'ScreenSize'); sz0=sz;
sz = [.005*sz(3) .005*sz(4) .97*sz(3) .85*sz(4)];
fig = findobj('tag','mainfig');
try
  if ~any(strfind(version,'R2014b')) && any(fig)
    figure(fig);
  else
    fig = figure('position',sz,'color','w','tag','mainfig','name','Dynamic Neural Simulator','NumberTitle','off','WindowScrollWheelFcn',@ZoomFunction,'CloseRequestFcn','delete(gcf); clear global H'); % [320 240 920 560]
  end
catch
  fig = figure('position',sz,'color','w','tag','mainfig','name','Dynamic Neural Simulator','NumberTitle','off','WindowScrollWheelFcn',@ZoomFunction,'CloseRequestFcn','delete(gcf); clear global H'); % [320 240 920 560]
end
% global controls (i.e., always present in main figure in all views)
titlestring = 'DNSim';%'Dynamic Neural Simulator'; % DNSim
  uicontrol('parent',fig,'style','text','string',titlestring,'fontsize',19,'units','normalized','position',[.085 .91 .25 .07],'backgroundcolor','w');
  txt_user=uicontrol('parent',fig,'style','text','string',['user: ' cfg.username],'fontsize',12,'units','normalized','position',[.085 .87 .25 .07],'backgroundcolor','w');
% tabs:
  bbuild=uicontrol('parent',fig,'style','pushbutton','tag','tab','units','normalized','position',[0 .85 .1 .04],'string','build','backgroundcolor',[.7 .7 .7],'callback','set(findobj(''tag'',''ptoggle''),''visible'',''off''); set(findobj(''tag'',''tab''),''backgroundcolor'',[1 1 1]); set(findobj(''userdata'',''pbuild''),''visible'',''on''); set(gcbo,''backgroundcolor'',[.7 .7 .7]);');
  bmodel=uicontrol('parent',fig,'style','pushbutton','tag','tab','units','normalized','position',[.1 .85 .1 .04],'string','model','backgroundcolor',[1 1 1],'callback','set(findobj(''tag'',''ptoggle''),''visible'',''off''); set(findobj(''tag'',''tab''),''backgroundcolor'',[1 1 1]); set(findobj(''userdata'',''pmodel''),''visible'',''on''); set(gcbo,''backgroundcolor'',[.7 .7 .7]);');
  bsimstudy=uicontrol('parent',fig,'style','pushbutton','tag','tab','units','normalized','position',[.2 .85 .1 .04],'string','batch','backgroundcolor',[1 1 1],'callback','set(findobj(''tag'',''ptoggle''),''visible'',''off''); set(findobj(''tag'',''tab''),''backgroundcolor'',[1 1 1]); set(findobj(''userdata'',''psimstudy''),''visible'',''on''); set(gcbo,''backgroundcolor'',[.7 .7 .7]);');
  bhistory=uicontrol('parent',fig,'style','pushbutton','tag','tab','units','normalized','position',[.3 .85 .1 .04],'string','history','backgroundcolor',[1 1 1],'callback','set(findobj(''tag'',''ptoggle''),''visible'',''off''); set(findobj(''tag'',''tab''),''backgroundcolor'',[1 1 1]); set(findobj(''userdata'',''phistory''),''visible'',''on''); set(gcbo,''backgroundcolor'',[.7 .7 .7]);');
% model controls:
  bsave=uicontrol('parent',fig,'visible','off','style','pushbutton','units','normalized','position',[0 .98 .035 .025],'string','save','backgroundcolor',[.8 .8 .8],'callback',@Save_Spec);
  bload=uicontrol('parent',fig,'visible','off','style','pushbutton','units','normalized','position',[.035 .98 .035 .025],'string','load','backgroundcolor',[.8 .8 .8],'callback',@Load_File);
  bappend=uicontrol('parent',fig,'visible','off','style','pushbutton','units','normalized','position',[.07 .98 .04 .025],'string','append','backgroundcolor',[.8 .8 .8],'callback',{@Load_File,[],1});
  %bundo=uicontrol('parent',fig,'style','pushbutton','units','normalized','position',[.11 .98 .035 .025],'string','undo','backgroundcolor',[.8 .8 .8],'callback',@undo);
  bapply=uicontrol('parent',fig,'style','pushbutton','units','normalized','position',[.35 .98 .05 .025],'string','refresh','backgroundcolor',[.8 .8 .8],'callback',{@refresh,0},'visible','off');

%   editusername=uicontrol('parent',fig,'style','edit','tag','login','units','normalized','position',[.25 .98 .05 .025],'string','username','backgroundcolor','w','callback',[],'visible','on');
%   editpassword=uicontrol('parent',fig,'style','edit','tag','login','units','normalized','position',[.3 .98 .05 .025],'string','password','backgroundcolor','w','callback',[],'visible','on');
%   blogin=uicontrol('parent',fig,'style','pushbutton','tag','login','units','normalized','position',[.35 .98 .05 .025],'string','login','backgroundcolor',[.9 .9 .9],'callback',@DB_Login,'visible','on');
%   blogin=uicontrol('parent',fig,'style','pushbutton','tag','logout','units','normalized','position',[.35 .98 .05 .025],'string','logout','backgroundcolor',[.9 .9 .9],'callback',@DB_Logout,'visible','off');
  editusername=uicontrol('parent',fig,'style','edit','tag','login','units','normalized','position',[.34 .94 .06 .03],'string','username','backgroundcolor','w','callback',[],'visible','on');
  editpassword=uicontrol('parent',fig,'style','edit','tag','login','units','normalized','position',[.34 .91 .06 .03],'string','password','backgroundcolor','w','callback',[],'visible','on','KeyPressFcn',@EnterPassword,'UserData','password');
  blogin=uicontrol('parent',fig,'style','pushbutton','tag','login','units','normalized','position',[.34 .97 .06 .025],'string','login','backgroundcolor',[.9 .9 .9],'callback',@DB_Login,'visible','on');
  blogin=uicontrol('parent',fig,'style','pushbutton','tag','logout','units','normalized','position',[.34 .97 .06 .025],'string','logout','backgroundcolor',[.9 .9 .9],'callback',@DB_Logout,'visible','off');
  %uicontrol('parent',fig,'style','text','units','normalized','position',[0 .97 .06 .025],'string','browse:','backgroundcolor','w');
  bDB=uicontrol('parent',fig,'style','pushbutton','units','normalized','position',[0 .97 .08 .03],'string','browse','backgroundcolor','c','callback','global cfg; browse_dnsim(cfg.username,cfg.password,''global CURRSPEC H; close(H.fig); modeler(CURRSPEC);'');');%@BrowseDB,'visible','on');
%   uicontrol('parent',fig,'style','pushbutton','units','normalized','position',[0 .91 .08 .03],'string','mechanisms','backgroundcolor','c','callback',@MechanismBrowser);%,'global allmechs; msgbox({allmechs.label},''available'');');%msgbox(get_mechlist,''available'')');%'get_mechlist');

% left panels for cell, network, and mechanism controls
pbuild=uipanel('parent',fig,'backgroundcolor',bgcolor,'title','','visible','on','tag','ptoggle','userdata','pbuild','units','normalized','position',[0 0 .4 .85],'fontweight','normal');
  bnet=uicontrol('parent',pbuild,'style','pushbutton','tag','tab2','units','normalized','position',[.21 .65 .22 .04],'string','connections','backgroundcolor',[1 1 1],'callback','set(findobj(''tag'',''ptoggle2''),''visible'',''off''); set(findobj(''tag'',''tab2''),''backgroundcolor'',[1 1 1]); set(findobj(''userdata'',''pnet''),''visible'',''on''); set(gcbo,''backgroundcolor'',[.7 .7 .7]);');
  bmech=uicontrol('parent',pbuild,'style','pushbutton','tag','tab2','units','normalized','position',[.43 .65 .22 .04],'string','mechanisms','backgroundcolor',[.7 .7 .7],'callback','set(findobj(''tag'',''ptoggle2''),''visible'',''off''); set(findobj(''tag'',''tab2''),''backgroundcolor'',[1 1 1]); set(findobj(''userdata'',''pmech''),''visible'',''on''); set(gcbo,''backgroundcolor'',[.7 .7 .7]);');
  bcell=uicontrol('parent',pbuild,'style','pushbutton','tag','tab2','units','normalized','position',[.65 .65 .22 .04],'string','parameters','backgroundcolor',[1 1 1],'callback','set(findobj(''tag'',''ptoggle2''),''visible'',''off''); set(findobj(''tag'',''tab2''),''backgroundcolor'',[1 1 1]); set(findobj(''userdata'',''pcell''),''visible'',''on''); set(gcbo,''backgroundcolor'',[.7 .7 .7]);');
  pmech=uipanel('parent',pbuild,'backgroundcolor',bgcolor,'title','mechanism editor','visible','on','tag','ptoggle2','userdata','pmech','units','normalized','position',[0 0 1 .65],'fontweight','normal');
  pnet=uipanel('parent',pbuild,'backgroundcolor',bgcolor,'title','connection mechanisms','visible','off','tag','ptoggle2','userdata','pnet','units','normalized','position',[0 0 1 .65]);
  pcell=uipanel('parent',pbuild,'backgroundcolor',bgcolor,'title','parameters','visible','off','tag','ptoggle2','userdata','pcell','units','normalized','position',[0 0 1 .65]);
pmodel=uipanel('parent',fig,'backgroundcolor',bgcolor,'title','','visible','off','tag','ptoggle','userdata','pmodel','units','normalized','position',[0 0 .4 .85]);
psimstudy=uipanel('parent',fig,'backgroundcolor',bgcolor,'title','batch simulation','visible','off','tag','ptoggle','userdata','psimstudy','units','normalized','position',[0 0 .4 .85],'fontweight','bold');
  pbatchcontrols=uipanel('parent',psimstudy,'backgroundcolor',bgcolor,'title','','units','normalized','position',[0 .8 1 .2]);
  pbatchspace=uipanel('parent',psimstudy,'backgroundcolor',bgcolor,'title','search space','units','normalized','position',[0 .3 1 .5],'fontweight','bold');
  pbatchoutputs=uipanel('parent',psimstudy,'backgroundcolor',bgcolor,'title','outputs','units','normalized','position',[0 0 1 .3],'fontweight','bold');
phistory=uipanel('parent',fig,'backgroundcolor',bgcolor,'title','','visible','off','tag','ptoggle','userdata','phistory','units','normalized','position',[0 0 .4 .85]);
  pnotes=uipanel('parent',phistory,'backgroundcolor',bgcolor,'title','project notes','units','normalized','position',[.22 .3 .78 .7],'fontweight','bold');%,'backgroundcolor',[.5 .5 .5]);
  pcomparison=uipanel('parent',phistory,'backgroundcolor',bgcolor,'title','model comparison','units','normalized','position',[.22 0 .78 .3],'fontweight','bold');

% left panel: model view
txt_model = uicontrol('parent',pmodel,'style','edit','units','normalized','tag','modeltext',...
  'position',[0 0 1 1],'string',cfg.modeltext,'ForegroundColor','k','FontName','Monospaced','FontSize',9,'HorizontalAlignment','Left','Max',100,'BackgroundColor',[.9 .9 .9]);
  % enable horizontal scrolling
%   jEdit = findjobj(txt_model);
%   try
%     jEditbox = jEdit.getViewport().getComponent(0);
%     jEditbox.setWrapping(false);                % turn off word-wrapping
%     jEditbox.setEditable(false);                % non-editable
%     set(jEdit,'HorizontalScrollBarPolicy',30);  % HORIZONTAL_SCROLLBAR_AS_NEEDED
%     % maintain horizontal scrollbar policy which reverts back on component resize
%     hjEdit = handle(jEdit,'CallbackProperties');
%     set(hjEdit, 'ComponentResizedCallback','set(gcbo,''HorizontalScrollBarPolicy'',30)')
%   end

% left panel: network builder %GUI_netpanel;
p_net_select  = uipanel('parent',pbuild,'BackgroundColor',bgcolor,'Position',[0 .7 1 .29],'BorderWidth',.2,'BorderType','line'); % cell morphology
% p_net_connect = uipanel('parent',pnet,'BackgroundColor',bgcolor,'Position',[0 .5 1 .5],'BorderWidth',.2,'BorderType','line','title','','fontweight','normal'); % cell specification
tit='                    [targets]';
tit='                    (columns = targets)';
tit='(columns: target nodes)';
tit='(rows are sources, columns are targets)';
tit='';
p_net_connect = uipanel('parent',pnet,'BackgroundColor',bgcolor,'Position',[0 .6 1 .4],'BorderWidth',.2,'BorderType','line','title',tit,'fontweight','normal'); % cell specification
p_net_kernel  = uipanel('parent',pnet,'BackgroundColor',bgcolor,'Position',[0 0 1 .6],'BorderWidth',.2,'BorderType','line','title','view and edit connectivity'); % cell specification
% compartment controls
if ~isempty(net.cells) && ischar(net.cells(1).label)
  l1={net.cells.label};
  l=l1;
  i=1:length(l);
else
  l={}; i=[];
end
lst_comps = uicontrol('parent',p_net_select,'units','normalized','style','listbox','position',[0 0 .2 .9],'value',i,'string',l,'BackgroundColor',[.9 .9 .9],'Max',5,'Min',0,'Callback',@SelectCells,...
  'ButtonDownFcn',@RenameComponent,'TooltipString','Right-click to edit node name');
% headers for cell info
uicontrol('parent',p_net_select,'tag','nodecontrols','BackgroundColor',bgcolor,'units','normalized','style','text','position',[0 .91 .25 .09],'string','nodes','ListboxTop',0,'HorizontalAlignment','left','fontsize',10,'fontweight','normal');
uicontrol('parent',p_net_select,'tag','nodecontrols','BackgroundColor',bgcolor,'units','normalized','style','text','position',[.25 .91 .06 .09],'string','n','ListboxTop',0,'HorizontalAlignment','left','fontsize',10,'fontweight','normal');
uicontrol('parent',p_net_select,'tag','nodecontrols','BackgroundColor',bgcolor,'units','normalized','style','text','position',[.59 .91 .4 .09],'string','intrinsic mechanisms','ListboxTop',0,'HorizontalAlignment','left','fontsize',10,'fontweight','normal');
uicontrol('parent',p_net_select,'tag','nodecontrols','BackgroundColor',bgcolor,'units','normalized','style','text','position',[.31 .91 .25 .09],'string','dynamics (schema)','ListboxTop',0,'HorizontalAlignment','left','fontsize',10,'fontweight','normal');
uicontrol('parent',p_net_select,'tag','nodecontrols','style','pushbutton','units','normalized','position',[.9 .92 .1 .1],'string','undo','backgroundcolor',[.8 .8 .8],'callback',@undo);

% left panel: mechanism editor %GUI_mechpanel;
% compartment label
if ~isempty(CURRSPEC.(cfg.focustype)) && isfield(CURRSPEC.(cfg.focustype),'mechanisms') && ~isempty(CURRSPEC.(cfg.focustype)(cfg.focus).mechanisms)
  tmp=CURRSPEC.(cfg.focustype)(cfg.focus);
  str1=tmp.mechanisms;
  str2=mech_spec2str(tmp.mechs(1));
  cl=tmp.label;
  u.focustype=cfg.focustype;
  u.focus=cfg.focus;
  u.mechlabel=[tmp.mechanisms{1}];
else
  str1='';
  str2='';
  cl='';
  u=[];
end
txt_comp = uicontrol('style','text','string',cl,'units','normalized','position',[.05 .95 .1 .05],'parent',pmech,'FontWeight','bold','visible','off');
% button to expand/collapse mechanism editor
H.btn_resizemech=uicontrol('parent',pmech,'style','pushbutton','units','normalized','position',[.4 .97 .2 .04],'string','expand','callback',@ResizeMechEditor,'visible','on');
% button to upload a new mechanisms
uicontrol('parent',pmech,'style','pushbutton','units','normalized','position',[.85 .97 .15 .04],'string','upload','callback',@DB_SaveMechanism,'visible','on');
% button to write a new mechanism to disk
uicontrol('parent',pmech,'style','pushbutton','units','normalized','position',[.75 .97 .1 .04],'string','save','callback',@SaveMech);
% button to display list of mechs in DB
%uicontrol('parent',pmech,'style','pushbutton','units','normalized','position',[.95 .97 .05 .04],'string','DB','callback',@MechanismBrowser);%,'global allmechs; msgbox({allmechs.label},''available'');');%msgbox(get_mechlist,''available'')');%'get_mechlist');
% edit box with mech info
lst_mechs = uicontrol('units','normalized','position',[0 .42 .2 .55],'parent',pmech,'BackgroundColor',[.9 .9 .9],...
  'style','listbox','value',1,'string',str1,'Max',1,'Callback',@Display_Mech_Info,'ButtonDownFcn',@RenameMech,'TooltipString','Right-click to edit mechanism name');
txt_mech = uicontrol('parent',pmech,'style','edit','units','normalized','BackgroundColor','w','callback',@UpdateMech,... % [.9 .9 .9]
  'position',[.2 .42 .8 .55],'string',str2,'userdata',u,'FontName','courier','FontSize',10,'HorizontalAlignment','Left','Max',100);
% mech plots associated w/ this compartment
p_static_plots = uipanel('parent',pmech,'Position',[0 0 1 .4],'BackgroundColor','white','BorderWidth',.2,'BorderType','line','title','');
lst_static_funcs = uicontrol('units','normalized','position',[0 0 .2 .95],'parent',p_static_plots,'BackgroundColor',[.9 .9 .9],...
  'style','listbox','value',1:5,'string',{},'Max',50,'Callback',@DrawAuxFunctions);
ax_static_plot = subplot('position',[.23 .1 .77 .78],'parent',p_static_plots,'linewidth',3,'color','w','fontsize',6); box on;
title('functions of one variable');
% lst_static_funcs = uicontrol('units','normalized','position',[.04 .02 .9 .35],'parent',p_static_plots,...
%   'style','listbox','value',1:5,'string',{},'Max',50,'Callback',@DrawAuxFunctions);
edit_static_lims=uicontrol('Style','edit', 'Units','normalized','Position',[0.865 0.075 0.13 0.1],'backgroundcolor','w',...
          'String',sprintf('[%g,%g]',min(cfg.V),max(cfg.V)),'Callback',{@DrawAuxFunctions,1},'parent',p_static_plots);
btn_static_autoscale=uicontrol('style','pushbutton','fontsize',10,'string','autoscale','parent',p_static_plots,...
          'Units','normalized','Position',[0.865 0 0.13 0.075],'callback',@StaticAutoscale);
uicontrol('style','text','parent',p_static_plots,'Units','normalized','Position',[0.84 .09 0.02 0.075],'string','x','backgroundcolor','w');
uicontrol('style','text','parent',p_static_plots,'Units','normalized','Position',[0.84 0 0.02 0.075],'string','y','backgroundcolor','w');

if ~isempty(CURRSPEC.cells) && isfield(CURRSPEC.cells,'functions')
  maxlhs=20; maxlen=150; % limit how much is shown in the listbox
  funcs = CURRSPEC.cells(cfg.focuscomp).functions;
  len = min(maxlhs,max(cellfun(@length,funcs(:,1))));
  str = {};
  for i=1:size(funcs,1)
    str{i} = sprintf(['%-' num2str(len) 's  = %s'],funcs{i,1},strrep(funcs{i,2},' ',''));
    if length(str{i})>maxlen, str{i}=str{i}(1:maxlen); end
  end
  val=1:4;
  set(lst_static_funcs,'string',str);
  set(lst_static_funcs,'value',val(val<=length(str)));
end

% right panel: simulation plots and controls %GUI_simpanel;
psims=uipanel('parent',fig,'title','','visible','on','units','normalized','position',[.4 0 .6 1]);%,'backgroundcolor',cfg.bgcolor);
uicontrol('parent',psims,'style','text','units','normalized','position',[.3 .93 .2 .05],'string','simulations','fontsize',20);
% menu %GUI_menu;
set(fig,'MenuBar','none');
file_m = uimenu(fig,'Label','File');
%uimenu(file_m,'Label','Load model','Callback',@Load_File);
%uimenu(file_m,'Label','Append model','Callback',{@Load_File,[],1});
uimenu(file_m,'Label','Load model(s)','Callback',{@load_models,1,'file'});
uimenu(file_m,'Label','Append model(s)','Callback',{@load_models,0,'file'});
uimenu(file_m,'Label','Save model','Callback',@Save_Spec);
uimenu(file_m,'Label','Upload model','Callback','upload_dnsim;');%@GetUploadInfo);%DB_SaveModel);
uimenu(file_m,'Label','Write Matlab script','Callback','global CURRSPEC; write_dnsim_script(CURRSPEC);');
% uimenu(file_m,'Label','Write ODEFUN script','Callback',@write_odefun_script);

ws_m = uimenu(file_m,'Label','Interact');
uimenu(ws_m,'Label','Pass model (''spec'') to command window','Callback','global CURRSPEC; assignin(''base'',''spec'',CURRSPEC);');
uimenu(ws_m,'Label','Update model (''spec'') from base workspace','Callback',{@refresh,1});
uimenu(ws_m,'Label','Pass ''sim_data'' (during interactive simulation) to command window','Callback','global cfg;cfg.publish=1;');
if 0
  import_m = uimenu(file_m,'Label','Import');
  uimenu(import_m,'Label','XPP (wip)','Callback','not implemented yet');
  export_m = uimenu(file_m,'Label','Export');
  uimenu(export_m,'Label','XPP (wip)','Callback','not implemented yet');
  uimenu(export_m,'Label','NEURON (wip)','Callback','not implemented yet');
  uimenu(export_m,'Label','CellML (wip)','Callback','not implemented yet');
end
uimenu(file_m,'Label','Refresh GUI','Callback','global CURRSPEC H; close(H.fig); modeler(CURRSPEC);');
uimenu(file_m,'Label','Exit','Callback','global CURRSPEC H cfg; close(H.fig); clear CURRSPEC H cfg; warning on');
plot_m = uimenu(fig,'Label','Plot');
uimenu(plot_m,'Label','quick plot','Callback',['global CURRSPEC; if ismember(''sim_data'',evalin(''base'',''who'')), plotv(evalin(''base'',''sim_data''),CURRSPEC,''varlabel'',sprintf(''%s'',CURRSPEC.variables.global_oldlabel{1})); else disp(''load data to plot''); end']);
if 0
  uimenu(plot_m,'Label','plotpow','Callback','global CURRSPEC; if ismember(''sim_data'',evalin(''base'',''who'')), plotpow(evalin(''base'',''sim_data''),CURRSPEC,''spectrogram_flag'',0); else disp(''load data to plot''); end');
  uimenu(plot_m,'Label','plotspk','Callback','global CURRSPEC; if ismember(''sim_data'',evalin(''base'',''who'')), plotspk(evalin(''base'',''sim_data''),CURRSPEC,''window_size'',30/1000,''dW'',5/1000); else disp(''load data to plot''); end');
end
uimenu(plot_m,'Label','visualizer','Callback','global CURRSPEC; if ismember(''sim_data'',evalin(''base'',''who'')), visualizer(evalin(''base'',''sim_data'')); else disp(''load data to plot''); end');

% collect object handles
% figures
H.fig   = fig;
% panels
H.pbuild = pbuild;
H.pcell  = pcell;
H.pnet  = pnet;
H.pmech = pmech;
H.pmodel = pmodel;
H.psimstudy = psimstudy;
H.phistory = phistory;
H.psims = psims;
H.p_net_select  = p_net_select;
H.p_net_connect = p_net_connect;
H.p_net_kernel  = p_net_kernel;
H.pbatchcontrols = pbatchcontrols;
H.pbatchspace = pbatchspace;
H.pbatchoutputs = pbatchoutputs;
H.pnotes = pnotes;
H.pcomparison = pcomparison;
H.H.btn_resizemech = H.btn_resizemech;
% H.p_cell_morph  = p_cell_morph;
% H.p_cell_spec   = p_cell_spec;
% H.p_cell_parms  = p_cell_parms;
H.p_static_plots= p_static_plots;
H.edit_static_lims = edit_static_lims;
% buttons
H.pbuild = pbuild;
H.bnet  = bnet;
H.bmech = bmech;
H.bmodel = bmodel; % @callback (name callback functions here...)
H.bsimstudy = bsimstudy;
H.bhistory = bhistory;
H.bsave = bsave; % @callback
H.bload = bload; % @callback
H.bapply= bapply;
H.bappend= bappend;
% list boxes
H.lst_comps = lst_comps; % compartment listbox in cell view
H.lst_mechs = lst_mechs; % mechanism listbox in mech view
H.txt_mech = txt_mech; % edit box with mech info
H.txt_comp = txt_comp; % text label in mech view
H.txt_model = txt_model; % text control for readable model text
H.txt_user = txt_user;
% edit
H.editusername=editusername;
H.editpassword=editpassword;
% menu items
H.file_m = file_m;
H.plot_m = plot_m;

H.ax_static_plot = ax_static_plot;
H.lst_static_funcs = lst_static_funcs;
% H.edit_comp_dynamics = edit_comp_dynamics; % cell dynamics for focuscomp

% populate controls
if ~isempty(CURRSPEC.cells)
  SelectCells;
  DrawAuxView;
  DrawAuxFunctions;
  DrawUserParams;%([],[],[],0);
  DrawSimPlots;
end
DrawStudyInfo;
UpdateHistory;
Display_Mech_Info;

if load_models_flag
  load_models([],[],1,'file');
end

%% FUNCTIONS

function ResizeMechEditor(src,evnt)
global H
if strcmp(get(src,'string'),'expand')
  set(src,'string','collapse');
  set(H.pmech,'position',[0 0 1 1]);
  set(H.txt_mech,'position',[0 .26 1 .71]);
  set(H.p_static_plots,'position',[0 0 1 .25]);
  % toggle visibility
  set(H.btn_comp_copy,'visible','off');
  set(H.btn_comp_delete,'visible','off');
  set(H.edit_comp_N,'visible','off');
  set(H.edit_comp_mechs,'visible','off');
  set(H.edit_comp_dynamics,'visible','off');
  set(H.lst_comps,'visible','off');
  set(H.lst_mechs,'visible','off');
  set(findobj('tag','nodecontrols'),'visible','off');
  %set(findobj('tag','substfunctions'),'visible','off');
  set(findobj('tag','tab2'),'visible','off');
else
  set(src,'string','expand');
  set(H.pmech,'position',[0 0 1 .65]);
  set(H.txt_mech,'position',[.2 .42 .8 .55]);
  set(H.p_static_plots,'position',[0 0 1 .4]);
  % toggle visibility
  set(H.btn_comp_copy,'visible','on');
  set(H.btn_comp_delete,'visible','on');
  set(H.edit_comp_N,'visible','on');
  set(H.edit_comp_mechs,'visible','on');
  set(H.edit_comp_dynamics,'visible','on');
  set(H.lst_comps,'visible','on');
  set(H.lst_mechs,'visible','on');
  set(findobj('tag','nodecontrols'),'visible','on');
  %set(findobj('tag','substfunctions'),'visible','on');
  set(findobj('tag','tab2'),'visible','on');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function Load_File(src,evnt,path,append_flag)
% Usage:
% @Load_File; % to load and override current data and model
% Load_File([],[],path); % to load from path (e.g., batch result saved in rootdir) and override current data and model
% Load_File([],[],[],1); % to load and concatenate models
% Load_File([],[],path,1); % to load from path and concatenate
if nargin<4, append_flag=0; end
if nargin>=3 && isdir(path) % cd if given a directory where to find files
  cwd=pwd;
  cd(path);
end
[filename,pathname] = uigetfile({'*.mat'},'Pick a model or sim_data file.','MultiSelect','off');
if nargin>=3 && isdir(path) % move back to original directory
  cd(cwd);
end
if isequal(filename,0) || isequal(pathname,0), return; end
if iscell(filename)
  datafile = cellfun(@(x)fullfile(pathname,x),filename,'uniformoutput',false);
  filename = filename{1};
else
  datafile = [pathname filename];
end
if exist(datafile,'file')
  fprintf('Loading file: %s\n',datafile);
  try
    o=load(datafile); % load file
  catch
    fprintf('failed to load file. check that it is a valid matlab file: %s\n',datafile);
    return;
  end
  if isfield(o,'modelspec') % standardize spec name
    o.spec=o.modelspec;
    o=rmfield(o,'modelspec');
  end
  if ~isfield(o,'sim_data') && ~isfield(o,'spec')
    fprintf('select file does not contain sim_data or spec structure. no data loaded\n');
    return;
  end
  if isfield(o,'sim_data')
    % pass data to base workspace
    assignin('base','sim_data',o.sim_data);
    fprintf('sim_data assigned to base workspace.\n');
  end
  if isfield(o,'spec') % has model
    % standarize spec structure
    if isfield(o.spec,'entities')
      if ~isfield(o.spec,'cells')
        o.spec.cells=o.spec.entities;
      end
      o.spec=rmfield(o.spec,'entities');
    end
    if ~isfield(o.spec,'history')
      o.spec.history=[];
    end
    if ~isfield(o.spec,'model_uid')
      o.spec.model_uid=[];
    end
    if ~isfield(o.spec,'parent_uids')
      o.spec.parent_uids=[];
    end
    if ~isfield(o.spec.cells,'parent')
      for i=1:length(o.spec.cells)
        o.spec.cells(i).parent=o.spec.cells(i).label;
      end
    end
    global CURRSPEC
    newspec=CURRSPEC;
    if append_flag
      if isempty(newspec) || isempty(newspec.cells)
        test = 0;
      else
        test = ismember({o.spec.cells.label},{newspec.cells.label});
      end
      if any(test)
        dup={o.spec.cells.label};
        dup=dup(test);
        str='';
        for i=1:length(dup)
          str=[str dup{i} ', '];
        end
        fprintf('failed to concatenate models. duplicate names found: %s. rename and try again.\n',str(1:end-2));
      else
        if isfield(newspec,'cells') && ~isempty(newspec.cells)
          n=length(o.spec.cells);
          [addflds,I]=setdiff(fieldnames(newspec.cells),fieldnames(o.spec.cells));
          [jnk,I]=sort(I);
          addflds=addflds(I);
          for i=1:length(addflds)
            o.spec.cells(1).(addflds{i})=[];
          end
          o.spec.cells=orderfields(o.spec.cells,newspec.cells);
          o.spec.connections=orderfields(o.spec.connections,newspec.connections);
          newspec.cells(end+1:end+n) = o.spec.cells;
          for i=1:n
            newspec.connections(end+i,end+1:end+n) = o.spec.connections(i,:);
          end
          if isfield(o.spec,'files')
            newspec.files = unique({newspec.files{:},o.spec.files{:}});
          end
        else
          newspec = o.spec;
        end
      end
    else
      newspec=o.spec;
    end
    % update model
    updatemodel(newspec);
    refresh;
    % pass model to base workspace
    assignin('base','spec',o.spec);
    fprintf('model specification loaded and assigned to base workspace as ''spec''.\n');
  end
else
  fprintf('file does not exist: %s\n',datafile);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function Save_Spec(src,evnt)
[filename,pathname] = uiputfile({'*.mat;'},'Save as','model-specification.mat');
if isequal(filename,0) || isequal(pathname,0)
  return;
end
outfile = fullfile(pathname,filename);
[fpath,fname,fext] = fileparts(outfile);
global CURRSPEC
spec=CURRSPEC;
fprintf('Saving model specification: %s\n',outfile);
save(outfile,'spec');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function write_odefun_script(src,evnt)
global cfg
answer=inputdlg('Model name:','Enter name');
if isempty(answer)
  return;
end
txt=regexp(cfg.modeltext,'%-.*%-','match');
fid=fopen([answer{1} '_odefun.m'],'wt');
fprintf(fid,'%s\n',txt{:});
fclose(fid);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function SelectCells(src,evnt,null)
global H CURRSPEC cfg
if nargin<3, null=0; end
if null==1
  CURRSPEC=[];
  set(H.lst_comps,'string',{},'value',[]);
  set(H.lst_notes,'string',{},'value',[]);
  UpdateHistory;
  try
    set(H.edit_comp_parent,'visible','off');
    set(H.edit_comp_label,'visible','off');
    set(H.edit_comp_N,'visible','off');
    set(H.edit_comp_dynamics,'visible','off');
    set(H.edit_comp_mechs,'visible','off');
    set(H.btn_comp_copy,'visible','off');
    set(H.btn_comp_delete,'visible','off');
    set(H.btn_comp_edit,'visible','off');
    set(H.p_comp_mechs,'visible','off');
  end
  %refresh;
  return;
elseif isempty(CURRSPEC) || isempty(CURRSPEC.cells)
  set(H.lst_comps,'string',{},'value',[]);
  set(H.lst_mechs,'string',{},'value',[]);
  return;
end
v=get(H.lst_comps,'value');
l=get(H.lst_comps,'string');
if ischar(CURRSPEC.cells(1).label)
  if isfield(CURRSPEC.cells,'parent') && ~isempty(CURRSPEC.cells(1).parent)
    l1={CURRSPEC.cells.label};
    %l2={CURRSPEC.cells.parent};
    %l=cellfun(@(x,y)[x '.' y],l2,l1,'uni',0);
    l=l1;
  else
    l={CURRSPEC.cells.label};
  end
else
  l={};
end
set(H.lst_comps,'string',l,'value',v(v<=length(CURRSPEC.cells)));
if isfield(H,'p_comp_mechs')
  set(H.p_comp_mechs,'visible','off');
end
DrawCellInfo(CURRSPEC); % Selection panel
DrawNetGrid(CURRSPEC);  % Connection panel
% cfg.pauseflag=1;
% DrawSimPlots;
% cfg.pauseflag=0;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function DrawCellInfo(net)
global H
c=1.5; dy=-.07*c; ht=.1;
sel = get(H.lst_comps,'value');
if isfield(net.cells,'parent')
  p={net.cells(sel).parent};
else
  [p{1:length(sel)}]=deal('');
end
l={net.cells(sel).label};
N=[net.cells(sel).multiplicity];
mechs={net.cells(sel).mechanisms};
for i=1:length(sel)
  m=mechs{i};
  if isempty(m)
    str='';
  else
    str=m{1}; for j=2:length(m), str=[str ', ' m{j}]; end
  end
  if ~isempty(net.cells(sel(i)).dynamics)
    if iscell(net.cells(sel(i)).dynamics)
      compdynamics=[net.cells(sel(i)).dynamics{:}];
    else
      compdynamics=net.cells(sel(i)).dynamics;
    end
  else
    compdynamics='';
  end
  if ~isfield(H,'edit_comp_label') || length(H.edit_comp_label)<length(sel) || ~ishandle(H.edit_comp_label(i))
    H.edit_comp_parent(i) = uicontrol('parent',H.p_net_select,'units','normalized',...
      'style','edit','position',[.24 .8+dy*(i-1) .09 ht],'backgroundcolor','w','string',p{i},...
      'HorizontalAlignment','left','Callback',{@UpdateCells,l{i},'parent'},'ButtonDownFcn',{@DrawUserParams,sel(i)},'visible','off');
    H.edit_comp_label(i) = uicontrol('parent',H.p_net_select,'units','normalized','visible','off',...
      'style','edit','position',[.24 .8+dy*(i-1) .1 ht],'backgroundcolor','w','string',l{i},...
      'HorizontalAlignment','left','Callback',{@UpdateCells,l{i},'label'},'ButtonDownFcn',{@DrawUserParams,sel(i)});
    H.btn_comp_delete(i) = uicontrol('parent',H.p_net_select,'units','normalized',...
      'style','pushbutton','fontsize',10,'string','-','callback',{@DeleteCell,l{i}},...
      'position',[.205 .8+dy*(i-1) .03 ht],'TooltipString',l{i});%,'BackgroundColor','white');
    H.edit_comp_N(i) = uicontrol('parent',H.p_net_select,'units','normalized',...
      'style','edit','position',[.24 .8+dy*(i-1) .06 ht],'backgroundcolor','w','string',N(i),...
      'HorizontalAlignment','left','Callback',{@UpdateCells,l{i},'multiplicity'},'TooltipString',l{i});
    H.edit_comp_dynamics(i) = uicontrol('parent',H.p_net_select,'units','normalized',...
      'style','edit','position',[.3 .8+dy*(i-1) .28 ht],'backgroundcolor','w','string',compdynamics,...
      'HorizontalAlignment','left','Callback',{@UpdateCells,l{i},'dynamics'},...
      'ButtonDownFcn',{@Display_Mech_Info,l{i},{},'cells'},'fontsize',9,'TooltipString',l{i});
    H.edit_comp_mechs(i) = uicontrol('parent',H.p_net_select,'units','normalized',...
      'style','edit','position',[.58 .8+dy*(i-1) .38 ht],'backgroundcolor','w','string',str,...
      'HorizontalAlignment','left','Callback',{@UpdateCells,l{i},'mechanisms'},...
      'ButtonDownFcn',{@Display_Mech_Info,l{i},{},'cells'},'fontsize',9,'TooltipString',l{i});
    H.p_comp_mechs(i) = uipanel('parent',H.p_net_select,'units','normalized',...
      'position',[.51 .8+dy*(i-1) .42 ht],'visible','off');
    H.btn_comp_copy(i) = uicontrol('parent',H.p_net_select,'units','normalized',...
      'style','pushbutton','fontsize',10,'string','+','callback',{@CopyCell,l{i}},...
      'position',[.965 .8+dy*(i-1) .03 ht],'TooltipString',l{i});%,'BackgroundColor','white');
    H.btn_comp_edit(i) = uicontrol('parent',H.p_net_select,'units','normalized','visible','off',...
      'style','pushbutton','fontsize',10,'string','...','callback',{@ShowClickMechList,i,'cells'},...%{@OpenCellModeler,l{i}},...
      'position',[.965 .8+dy*(i-1) .03 ht]);%,'BackgroundColor','white');
  else
    % update properties
    set(H.edit_comp_parent(i),'string',p{i},'visible','off','Callback',{@UpdateCells,l{i},'parent'});
    set(H.edit_comp_label(i),'string',l{i},'visible','off','Callback',{@UpdateCells,l{i},'label'});
    set(H.edit_comp_dynamics(i),'string',compdynamics,'visible','on','Callback',{@UpdateCells,l{i},'dynamics'},'TooltipString',l{i});
    set(H.edit_comp_N(i),'string',N(i),'visible','on','Callback',{@UpdateCells,l{i},'multiplicity'},'TooltipString',l{i});
    set(H.edit_comp_mechs(i),'string',str,'visible','on','Callback',{@UpdateCells,l{i},'mechanisms'},'ButtonDownFcn',{@Display_Mech_Info,l{i},{},'cells'},'TooltipString',l{i});
    set(H.btn_comp_copy(i),'callback',{@CopyCell,l{i}},'visible','on','TooltipString',l{i});
    set(H.btn_comp_delete(i),'callback',{@DeleteCell,l{i}},'visible','on','TooltipString',l{i});
    set(H.btn_comp_edit(i),'callback',{@ShowClickMechList,i,'cells'},'visible','off');
    set(H.p_comp_mechs(i),'visible','off');
  end
  if length(H.edit_comp_label)>i
    set(H.edit_comp_parent(i+1:end),'visible','off');
    set(H.edit_comp_label(i+1:end),'visible','off');
    set(H.edit_comp_dynamics(i+1:end),'visible','off');
    set(H.edit_comp_N(i+1:end),'visible','off');
    set(H.edit_comp_mechs(i+1:end),'visible','off');
    set(H.btn_comp_copy(i+1:end),'visible','off');
    set(H.btn_comp_delete(i+1:end),'visible','off');
    set(H.btn_comp_edit(i+1:end),'visible','off');
    set(H.p_comp_mechs(i),'visible','off');
  end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function DrawNetGrid(net)
global H cfg
if nargin<1
  global CURRSPEC;
  net=CURRSPEC;
end
% dx=.15; x=.13; c=1.5; dy=-.07*c; ht=.1;
dx=.15; x=.13; c=1.5; dy=-.1*c; ht=.14;
sel = get(H.lst_comps,'value');
net.cells = net.cells(sel);
net.connections = net.connections(sel,:);
net.connections = net.connections(:,sel);
l={net.cells.label};
for i=1:length(sel)
  for j=1:length(sel)
    m = net.connections(j,i).mechanisms;
    pos = [x+dx*(i-1) .8+dy*(j-1) .9*dx ht];
    u.from=l{j}; u.to=l{i};
    connname = net.connections(j,i).label;
    if ~isempty(m)
      if ischar(m), m={m}; end
      str=m{1}; for k=2:length(m), str=[str ', ' m{k}]; end
      ml=m{1};
    else
      str = '';
      ml={};
    end
    if ~isfield(H,'txt_to') || i>length(H.txt_from) || j>length(H.txt_to) || ~ishandle(H.edit_conn_mechs(i,j)) || H.edit_conn_mechs(i,j)==0
      if i==1 % to
        this=zeros(max(sel),1);
        this(sel)=j;
        H.txt_to(j) = uicontrol('parent',H.p_net_connect,'units','normalized',...
          'style','text','position',[x+dx*(j-1) .88 .11 ht],'string',['--> ' l{j}],...
          'callback',{@ShowClickMechList,this,'connections'},'backgroundcolor',cfg.bgcolor);
      end
      if j==1 % from
        this=ones(1,max(sel));
        this(sel)=i;
        H.txt_from(i) = uicontrol('parent',H.p_net_connect,'units','normalized',...
          'style','text','position',[.01 .8+dy*(i-1) .11 ht],'string',[l{i} ' -->'],...
          'callback',{@ShowClickMechList,this,'connections'},'backgroundcolor',cfg.bgcolor);
      end
      H.edit_conn_mechs(i,j) = uicontrol('parent',H.p_net_connect,'units','normalized',...
        'style','edit','position',pos,'backgroundcolor','w',...
        'string',str,'HorizontalAlignment','left','UserData',u);
      set(H.edit_conn_mechs(i,j),'Callback',{@UpdateNet,connname},...
        'ButtonDownFcn',{@Display_Mech_Info,connname,ml,'connections'});
    H.p_conn_mechs(i,j) = uipanel('parent',H.p_net_connect,'units','normalized',...
      'position',pos,'visible','off');
    else
      set(H.txt_to(i),'string',['--> ' l{i}],'visible','on');
      set(H.txt_from(i),'string',[l{i} ' -->'],'visible','on');
      set(H.p_conn_mechs(i,j),'visible','off');
      set(H.edit_conn_mechs(i,j),'string',str,'UserData',u,'Callback',{@UpdateNet,connname},...
        'ButtonDownFcn',{@Display_Mech_Info,connname,ml,'connections'},'visible','on');
    end
  end
end
if isfield(H,'txt_to') && length(H.txt_to)>length(sel)
  set(H.txt_to(i+1:end),'visible','off');
  set(H.txt_from(i+1:end),'visible','off');
  set(H.edit_conn_mechs(i+1:end,:),'visible','off');
  set(H.edit_conn_mechs(:,i+1:end),'visible','off');
  set(H.p_conn_mechs(i+1:end,:),'visible','off');
  set(H.p_conn_mechs(:,i+1:end),'visible','off');
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function ShowClickMechList(src,evnt,this,type)
global H CURRSPEC cfg
sel=get(H.lst_comps,'value');
if strcmp(type,'cells')
  % cell mech selected in comp mechlist
  h=H.edit_comp_mechs(this);
  p=H.p_comp_mechs(this);
  cfg.focuscomp=this;
else
  % connection mech selected in NetGrid
  if numel(this)>1
    % clicked to or from label; toggle panel...
    % ...
    return; % not implemented yet
  else
    % clicked connections
    % ...
    cfg.focusconn=this;
  end
end
cfg.focustype=type;
cfg.focus=sel(this);
if strcmp(get(h,'visible'),'off')
  set(p,'visible','off');
  set(h,'visible','on');
  return;
end
set(p,'visible','on');
set(h,'visible','off');
children=get(p,'Children');
if ~isempty(children)
  delete(children);
end
l=CURRSPEC.(type)(cfg.focus).label;
m=CURRSPEC.(type)(cfg.focus).mechanisms;
n=length(m);
if length(n)<1, return; end
w=1/n;
x=(0:n-1)*w;
for i=1:n
  uicontrol('parent',p,'style','text','string',m{i},'units','normalized','position',[x(i) 0 w 1],...
    'tooltip',m{i},'ButtonDownFcn',{@Display_Mech_Info,l,m{i}});
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function DrawAuxView(src,evnt)
%@DrawAuxView:
global H CURRSPEC cfg
if isempty(CURRSPEC.cells), return; end
% get strings and userdata for all mechs given CURRSPEC.(cells|connections)
% make list of connections
EL={CURRSPEC.cells.label};
CL={CURRSPEC.connections.label};
sel=find(~cellfun(@isempty,CL));
if isempty(sel) % no connections
  return;
end
allvars = CURRSPEC.model.auxvars;
NE=numel(EL);
NC=numel(sel);
MECHlabel = {};
VARlabel = {};
SRCind = [];
DSTind = [];
MECHind = [];
mechVARinds = {}; % make cell array in case a mechanism variable is set using >1 sequential expressions
allVARinds = {};  % make cell array for indices in model.auxvars corresponding to mechVARinds
mechlistind = [];
varlistind = [];
mechlistlabels = {};
cnt=0; mechcnt=0;
for a=1:NC
  [i,j]=ind2sub([NE NE],sel(a));
  c=CURRSPEC.connections(i,j);
  for k=1:numel(c.mechanisms)
    mechcnt=mechcnt+1;
    thismechlabel=sprintf('%s->%s.%s',EL{i},EL{j},c.mechanisms{k});
    mechlistlabels{mechcnt} = thismechlabel;
    thisvars=c.mechs(k).auxvars;
    if isempty(thisvars), continue; end
    uniqvarlabels=unique(thisvars(:,1),'stable');
    for u=1:numel(uniqvarlabels)
      cnt=cnt+1;
      SRCind(cnt) = i;
      DSTind(cnt) = j;
      MECHind(cnt) = k;
      tmp = sprintf('%s_%s_%s_%s',EL{i},EL{j},c.mechanisms{k},uniqvarlabels{u});
      mechVARinds{cnt} = find(strcmp(uniqvarlabels{u},thisvars(:,1)));
      allVARinds{cnt} = find(strcmp(tmp,allvars(:,1)));
      MECHlabel{cnt} = thismechlabel;
      VARlabel{cnt} = uniqvarlabels{u};
      mechlistind(cnt) = mechcnt;
    end
  end
end
mechlist_string = mechlistlabels; %unique(MECHlabel,'stable');
mechlist_userdata.SRCind = SRCind;
mechlist_userdata.DSTind = DSTind;
mechlist_userdata.MECHind = MECHind;
mechlist_userdata.mechVARinds = mechVARinds;
mechlist_userdata.allVARinds = allVARinds;
mechlist_userdata.MECHlabel = MECHlabel;
mechlist_userdata.VARlabel = VARlabel;
mechlist_userdata.mechlistind = mechlistind;

% create/update uicontrols
if ~isfield(H,'lst_auxconns') || ~ishandle(H.lst_auxconns)
  uicontrol('style','text','string','select mechanism','units','normalized','position',[0 .94 .2 .06],'parent',H.p_net_kernel,'backgroundcolor',cfg.bgcolor);
  H.lst_auxconns = uicontrol('parent',H.p_net_kernel,'units','normalized','style','listbox','userdata',mechlist_userdata,...
    'position',[0 0 .2 .94],'value',1,'string',mechlist_string,'BackgroundColor',[.9 .9 .9],'Max',1,'Callback',@ChangeAuxMechSelection);
else
  value=get(H.lst_auxconns,'value');
  if value>numel(mechlist_string), value=1; end
  set(H.lst_auxconns,'value',value,'string',mechlist_string,'userdata',mechlist_userdata);
end
ChangeAuxMechSelection([],[]);

function ChangeAuxMechSelection(src,evnt)
%@ChangeAuxMechSelection:
global H CURRSPEC cfg
if isempty(CURRSPEC.cells), return; end
% get strings and userdata for select mech (lst_auxconns.value) given lst_auxconns.userdata
mechsel=get(H.lst_auxconns,'value');
ud=get(H.lst_auxconns,'userdata');
idx=(ud.mechlistind==mechsel);
varlist_string = ud.VARlabel(idx);
varlist_userdata.srcind=ud.SRCind(idx);
varlist_userdata.dstind=ud.DSTind(idx);
varlist_userdata.mechind=ud.MECHind(idx);
varlist_userdata.mechvarinds=ud.mechVARinds(idx);
varlist_userdata.allvarinds=ud.allVARinds(idx);
varlist_userdata.mechlabel=ud.MECHlabel(idx);
varlist_userdata.varlabel=ud.VARlabel(idx);

% create/update uicontrols
if ~isfield(H,'lst_auxvars') || ~ishandle(H.lst_auxvars)
  uicontrol('style','text','string','select matrix','units','normalized','position',[.2 .94 .15 .06],'parent',H.p_net_kernel,'backgroundcolor',cfg.bgcolor);
  H.lst_auxvars = uicontrol('parent',H.p_net_kernel,'units','normalized','backgroundcolor',[.9 .9 .9],...
    'style','listbox','position',[.21 .66 .15 .28],'string',varlist_string,'value',length(varlist_string),'userdata',varlist_userdata,'Callback',@ChangeAuxVarSelection);
else
  value=get(H.lst_auxvars,'value');
%   if isequal(index,'last') || (value>numel(varlist_string))
    value=numel(varlist_string);
%   end
  set(H.lst_auxvars,'value',value,'string',varlist_string,'userdata',varlist_userdata);
end
ChangeAuxVarSelection;

% Structure info:
% spec.connections(i,j).mechs(k).auxvars{ul,1} == varlabel
% spec.connections(i,j).mechs(k).auxvars{ul,2} == expression
%   where ul = mechVARinds{u}(l), l=1...
% spec.model.auxvars{vl,1} == src_dst_mech_varlabel
% spec.model.auxvars{vl,2} == expression w/ substitutions
%   where vl = allVARinds{u}(l), l=1...

function ChangeAuxVarSelection(src,evnt)
%@ChangeAuxVarSelection:
global H CURRSPEC cfg
if isempty(CURRSPEC.cells), return; end

% get equation, matrix, & header for select var (lst_auxvars.value) | userdata & CURRSPEC
varsel=get(H.lst_auxvars,'value');
varlist=get(H.lst_auxvars,'string');
ud=get(H.lst_auxvars,'userdata');
i=ud.srcind(varsel);
j=ud.dstind(varsel);
k=ud.mechind(varsel);
varinds=ud.mechvarinds{varsel};
varinfo=CURRSPEC.connections(i,j).mechs(k).auxvars(varinds,:);
edit_string = '';
for l=1:numel(varinds)
  edit_string = [edit_string sprintf('%s=%s; ',varinfo{l,1},strrep(varinfo{l,2},';',''))];
end
image_header = sprintf('%s: %s',ud.mechlabel{varsel},ud.varlabel{varsel});

% evaluate matrix
for ii=1:length(ud.allvarinds)
  for jj=1:length(ud.allvarinds{ii})
    k=ud.allvarinds{ii}(jj);
    a=CURRSPEC.model.auxvars(k,:);
    eval(sprintf('%s = %s;',a{1,1},a{1,2}));
  end
end
varinds=ud.allvarinds{varsel};
varinfo=CURRSPEC.model.auxvars(varinds,:);
try
  val = eval(varinfo{1});
catch
  val = nan;
end
lims=[min(val(:)) max(val(:))];

% whether to show checkbox for self connection
noself = [varlist{varsel} '=' varlist{varsel} '.*(1-eye(Npop))'];
if any(strfind(edit_string,noself))
  noself_value=1;
else
  noself_value=0;
end
if i==j
  self_visible='on';
else
  self_visible='off';
end

yshift=.16;
% create/update uicontrols
if ~isfield(H,'edit_auxvar_eqn') || ~ishandle(H.edit_auxvar_eqn)
  % create uicontrol edit_auxvar_eqn (callback: @EditAuxVarEqn)
  H.edit_auxvar_eqn = uicontrol('parent',H.p_net_kernel,'units','normalized',...
    'style','edit','position',[.21 0 .79 .135],'backgroundcolor','w','string',edit_string,... % [.21 .48 .3 .12]
    'HorizontalAlignment','left','fontsize',10,'Callback',@EditAuxVarEqn);
  % create uicontrol txt_auxvar_header, img_auxvar
  H.txt_auxvar_header = uicontrol('style','text','string',image_header,'units','normalized','position',[.57 .925 .4 .075],'parent',H.p_net_kernel,'backgroundcolor',cfg.bgcolor,'ForegroundColor','b','fontsize',12,'fontweight','bold');
  H.ax_conn_img = subplot('position',[.6 .2 .35 .65],'parent',H.p_net_kernel);
  H.img_auxvar = imagesc(val); %axis xy;
  %ylabel('ylabel'); title('title');
  if lims(2)>lims(1), caxis(lims); end
  colorbar
  % create uicontrol buttons (callback: @EditAuxVarAuto)
  uicontrol('style','text','string','redefine matrix','units','normalized','position',[.21 .56 .15 .06],'parent',H.p_net_kernel,'backgroundcolor',cfg.bgcolor);
  uicontrol('style','pushbutton','units','normalized','position',[.21 .3+yshift .15 .1],'string','gaussian','parent',H.p_net_kernel,'callback',{@EditAuxVarAuto,'gaussian'});
  uicontrol('style','text','units','normalized','position',      [.41 .29+yshift .15 .1],'string','stdev (%n)','parent',H.p_net_kernel,'backgroundcolor',cfg.bgcolor,'horizontalalignment','left');
  H.edit_gaussian_sigma = uicontrol('style','edit','units','normalized','position',[.36 .3+yshift .05 .1],'string','50','parent',H.p_net_kernel,'backgroundcolor','w');
  uicontrol('style','pushbutton','units','normalized','position',[.21 .2+yshift .15 .1],'string','random','parent',H.p_net_kernel,'callback',{@EditAuxVarAuto,'rand'});
  uicontrol('style','text','units','normalized','position',      [.41 .19+yshift .15 .1],'string','Pr[connect]','parent',H.p_net_kernel,'backgroundcolor',cfg.bgcolor,'horizontalalignment','left');
  H.edit_rand_p = uicontrol('style','edit','units','normalized','position',[.36 .2+yshift .05 .1],'string','.5','parent',H.p_net_kernel,'backgroundcolor','w');
  uicontrol('style','pushbutton','units','normalized','position',[.37 .1+yshift .15 .1],'string','all-to-all','parent',H.p_net_kernel,'callback',{@EditAuxVarAuto,'all'});
  uicontrol('style','pushbutton','units','normalized','position',[.21 .1+yshift .15 .1],'string','one-to-one','parent',H.p_net_kernel,'callback',{@EditAuxVarAuto,'one'});
  uicontrol('style','pushbutton','units','normalized','position',[.21 0+yshift .15 .1],'string','load matrix','parent',H.p_net_kernel,'callback',{@EditAuxVarAuto,'loadmat'});
  H.chk_selfconnect = uicontrol('style','checkbox','string','no self connect','value',noself_value,'units','normalized','position',[.37 0+yshift .2 .1],'parent',H.p_net_kernel,'visible',self_visible,'callback',{@EditAuxVarAuto,'self'},'backgroundcolor',cfg.bgcolor);
else
  % update uicontrols
  set(H.chk_selfconnect,'visible',self_visible,'value',noself_value);
  set(H.edit_auxvar_eqn,'string',edit_string);
  set(H.txt_auxvar_header,'string',image_header);
  set(H.img_auxvar,'cdata',val);
  axes(H.ax_conn_img); axis tight
  if lims(2)>lims(1)
    set(H.ax_conn_img,'clim',lims);
  end
end
% conditionally set plot text
NE=[CURRSPEC.cells.multiplicity];
if size(val,1)==NE(i) && size(val,2)==NE(j)
  ylabel(CURRSPEC.cells(i).label);
  title(CURRSPEC.cells(j).label);
end

function EditAuxVarEqn(src,evnt)
%@EditAuxVarEqn:
global H CURRSPEC
% get new auxinfo from edit_auxvar_eqn
eqn = get(H.edit_auxvar_eqn,'string');
if isempty(eqn), return; end
eqn = strtrim(strread(eqn,'%s','delimiter',';'));
if length(eqn)<1, return; end
eqn = eqn(~cellfun(@isempty,eqn));
if length(eqn)<1, return; end

% update CURRSPEC.connections().mechs().auxvars()
varsel=get(H.lst_auxvars,'value');
ud=get(H.lst_auxvars,'userdata');
i=ud.srcind(varsel);
j=ud.dstind(varsel);
k=ud.mechind(varsel);
varinds=ud.mechvarinds{varsel};
oldauxvars=CURRSPEC.connections(i,j).mechs(k).auxvars;
neqns=size(oldauxvars,1);
auxvars = {};
if min(varinds)>1 & neqns>0
  auxvars=cat(1,auxvars,oldauxvars(1:min(varinds)-1,:));
end
for l=1:length(eqn)
  ind=find(eqn{l}=='=',1,'first');
  tmp=strtrim({eqn{l}(1:ind-1),eqn{l}(ind+1:end)});
  auxvars=cat(1,auxvars,tmp);
end
if max(varinds)<neqns
  auxvars=cat(1,auxvars,oldauxvars(max(varinds)+1:end,:));
end
newspec = CURRSPEC;
newspec.connections(i,j).mechs(k).auxvars = auxvars;

% update model
updatemodel(newspec);
DrawAuxView;
Display_Mech_Info;

function EditAuxVarAuto(src,evnt,type)
%@EditAuxVarAuto:
global H
varsel=get(H.lst_auxvars,'value');
varlist=get(H.lst_auxvars,'string');
if ~strcmp(type,'self')
  set(H.chk_selfconnect,'value',0);
end
% update edit_auxvar_eqn
switch type
  case 'rand'
    eqn = [varlist{varsel} sprintf('=rand(Npost,Npre)<%g;',str2num(get(H.edit_rand_p,'string')))];
  case 'all'
    eqn = [varlist{varsel} '=ones(Npost,Npre);'];
  case 'one'
    eqn = [varlist{varsel} '=eye(Npost,Npre);'];
  case 'gaussian'
    eqn='';
    if ~ismember('Nmax',varlist)
      eqn='Nmax=max(Npost,Npre);';
    end
    if ~ismember('srcpos',varlist)
      eqn=[eqn 'srcpos=linspace(1,Nmax,Npre)''*ones(1,Npost);'];
    end
    if ~ismember('dstpos',varlist)
      eqn=[eqn 'dstpos=(linspace(1,Nmax,Npost)''*ones(1,Npre))'';'];
    end
    eqn=[eqn varlist{varsel} sprintf('=exp(-(srcpos-dstpos).^2/(%g*Npost)^2)''',str2num(get(H.edit_gaussian_sigma,'string'))/100)];
  case 'loadmat'
    [filename,pathname] = uigetfile({'*.mat'},'Pick a file containing a connectivity matrix.','MultiSelect','off');
    if isequal(filename,0) || isequal(pathname,0), return; end
    file=fullfile(pathname,filename);
    if ~exist(file,'file')
      return;
    end
    dat=load(file);
    flds=fieldnames(dat);
    eqn = [varlist{varsel} sprintf('=getfield(load(''%s''),''%s'');',file,flds{1})];
  case 'self'
    eqn = get(H.edit_auxvar_eqn,'string');
    noself = [varlist{varsel} '=' varlist{varsel} '.*(1-eye(Npop))'];
    if get(H.chk_selfconnect,'value')==0 % remove identity subtraction
      if any(strfind(eqn,noself))
        eqn = strrep(eqn,noself,'');
      end
    else % append identity subtraction
      if ~any(strfind(eqn,noself))
        eqn=strtrim(eqn);
        if ~strcmp(eqn(end),';')
          eqn=[eqn ';'];
        end
        eqn = [eqn ' ' noself];
      end
    end
    eqn=strrep(eqn,';;',';');
  otherwise
    eqn = get(H.edit_auxvar_eqn,'string');
end
set(H.edit_auxvar_eqn,'string',eqn);
EditAuxVarEqn;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function simulate(src,evnt,action)
global CURRSPEC H cfg eventdata t
clear global eventdata
if isequal(src,findobj('tag','start'))
  cfg.quitflag=-1;
  set(findobj('tag','plottype'),'visible','on');
  set(findobj('tag','autoscale'),'visible','on');
  set(findobj('tag','pause'),'visible','on');
  set(findobj('tag','stop'),'visible','on');
  %set(findobj('tag','publish'),'visible','on');
  set(findobj('tag','substfunctions'),'visible','on');
end
DrawSimPlots;
% reset plottype to trace
h=findobj('tag','plottype');
if strcmp(get(h,'string'),'trace')
  set(h,'string','image');
  cfg.plottype='trace';
end

functions = CURRSPEC.model.functions;
auxvars = CURRSPEC.model.auxvars;
ode = CURRSPEC.model.ode;
IC = CURRSPEC.model.IC;
allvars=CURRSPEC.variables.labels;
allinds=CURRSPEC.variables.entity;
cfg.T = (0:cfg.buffer-1)*cfg.dt; % ms
fh_pow = @(x,y) PowerSpecTA(x,y,[10 80],min(8000,cfg.buffer/2),'Normalized',[]);

% get list of indices of vars to plot
list=get(H.lst_comps,'string');
sel=get(H.lst_comps,'value');
if length(sel)>3, sel=sel(1:3); end
plotvars=cell(size(sel));
show=list(sel);
for k=1:length(show)
  this=sel(k);
  list=get(H.lst_vars(k),'string');
  vind=get(H.lst_vars(k),'value');
  if isempty(list)
    continue;
  end
  var = list{vind};% CURRSPEC.cells(this).ode_labels{1};
  plotvars{k}=find(cellfun(@(x)isequal(x,var),allvars));
end
plotfuncs=cell(size(sel));
if all(cellfun(@isempty,plotvars))
  fprintf('Nothing to simulate.\n');
  return;
end
% evaluate auxiliary variables (ie., adjacency matrices)
for k = 1:size(auxvars,1)
  %try  % added to catch mask=mask-diag(diag(mask)) when mask is not square
    eval(sprintf('%s = %s;',auxvars{k,1},auxvars{k,2}) );
  %end
end
% evaluate anonymous functions
for k = 1:size(functions,1)
  eval(sprintf('%s = %s;',functions{k,1},functions{k,2}) );
end

F = eval(ode);

% Simulate (simple forward Euler integration)
X=IC;
t=0;
cnt=0;
var_flag=ones(size(sel));
tvec=zeros(1,cfg.buffer);
xticks=get(H.ax_state_plot(end),'xtick');
tinds=1:cfg.buffer; index=1;
%cfg.record=zeros(length(IC),cfg.buffer);
cfg.record=nan(length(IC),cfg.buffer);
while cfg.quitflag<0 && (length(IC)==length(CURRSPEC.model.IC))
  if ~isequal(ode,CURRSPEC.model.ode)
    ode=CURRSPEC.model.ode;
    allvars=CURRSPEC.variables.labels;
    allinds=CURRSPEC.variables.entity;
    F=eval(ode);
    functions = CURRSPEC.model.functions;
    auxvars = CURRSPEC.model.auxvars;
    % update auxiliary variables (ie., adjacency matrices)
    for k = 1:size(auxvars,1)
      %try  % added to catch mask=mask-diag(diag(mask)) when mask is not square
        eval(sprintf('%s = %s;',auxvars{k,1},auxvars{k,2}) );
      %end
    end
    % update anonymous functions
    for k = 1:size(functions,1)
      eval(sprintf('%s = %s;',functions{k,1},functions{k,2}) );
    end
  end
  cnt=cnt+1;
  % speed?
  if get(findobj('tag','speed'),'value')~=0
    pause(0.1*get(findobj('tag','speed'),'value')^1);
  end
  if cfg.publish~=0
    tmp_data = ts_matrix2data(cfg.record,'sfreq',1/cfg.dt);
    [tmp_data.sensor_info.label] = deal(allvars{:});
    assignin('base','sim_data',tmp_data);
    assignin('base','spec',CURRSPEC);
    clear tmp_data
    cfg.publish=0;
    fprintf('sim_data assigned to command line at t=%g\n',t);
    msgbox(sprintf('simulated data assigned to command line in variable ''sim_data'' at t=%g',t));
  end
  % pause?
  p=findobj('tag','pause');
  while cfg.pauseflag>0
    pause(0);drawnow; %needed to overcome MATLAB7 bug (found by Gerardo Lafferriere)
    set(p,'string','resume');
  end;
  set(p,'string','pause');
  % integrate
  X = X+cfg.dt*F(t,X);
  t = t + cfg.dt;
  if cnt<=cfg.buffer
    cfg.record(:,cnt)=X;
    tvec(cnt)=t;
  else
    %cfg.record = [cfg.record(:,2:end) X];
    %tvec(2:end)=t;
    index=index+1;
    if index>cfg.buffer
      index=1;
      tinds=1:cfg.buffer;
    else
      tinds=[index:cfg.buffer 1:index-1];
    end
    cfg.record(:,index)=X;
    xticks=xticks+cfg.dt;
    %if mod(cnt,100)==0
      %set(H.ax_state_plot,'xtick',get(H.ax_state_plot(1),'xtick')+100*cfg.dt);
    %end
  end
  if cfg.plotchange
    hbtn=findobj('tag','plottype');
    type=get(hbtn,'string');
    if strcmp(type,'trace')
      set(H.ax_state_img(ishandle(H.ax_state_img)),'visible','off');
      set(H.img_state(ishandle(H.img_state)),'visible','off');
      set(H.ax_state_plot(ishandle(H.ax_state_plot)),'visible','on');
      set(H.simdat_alltrace(ishandle(H.simdat_alltrace)),'visible','on');
      for k=1:length(H.ax_state_plot)
        if ishandle(H.ax_state_plot(k))
          set(H.ax_state_plot(k),'ylim',get(H.ax_state_img(k),'clim'));
        end
      end
      cfg.plottype='trace';
      set(hbtn,'string','image');
    else
      set(H.ax_state_plot(ishandle(H.ax_state_plot)),'visible','off');
      set(H.simdat_alltrace(ishandle(H.simdat_alltrace)),'visible','off');
      set(H.ax_state_img(ishandle(H.ax_state_img)),'visible','on');
      set(H.img_state(ishandle(H.img_state)),'visible','on');
      for k=1:length(H.ax_state_img)
        if ishandle(H.ax_state_img(k))
          set(H.ax_state_img(k),'clim',get(H.ax_state_plot(k),'ylim'));
        end
      end
      cfg.plottype='image';
      set(hbtn,'string','trace');
    end
    cfg.plotchange=0;
    cfg.changeflag=1;
  end
  if mod(cnt,round(cfg.buffer/50))==0
    % get output to plot
    list=get(H.lst_comps,'string');
    sel=get(H.lst_comps,'value');
    if length(sel)>3, sel=sel(1:3); end
    show=list(sel);
    if cfg.changeflag>0
      % get vars to plot from listboxes
      for k=1:length(show)
        this=sel(k);
        numcell=CURRSPEC.cells(this).multiplicity;
        list=get(H.lst_vars(k),'string');
        vind=get(H.lst_vars(k),'value');
        var = list{vind};% CURRSPEC.cells(this).ode_labels{1};
        if ismember(var,allvars) % plot state var
          var_flag(k)=1;
          plotvars{k}=find(cellfun(@(x)isequal(x,var),allvars));
        elseif ismember(var,functions(:,1)) % plot aux function
          var_flag(k)=0;
        end
        if var_flag(k)==1
          if strcmp(cfg.plottype,'trace')
            set(get(H.ax_state_plot(k),'title'),'string',sprintf('%s (n=%g/%g)',strrep(list{vind},'_','\_'),min(numcell,cfg.ncellshow),numcell));
          else
            set(get(H.ax_state_plot(k),'title'),'string',sprintf('%s (n=%g/%g)',strrep(list{vind},'_','\_'),numcell,numcell));
          end
        else
          if strcmp(cfg.plottype,'trace')
            set(get(H.ax_state_plot(k),'title'),'string',sprintf('%s (n=%g/%g): %s',strrep(list{vind},'_','\_'),min(numcell,cfg.ncellshow),numcell,strrep(functions{find(strcmp(var,functions(:,1))),2},'_','\_')));
          else
            set(get(H.ax_state_plot(k),'title'),'string',sprintf('%s (n=%g/%g): %s',strrep(list{vind},'_','\_'),numcell,numcell,strrep(functions{find(strcmp(var,functions(:,1))),2},'_','\_')));
          end
        end
      end
      cfg.changeflag=-1;
    end
    for k=1:length(show)
      this=sel(k);
      numcell=CURRSPEC.cells(this).multiplicity;
      if strcmp(cfg.plottype,'trace') && (numcell > cfg.ncellshow)
        tmp=randperm(numcell);
        inds = sort(tmp(1:cfg.ncellshow));
      else
        inds = 1:numcell;
      end
      %for j=1:length(inds)
        list=get(H.lst_vars(k),'string');
        vind=get(H.lst_vars(k),'value');
        if var_flag(k)==1 % plot state var
          if strcmp(cfg.plottype,'trace')
            for j=1:length(inds)
              set(H.simdat_alltrace(k,j),'ydata',cfg.record(plotvars{k}(inds(j)),tinds));
              if cnt>cfg.buffer % && k==length(show)
                set(H.ax_state_plot(k),'xticklabel',xticks);
              end
            end
          else
            set(H.img_state(k),'cdata',cfg.record(plotvars{k},tinds));
            if numcell>1
              set(H.ax_state_img(k),'ylim',[1 numcell]);
            end
            if cnt>cfg.buffer % && k==length(show)
              set(H.ax_state_img(k),'xticklabel',xticks);
            end
          end
          %set(get(H.ax_state_plot(k),'title'),'string',sprintf('%s (n=%g/%g)',strrep(list{vind},'_','\_'),min(numcell,cfg.ncellshow),numcell));
        elseif var_flag(k)==0 % plot aux function
          % -----------------------------------------------------------
          var = list{vind};% CURRSPEC.cells(this).ode_labels{1};
          thisfunc=find(strcmp(var,functions(:,1)));
          basename=functions{thisfunc,3};
          funceqn=functions{thisfunc,2};
          args=regexp(funceqn,'^@\([\w,]*\)','match');
          args=strread(args{1}(3:end-1),'%s','delimiter',',');
          plotfargs=cell(1,length(args));
          % loop over args
          plotfunc_flag=1;
          for a=1:length(args)
            plotfargs{a}=zeros(numcell,cfg.buffer);
            arg=args{a};
            if isequal(arg,'t') % current time vector
              for b=1:numcell
                plotfargs{a}(b,:)=tvec;%t+(0:cfg.buffer-1)*cfg.dt;
              end
            elseif ismember(arg,allvars) % known state var
              tmp=find(cellfun(@(x)isequal(x,arg),allvars));
              plotfargs{a}(:,:)=cfg.record(tmp,tinds);
            else % unknown var. need to map var labels to get state var indices
              try
                spc=CURRSPEC.cells(this);
                ii=find(~cellfun(@isempty,{spc.mechs.functions}));
                jj=arrayfun(@(x)any(ismember(basename,x.functions(:,1))),spc.mechs(ii));
                if any(jj)
                  m=ii(jj);
                  args2=regexp(spc.mechs(m).substitute(:,2),[basename '\([\w,]*\)'],'match');
                else
                  ii=find(~cellfun(@isempty,{spc.connection_mechs.functions}));
                  jj=arrayfun(@(x)any(ismember(basename,x.functions(:,1))),spc.connection_mechs(ii));
                  m=ii(jj);
                  args2=regexp(spc.connection_mechs(m).substitute(:,2),[basename '\([\w,]*\)'],'match');
                end
                args2=args2{1};
                if iscell(args2), args2=args2{1}; end
                args2=strread(args2((length(basename)+2):end-1),'%s','delimiter',',');
                for b=a:length(args2)
                  origvar=args2{a};
                  thisarg=spc.var_list{strmatch(origvar,spc.orig_var_list)};
                  if ismember(thisarg,allvars)
                    tmp=find(cellfun(@(x)isequal(x,thisarg),allvars));
                    plotfargs{a}(:,:)=cfg.record(tmp,tinds);
                  end
                end
                plotfunc_flag=1;
              catch
                plotfunc_flag=0;
              end
            end
          end
          if strcmp(cfg.plottype,'trace')
            for j=1:length(inds)
              if plotfunc_flag
                plotfuncs=eval(sprintf('%s(plotfargs{:})',var)); %feval(var,plotfargs{:});
                set(H.simdat_alltrace(k,j),'ydata',plotfuncs(inds(j),:));
              else
                set(H.simdat_alltrace(k,j),'ydata',zeros(1,cfg.buffer));
              end
            end
          else
            try
              set(H.img_state(k),'cdata',plotfuncs);
              if numcell>1
                set(H.ax_state_img(k),'ylim',[1 numcell]);
              end
            catch
              set(H.img_state(k),'cdata',zeros(numcell,cfg.buffer));
              if numcell>1
                set(H.ax_state_img(k),'ylim',[1 numcell]);
              end
            end
          end
          % -----------------------------------------------------------
        end
      %end
  %     if 0
  %       lfp=mean(cfg.record(plotvars{k},:),1);
  %       set(H.simdat_LFP(k),'ydata',lfp,'linewidth',4,'color','k','linestyle','-');
  %     end
  %     if 0 && mod(cnt,cfg.buffer)==0 && cnt>1
  %       % update power spectrum
  %       try
  %         res = feval(fh_pow,cfg.T,lfp);
  %         set(H.simdat_LFP_power(k),'xdata',res.f,'ydata',log10(res.Pxx));
  %       catch
  %         fprintf('power spectrum calc failed.\n');
  %       end
  %     end
    end
    drawnow
  end
end
cfg.quitflag=1;
p=findobj('tag','pause');
set(p,'string','pause');
set(findobj('tag','start'),'string','restart');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function DrawSimPlots
global H cfg CURRSPEC
cfg.T = (0:cfg.buffer-1)*cfg.dt; % ms
cfg.f = 1:100;
cfg.ncellshow=10;
cfg.colors  = 'kbrgmy';
cfg.lntype  = {'-',':','-.','--'};
dy=-.25;
list=get(H.lst_comps,'string');
sel=get(H.lst_comps,'value');
show=list(sel);
if length(show)>3, show=show(1:3); end
allvars=CURRSPEC.variables.labels;
allinds=CURRSPEC.variables.entity;
numcells=[CURRSPEC.cells.multiplicity];
% data plots
if isfield(H,'ax_state_plot')
  delete(H.simdat_alltrace(ishandle(H.simdat_alltrace)));
  delete(H.simdat_LFP(ishandle(H.simdat_LFP)));
  delete(H.ax_state_plot(ishandle(H.ax_state_plot)));
  delete(H.ax_state_img(ishandle(H.ax_state_img)));
  %delete(H.ax_state_title(ishandle(H.ax_state_title)));
%   delete(H.simdat_LFP_power(ishandle(H.simdat_LFP_power)));
  delete(H.lst_vars(ishandle(H.lst_vars)));
  %delete(H.ax_state_power(ishandle(H.ax_state_power)));
  H=rmfield(H,{'simdat_alltrace','simdat_LFP','ax_state_plot'});%,'simdat_LFP_power'});%,'ax_state_title','ax_state_power'});
end
for i=1:length(show) % i=1:ncomp
  % get var labels
  vars=unique(allvars(allinds==sel(i)));
  % add function labels
  vars=cat(2,vars,CURRSPEC.cells(sel(i)).functions(:,1)');
  try
    vind=find(strcmp(CURRSPEC.cells(sel(i)).var_list{1},vars),1,'first');
  catch
    vind=find(~cellfun(@isempty,regexp(vars,'_V$','once')));
  end
  if isempty(vind), vind=1; end
  if i==1
    uicontrol('parent',H.psims,'style','text','units','normalized','position',[.8 .895 .2 .025],'string','what to plot?');
  end
  H.lst_vars(i) = uicontrol('parent',H.psims,'units','normalized','backgroundcolor','w',...
    'style','listbox','position',[.8 .7+(i-1)*dy .2 -.8*dy],'value',vind,'string',vars,'Callback','global cfg;cfg.changeflag=1;');
  % image plot
  H.ax_state_img(i) = subplot('position',[.03 .7+(i-1)*dy .76 -.8*dy],'parent',H.psims,'visible','off');
  if i<length(show)
    set(H.ax_state_img(i),'xtick',[])
  end
  nn=CURRSPEC.cells(sel(i)).multiplicity;
  if nn>1, ylim([1 nn]); end
  H.img_state(i) = imagesc(cfg.T,1:nn,zeros(nn,cfg.buffer)); axis xy; %colorbar
  set(H.img_state(i),'visible','off');
  % trace plot
  H.ax_state_plot(i) = subplot('position',[.03 .7+(i-1)*dy .76 -.8*dy],...
    'parent',H.psims,'linewidth',3,'color','w','visible','on');
  if i<length(show)
    set(H.ax_state_plot(i),'xtick',[])
  end
  for k=1:cfg.ncellshow
    H.simdat_alltrace(i,k)=line('color',cfg.colors(max(1,mod(k,length(cfg.colors)))),'LineStyle',cfg.lntype{max(1,mod(k,length(cfg.lntype)))},'erase','background','xdata',cfg.T,'ydata',zeros(1,cfg.buffer),'zdata',[]);
  end
  H.simdat_LFP(i)=line('color',cfg.colors(max(1,mod(k,length(cfg.colors)))),'LineStyle',cfg.lntype{max(1,mod(k,length(cfg.lntype)))},'erase','background','xdata',cfg.T,'ydata',zeros(1,cfg.buffer),'zdata',[],'linewidth',2);
  axis([cfg.T(1) cfg.T(end) -100 30]);
  if i==length(show), xlabel('time'); end
  if ~isempty(vars)
    titlestr=sprintf('%s (n=%g/%g)',strrep(vars{vind},'_','\_'),min(numcells(sel(i)),cfg.ncellshow),numcells(sel(i)));
  else
    titlestr='';
  end
  title(titlestr);
  %H.ax_state_title(i) = title(titlestr);
  %title(strrep(vars{vind},'_','\_'));%[show{i} '.V']);  %ylabel([show{i} '.V']);
  %H.ax_state_power(i) = subplot('position',[.7 .7+(i-1)*dy .25 -.8*dy],'parent',H.psims);
%   H.simdat_LFP_power(i)=line('color','k','LineStyle','-','erase','background','xdata',cfg.f,'ydata',zeros(size(cfg.f)),'zdata',[],'linewidth',2);
end
% % slider control
if isempty(findobj('tag','speed'))
  uicontrol('Style','frame', 'Units','normalized', ...
            'Position',[0.1  0.05 0.41 0.05],'parent',H.psims,'visible','off');
  uicontrol('Style','text', 'Units','normalized',...
            'Position',[0.15  0.075 0.3 0.02],'parent',H.psims,'string','visualization speed','visible','off');
  uicontrol('Style','slider', 'Units','normalized', ...
            'Position',[0.15  0.055 0.3 0.015],'parent',H.psims,'visible','off',...
            'value',0.0, 'tag','speed');
end
if ~isfield(H,'edit_notes')
  H.edit_notes = uicontrol('style','edit','units','normalized','Position',[.02 .03 0.55 .13],'parent',H.psims,...
    'Callback',@RecordNotes,'string','type notes here...','BackgroundColor','w','fontsize',10,'HorizontalAlignment','Left','Max',100);
end

if isempty(findobj('tag','start'))
  % btn: start <=> reset
  uicontrol('Style','pushbutton', 'Units','normalized', ...
            'Position',[0.80  0.05 0.04 0.05],'fontsize',13,...
            'String','start','tag','start','Callback',{@simulate,'restart'}); % start <=> pause
end
if isempty(findobj('tag','pause'))
  % btn: pause <=> resume
  uicontrol('Style','pushbutton', 'Units','normalized', ...
            'Position',[0.85  0.11 0.04 0.05],'visible','off',...
            'String','pause','tag','pause','Callback','global cfg;cfg.pauseflag;cfg.pauseflag=-cfg.pauseflag;');
end

if isempty(findobj('tag','substfunctions'))
  uicontrol('tag','substfunctions','style','checkbox','value',0,'string','accelerate','visible','off',...
    'units','normalized','position',[0.9 0.05 0.075 0.05],...%'backgroundcolor',[.8 .8 .8],...
    'tooltipstring','check to consolidate model; consolidation speeds up simulation but slows down model processing');
end
if 0%isempty(findobj('tag','publish'))
  uicontrol('Style','pushbutton', 'Units','normalized','visible','off', ...
            'Position',[0.9 0.05 0.075 0.05],'tag','publish',... % [0.85  0.11 0.04 0.05]
            'String','get sim_data','Callback','global cfg;cfg.publish=1;');
end
if isempty(findobj('tag','stop'))
  % btn: stop
  uicontrol('Style','pushbutton', 'Units','normalized','visible','off', ...
            'Position',[.8 .11 .04 .05],...
            'String','stop','tag','stop','Callback','global cfg;cfg.quitflag=1;');
end
if isempty(findobj('tag','plottype'))
  % btn: stop
  uicontrol('Style','pushbutton', 'Units','normalized','visible','off', ...
            'Position',[0.85  0.05 0.04 0.05],...
            'String','image','tag','plottype','Callback','global cfg;cfg.plotchange=1;');
end
if isempty(findobj('tag','dtlabel'))
  uicontrol('style','text','tag','dtlabel','string','dt','Units','normalized','position',[.75 .14 .04 .02]);
end
if isempty(findobj('tag','dt'))
  % btn: start <=> reset
  uicontrol('Style','edit','Units','normalized','backgroundcolor','w', ...
            'Position',[0.75  0.11 0.04 0.03],...
            'String',num2str(cfg.dt),'tag','dt','Callback','global cfg; cfg.dt=str2num(get(gcbo,''string''));'); % start <=> pause
end
if isempty(findobj('tag','bufferlabel'))
  uicontrol('style','text','tag','bufferlabel','string','buffer','Units','normalized','position',[.75 .08 .04 .02]);
end                                                   % '#points'
if isempty(findobj('tag','buffer'))
  % btn: start <=> reset
  uicontrol('Style','edit', 'Units','normalized', ...
            'Position',[0.75  0.05 0.04 0.03],'backgroundcolor','w',...
            'String',num2str(cfg.buffer),'tag','buffer','Callback','global cfg; cfg.buffer=str2num(get(gcbo,''string''));'); % start <=> pause
end
% autoscale
uicontrol('Style','pushbutton', 'Units','normalized', ...
          'Position',[0.9 0.11 0.075 0.05],'visible','off',...
          'String','autoscale','tag','autoscale','Callback',{@setlimits,'autoscale'});
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function setlimits(src,evnt,action)
global cfg H CURRSPEC
if ~isfield(cfg,'record'), return; end
allvars=CURRSPEC.variables.labels;
switch action
  case 'autoscale'
    for i=1:length(H.ax_state_plot)
%       list=get(H.lst_vars(i),'string');
%       ind=get(H.lst_vars(i),'value');
%       var = list{ind};
%       ind = find(cellfun(@(x)isequal(x,var),allvars));
%       if ~isempty(ind)
%         rec = cfg.record(ind,:);
%       else
        if strcmp(cfg.plottype,'trace')
          rec = get(H.simdat_alltrace(i,:),'ydata');
          rec = [rec{:}];
          rec(rec==0)=[];
        else
          rec = get(H.img_state(i),'cdata');
          rec(rec==0)=[];
        end
%       end
      ymin = min(rec(:));
      ymax = max(rec(:));
      if ymin~=ymax
        if strcmp(cfg.plottype,'trace')
          set(H.ax_state_plot(i),'ylim',[ymin ymax]);
        elseif strcmp(cfg.plottype,'image')
          set(H.ax_state_img(i),'clim',[ymin ymax]);
        end
      end
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function StaticAutoscale(src,evnt)
global H
if ~isfield(H,'static_traces'), return; end
try
  data=get(H.static_traces,'ydata');
catch
  fprintf('failed to autoscale plot of one-variable functions. may lack dependencies necessary to process functions. try selecting and autoscaling different functions.\n');
  return;
end
if isempty(data)
  return;
elseif ~iscell(data)
  data={data};
end
ymin=min(cellfun(@min,data));
ymax=max(cellfun(@max,data));
if ymin~=ymax
  set(H.ax_static_plot,'ylim',[ymin ymax]);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function CopyCell(src,evnt,compname)
global CURRSPEC H
n=length(CURRSPEC.cells);
ind = strmatch(compname,{CURRSPEC.cells.label},'exact');
lold=CURRSPEC.cells(ind).label;
lnew=sprintf('%s%g',lold,n+1); cnt=1;
while any(strmatch(lnew,{CURRSPEC.cells.label},'exact'))
  lnew=sprintf('%s%g',lold,n+1+cnt); cnt=cnt+1;
end
newspec = CURRSPEC;
newspec.cells(n+1) = CURRSPEC.cells(ind);
newspec.cells(n+1).label = lnew;
newspec.connections(n+1,1:n) = newspec.connections(ind,1:n);
newspec.connections(1:n,n+1) = newspec.connections(1:n,ind);
for i=1:n+1
  l=newspec.connections(n+1,i).label;
  if ischar(l) && ~isempty(regexp(l,['^' lold '-'],'once'))
    l=strrep(l,[lold '-'],[lnew '-']);
  end
  newspec.connections(n+1,i).label=l;
  l=newspec.connections(i,n+1).label;
  if ischar(l) && ~isempty(regexp(l,['-' lold '$'],'once'))
    l=strrep(l,['-' lold],['-' lnew]);
  end
  newspec.connections(i,n+1).label=l;
end
set(H.lst_comps,'string',{newspec.cells.label},'value',[get(H.lst_comps,'value') n+1]);
updatemodel(newspec);
SelectCells;
DrawAuxView;
Display_Mech_Info;
DrawUserParams;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function DeleteCell(src,evnt,compname)
global CURRSPEC cfg
ind = strmatch(compname,{CURRSPEC.cells.label},'exact');
newspec = CURRSPEC;
newspec.cells(ind) = [];
newspec.connections(ind,:) = [];
newspec.connections(:,ind) = [];
cfg.focusconn = 1;
if cfg.focuscomp>=ind
  cfg.focuscomp = max(1,cfg.focuscomp-1);
end
updatemodel(newspec);
SelectCells(src,evnt);
DrawAuxView;
Display_Mech_Info;
DrawUserParams;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function Display_Mech_Info(src,evnt,complabel,mechlabel,type)%mechpos,hmech,connname)
% purpose: display the mech model in a readable form
global H CURRSPEC cfg
if isempty(CURRSPEC.cells), return; end

umech=[]; cnt=1; mechlabels={};
for i=1:length(CURRSPEC.cells)
  for j=1:length(CURRSPEC.cells(i).mechanisms)
    umech(cnt).celllabel = CURRSPEC.cells(i).label;
    umech(cnt).mechlabel = CURRSPEC.cells(i).mechanisms{j};
    umech(cnt).type = 'cells';
    mechlabels{end+1}=sprintf('%s.%s',umech(cnt).celllabel,umech(cnt).mechlabel);
    cnt=cnt+1;
  end
  for j=1:length(CURRSPEC.cells)
    for k=1:length(CURRSPEC.connections(i,j).mechanisms)
      umech(cnt).celllabel = CURRSPEC.connections(i,j).label;
      umech(cnt).mechlabel = CURRSPEC.connections(i,j).mechanisms{k};
      umech(cnt).type = 'connections';
      mechlabels{end+1}=sprintf('%s.%s',strrep(umech(cnt).celllabel,'-','->'),umech(cnt).mechlabel);
      cnt=cnt+1;
    end
  end
end
oldmechs=get(H.lst_mechs,'string');
oldvalue=get(H.lst_mechs,'value');
if numel(oldmechs)>=1 && numel(oldvalue)>=1
  oldmech=oldmechs{oldvalue};
else
  oldmech=[];
end
if ~isequal(oldmechs,mechlabels)
  if ~isempty(oldmech)
    newvalue=find(strcmp(oldmech,mechlabels));
  else
    newvalue=1;
  end
  newmechs=mechlabels;
else
  newvalue=oldvalue;
  newmechs=oldmechs;
end
if isempty(newvalue) && length(newmechs)>0%1
  newvalue=1;
end
% update mech list
set(H.lst_mechs,'string',newmechs,'value',newvalue,'userdata',umech);

% update mech text
if isempty(umech)
  return;
end
m=umech(newvalue);
if isempty(m), return; end
cfg.focus=find(cellfun(@(x)isequal(m.celllabel,x),{CURRSPEC.(m.type).label}));
cfg.focustype=m.type;
focusmech=find(strcmp(m.mechlabel,CURRSPEC.(m.type)(cfg.focus).mechanisms));
u.focustype=cfg.focustype;
u.focus=cfg.focus;
u.mechlabel=m.mechlabel;
mech = CURRSPEC.(cfg.focustype)(cfg.focus).mechs(focusmech);
set(H.txt_mech,'string',mech_spec2str(mech),'userdata',u);

% update mech plot
DrawAuxFunctions;

% if isempty(newmechs) && ~isempty(cfg.newmechs)
%   Display_Mech_Info; %newmechs=cfg.newmechs;
% end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function SaveMech(src,evnt)
global CURRSPEC cfg H allmechs
% purpose: write mech to new file
UpdateMech;
txt = get(H.txt_mech,'string');
if isempty(txt)
  msgbox('empty mechanism. nothing to write.');
  return;
end
% get file name
u=get(H.txt_mech,'userdata');
defaultname=[u.mechlabel '.txt'];
[filename,pathname] = uiputfile({'*.txt;'},'Save as',defaultname);
if isequal(filename,0) || isequal(pathname,0)
  return;
end
outfile = fullfile(pathname,filename);
fid = fopen(outfile,'wt');
for i=1:length(txt)
  fprintf(fid,[txt{i} '\n']);
end
fclose(fid);
fprintf('mechanism written to file: %s\n',outfile);
% update internal structures
thiscell=CURRSPEC.(u.focustype)(u.focus);
mind=strcmp(u.mechlabel,thiscell.mechanisms);
thismech=thiscell.mechs(mind);
thismech.file=outfile;
allmechs(strcmp(u.mechlabel,{allmechs.label}))=thismech;
cfg.allmechfiles{end+1}=outfile;
CURRSPEC.files{end+1}=outfile;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function UpdateMech(src,evnt)%,htxt,connname,mechname)
% purpose: apply user changes to the mech model
global CURRSPEC H cfg allmechs
if isempty(get(H.edit_comp_mechs,'string')) % create mechanism container
  if strcmp(get(H.btn_resizemech,'string'),'expand')
    ResizeMechEditor(H.btn_resizemech,[]);
  end
  set(H.edit_comp_mechs,'string','mech');
  v=get(H.lst_comps,'value');
  l=get(H.lst_comps,'string');
  txt = get(H.txt_mech,'string');
  UpdateCells(H.edit_comp_mechs,[],l{v(1)},'mechanisms');
  if ischar(txt), txt={txt}; end
  set(H.txt_mech,'string',txt);
end
u=get(H.txt_mech,'userdata');
txt = get(H.txt_mech,'string');
newmech = parse_mech_spec(txt);
newmech.label = u.mechlabel;
if ismember(newmech.label,cfg.newmechs)
  ind=find(strcmp(newmech.label,{allmechs.label})); % index into allmechs
  ind2=ismember(cfg.newmechs,newmech.label); % index into cfg.newmechs
  tmp=newmech;
  tmp.file=allmechs(ind).file;
  allmechs(ind)=tmp;
  cfg.newmechs(ind2)=[];
end
spec=CURRSPEC;
this = spec.(u.focustype)(u.focus);
if ~iscell(this.mechanisms), this.mechanisms={this.mechanisms}; end
mech_i = find(strcmp(u.mechlabel,this.mechanisms));
if ~isempty(mech_i)
  newmech = rmfield(newmech,setdiff(fieldnames(newmech),fieldnames(this.mechs)));
  this.mechs(mech_i) = newmech;
else
  this.mechs(end+1)=newmech;
  this.mechanisms{end+1}=u.mechlabel;
end
spec.(u.focustype)(u.focus) = this;
updatemodel(spec);
DrawAuxFunctions;
DrawAuxView;
Display_Mech_Info;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function UpdateCells(src,evnt,compname,field)
% apply user changes to the compartment mechanisms
global cfg CURRSPEC H
this = strmatch(compname,{CURRSPEC.cells.label},'exact');
if numel(this)>1, this = this(1); end
newspec = CURRSPEC;
switch field
  case {'parent','label'}
    newspec.cells(this).(field) = get(src,'string');
    updatemodel(newspec);
    l1={newspec.cells.label};
    l2={newspec.cells.parent};
    l=cellfun(@(x,y)[x '.' y],l2,l1,'uni',0);
    set(H.lst_comps,'string',l);
    SelectCells;
  case 'multiplicity'
    newspec.cells(this).(field) = str2num(get(src,'string'));
    updatemodel(newspec);
  case 'mechanisms'
    mechlist = newspec.cells(this).mechanisms;
    str = get(src,'string');
    if isempty(str)
      newmechlist = {};
    else
      newmechlist = strtrim(strread(str,'%s','delimiter',','));
    end
    mechadded = setdiff(newmechlist,mechlist);
    mechremoved = setdiff(mechlist,newmechlist);
    if ~isempty(mechadded) || ~isempty(mechremoved)
      newspec = removemech(newspec,mechremoved,'cells',this);
      newspec = addmech(newspec,mechadded,'cells',this);
      updatemodel(newspec);
    end
  case 'dynamics'
    newspec.cells(this).(field) = get(src,'string'); % strread(get(src,'string'),'%s','delimiter',',');
    updatemodel(newspec);
end
Display_Mech_Info;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function UpdateNet(src,evnt,connname)
% apply user changes to the connection mechanisms
global cfg CURRSPEC
newspec = CURRSPEC;
if isempty(connname) % first connection b/w these compartments...
  u=get(src,'UserData');
  connname = [u.from '-' u.to];
  source=find(strcmp({newspec.cells.label},u.from));
  target=find(strcmp({newspec.cells.label},u.to));
  newspec.connections(source,target).label = connname;
  set(src,'ButtonDownFcn',{@Display_Mech_Info,connname,{},'connections'});
end
cfg.focusconn = find(cellfun(@(x)isequal(connname,x),{newspec.connections.label}));
if ~isempty(cfg.focusconn)
  mechlist = newspec.connections(cfg.focusconn).mechanisms;
else
  cfg.focusconn = 1;
  mechlist = {};
end
str = get(src,'string');
if isempty(str)
  newmechlist = {};
else
  newmechlist = strtrim(strread(str,'%s','delimiter',','));
end
mechadded = setdiff(newmechlist,mechlist);
mechremoved = setdiff(mechlist,newmechlist);
if ~isempty(mechadded) || ~isempty(mechremoved)
  newspec = removemech(newspec,mechremoved,'connections',cfg.focusconn);
  newspec = addmech(newspec,mechadded,'connections',cfg.focusconn);
  if isempty(newspec.connections(cfg.focusconn).mechanisms)
    newspec.connections(cfg.focusconn).label = [];
  end
  updatemodel(newspec);
  DrawAuxView;
  DrawNetGrid;
end
Display_Mech_Info;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function CURRSPEC = addmech(CURRSPEC,mechadded,type,index)
% purpose: add a mechanism to the compartment model
global allmechs cfg
if isempty(mechadded), return; end
if ~iscell(mechadded), mechadded={mechadded}; end
% addfile_flag=1;
for i=1:length(mechadded)
  newmech = mechadded{i};
  mechind = find(strcmp({allmechs.label},newmech),1,'last');
  if exist(fullfile(pwd,[newmech '.txt.']),'file') % && isempty(mechind)
    file=fullfile(pwd,[newmech '.txt.']);
    this = parse_mech_spec(file,[]);
    cfg.allmechfiles{end+1}=file;
    this.label = newmech;
    this.file = file;
    allmechs(end+1)=this;
    newmech=this;
    mechind=length(allmechs);
  else
    newmech = allmechs(mechind);
  end
  if isempty(newmech)
    fprintf('Creating new mechanism: %s\n',mechadded{i});
    this.params=[];
    this.auxvars={};
    this.functions={};
    this.statevars={};
    this.odes={};
    this.ic={};
    this.substitute={};
    this.inputvars={};
    this.label = mechadded{i};
    this.file = '';%'new';
%     addfile_flag=0;
    cfg.allmechfiles{end+1}=this.file;
    allmechs(end+1)=this;
    newmech=this;
    mechind=length(allmechs);
    cfg.newmechs{end+1}=this.label;
    %warndlg([mechadded{i} ' not found. Check spelling and case.']);
    %disp('known mechanisms include: '); disp(get_mechlist');
  end
%   else
    newmech = rmfield(newmech,'file');
    if ~isempty(CURRSPEC.(type)(index)) && isfield(CURRSPEC.(type)(index),'mechs') && isstruct(CURRSPEC.(type)(index).mechs)
      newmech = rmfield(newmech,setdiff(fieldnames(newmech),fieldnames(CURRSPEC.(type)(index).mechs)));
      CURRSPEC.(type)(index).mechs(end+1)=newmech;
    else
      CURRSPEC.(type)(index).mechs = newmech;
    end
    CURRSPEC.(type)(index).mechanisms{end+1}=mechadded{i};
%     if addfile_flag
      CURRSPEC.files{end+1} = cfg.allmechfiles{mechind};
%     end
%   end
end
Display_Mech_Info;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function CURRSPEC = removemech(CURRSPEC,mechremoved,type,index)
% purpose: remove a mechanism from the compartment model
global cfg
if isempty(mechremoved), return; end
if ~iscell(mechremoved), mechremoved={mechremoved}; end
for i=1:length(mechremoved)
  oldmech = mechremoved{i};
  oldmech = find(strcmp(CURRSPEC.(type)(index).mechanisms,oldmech));
  if ~isempty(oldmech)
    CURRSPEC.(type)(index).mechs(oldmech)=[];
    CURRSPEC.(type)(index).mechanisms(oldmech)=[];
  end
end
Display_Mech_Info;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function undo(src,evnt)
% revert to the last working model
global LASTSPEC
updatemodel(LASTSPEC);
refresh;%SelectCells;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function refresh(src,evnt,where)
if 1
  % load all mech data (if db has changed)
  global allmechs cfg
  [allmechlist,allmechfiles]=get_mechlist(cfg.DBPATH);
  if ~isequal(cfg.allmechfiles_db,allmechfiles)
    cfg.allmechfiles_db=allmechfiles;
    cfg.allmechfiles=unique({cfg.allmechfiles{:},allmechfiles{:}});
    for i=1:length(cfg.allmechfiles)
      this = parse_mech_spec(cfg.allmechfiles{i},[]);
      [fpath,fname,fext]=fileparts(cfg.allmechfiles{i});
      this.label = fname;
      this.file = cfg.allmechfiles{i};
      if i==1, allmechs = this;
      else allmechs(i) = this;
      end
    end
  end
end
if nargin<3 || where==0
%   global CURRSPEC
%   updatemodel(CURRSPEC);
elseif where==1 % get spec from base workspace
  if ismember('spec',evalin('base','who'))
    updatemodel(evalin('base','spec'));
  else
    return;
  end
end
SelectCells;
DrawSimPlots; % ??? should this be here???
DrawAuxView;
DrawAuxFunctions;
DrawUserParams;%([],[],[],0);
DrawStudyInfo;
UpdateHistory;
Display_Mech_Info;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function printmodel(src,evnt)
global CURRSPEC
buildmodel(CURRSPEC,'verbose',1,'nofunctions',get(findobj('tag','substfunctions'),'value'));
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
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function N=get_neighb(n,xi,yi)
% purpose: get neighborhood of a given grid element
% N = linear identifiers for neighbors of compartment at (x,y) in grid
% n = # of elements in grid
% x,y = row,col indices (increasing away from top-left corner)
id=flipud(reshape(1:n,sqrt([n n])));
N=[xi-1,yi-1; xi-1,yi; xi-1,yi+1; xi,yi+1; xi+1,yi+1; xi+1,yi; xi+1,yi-1; xi,yi-1];
N(N<1)=1; N(N>sqrt(n))=sqrt(n);
N=cellfun(@(x,y)id(x,y),num2cell(N(:,1)),num2cell(N(:,2)));
N(N==id(xi,yi))=[];
[jnk,I]=unique(N,'first');
N=N(sort(I));
function conninds=get_connected(spec,compind)
% purpose: get compartments connected to a target compartment
% conninds = linear indices in spec.connections(conninds) of cell/comp types
%            connected to spec.cells(compind).
conninds=[];
if size(spec.connections,1)>=compind
  conninds=[conninds find(~cellfun(@isempty,{spec.connections(compind,:).label}))];
end
if size(spec.connections,2)>=compind
  conninds=[conninds find(~cellfun(@isempty,{spec.connections(:,compind).label}))];
end
conninds=unique(conninds);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function changename(src,evnt)
global currspec
name=get(src,'string');
[currspec.cells.parent]=deal(name);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function disperror(err)
  fprintf('Error: %s\n',err.message);
  for i=1:length(err.stack)
    fprintf('\t in %s (line %g)\n',err.stack(i).name,err.stack(i).line);
  end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function ZoomFunction(src,evnt)
global H cfg
if isfield(H,'ax_static_plot') && isequal(gco,H.ax_static_plot)
  hplot=H.ax_static_plot;
  prop='ylim';
elseif isfield(H,'img_auxvar') && isequal(gco,H.img_auxvar)
  hplot=H.ax_conn_img;
  prop='clim';
elseif (isfield(H,'img_state') && ismember(gco,H.img_state)) || (isfield(H,'ax_state_plot') && ismember(gco,H.ax_state_plot)) || (isfield(H,'simdat_alltrace') && ismember(gco,H.simdat_alltrace))
  if strcmp(cfg.plottype,'trace')
    if ismember(gco,H.ax_state_plot)
      hplot=H.ax_state_plot(gco==H.ax_state_plot);
    elseif ismember(gco,H.simdat_alltrace)
      hplot=get(H.simdat_alltrace(H.simdat_alltrace==gco),'parent');
    end
    prop='ylim';
  elseif strcmp(cfg.plottype,'image')
    hplot=H.ax_state_img(gco==H.img_state);
    prop='clim';
  end
else
  return;
end
LIM = get(hplot,prop);
if isempty(LIM) || LIM(1)==LIM(2), return; end
if evnt.VerticalScrollCount < 0           % zoom in
  if LIM(1)>0, LIM(1)=LIM(1)*1.5; else LIM(1)=LIM(1)/1.5; end
  if LIM(2)>0, LIM(2)=LIM(2)/1.5; else LIM(1)=LIM(1)*1.5; end
  set(hplot,prop,LIM);
else                                      % zoom out
  if LIM(1)>0, LIM(1)=LIM(1)/1.5; else LIM(1)=LIM(1)*1.5; end
  if LIM(2)>0, LIM(2)=LIM(2)*1.5; else LIM(1)=LIM(1)/1.5; end
  set(hplot,prop,LIM);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function DrawAuxFunctions(src,evnt,limflag)
global H cfg CURRSPEC
if nargin<3, limflag=0; end
if limflag
  l=str2num(get(H.edit_static_lims,'string'));
  cfg.V=linspace(l(1),l(2),cfg.buffer);
end
% get list of functions in focuscomp
maxlhs = 20; % limit how much is shown in the listbox
maxlen = 150;
funcs={};
for i=1:length(CURRSPEC.cells)
  keep=(~cellfun(@isempty,regexp(CURRSPEC.cells(i).functions(:,2),'^@\([^,]+\) ','match')));
  funcs=cat(1,funcs,CURRSPEC.cells(i).functions(keep,:));
end
%funcs = CURRSPEC.cells(cfg.focuscomp).functions;
len = min(maxlhs,max(cellfun(@length,funcs(:,1))));
str = {};
for i=1:size(funcs,1)
  str{i} = funcs{i,1};
  %str{i} = sprintf(['%-' num2str(len) 's  = %s'],funcs{i,1},strrep(funcs{i,2},' ',''));
  if length(str{i})>maxlen, str{i}=str{i}(1:maxlen); end
end
% get list of functions in aux listbox
sel = get(H.lst_static_funcs,'value');
list = get(H.lst_static_funcs,'string');
if ~isequal(list,str)
  sel=sel(sel<=length(str));
  set(H.lst_static_funcs,'string',str);
  set(H.lst_static_funcs,'value',sel);
  list=str;
end
functions = funcs(sel,:);%CURRSPEC.cells(cfg.focuscomp).functions(sel,:);
% manage curves
if isfield(H,'static_traces')
  axislimits=[get(H.ax_static_plot,'xlim') get(H.ax_static_plot,'ylim')];
  try delete(H.static_traces); end
  H=rmfield(H,'static_traces');
  cla(H.ax_static_plot);
else
  axislimits='tight';
end
for k=1:size(funcs,1)
  try
    eval(sprintf('%s=%s;',funcs{k,1},funcs{k,2}));
  end
end

% only consider functions of one variable
keep = zeros(size(sel));
for k=1:length(sel)
  var = regexp(functions{k,2},'@\([\w,]+\)','match'); var=var{1};
  if length(strread(var,'%s','delimiter',','))==1
    keep(k)=1;
  end
end
functions = functions(keep==1,:);
X = cfg.V; cnt=1;
keep=zeros(size(functions,1),1);
for k=1:size(functions,1)
  %f = str2func(functions{k,2});
  try
    %Y = f(X);
    eval(sprintf('Y=%s(X);',functions{k,1}));
    H.static_traces(cnt)=line('parent',H.ax_static_plot,'color',cfg.colors(max(1,mod(k,length(cfg.colors)))),...
      'LineStyle',cfg.lntype{max(1,mod(k,length(cfg.lntype)))},'erase','background','xdata',X,'ydata',Y,'zdata',[]);
    cnt=cnt+1;
    keep(k)=1;
  end
end
functions = functions(keep==1,:);
funclabels=cellfun(@(x)strrep(x,'_','\_'),functions(:,1),'uni',0);
if isfield(H,'static_traces') && ~isempty(H.static_traces)
  h=legend(H.ax_static_plot,funclabels); set(h,'fontsize',6,'location','EastOutside');
  if strcmp(axislimits,'tight')
    axes(H.ax_static_plot); axis(axislimits);
  else
    set(H.ax_static_plot,'xlim',axislimits(1:2),'ylim',axislimits(3:4));
  end
end
if limflag
  set(H.ax_static_plot,'xlim',[min(cfg.V(:)) max(cfg.V(:))]);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function DrawUserParams(src,evnt,jnk,movetabs)
if nargin<4, movetabs=0; end
global CURRSPEC cfg H
bgcolor=cfg.bgcolor;
if movetabs
  % switch to cellview:
  set(findobj('tag','ptoggle'),'visible','off');
  set(findobj('tag','tab'),'backgroundcolor',[1 1 1]);
  set(findobj('userdata','pcell'),'visible','on');
  set(H.bcell,'backgroundcolor',[.7 .7 .7]);
end

uparm=[]; cnt=1; parmlabels={};
for i=1:length(CURRSPEC.cells)
  for j=1:length(CURRSPEC.cells(i).parameters)/2
    uparm(cnt).celllabel = CURRSPEC.cells(i).label;
    uparm(cnt).parmlabel = CURRSPEC.cells(i).parameters{1+2*(j-1)};
    uparm(cnt).parmvalue = CURRSPEC.cells(i).parameters{2*j};
    uparm(cnt).type = 'cells';
    parmlabels{end+1}=sprintf('%s.%s',uparm(cnt).celllabel,uparm(cnt).parmlabel);
    cnt=cnt+1;
  end
  for j=1:length(CURRSPEC.cells)
    for k=1:length(CURRSPEC.connections(i,j).parameters)/2
      uparm(cnt).celllabel = CURRSPEC.connections(i,j).label;
      uparm(cnt).parmlabel = CURRSPEC.connections(i,j).parameters{1+2*(k-1)};
      uparm(cnt).parmvalue = CURRSPEC.connections(i,j).parameters{2*k};
      uparm(cnt).type = 'connections';
      parmlabels{end+1}=sprintf('%s.%s',uparm(cnt).celllabel,uparm(cnt).parmlabel);
      cnt=cnt+1;
    end
  end
end

if ~isempty(uparm)
  parmind=1;
  parmval=num2str(uparm(parmind).parmvalue);
else
  parmind=[];
  parmval='';
  parmlabels='';
end
if ~isfield(H,'lst_parms') || ~ishandle(H.lst_parms)
  H.lst_parms = uicontrol('parent',H.pcell,'units','normalized','BackgroundColor',[.9 .9 .9],'Max',1,'TooltipString','Right-click to edit parameter name. Hit ''d'' to delete.',...
    'position',[0 0 .2 1],'style','listbox','value',parmind,'string',parmlabels,...
    'ButtonDownFcn',@RenameParm,'Callback',{@UpdateParams,'show'},'KeyPressFcn',{@UpdateParams,'delete'},'userdata',uparm);
  uicontrol('style','text','BackgroundColor',bgcolor,'parent',H.pcell,'units','normalized','string','add/update parameter:',...
    'position',[.3 .85 .6 .05],'HorizontalAlign','Left');
  H.edit_parmadd = uicontrol('parent',H.pcell,'units','normalized','style','edit','TooltipString','format: source-target.param = value',...
    'position',[.3 .8 .6 .05],'backgroundcolor','w','string','name = value',...
    'HorizontalAlignment','left','Callback',{@UpdateParams,'add'});
%   uicontrol('style','text','parent',H.pcell,'units','normalized','string','update value:',...
%     'position',[.3 .7 .6 .05],'HorizontalAlign','Left');
  H.edit_parmedit = uicontrol('parent',H.pcell,'units','normalized','style','edit','TooltipString','select parameter in list and enter new value here',...
    'position',[0 0 .2 .05],'backgroundcolor','w','string',parmval,...
    'HorizontalAlignment','left','Callback',{@UpdateParams,'change'},'visible','off');
else
  set(H.lst_parms,'value',parmind,'string',parmlabels,'userdata',uparm);
  set(H.edit_parmedit,'string',parmval);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function UpdateParams(src,evnt,action)
global H CURRSPEC
uparm=get(H.lst_parms,'userdata');
sel=get(H.lst_parms,'value');
switch action
  case 'show'
    s=get(H.lst_parms,'string');
    val=num2str(uparm(sel).parmvalue);
    set(H.edit_parmadd,'string',[s{sel} ' = ' val]);
    set(H.edit_parmedit,'string',val);
  case 'change'
    newspec=CURRSPEC;
    u=uparm(sel);
    cellind=cellfun(@(x)isequal(x,u.celllabel),{newspec.(u.type).label});
    keys=newspec.(u.type)(cellind).parameters(1:2:end);
    parmind = 2*find(strcmp(u.parmlabel,keys));
    newspec.(u.type)(cellind).parameters{parmind}=str2double(get(H.edit_parmedit,'string'));
    updatemodel(newspec);
    DrawUserParams;
  case 'add' % format: source-target.param = value
    newspec=CURRSPEC;
    str = get(H.edit_parmadd,'string');
    if isempty(str), return; end
    parts=strread(str,'%s','delimiter','=');
    value = str2double(strtrim(parts{2}));
    parts=strread(parts{1},'%s','delimiter','.');
    if numel(parts)==1 && length(CURRSPEC.cells)==1
      parts={CURRSPEC.cells(1).label,parts{1}};
    elseif numel(parts)==1
      parts={'__all__',parts{1}};
      %msgbox('improper syntax. use: compartment.parameter = value','syntax error','error');
      %return;
    end
    param= strtrim(parts{2});
    tmpparts=strread(parts{1},'%s','delimiter','-');
    if numel(tmpparts)==1
      type='cells';
      if strcmp(parts{1},'__all__')
        targets=1:length(CURRSPEC.cells);
      else
        target=find(strcmp(strtrim(parts{1}),{CURRSPEC.cells.label}));
        targets=target;
      end
    elseif numel(parts)==2
      type='connections';
      target=find(cellfun(@(x)isequal(strtrim(parts{1}),x),{CURRSPEC.connections.label}));
      if isempty(target)
        src=tmpparts{1}; srcind=find(strcmp(strtrim(src),{CURRSPEC.cells.label}));
        dst=tmpparts{2}; dstind=find(strcmp(strtrim(dst),{CURRSPEC.cells.label}));
        target=sub2ind(size(CURRSPEC.connections),srcind,dstind);
      end
      targets=target;
    end
    for i=1:length(targets)
      target=targets(i);
      tmp=newspec.(type)(target).parameters;
      if ~iscell(tmp)
        tmp={};
      end
      if ~isempty(tmp) && any(ismember(param,tmp(1:2:end))) % param already exists. just update it.
        ind=2*find(strcmp(param,tmp(1:2:end)));
        newspec.(type)(target).parameters{ind}=value;
      else % new parameter. add it.
        newspec.(type)(target).parameters{end+1}=param;
        newspec.(type)(target).parameters{end+1}=value;
      end
    end
    updatemodel(newspec);
    DrawUserParams;
  case 'delete' % on KeyPress 'd' or 'delete'
    if strcmp(evnt.Key,'d') || strcmp(evnt.Key,'delete')
      newspec=CURRSPEC;
      u=uparm(sel);
      cellind=cellfun(@(x)isequal(x,u.celllabel),{newspec.(u.type).label});
      keys=newspec.(u.type)(cellind).parameters(1:2:end);
      parmind = 2*find(strcmp(u.parmlabel,keys))-1;
      % remove parameter
      if ~isempty(parmind)
        newspec.(u.type)(cellind).parameters([parmind parmind+1])=[];
      else
        return;
      end
      updatemodel(newspec);
      DrawUserParams;
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function DrawStudyInfo
global cfg H
if isfield(cfg,'study')
  study = cfg.study;
else
  study.scope = '';
  study.variable = '';
  study.values = '';
  cfg.study = study;
end
bgcolor=cfg.bgcolor;
bgcolor2='w';
% H.pbatchcontrols = pbatchcontrols;
% H.pbatchspace = pbatchspace;
% H.pbatchoutputs = pbatchoutputs;
if ~isfield(H,'text_scope') || ~ishandle(H.text_scope)
  % controls
  yshift=-.05; ht=.17;
  uicontrol('parent',H.pbatchcontrols,'units','normalized','backgroundcolor',bgcolor,...
    'style','text','position',[.05 .75+yshift .13 .2],'string','machine',...
    'HorizontalAlignment','left');%,'backgroundcolor','w'
  uicontrol('parent',H.pbatchcontrols,'units','normalized','backgroundcolor',bgcolor,...
    'style','text','position',[.5 .75+yshift .13 .2],'string','memlimit',...
    'HorizontalAlignment','right');%,'backgroundcolor','w'
  uicontrol('parent',H.pbatchcontrols,'units','normalized','backgroundcolor',bgcolor,...
    'style','text','position',[.05 .5+yshift .13 .2],'string','timelimits',...
    'HorizontalAlignment','left');%,'backgroundcolor','w'
  uicontrol('parent',H.pbatchcontrols,'units','normalized','backgroundcolor',bgcolor,...
    'style','text','position',[.05 .3+yshift .13 .2],'string','solver',...
    'HorizontalAlignment','left');%,'backgroundcolor','w'
  uicontrol('parent',H.pbatchcontrols,'units','normalized','backgroundcolor',bgcolor,...
    'style','text','position',[.3 .3+yshift .13 .2],'string','dt',...
    'HorizontalAlignment','right');%,'backgroundcolor','w'
  uicontrol('parent',H.pbatchcontrols,'units','normalized',...
    'style','text','position',[.05 .1+yshift .13 .2],'string','#repeats','backgroundcolor',bgcolor,...
    'HorizontalAlignment','left');%,'backgroundcolor','w'
  H.rad_machine=uibuttongroup('visible','off','units','normalized','backgroundcolor',bgcolor2,'Position',[.18 .8+yshift .3 .2],'parent',H.pbatchcontrols);
  H.rad_machine_1=uicontrol('style','radiobutton','backgroundcolor',bgcolor2,'string','local','parent',H.rad_machine,'HandleVisibility','off',...
    'units','normalized','pos',[0 0 .4 1]);
  H.rad_machine_2=uicontrol('style','radiobutton','backgroundcolor',bgcolor2,'string','cluster','parent',H.rad_machine,'HandleVisibility','off',...
    'units','normalized','pos',[.45 0 .5 1]);
  set(H.rad_machine,'SelectedObject',H.rad_machine_1);  % No selection
  set(H.rad_machine,'Visible','on');
  H.edit_memlimit = uicontrol('parent',H.pbatchcontrols,'units','normalized',...
    'style','edit','position',[.65 .8+yshift .1 ht],'backgroundcolor','w','string','8G',...
    'HorizontalAlignment','left');
  H.edit_timelimits = uicontrol('parent',H.pbatchcontrols,'units','normalized',...
    'style','edit','position',[.18 .55+yshift .2 ht],'backgroundcolor','w','string','[0 40]',...
    'HorizontalAlignment','left');
  H.edit_SOLVER = uicontrol('parent',H.pbatchcontrols,'units','normalized',...
    'style','edit','position',[.18 .35+yshift .2 ht],'backgroundcolor','w','string','euler',...
    'HorizontalAlignment','left');
  H.edit_dt = uicontrol('parent',H.pbatchcontrols,'units','normalized',...
    'style','edit','position',[.45 .35+yshift .1 ht],'backgroundcolor','w','string','0.01',...
    'HorizontalAlignment','left');
  H.edit_repeats = uicontrol('parent',H.pbatchcontrols,'units','normalized',...
    'style','edit','position',[.18 .15+yshift .2 ht],'backgroundcolor','w','string','1',...
    'HorizontalAlignment','left');
  % search space
  H.text_scope = uicontrol('parent',H.pbatchspace,'units','normalized','backgroundcolor',bgcolor,...
    'style','text','position',[.1 .9 .1 .05],'string','scope',...
    'HorizontalAlignment','center');%,'backgroundcolor','w'
  H.text_variable = uicontrol('parent',H.pbatchspace,'units','normalized','backgroundcolor',bgcolor,...
    'style','text','position',[.31 .9 .1 .05],'string','variable',...
    'HorizontalAlignment','center');%,'backgroundcolor','w'
  H.text_values = uicontrol('parent',H.pbatchspace,'units','normalized','backgroundcolor',bgcolor,...
    'style','text','position',[.52 .9 .1 .05],'string','values',...
    'HorizontalAlignment','center'); %,'backgroundcolor','w'
  H.btn_batch_help = uicontrol('parent',H.pbatchspace,'units','normalized',...
    'style','pushbutton','fontsize',10,'string','help','callback','web(''https://github.com/cogrhythms/dsim/tree/master/matlab/readme'',''-browser'');',...
    'position',[.85 .92 .1 .06]);
  % outputs
  uicontrol('parent',H.pbatchoutputs,'units','normalized','backgroundcolor',bgcolor,...
    'style','text','position',[.05 .85 .13 .1],'string','rootdir',...
    'HorizontalAlignment','left');%,'backgroundcolor','w'
  uicontrol('parent',H.pbatchoutputs,'units','normalized','backgroundcolor',bgcolor,...
    'style','text','position',[.8 .85 .1 .1],'string','dsfact',...
    'HorizontalAlignment','right');%,'backgroundcolor','w'
  uicontrol('parent',H.pbatchoutputs,'units','normalized','backgroundcolor',bgcolor,...
    'style','text','position',[.05 .7 .1 .1],'string','save',...
    'HorizontalAlignment','right');%,'backgroundcolor','w'
  uicontrol('parent',H.pbatchoutputs,'units','normalized','backgroundcolor',bgcolor,...
    'style','text','position',[.3 .7 .1 .1],'string','plot',...
    'HorizontalAlignment','right');%,'backgroundcolor','w'
  H.edit_rootdir = uicontrol('parent',H.pbatchoutputs,'units','normalized',...
    'style','edit','position',[.15 .85 .65 .15],'backgroundcolor','w','string',pwd,...
    'HorizontalAlignment','left');
  H.edit_dsfact = uicontrol('parent',H.pbatchoutputs,'units','normalized',...
    'style','edit','position',[.92 .85 .05 .15],'backgroundcolor','w','string','1',...
    'HorizontalAlignment','left');
  H.btn_run_simstudy = uicontrol('parent',H.pbatchoutputs,'units','normalized',...
    'style','pushbutton','fontsize',20,'string','submit!','callback',@RunSimStudy,...
    'position',[.67 .27 .3 .4]);
  H.chk_overwrite=uicontrol('style','checkbox','value',0,'parent',H.pbatchoutputs,'backgroundcolor',bgcolor2,'units','normalized','position'   ,[.83 .75 .14 .08],'string','overwrite');
  H.chk_savedata=uicontrol('style','checkbox','value',0,'parent',H.pbatchoutputs,'backgroundcolor',bgcolor2,'units','normalized','position'   ,[.13 .6 .15 .1],'string','data');
  H.chk_savesum=uicontrol('style','checkbox','value',0,'parent',H.pbatchoutputs,'backgroundcolor',bgcolor2,'units','normalized','position'    ,[.13 .5 .15 .1],'string','popavg');
  H.chk_savespikes=uicontrol('style','checkbox','value',0,'parent',H.pbatchoutputs,'backgroundcolor',bgcolor2,'units','normalized','position' ,[.13 .4 .15 .1],'string','spikes');
  H.chk_saveplots=uicontrol('style','checkbox','value',0,'parent',H.pbatchoutputs,'backgroundcolor',bgcolor2,'units','normalized','position'  ,[.13 .3 .15 .1],'string','plots');
  H.chk_plottraces=uicontrol('style','checkbox','value',1,'parent',H.pbatchoutputs,'backgroundcolor',bgcolor2,'units','normalized','position' ,[.38 .6 .17 .1],'string','state vars');
  H.chk_plotrates=uicontrol('style','checkbox','value',0,'parent',H.pbatchoutputs,'backgroundcolor',bgcolor2,'units','normalized','position'  ,[.38 .5 .17 .1],'string','spike rates');
  H.chk_plotspectra=uicontrol('style','checkbox','value',0,'parent',H.pbatchoutputs,'backgroundcolor',bgcolor2,'units','normalized','position',[.38 .4 .17 .1],'string','spectrum');
end
if isfield(H,'edit_scope')
  if ishandle(H.edit_scope)
    delete(H.edit_scope);
    delete(H.edit_variable);
    delete(H.edit_values);
    delete(H.btn_simset_delete);
    delete(H.btn_simset_copy);
  end
  H = rmfield(H,{'edit_scope','edit_variable','edit_values','btn_simset_delete','btn_simset_copy'});
end
for i=1:length(study)
  H.edit_scope(i) = uicontrol('parent',H.pbatchspace,'units','normalized',...
    'style','edit','position',[.1 .8-.1*(i-1) .2 .08],'backgroundcolor','w','string',study(i).scope,...
    'HorizontalAlignment','left','Callback',sprintf('global cfg; cfg.study(%g).scope=get(gcbo,''string'');',i));
  H.edit_variable(i) = uicontrol('parent',H.pbatchspace,'units','normalized',...
    'style','edit','position',[.31 .8-.1*(i-1) .2 .08],'backgroundcolor','w','string',study(i).variable,...
    'HorizontalAlignment','left','Callback',sprintf('global cfg; cfg.study(%g).variable=get(gcbo,''string'');',i));
  H.edit_values(i) = uicontrol('parent',H.pbatchspace,'units','normalized',...
    'style','edit','position',[.52 .8-.1*(i-1) .4 .08],'backgroundcolor','w','string',study(i).values,...
    'HorizontalAlignment','left','Callback',sprintf('global cfg; cfg.study(%g).values=get(gcbo,''string'');',i));
  H.btn_simset_delete(i) = uicontrol('parent',H.pbatchspace,'units','normalized',...
    'style','pushbutton','fontsize',10,'string','-','callback',{@DeleteSimSet,i},...
    'position',[.06 .8-.1*(i-1) .03 .08]);
  H.btn_simset_copy(i) = uicontrol('parent',H.pbatchspace,'units','normalized',...
    'style','pushbutton','fontsize',10,'string','+','callback',{@CopySimSet,i},...
    'position',[.93 .8-.1*(i-1) .03 .08]);
end
function DeleteSimSet(src,evnt,index)
global cfg
cfg.study(index) = [];
DrawStudyInfo;
function CopySimSet(src,evnt,index)
global cfg
cfg.study(end+1) = cfg.study(index);
DrawStudyInfo;
function RunSimStudy(src,evnt)
global cfg CURRSPEC H BACKUPFILE BIOSIMROOT
if isempty(CURRSPEC.cells), return; end
if isempty([cfg.study.scope]) && isempty([cfg.study.variable])
  cfg.study.scope=CURRSPEC.cells(1).label;
  cfg.study.variable='N';
  cfg.study.values=sprintf('[%g]',CURRSPEC.cells(1).multiplicity);
end
scope = {cfg.study.scope};
variable = {cfg.study.variable};
values = {cfg.study.values};
dir=get(H.edit_rootdir,'string');
mem=get(H.edit_memlimit,'string');
dt=str2num(get(H.edit_dt,'string'));
lims=str2num(get(H.edit_timelimits,'string'));
dsfact=str2num(get(H.edit_dsfact,'string'));

machine=get(get(H.rad_machine,'SelectedObject'),'String');
if strcmp(machine,'local')
  clusterflag = 0;
elseif strcmp(machine,'cluster')
  clusterflag = 1;
end
nrepeats=str2num(get(H.edit_repeats,'string'));
for i=1:nrepeats
  if nrepeats>1
    fprintf('Submitting batch iteration %g of %g...\n',i,nrepeats);
  end
  % record note
  if ~isfield(CURRSPEC,'history') || isempty(CURRSPEC.history)
    id=1;
  else
    id=max([CURRSPEC.history.id])+1;
  end
  note.id=id;
  timestamp=datestr(now,'yyyymmdd-HHMMSS');
  note.date=timestamp;
  if strcmp(machine,'local')
    note.text=sprintf('%s BATCH: t=[%g %g], dt=%g. ',machine,lims,dt);
  else
    note.text=sprintf('%s BATCH: t=[%g %g], dt=%g. ',machine,lims,dt);% rootdir=%s',machine,dir);
  end
  tmp=CURRSPEC;
  if isfield(tmp.model,'eval')
    tmp.model=rmfield(tmp.model,'eval');
  end
  if isfield(tmp,'history')
    tmp = rmfield(tmp,'history');
  end
  if id>1 && isequal(CURRSPEC.history(end).spec.model,CURRSPEC.model)
    note.id=id-1;
    note.spec=tmp;
    note.changes={};
  else
    note.spec=tmp;
    note.changes={'changes made'};
  end
  note.isbatch=1;
  note.batch.space=cfg.study;
  note.batch.rootdir = dir;
  note.batch.machine = machine;
  % update controls
  s=get(H.lst_notes,'string');
  v=get(H.lst_notes,'value');
  s={s{:} num2str(note.id)};
  v=[v length(s)];
  set(H.lst_notes,'string',s,'value',v);
  set(H.edit_notes,'string','');
  note.batch.savedata = get(H.chk_savedata,'value');
%   if id==1
%     CURRSPEC.history = note;
%   else
%     CURRSPEC.history(end+1) = note;
%   end
%   UpdateHistory;
  % submit to simstudy
  tmpspec=rmfield(CURRSPEC,'history');
  [allspecs,timestamp,rootoutdir]=simstudy(tmpspec,scope,variable,values,'dt',dt,'rootdir',dir,'memlimit',mem,...
    'timelimits',lims,'dsfact',dsfact,'sim_cluster_flag',clusterflag,'timestamp',timestamp,...
    'savedata_flag',get(H.chk_savedata,'value'),'savepopavg_flag',get(H.chk_savesum,'value'),'savespikes_flag',get(H.chk_savespikes,'value'),'saveplot_flag',get(H.chk_saveplots,'value'),...
    'plotvars_flag',get(H.chk_plottraces,'value'),'plotrates_flag',get(H.chk_plotrates,'value'),'plotpower_flag',get(H.chk_plotspectra,'value'),...
    'addpath',fullfile(BIOSIMROOT,'matlab'),'overwrite_flag',get(H.chk_overwrite,'value'),'SOLVER',get(H.edit_SOLVER,'string'));
  clear tmpspec
  if isempty(rootoutdir)
    note.batch.rootoutdir = {};
  else
    note.batch.rootoutdir = rootoutdir{1};
  end
  if id==1
    CURRSPEC.history = note;
  else
    CURRSPEC.history(end+1) = note;
  end
  UpdateHistory;
end
% autosave
if 1
  spec=CURRSPEC;
  save(BACKUPFILE,'spec');
end
% notes(2).id='model2';
% notes(2).date='yyyymmdd-hhmmss';
% notes(2).text='batch sim note...';
% notes(2).changes{1}='E.n: 1 => 2';
% notes(2).changes{2}='+E2: {iNa,iK}';
% notes(2).isbatch = 1;
% notes(2).batch.space(1).scope = '(E,I)';
% notes(2).batch.space(1).variables = 'N';
% notes(2).batch.space(1).values = '[1 2 3]';
% notes(2).model = CURRSPEC;
% CURRSPEC.history(end+1)=notes;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function UpdateHistory(src,evnt)
global CURRSPEC H cfg

if ~isfield(H,'lst_notes') || ~ishandle(H.lst_notes)
  notes=[]; ids={};
  H.lst_notes = uicontrol('units','normalized','position',[0 0 .2 1],'parent',H.phistory,'BackgroundColor',[.9 .9 .9],'ToolTipString','Select notes and hit ''d'' to delete.',...
    'style','listbox','value',1:min(3,length(notes)),'string',ids,'Max',100,'Callback',@UpdateHistory,'KeyPressFcn',@NoteKeyPress);
  H.edit_comparison = uicontrol('parent',H.pcomparison,'style','edit','units','normalized','tag','modelcomparison',...
  'position',[0 0 1 .85],'string','','FontName','Courier','FontSize',9,'HorizontalAlignment','Left','Max',100,'BackgroundColor',[.9 .9 .9]);
%   try
%     jEdit = findjobj(H.edit_comparison);
%     jEditbox = jEdit.getViewport().getComponent(0);
%     jEditbox.setEditable(false);                % non-editable
%   end
  H.btn_compare = uicontrol('parent',H.pcomparison,'units','normalized',...
    'style','pushbutton','fontsize',10,'string','compare','callback',@CompareModels,...
    'position',[.05 .85 .2 .15]);
  H.btn_report = uicontrol('parent',H.pcomparison,'style','pushbutton','fontsize',10,'string','gen report','callback',@GenerateReport,...
    'units','normalized','position',[.75 .85 .2 .15]);%[.25 .935 .1 .03]);
end

if ~isfield(CURRSPEC,'history') || isempty(CURRSPEC.history)
  return;
else
  notes=CURRSPEC.history;
end

ids = cellfun(@num2str,{notes.id},'uni',0);
if isempty(ids)
  return;
end
str = get(H.lst_notes,'string');
if ~isequal(ids,str)
  set(H.lst_notes,'string',ids);
end
sel = get(H.lst_notes,'value');
sel = sel(1:min(length(sel),length(ids)));
if numel(sel)<1
  sel = 1;
elseif any(sel>length(notes))
  sel(sel>length(notes))=[];
end
set(H.lst_notes,'value',sel);
notes = notes(sel);

delete(findobj('tag','note'));

ypos=.9; ht=.05;
for i=1:length(notes)
  if notes(i).isbatch==1 && isfield(notes(i).batch,'savedata') && notes(i).batch.savedata==1 %strcmp(notes(i).batch.machine,'cluster')
    saved_flag=1; fontcolor='k';
  else
    saved_flag=0; fontcolor='k';
  end
  if length(notes(i).changes)>=1
    changed_flag=1; fontweight='bold';
  else
    changed_flag=0; fontweight='normal';
  end
  if changed_flag
    H.chk_notes(i) = uicontrol('style','checkbox','value',0,'parent',H.pnotes,'units','normalized','userdata',notes(i),'backgroundcolor',cfg.bgcolor,...
      'position',[.05 ypos .7 ht],'string',sprintf('Model %s (%s)',ids{sel(i)},notes(i).date),'visible','on','foregroundcolor',fontcolor,'tag','note','fontweight',fontweight); % ['Model ' ids{sel(i)} ' (' notes(i).date ')']
  else
    H.chk_notes(i) = uicontrol('style','checkbox','value',0,'parent',H.pnotes,'units','normalized','userdata',notes(i),'backgroundcolor',cfg.bgcolor,...
      'position',[.05 ypos .7 ht],'string',sprintf('Model %s (%s)',ids{sel(i)},notes(i).date),'visible','on','foregroundcolor',fontcolor,'tag','note','fontweight',fontweight); % ['Model ' ids{sel(i)} ' (' notes(i).date ')']
  end
  H.btn_revert(i) = uicontrol('parent',H.pnotes,'units','normalized','style','pushbutton','fontsize',10,'visible','on','tag','note',...
    'string','<--','position',[.87 ypos .1 .04],'callback',{@updatemodel,notes(i).spec,notes(i).id});%%sprintf('global CURRSPEC; updatemodel(CURRSPEC.history(%g).spec); refresh;',sel(i)));
  ypos=ypos-ht;
  H.edit_note(i) = uicontrol('style','edit','units','normalized','HorizontalAlignment','left','parent',H.pnotes,'BackgroundColor','w','visible','on',...
    'string',notes(i).text,'position',[.15 ypos .82 ht],'tag','note','callback',sprintf('global CURRSPEC; CURRSPEC.history(%g).text=get(gcbo,''string'');',sel(i)));
  if notes(i).isbatch==0
    ypos=ypos-ht;
  else
    if saved_flag
      H.btn_batchmanager(i) = uicontrol('parent',H.pnotes,'units','normalized','style','pushbutton','fontsize',10,...
        'string','data','tag','note','position',[.87 ypos-ht+.01 .1 .04],'callback',{@Load_File,notes(i).batch.rootoutdir},'visible','on');
      H.btn_quickplot(i) = uicontrol('parent',H.pnotes,'units','normalized','style','pushbutton','fontsize',10,...
        'string','plot','tag','note','position',[.75 ypos+ht .1 .04],'callback',{@QuickPlot_inputdlg,notes(i).batch.rootoutdir,notes(i).batch.space},'visible','on');
      uicontrol('parent',H.pnotes,'units','normalized','style','pushbutton','fontsize',10,...
        'string','outputs','tag','note','position',[.55 ypos+ht .18 .04],'callback',['web(''' notes(i).batch.rootoutdir ''',''-browser'');'],'visible','on');
    end
    for j=1:length(notes(i).batch.space)
      b=notes(i).batch.space(j);
      ypos=ypos-ht;
      H.txt_searchspace = uicontrol('style','text','string',sprintf('(%s).(%s)=%s',b.scope,b.variable,b.values),'fontsize',10,'fontweight','bold',...
        'parent',H.pnotes,'tag','note','units','normalized','position',[.15 ypos .72 ht],'HorizontalAlignment','left','visible','on','foregroundcolor','b');
    end
    ypos=ypos-ht/1.1;% 1.5
  end
end
% notes(1).id='model1';
% notes(1).date='yyyymmdd-hhmmss';
% notes(1).text='interactive sim note...';
% notes(1).changes{1}='E.N: 1 => 2';
% notes(1).changes{2}='+E2: {iNa,iK}';
% notes(1).changes{3}='E2: +iM';
% notes(1).changes{4}='E2.iM.gM: 10 => 20';
% notes(1).isbatch = 0;
% notes(1).batch = [];
% notes(1).model = CURRSPEC;
% notes(2).id='model2';
% notes(2).date='yyyymmdd-hhmmss';
% notes(2).text='batch sim note...';
% notes(2).changes{1}='E.n: 1 => 2';
% notes(2).changes{2}='+E2: {iNa,iK}';
% notes(2).isbatch = 1;
% notes(2).batch.space(1).scope = '(E,I)';
% notes(2).batch.space(1).variables = 'N';
% notes(2).batch.space(1).values = '[1 2 3]';
% notes(2).model = CURRSPEC;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function NoteKeyPress(src,evnt)
switch evnt.Key
  case {'delete','d'}
    global CURRSPEC;
    newspec=CURRSPEC;
    s=get(src,'string');
    v=get(src,'value');
    newspec.history(v)=[];
    s(v)=[];
    set(src,'string',s,'value',[]);
    updatemodel(newspec);
    UpdateHistory;
    %refresh;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function txt=GenerateReport(src,evnt,plotflag)
if nargin<3, show_flag=1; end
global CURRSPEC cfg
notes=CURRSPEC.history;
txt={};
ids=[notes.id];
uids=unique(ids);
lastmodel=[];
for i=1:length(uids) % loop over models
  id=uids(i);
  these=notes([notes.id]==id);
  thismodel=these(1).spec;
  txt{end+1}=sprintf('Model %g notes',id);
  for j=1:length(these)
    note=these(j);
    txt{end+1}=sprintf('%s: %s',note.date,note.text);
    if note.isbatch && ~isempty(note.batch.space)
      for k=1:length(note.batch.space)
        b=note.batch.space(k);
        txt{end+1}=sprintf('\t(%s).(%s)=%s',b.scope,b.variable,b.values);
      end
    end
  end
  if ~isempty(lastmodel)
    txt{end+1}='';
    txt{end+1}=sprintf('diff(Model%g,Model%g): changes in Model%g compared to Model%g',uids(i-1),id,id,uids(i-1));
    try
      txt=cat(2,txt,modeldiff(lastmodel,thismodel));
    catch
      txt=cat(2,txt,'model comparison failed...');
    end
    txt{end+1}='';
  end
  if i < length(uids)
    txt{end+1}='-----------------------------------------------------------------';
  else
    txt{end+1}='';
  end
  lastmodel=thismodel;
  end
txt{end+1}=cfg.modeltext;
if show_flag
  h=figure('position',[70 120 930 580]);
  uicontrol('parent',h,'style','edit','units','normalized','position',[0 0 1 .85],'tag','report',...
    'string',txt,'FontName','Courier','FontSize',9,'HorizontalAlignment','Left','Max',100,'BackgroundColor','w'); % Courier Monospaced
  uicontrol('parent',h,'style','pushbutton','fontsize',10,'string','write','callback',@WriteReport,...
      'units','normalized','position',[0 .9 .1 .05]);
  uicontrol('parent',h,'style','pushbutton','fontsize',10,'string','email','callback',@EmailReport,...
      'units','normalized','position',[.1 .9 .1 .05]);
end
function WriteReport(src,evnt)
timestamp=datestr(now,'yyyymmdd-HHMMSS');
[filename,pathname] = uiputfile({'*.txt;'},'Save as',['report_' timestamp '.txt']);
if isequal(filename,0) || isequal(pathname,0)
  return;
end
txt=get(findobj('tag','report'),'string');
outfile = fullfile(pathname,filename);
fid = fopen(outfile,'wt');
for i=1:length(txt)
  fprintf(fid,[txt{i} '\n']);
end
fclose(fid);
fprintf('report written to file: %s\n',outfile);
function EmailReport(src,evnt)
global CURRSPEC cfg
% prepare report text
txt=get(findobj('tag','report'),'string');
if isempty(txt), return; end
if iscell(txt{1}), txt=txt{end}; end
str='';
for i=1:length(txt)
  str=sprintf('%s%s\n',str,txt{i});
end
% get email address
emailaddress=inputdlg('Email address:','Enter email address',1,{cfg.email});
drawnow; pause(0.05);  % this innocent line prevents the Matlab hang
if isempty(emailaddress)
  return;
else
  emailaddress=emailaddress{1};
end
% add system info to email content
sysinfo='';
[r, username] = system('echo $USER');
if ~r
  username=regexp(username,'\w+','match'); % remove new line characters
  if ~isempty(username), username=username{1}; end
  sysinfo=sprintf('%sUser: %s\n',sysinfo,username);
end
[r, computername] = system('hostname');           % Uses linux system command to get the machine name of host.
if ~r, sysinfo=sprintf('%sHost: %s',sysinfo,computername); end
sysinfo=sprintf('%sMatlab version: %s\n',sysinfo,version);
if exist('BIOSIMROOT','var') % get unique id for this version of the git repo
  cwd=pwd;
  cd(BIOSIMROOT);
  [r,m]=system('git log -1');
  cd(cwd);
else
  [r,m]=system('git log -1');
end
if ~r
  githash=strrep(regexp(m,'commit\s[\w\d]+','match','once'),'commit ','');
  sysinfo=sprintf('%sDNSim Git hash: %s',sysinfo,githash);
end
str=sprintf('Report generated at %s.\n%s\n\n%s',datestr(now,31),sysinfo,str);
timestamp=datestr(now,'yyyymmdd-HHMMSS');
% create temporary file for attachment
tmpfile=sprintf('model_%s.mat',timestamp);
spec=CURRSPEC;
save(tmpfile,'spec');
% send email
setpref('Internet','SMTP_Server','127.0.0.1'); % Sets the outgoing mail server - often the default 127.0.0.1
setpref('Internet','E_mail','sherfey@bu.edu'); % Sets the email FROM/reply address for all outgoing email reports.
sendmail(emailaddress,['DNSim Report: ' timestamp],str,tmpfile);
fprintf('report emailed to: %s\n',emailaddress);
% remove temporary file
delete(tmpfile);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function QuickPlot_inputdlg(src,evnt,rootoutdir,space)
global CURRSPEC H
% if isfield(H,'QuickPlot_inputdlg') && ishandle(H.QuickPlot_inputdlg) % any(findobj('tag','QuickPlot_inputdlg'))
%   figure(H.QuickPlot_inputdlg);%findobj('tag','QuickPlot_inputdlg'));
%   return;
% end
if issubfield(CURRSPEC,'variables.labels') && iscell(CURRSPEC.variables.labels)
  defaultvar=CURRSPEC.variables.labels{1};
else
  defaultvar='variable';
end
nelem = arrayfun(@(x)numel(x.values),space);
index = find(nelem==max(nelem),1,'first');
variable = space(index).variable;
values = space(index).values;
H.QuickPlot_inputdlg = figure('tag','QuickPlot_inputdlg','name','What to plot','NumberTitle','off','MenuBar','none');
uicontrol('style','text','units','normalized','position',[.1 .8 .8 .04],'string','Variable to plot (required)','fontsize',12);
H.quickplot_var = uicontrol('style','edit','units','normalized','position',[.1 .7 .8 .1],'string',defaultvar,'tag','quickplot_var','backgroundcolor','w','horizontalalignment','left','fontsize',12);
uicontrol('style','text','units','normalized','position',[.1 .65 .8 .04],'string','Parameter varied (required)','fontsize',12);
H.quickplot_param = uicontrol('style','edit','units','normalized','position',[.1 .55 .8 .1],'string',variable,'tag','quickplot_param','backgroundcolor','w','horizontalalignment','left','fontsize',12);
uicontrol('style','text','units','normalized','position',[.1 .5 .8 .04],'string','Parameter range/values to plot','fontsize',12);
H.quickplot_values = uicontrol('style','edit','units','normalized','position',[.1 .4 .8 .1],'string',values,'tag','quickplot_values','backgroundcolor','w','horizontalalignment','left','fontsize',12);
uicontrol('style','text','units','normalized','position',[.1 .35 .8 .04],'string','x-axis limits','fontsize',12);
H.quickplot_xlims = uicontrol('style','edit','units','normalized','position',[.1 .25 .8 .1],'string','[]','tag','quickplot_xlims','backgroundcolor','w','horizontalalignment','left','fontsize',12);
uicontrol('style','pushbutton','units','normalized','position',[.45 .1 .2 .1],'string','OK','callback',{@QuickPlot_sim_data,rootoutdir},'fontsize',14);
uicontrol('style','pushbutton','units','normalized','position',[.7 .1 .2 .1],'string','Cancel','callback','global H; close(H.QuickPlot_inputdlg);','fontsize',14);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function QuickPlot_sim_data(src,evnt,rootoutdir)
% answer=inputdlg(...
%   {'Variable to plot (required)','Parameter varied (required)','Parameter range/values to plot', 'xlims'},...
%   'What to plot',1,...
%   {defaultvar,space(1).variable,space(1).values,'[]'});
% drawnow; pause(0.05);  % this innocent line prevents the Matlab hang
global H
answer{1} = get(H.quickplot_var,'string');
answer{2} = get(H.quickplot_param,'string');
answer{3} = get(H.quickplot_values,'string');
answer{4} = get(H.quickplot_xlims,'string');
if isempty(answer), return; end
if isequal(answer{3},'[]') || isempty(answer{3}) || isequal(answer{3},'-1'), answer{3}=[]; end
if isequal(answer{4},'[]') || isempty(answer{4}), answer{4}=[]; end
if ischar(answer{3}) && isempty(regexp(answer{3},'[a-zA-Z]'))
  answer{3}=str2num(answer{3});
end
if ischar(answer{4}), answer{4}=str2num(answer{4}); end
plot_search_space(fullfile(rootoutdir,'data'),answer{1},answer{2},answer{3},'xlims',answer{4});
close(H.QuickPlot_inputdlg);% findobj('tag','QuickPlot_inputdlg'))

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function CompareModels(src,evnt)
global H
if ~isfield(H,'chk_notes'), return; end
H.chk_notes(~ishandle(H.chk_notes))=[];
if isempty(H.chk_notes), return; end
sel=get(H.chk_notes,'value');
if isempty(sel),return; end
sel=[sel{:}]==1;
if length(find(sel))<2, return; end
notes = get(H.chk_notes(sel),'userdata');
basemodel=notes{1}.spec;
othermodels=cellfun(@(x)x.spec,notes(2:end),'uni',0);
txt={};
for i=1:length(othermodels)
  txt{end+1}=sprintf('diff(Model%g,Model%g): changes in Model%g compared to Model%g',notes{1}.id,notes{i+1}.id,notes{i+1}.id,notes{1}.id);
  try
    txt=cat(2,txt,modeldiff(basemodel,othermodels{i}));
  catch
    txt=cat(2,txt,'model comparison failed...');
  end
  txt{end+1}='------------------------------------------------';
end
set(H.edit_comparison,'string',txt);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function RenameComponent(src,evnt)
global CURRSPEC
s=get(src,'string');
v=get(src,'value');
if length(v)>1, return; end
newname=inputdlg(['Rename Compartment: ' s{v}],'New name');
drawnow; pause(0.05);  % this innocent line prevents the Matlab hang
if isempty(newname), return; end
newname=newname{1};
newspec=CURRSPEC;
I=find(strcmp(s{v},{newspec.cells.label}));
newspec.cells(I).label=newname;
for i=1:length(s)
  l=newspec.connections(v,i).label;
  if ~isempty(l)
    newspec.connections(v,i).label=strrep(l,[s{v} '-'],[newname '-']);
  end
  l=newspec.connections(i,v).label;
  if ~isempty(l)
    newspec.connections(i,v).label=strrep(l,['-' s{v}],['-' newname]);
  end
end
s{v}=newname;
set(src,'string',s);
updatemodel(newspec);
SelectCells;
Display_Mech_Info;
DrawAuxView;
DrawUserParams;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function RenameMech(src,evnt)
global CURRSPEC
ud=get(src,'userdata');
v=get(src,'value');
s=get(src,'string');
if length(v)>1, return; end
newname=inputdlg(['Rename Mechanism: ' ud(v).mechlabel ' (in ' ud(v).celllabel ')'],'New name');
drawnow; pause(0.05);  % this innocent line prevents the Matlab hang
if isempty(newname), return; end
newname=newname{1};
newspec=CURRSPEC;
u=ud(v);
ud(v).mechlabel=newname;
comp=u.celllabel;
mech=u.mechlabel;
i=find(cellfun(@(x)isequal(comp,x),{newspec.(u.type).label}));
j=find(strcmp(mech,newspec.(u.type)(i).mechanisms));
newspec.(u.type)(i).mechanisms{j}=newname;
newspec.(u.type)(i).mechs(j).label=newname;
s{v}=[comp '.' newname];
set(src,'string',s,'userdata',ud);
updatemodel(newspec);
SelectCells;
Display_Mech_Info;
DrawAuxView;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function RecordNotes(src,evnt)
global CURRSPEC H cfg t
if ~isfield(CURRSPEC,'history') || isempty(CURRSPEC.history)
  id=1;
else
  id=max([CURRSPEC.history.id])+1;
end
note.id=id;
note.date=datestr(now,'yyyymmdd-HHMMSS');
note.text=get(H.edit_notes,'string');
if cfg.quitflag<0
  note.text = sprintf('SIM(t=%g): %s',t,note.text);
end
tmp=CURRSPEC;
if isfield(tmp.model,'eval')
  tmp.model=rmfield(tmp.model,'eval');
end
if isfield(tmp,'history')
  tmp = rmfield(tmp,'history');
end
if id>1 && isequal(CURRSPEC.history(end).spec.cells,CURRSPEC.cells) && isequal(CURRSPEC.history(end).spec.connections,CURRSPEC.connections) % isequal(CURRSPEC.history(end).spec.model,CURRSPEC.model)
  note.id=id-1;
  note.spec=tmp;
  note.changes={};
else
  note.spec=tmp;
  note.changes={'changes made'};
end
note.isbatch=0;
note.batch=[];
if id==1
  CURRSPEC.history = note;
else
  CURRSPEC.history(end+1) = note;
end
s=get(H.lst_notes,'string');
v=get(H.lst_notes,'value');
s={s{:} num2str(note.id)};
v=[v length(s)];
set(H.lst_notes,'string',s,'value',v);
set(H.edit_notes,'string','');
UpdateHistory;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function updatemodel(newspec,varargin) % maybe use same specification as for "override"
% purpose: update the integratable model after each change to its specification
if nargin>2, newspec=varargin{2}; end % get spec from history:revert
global CURRSPEC LASTSPEC cfg
LASTSPEC = CURRSPEC;
CURRSPEC = newspec;
if 1
  try
    [model,IC,functions,auxvars,CURRSPEC,sodes,svars,txt] = buildmodel(CURRSPEC,'verbose',0,'nofunctions',get(findobj('tag','substfunctions'),'value'));
    if isfield(CURRSPEC,'entities') && ~isfield(CURRSPEC,'cells')
      CURRSPEC.cells=CURRSPEC.entities; CURRSPEC=rmfield(CURRSPEC,'entities');
    elseif isfield(CURRSPEC,'nodes') && ~isfield(CURRSPEC,'cells')
      CURRSPEC.cells=CURRSPEC.nodes; CURRSPEC=rmfield(CURRSPEC,'nodes');
    end
    cfg.modeltext = txt;
    h=findobj('tag','modeltext');
    if ~isempty(h)
      set(h,'string',cfg.modeltext);
    end
    %fprintf('model updated successfully\n');
  catch err
    disperror(err);
  end
end
if nargin>2
  CURRSPEC.history = LASTSPEC.history; % hold onto history since the reverted model
  refresh;
  if nargin>3
    fprintf('reverting to model %g\n',varargin{3});
  else
    fprintf('reverting to selected model\n');
  end
end
function CURRSPEC = trimparams(spec)

for i=1:length(spec.cells)
  if length(spec.cells(i).parameters)<2
    continue;
  end
  parmlist={};
  if isfield(spec.cells,'mechanisms')
    for j=1:length(spec.cells(i).mechanisms)
      if ~isfield(spec.cells,'mechs'), break; end
      if isstruct(spec.cells(i).mechs(j).params)
        parmlist=cat(1,parmlist,fieldnames(spec.cells(i).mechs(j).params));
      end
    end
  end
  if isfield(spec.connections,'mechanisms')
    for k=1:length(spec.cells)
      if ~isfield(spec.connections,'mechs'), break; end
      for j=1:length(spec.connections(k,i).mechanisms)
        if isstruct(spec.connections(k,i).mechs(j).params)
          parmlist=cat(1,parmlist,fieldnames(spec.connections(k,i).mechs(j).params));
        end
      end
    end
  end
  if isempty(parmlist), continue; end
  parmlist=unique(parmlist);
  rm=find(ismember(spec.cells(i).parameters(1:2:end),parmlist));
  if ~isempty(rm)
    rm=[2*rm 2*rm-1];
    spec.cells(i).parameters(rm)=[];
  end
  for k=1:length(spec.cells)
    if ~isempty(spec.connections(k,i).parameters)
      rm=find(ismember(spec.connections(k,i).parameters(1:2:end),parmlist));
      if ~isempty(rm)
        rm=[2*rm 2*rm-1];
        spec.connections(k,i).parameters(rm)=[];
      end
    end
  end
end
CURRSPEC=spec;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function BrowseDB(src,evnt)
global H cfg

% test remote connection
if strcmp(cfg.mysql_connector,'none')
  msgbox('Database connection cannot be established.');
  return;
end
% try
%   err=mym('open', cfg.webhost,cfg.dbuser,cfg.dbpassword);
%   mym('close');
% catch
%   msgbox('Database connection cannot be established.');
%   return;
% end

% set up figure
fig=findobj('tag','server');
if any(fig)
  figure(fig);
else
  fig=figure('name','InfiniteBrain.org','tag','server','position',[315 270 600 380],'color',cfg.bgcolor,'NumberTitle','off','MenuBar','none');
end
if isfield(H,'rad_authorscope') && ishandle(H.rad_authorscope), delete(H.rad_authorscope); end

% model listbox
if any(findobj('tag','list'))
  try delete(findobj('tag','list')); end
end
uicontrol('style','listbox','tag','list','units','normalized','position',[0 0 .6 .8],'background',[.9 .9 .9],'Max',20,'ButtonDownFcn','i=get(gcbo,''userdata''); v=get(gcbo,''value''); web(sprintf(''http://infinitebrain.org/models/%g/'',i(v(1))),''-browser'');','TooltipString','right-click to open model web page for discussion');

% button - update list
%uicontrol('style','pushbutton','units','normalized','position',[.5 .8 .4 .1],'string','update list','callback',@DB_UpdateList);
% button - load/append model
uicontrol('style','text','units','normalized','position',[.63 .7 .33 .05],'string','Download (multi)selected','fontsize',12,'backgroundcolor',cfg.bgcolor,'HorizontalAlignment','center');
uicontrol('style','pushbutton','units','normalized','position',[.65 .6 .3 .09],'string','as new model','callback',{@download_models,1},'TooltipString','replace active model with one or more selected models','fontsize',12);%,'ForegroundColor','c','fontweight','bold','backgroundcolor','m');%@DB_LoadModel);
uicontrol('style','pushbutton','units','normalized','position',[.65 .5 .3 .09],'string','append to model','callback',{@download_models,0},'TooltipString','combine one or more selected models with the active model','fontsize',12);%,'ForegroundColor','c','fontweight','bold','backgroundcolor','m');%@DB_AppendModel);
% button - save model
%uicontrol('style','pushbutton','units','normalized','position',[.5 .2 .4 .1],'string','Upload model','callback',@DB_SaveModel,'fontsize',13);%,'ForegroundColor','c','fontweight','bold','backgroundcolor','m');
% checkbox - whether to save simulation with model
uicontrol('visible','off','style','checkbox','units','normalized','position',[.5 .15 .15 .05],'string','simulate');
uicontrol('visible','off','style','text','units','normalized','position',[.65 .15 .1 .05],'string','tspan');
uicontrol('visible','off','style','edit','units','normalized','position',[.75 .15 .15 .05],'string','[0 200]');
uicontrol('visible','off','style','popupmenu','tag','privacy','units','normalized','position',[.5 .1 .15 .05],'string',{'Public','Private','Unlisted'},'value',1);
% which models to show:
if cfg.is_authenticated
  visible='on';
else
  visible='off';
end
% which user's models to display
H.rad_authorscope=uibuttongroup('visible',visible,'units','normalized','Position',[0 .9 .6 .1],'parent',fig,'SelectionChangeFcn',{@DB_UpdateList,'node'},'backgroundcolor','w');
H.rad_authorscope_1=uicontrol('style','radiobutton','string','public','parent',H.rad_authorscope,'HandleVisibility','off',...
    'units','normalized','pos',[0 0 .4 1],'backgroundcolor','w');
H.rad_authorscope_2=uicontrol('style','radiobutton','string',[cfg.username],'parent',H.rad_authorscope,'HandleVisibility','off',...
    'units','normalized','pos',[.41 0 .5 1],'backgroundcolor','w');
set(H.rad_authorscope,'SelectedObject',H.rad_authorscope_2);  % No selection
% which type of model to display
H.btn_db_nodes=uicontrol('style','pushbutton','units','normalized','position',[0 .8 .3 .1],'string','node','callback',{@DB_UpdateList,'node'},'fontsize',12,'backgroundcolor',[.7 .7 .7]);
H.btn_db_networks=uicontrol('style','pushbutton','units','normalized','position',[.3 .8 .3 .1],'string','network','callback',{@DB_UpdateList,'network'},'fontsize',12,'backgroundcolor',[1 1 1]);
% H.rad_modellevel=uibuttongroup('units','normalized','Position',[0 .8 .6 .1],'parent',fig,'SelectionChangeFcn',@DB_UpdateList,'backgroundcolor','w');
% H.rad_modellevel_1=uicontrol('style','radiobutton','string','network','parent',H.rad_modellevel,'HandleVisibility','off',...
%     'units','normalized','pos',[0 0 .4 1],'backgroundcolor','w');
% H.rad_modellevel_2=uicontrol('style','radiobutton','string','node','parent',H.rad_modellevel,'HandleVisibility','off',...
%     'units','normalized','pos',[.41 0 .2 1],'backgroundcolor','w');
% H.rad_modellevel_2=uicontrol('style','radiobutton','string','mechanism','parent',H.rad_modellevel,'HandleVisibility','off',...
%     'units','normalized','pos',[.68 0 .3 1],'backgroundcolor','w');
% set(H.rad_modellevel,'SelectedObject',H.rad_modellevel_1);  % No selection

DB_UpdateList([],[],'node');
% -------------------------------------------------------------------------
function DB_UpdateList(src,evnt,level)
global cfg H
if strcmp(level,'node')
  set(H.btn_db_nodes,'backgroundcolor',[.7 .7 .7]);
  set(H.btn_db_networks,'backgroundcolor',[1 1 1]);
elseif strcmp(level,'network')
  set(H.btn_db_networks,'backgroundcolor',[.7 .7 .7]);
  set(H.btn_db_nodes,'backgroundcolor',[1 1 1]);
end
% remote connection
if strcmp(cfg.mysql_connector,'none')
  return;
end
if cfg.is_authenticated && isequal(get(H.rad_authorscope,'SelectedObject'),H.rad_authorscope_2)
  result = mysqldb(sprintf('select id,name,level from modeldb_model where user_id=%g and level=''%s''',cfg.user_id,level),{'id','name','level'});
else
  result = mysqldb(sprintf('select id,name,level from modeldb_model where level=''%s'' and privacy=''public''',level),{'id','name','level'});
end
if isempty(result)
  list_of_models = '';
  ids=[];
else
  list_of_models = result.name;
  ids=result.id;
end
% err=mym('open', cfg.webhost,cfg.dbuser,cfg.dbpassword);
% if err
%   disp('there was an error opening the database.');
%   list_of_models='';
%   ids=[];
% else
%   mym(['use ' cfg.dbname]);
%   %level = get(get(H.rad_modellevel,'SelectedObject'),'string');
%   if cfg.is_authenticated && str isequal(get(H.rad_authorscope,'SelectedObject'),H.rad_authorscope_2)
%     q = mym(sprintf('select id,name,level from modeldb_model where user_id=%g and level=''%s''',cfg.user_id,level));
%   else
%     q = mym(sprintf('select id,name,level from modeldb_model where level=''%s'' and privacy=''public''',level));% and privacy=''public''',level));
%   end
%   list_of_models = q.name;
%   ids=q.id;
% end;
% mym('close');
set(findobj('tag','list'),'string',list_of_models);
set(findobj('tag','list'),'userdata',ids);
% -------------------------------------------------------------------------
% function GetUploadInfo(src,evnt)
% global cfg
% figure('name','Upload model to infinitebrain.org','NumberTitle','off','MenuBar','none','tag','uploadfig');
% uicontrol('style','text','units','normalized','position',[.1 .9 .8 .05],'string','Model name (required)');
% uicontrol('style','edit','units','normalized','position',[.1 .8 .8 .1],'string',cfg.uploadname,'backgroundcolor','w','horizontalalignment','left','tag','uploadname');
% uicontrol('style','text','units','normalized','position',[.1 .7 .8 .05],'string','Description (optional)');
% uicontrol('style','edit','units','normalized','position',[.1 .5 .8 .2],'string',cfg.uploadnotes,'max',3,'backgroundcolor','w','horizontalalignment','left','tag','uploadnotes');
% uicontrol('style','text','units','normalized','position',[.1 .4 .8 .05],'string','Tags (optional)');
% uicontrol('style','edit','units','normalized','position',[.1 .3 .8 .1],'string',cfg.uploadtags,'backgroundcolor','w','horizontalalignment','left','tag','uploadtags');
% uicontrol('style','text','units','normalized','position',[.1 .2 .3 .05],'string',['Privacy (' cfg.username '):']);
% if strcmp(cfg.username,'anonymous')
%   uicontrol('style','popupmenu','units','normalized','position',[.1 .1 .3 .1],'string',{'Public'},'value',1,'backgroundcolor','w','tag','uploadprivacy');
% else
%   uicontrol('style','popupmenu','units','normalized','position',[.1 .1 .3 .1],'string',{'Unlisted','Public'},'value',1,'backgroundcolor','w','tag','uploadprivacy');
% end
% uicontrol('style','pushbutton','units','normalized','position',[.6 .1 .3 .15],'string','Upload','fontsize',14,'callback',@DB_SaveModel,'busyaction','cancel','Interruptible','off');
% % -------------------------------------------------------------------------
% function DB_SaveModel(src,evnt) % (depends on server inbox/addmodel.py)
% global cfg CURRSPEC
% spec = CURRSPEC;
% if isfield(spec,'history'), spec=rmfield(spec,'history'); end
%
% % get model info
% modelname = get(findobj('tag','uploadname'),'string');
% tags = get(findobj('tag','uploadtags'),'string');
% notes = get(findobj('tag','uploadnotes'),'string');
% str = get(findobj('tag','uploadprivacy'),'string');
% val = get(findobj('tag','uploadprivacy'),'value');
% privacy = str{val};
% if isempty(modelname)
%   warndlg('Model name required. Nothing was uploaded.');
%   return;
% end
% cfg.uploadname = modelname;
% cfg.uploadnotes = notes;
% cfg.uploadtags = tags;
%
% tempfile=['temp' datestr(now,'YYMMDDhhmmss')];
%
% % save spec MAT file
% matfile = [tempfile '_spec.mat'];
% if 1
%   save(matfile,'spec');
% end
%
% % add Django model attributes (modelname, username, level, notes, d3file, readmefile)
% spec.modelname = modelname;
% spec.username = cfg.username;
% if any(~cellfun(@isempty,{spec.connections.mechanisms}))
%   spec.level='network';
% else
%   spec.level = 'node';
% end
% if ~isfield(spec,'parent_uids')
%   spec.parent_uids=[];
% end
% spec.notes=notes;
%   % todo: construct notes from CURRSPEC.history
% spec.specfile=[tempfile '_spec.json'];
% spec.d3file=[tempfile '_d3.json'];
% spec.readmefile=[tempfile '_report.txt'];
% spec.tags=tags;
%   % todo: add checkbox-optional auto-list of tags from cell and mech labels
% spec.privacy=privacy;
%
% % convert model to d3
% fprintf('preparing model d3 .json...');
% try
%   d3json = spec2d3(CURRSPEC,spec.d3file);
%   fprintf('success!\n');
% catch
%   spec.d3file='';
%   fprintf('failed!\n');
% end
%
% % convert model to human-readable descriptive report
% try
%   txt=cfg.modeltext;
%   txt=regexp(txt,'.*Specification files:','match');
%   txt=strrep(txt{1},'Specification files:','');
%   fid = fopen(spec.readmefile,'w+');
%   fprintf(fid,'%s\n',txt);
%   fclose(fid);
% catch
%   spec.readmefile='';
% end
%
% % convert model to json
% fprintf('converting model into .json format...');
% [json,jsonspec] = spec2json(spec,spec.specfile); % ss=loadjson(json); isequal(jsonspec,ss)
% fprintf('success!\n');
%
% % transfer files to server
% fprintf('transfering .json specification to server...');
% target='/project/infinitebrain/inbox';
% f=ftp([cfg.webhost ':' num2str(cfg.ftp_port)],cfg.xfruser,cfg.xfrpassword);
% pasv(f);
% cd(f,target);
% % model specification
% mput(f,spec.specfile);
% delete(spec.specfile);
% % mat-file specification
% if exist(matfile)
%   mput(f,matfile);
%   delete(matfile);
% end
% % d3 graphical model schematic
% if exist(spec.d3file)
%   mput(f,spec.d3file);
%   delete(spec.d3file);
% end
% % human-readable model description + equations
% if exist(spec.readmefile)
%   mput(f,spec.readmefile);
%   delete(spec.readmefile);
% end
% close(f);
% fprintf('success!\n');
%
% if ~isdeployed
%   % update database
%   fprintf('updating database...\n');
%   command = 'bash /project/infinitebrain/inbox/trigger.sh';
%   channel = sshfrommatlab(cfg.xfruser,cfg.webhost,cfg.xfrpassword);
%   [channel,result] = sshfrommatlabissue(channel,command);
%   for l=1:length(result)
%     fprintf('\t%s\n',result{l});
%   end
%   channel = sshfrommatlabclose(channel);
%   fprintf('success!\n');
% end
% fprintf('Model pushed to server successfully.\n\n');
% close(findobj('tag','uploadfig'));
%
% % goto web page
% if ~strcmp(cfg.mysql_connector,'none')
%   %result = mysqldb(sprintf('select id from modeldb_model where user_id=%g and level=''%s''',cfg.user_id,level),{'id','name','level'});
%   result = mysqldb(sprintf('select id from modeldb_model where name=''%s''',modelname),{'id'});
%   if ~isempty(result)
%     web(sprintf('http://infinitebrain.org/models/%g/',max(result.id)),'-browser');
%   end
% end

% % try
% %   err=mym('open', cfg.webhost,cfg.dbuser,cfg.dbpassword);
% %   if err
% %     disp('there was an error opening the database to get the new model ID.');
% %     mym('close');
% %     return;
% %   end
% %   mym(['use ' cfg.dbname]);
% %   q = mym(sprintf('select id from modeldb_model where name=''%s''',modelname));
% %   mym('close');
% %   web(sprintf('http://infinitebrain.org/models/%g/',max(q.id)),'-browser');
% % end

% -------------------------------------------------------------------------
function DB_SaveMechanism(src,evnt) % (depends on server inbox/addmodel.py)
global cfg H
tempfile=['temp' datestr(now,'YYMMDDhhmmss')];
ud=get(H.txt_mech,'userdata');

% validate mech text
UpdateMech;
txt = get(H.txt_mech,'string');
if isempty(txt)
  msgbox('empty mechanism. nothing to write.');
  return;
end

% get model name
answer=inputdlg({'Model name:','Tags','Description'},'Metadata',1,{ud.mechlabel,'',''});
drawnow; pause(0.05);  % this innocent line prevents the Matlab hang
if isempty(answer), return; end
modelname=answer{1};
tags=answer{2};
notes=answer{3};
if isempty(modelname)
  warndlg('Model name required. Nothing was uploaded.');
  return;
end

% write temporary mech file (mechfile)
mechfile=[tempfile '_' modelname '_mech.txt'];
fid = fopen(mechfile,'wt');
for i=1:length(txt)
  fprintf(fid,[txt{i} '\n']);
end
fclose(fid);

% add Django model attributes (modelname, username, level, notes, d3file, readmefile)
mech.modelname = modelname;
mech.username = cfg.username;
mech.level='mechanism';
mech.source=[];
mech.notes=notes;
mech.specfile=mechfile;
mech.d3file='';
mech.readmefile='';
mech.tags=tags;
if strcmp(cfg.username,'anonymous')
  mech.privacy='public';
else
  mech.privacy='unlisted';
end
% todo: add checkbox-optional auto-list of tags from cell and mech labels

% convert model to temporary json
jsonfile=[tempfile '_' modelname '_mech.json'];
fprintf('converting metadata to .json format...');
json=savejson('',mech,jsonfile);
fprintf('success!\n');

% transfer files to server
fprintf('transfering .json specification to server...');
target='/project/infinitebrain/inbox';
f=ftp([cfg.webhost ':' num2str(cfg.ftp_port)],cfg.xfruser,cfg.xfrpassword);
pasv(f);
cd(f,target);
% model specification
mput(f,mechfile);
delete(mechfile);
mput(f,jsonfile);
delete(jsonfile);
% d3 graphical model schematic
if exist(mech.d3file)
  mput(f,mech.d3file);
  delete(mech.d3file);
end
% human-readable model description + equations
if exist(mech.readmefile)
  mput(f,mech.readmefile);
  delete(mech.readmefile);
end
close(f);
fprintf('success!\n');

if ~isdeployed
  % update database
  fprintf('updating database...\n');
  command = 'bash /project/infinitebrain/inbox/trigger.sh';
  channel = sshfrommatlab(cfg.xfruser,cfg.webhost,cfg.xfrpassword);
  [channel,result] = sshfrommatlabissue(channel,command);
  for l=1:length(result)
    fprintf('\t%s\n',result{l});
  end
  channel = sshfrommatlabclose(channel);
  fprintf('success!\n');
end
fprintf('Model pushed to server successfully.\n\n');
% -------------------------------------------------------------------------
% function DB_LoadModel(src,evnt)
% global cfg BACKUPFILE H
%
% % what models to load:
% ids = get(findobj('tag','list'),'userdata');
% v = get(findobj('tag','list'),'value');
% ModelID = ids(v);
%
% % get file names of spec files on server
% fprintf('getting file name on server...\n');
% if ~strcmp(cfg.mysql_connector,'none')
%   result = mysqldb(['select file from modeldb_modelspec where model_id=' num2str(ModelID)],{'file'});
% else
%   result = [];
% end
% if isempty(result)
%   disp('there was an error opening the database.');
%   return;
% else
%   jsonfile = result.file{1};
% end
% % err=mym('open', cfg.webhost,cfg.dbuser,cfg.dbpassword);
% % if err
% %   disp('there was an error opening the database.');
% %   return;
% % else
% %   mym(['use ' cfg.dbname]);
% %   q = mym(['select file from modeldb_modelspec where model_id=' num2str(ModelID)]);
% %   jsonfile = q.file{1};
% % end
% % mym('close');
%
% % retrieve spec file
% fprintf('retrieving full model specification from server...\n');
% % temp dir
% target = fileparts(BACKUPFILE);
% if ~exist(target,'dir'), target=pwd; end
% % remote info
% [usermedia,modelfile] = fileparts(jsonfile);
% usermedia=fullfile(cfg.MEDIA_PATH,usermedia);
% modelfile=[modelfile '.json'];
% % ftp
% f=ftp([cfg.webhost ':' num2str(cfg.ftp_port)],cfg.xfruser,cfg.xfrpassword); % f=ftp([cfg.webhost ':' num2str(port)],cfg.username,cfg.password);
% pasv(f);
% cd(f,usermedia); % cd(f,'/project/infinitebrain/media/user/dev/models');
% mget(f,modelfile,target); % mget('model4.json')
% close(f);
%
% % % convert to Modulator spec
% fprintf('processing model specification and updating active model...\n');
% tempfile = fullfile(target,modelfile);
% [spec,jsonspec] = json2spec(tempfile);
% delete(tempfile);
%
% figure(H.fig);
% updatemodel(spec);
% refresh;
% fprintf('success.\n');
% % -------------------------------------------------------------------------
% function DB_AppendModel(src,evnt)
% -------------------------------------------------------------------------
function DB_Login(src,evnt)
global cfg H
u=get(H.editusername,'string');
p=get(H.editpassword,'string');
% authentication
result = mysqldb(sprintf('select id,email from auth_user where username=''%s''',u),{'id','email'});
if isempty(result)
  disp('authentication failed: there was an error opening the database for user authentication.');
  msgbox('LOGIN FAILED. You can upload models as ANONYMOUS user (File -> Upload)');
  return;
else
  cfg.username=u;
  cfg.password=p;
  cfg.user_id = result.id;
  if iscell(result.email)
    cfg.email = result.email{1};
  elseif ischar(result.email)
    cfg.email = result.email;
  else
    cfg.email = '';
  end
  cfg.is_authenticated = 1;
  disp('authentication successful.');
  fprintf('current user: %s (id=%g)\n',cfg.username,cfg.user_id);
end

% try
%   err=mym('open', cfg.webhost,cfg.dbuser,cfg.dbpassword);
% catch
%   err=1;
% end
% if err
%   disp('authentication failed: there was an error opening the database for user authentication.');
%   msgbox('LOGIN FAILED. You can upload models as ANONYMOUS user (File -> Upload)');
%   return;
% else
%   mym(['use ' cfg.dbname]);
%   q = mym(sprintf('select id,email from auth_user where username=''%s''',u));
%   mym('close');
%   if ~isempty(q.id)
%     cfg.username=u;
%     cfg.password=p;
%     cfg.user_id = q.id;
%     if iscell(q.email)
%       cfg.email = q.email{1};
%     elseif ischar(q.email)
%       cfg.email = q.email;
%     else
%       cfg.email = '';
%     end
%     cfg.is_authenticated = 1;
%     disp('authentication successful.');
%     fprintf('current user: %s (id=%g)\n',cfg.username,cfg.user_id);
%   else
%     fprintf('user "%s" not found\n',u);
%     return;
%   end
% end
set(H.txt_user,'string',['user: ' cfg.username]);
set(findobj('tag','login'),'visible','off');
set(findobj('tag','logout'),'visible','on');
if isfield(H,'rad_authorscope') && ishandle(H.rad_authorscope)
  set(H.rad_authorscope,'visible','on');
end
% -------------------------------------------------------------------------
function EnterPassword(src,evnt)
% password=get(src,'UserData');
% chars={'a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z',...
%        'A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z',...
%        '1','2','3','4','5','6','7','8','9','0',...
%        '!','@','#','$','%','^','&','*','(',')','-','_','+','=','~','.',',','/','\','|','?','<','>','`','{','}'};
% switch evnt.Key
%   case 'backspace'
%     if ~isempty(password)
%       password = password(1:end-1);
%     end
%     if isempty(get(src,'string'))
%       password = '';
%     end
%   otherwise
%     if ismember(evnt.Key,chars)
%       password = [password evnt.Key];
%     end
% end
% password
% set(src,'UserData',password);
% set(src,'String',repmat('*',[1 length(password)]));

% -------------------------------------------------------------------------
function DB_Logout(src,evnt)
global cfg H
cfg.username='anonymous';
cfg.password='';
cfg.user_id = 0;
cfg.email = '';
cfg.is_authenticated = 0;
set(findobj('tag','login'),'visible','on');
set(findobj('tag','logout'),'visible','off');
if isfield(H,'rad_authorscope') && ishandle(H.rad_authorscope)
  set(H.rad_authorscope,'visible','off');
end
set(H.txt_user,'string',['user: ' cfg.username]);
set(H.editusername,'string','username');
set(H.editpassword,'string','password');
% -------------------------------------------------------------------------
function download_models(src,evnt,replace_flag) % Load/Append from DB
% -- download and apply models (replaces: DB_LoadModel())
global cfg
% what models to download:
ids = get(findobj('tag','list'),'userdata');
v = get(findobj('tag','list'),'value');
ModelIDs = ids(v);
% download and use the models
models = download_get_models(ModelIDs,cfg); % get list of models from DB
if replace_flag
  spec = combine_models(models);
  spec.model_uid=[];
  spec.parent_uids=unique(cellfun(@(m)m.model_uid,models));
else
  global CURRSPEC
  spec = combine_models({CURRSPEC,models{:}});
  spec.model_uid=[];
  spec.parent_uids=unique([CURRSPEC.model_uid spec.parent_uids cellfun(@(m)m.model_uid,models)]);
end
figure(findobj('tag','mainfig'));
updatemodel(spec);
refresh;
fprintf('models downloaded successfully.\n');
function specs = download_get_models(ModelIDs,cfg)
% -- prepare list of model specs from list of Model IDs
target = pwd; % local directory for temporary files
specs={};
% Open MySQL DB connection
result = mysqldb(['select file from modeldb_modelspec where model_id=' num2str(ModelIDs(1))],{'file'});
if isempty(result)
  disp('there was an error opening the database.');
  return;
end
% err=mym('open', cfg.webhost,cfg.dbuser,cfg.dbpassword);
% if err
%   disp('there was an error opening the database.');
%   return;
% else
%   mym(['use ' cfg.dbname]);
% end

% Open ftp connection
try
  f=ftp([cfg.webhost ':' num2str(cfg.ftp_port)],cfg.xfruser,cfg.xfrpassword);
  pasv(f);
catch err
%   mym('close');
  disp('there was an error connecting (ftp) to the server.');
  rethrow(err);
end
% Get models from server
for i = 1:length(ModelIDs)
  ModelID=ModelIDs(i);
  % get file names of spec files on server
  fprintf('Model(uid=%g): getting file name and file from server\n',ModelID);
  result = mysqldb(['select file from modeldb_modelspec where model_id=' num2str(ModelID)],{'file'});
%   q = mym(['select file from modeldb_modelspec where model_id=' num2str(ModelID)]);
  jsonfile = result.file{1};
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
% -------------------------------------------------------------------------
function load_models(src,evnt,replace_flag,source_type) % Load/Append from disk
% -- load and apply models
if nargin<4, source_type='file'; end
if nargin<3, replace_flag=1; end
% what models to load:
switch source_type
  case 'file'
    [filename,pathname] = uigetfile({'*.mat'},'Pick a model or sim_data file.','MultiSelect','on');
    if isequal(filename,0) || isequal(pathname,0), return; end
    if iscell(filename)
      modelfiles = cellfun(@(x)fullfile(pathname,x),filename,'uniformoutput',false);
    else
      modelfiles = [pathname filename];
    end
  case 'list' % e.g., from launch screen
   % ...
   modelfiles = {};
end
if isempty(modelfiles)
  fprintf('nothing to load.\n');
  return;
end
% load and use the models
models = load_get_models(modelfiles); % get list of models from disk
if replace_flag
  spec = combine_models(models);
  spec.model_uid=[];
  if isfield(models,'model_uid')
    spec.parent_uids=unique(cellfun(@(m)m.model_uid,models));
  else
    spec.parent_uids=[];
  end
else
  global CURRSPEC
  spec = combine_models({CURRSPEC,models{:}});
  spec.model_uid=[];
  if isfield(models,'model_uid')
    spec.parent_uids=unique([CURRSPEC.model_uid spec.parent_uids cellfun(@(m)m.model_uid,models)]);
  else
    spec.parent_uids=[];
  end
end
updatemodel(spec);
refresh;
fprintf('models loaded successfully.\n');
function specs = load_get_models(modelfiles)
% -- prepare list of model specs from list of local model files
specs = {};
if ~iscell(modelfiles), modelfiles={modelfiles}; end
for i=1:numel(modelfiles)
  file=modelfiles{i};
  if exist(file,'file')
    try
      o=load(file);
      if isfield(o,'modelspec') && ~isfield(o,'spec') % standardize spec name
        o.spec=o.modelspec;
      end
      if isfield(o,'spec')
        specs{end+1}=o.spec;
      end
    catch
      fprintf('failed to load ''spec'' from %s\n',file);
    end
  else
    fprintf('model file not found: %s\n',file);
  end
end
% -------------------------------------------------------------------------
function spec = combine_models(models)
% -- combine cell array of models
if isempty(models), spec=[]; return; end
if ~iscell(models), models={models}; end
for i=1:numel(models)
  % standardize model spec structure
  this=standardize_model_spec(models{i});
  % combine models
  if i==1
    spec=this;
  else
    spec=combine_model_pair(spec,this);
  end
end
function spec = combine_model_pair(a,b)
% -- combine two models (and track model relations)
spec=a;
if isempty(spec) || isempty(spec.cells)
  trouble = 0;
else
  trouble = ismember({b.cells.label},{a.cells.label});
end
if any(trouble)
  dup={b.cells.label};
  dup=dup(test);
  str=''; for i=1:length(dup), str=[str dup{i} ', ']; end
  fprintf('failed to concatenate models. duplicate cell names found: %s. rename cells and try again.\n',str(1:end-2));
  return;
end
if isfield(a,'cells') && ~isempty(a.cells)
  n=length(b.cells);
  [addflds,I]=setdiff(fieldnames(a.cells),fieldnames(b.cells));
  [jnk,I]=sort(I);
  addflds=addflds(I);
  for i=1:length(addflds)
    b.cells(1).(addflds{i})=[];
  end
  b.cells=orderfields(b.cells,a.cells);
  b.connections=orderfields(b.connections,a.connections);
  spec.cells(end+1:end+n) = b.cells;
  for i=1:n
    spec.connections(end+i,end+1:end+n) = b.connections(i,:);
  end
  if isfield(b,'files')
    spec.files = unique({spec.files{:},b.files{:}});
  end
else
  spec = b;
end
function spec = standardize_model_spec(spec)
if isfield(spec,'entities')
  if ~isfield(spec,'cells')
    spec.cells=spec.entities;
  end
  spec=rmfield(spec,'entities');
end
if ~isfield(spec,'history')
  spec.history=[];
end
if ~isfield(spec,'model_uid')
  spec.model_uid=[];
end
if ~isfield(spec,'parent_uids');
  spec.parent_uids=[];
end
if ~isfield(spec.cells,'parent')
  for j=1:length(spec.cells)
    spec.cells(j).parent=spec.cells(j).label;
  end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function MechanismBrowser(src,evnt)
% global cfg allmechs
%
% % get list of local mechanisms
% localmechs = {allmechs.label};
% localfiles = {allmechs.file};
%
% % get list of remote mechanisms
% remotemechs='';
% remoteids=[];
% remotenotes='';
% try
%   level = 'mechanism';
%   if cfg.is_authenticated
%     result = mysqldb(sprintf('select id,name,level,notes from modeldb_model where user_id=%g and level=''%s''',cfg.user_id,level),{'id','name','level','notes'});
%   else
%     result = mysqldb(sprintf('select id,name,level,notes from modeldb_model where level=''%s''',level),{'id','name','level','notes'});
%   end
%   if ~isempty(result)
%     remotemechs = result.name';   % todo: sort so that mechs of an authenticated user are listed first
%     remoteids=result.id';
%     remotenotes=result.notes';
%   end
% %   err=mym('open', cfg.webhost,cfg.dbuser,cfg.dbpassword);
% %   mym(['use ' cfg.dbname]);
% %   level = 'mechanism';
% %   if cfg.is_authenticated
% %     q = mym(sprintf('select id,name,level,notes from modeldb_model where user_id=%g and level=''%s''',cfg.user_id,level));
% %   else
% %     q = mym(sprintf('select id,name,level,notes from modeldb_model where level=''%s''',level));
% %   end
% %   remotemechs = q.name';   % todo: sort so that mechs of an authenticated user are listed first
% %   remoteids=q.id';
% %   remotenotes=q.notes';
% %   mym('close');
% end
%
% % find "files" elements that are actually primary keys of remote mech models prefixed by "#"
% localremote_ind = find(~cellfun(@isempty,regexp(localfiles,'^#\d+')));
% % remove remote mechs that are already present in the local allmechs struct
% if any(localremote_ind)
%   redundant_ids = cellfun(@(x)strrep(x,'#',''),localfiles(localremote_ind),'unif',0);
%   redundant_ids = cellfun(@str2num,redundant_ids);
%   rmidx = ismember(remoteids,redundant_ids);
%   remotemechs(rmidx)=[];
%   remoteids(rmidx)=[];
%   remotenotes(rmidx)=[];
% end
%
% % prepare table data
% header = {'name','site','description','local','id'};%{'name','local','site','id','notes'};%{'id','name','local','site'};
% format= {'char','char','char','logical','numeric'};%{'numeric','char','logical','char'};
% editable=[1 0 1 0 0]==1;%[0 1 0 0]==1;
% localnotes=repmat({''},[1 length(localmechs)]);
% localids=zeros(1,length(localmechs));
% if any(localremote_ind)
%   localids(localremote_ind)=redundant_ids;
% end
% ids=[remoteids localids];
% names=cat(2,remotemechs,localmechs);
% local=[zeros(1,length(remoteids)) ones(1,length(localmechs))]==1;
% gosite=repmat({'link'},[1 length(local)]);
% [gosite{ids==0}]=deal(''); % remove links for mechs without key in DB (ie, w/o Django site)
% allnotes=cat(2,remotenotes,localnotes);
% data=cat(2,names',gosite',allnotes',num2cell(local'),num2cell(ids'));%data=cat(2,num2cell(ids'),names',num2cell(local'),gosite');
% ud.storage=cat(2,num2cell(remoteids),localfiles);
% ud.mechindex=cat(2,zeros(1,length(remoteids)),(1:length(localmechs)));
%
% % draw figure
% pos=get(findobj('tag','mainfig'),'position');
% if iscell(pos), pos=pos{1}; end
% pos(4)=.8*pos(4); % [10 30 800 510]
% h=findobj('tag','mechbrowser');
% if any(h)
%   figure(h(end));
% else
%   h=figure('tag','mechbrowser','position',pos,'color',cfg.bgcolor,'name','Browse Mechanisms','NumberTitle','off','MenuBar','none');
% end
% % draw controls
% % mechanism table
% uitable('parent',h,'units','normalized','position',[0 0 .35 1],'tag','mechtable','userdata',ud,...
%   'ColumnName',header,'ColumnFormat',format,'ColumnEditable',editable,'data',data,'CellSelectionCallback',@BrowserSelection,'CellEditCallback',@BrowserChange);
% % mechanism text box
% uicontrol('parent',h,'style','text','units','normalized','position',[.38 0 .59 .9],'tag','mechtext','BackgroundColor',[.9 .9 .9],'string','','FontName','Monospaced','FontSize',10,'HorizontalAlignment','Left');
% % -------------------------------------------------------------------------
% function BrowserSelection(src,evnt)
% if isempty(evnt.Indices)
%   return;
% end
% global allmechs cfg
% row=evnt.Indices(1);
% col=evnt.Indices(2);
% dat=get(src,'Data'); % {name,site,notes,local,id}
% if col==2 % site
%   if dat{row,5}>0 % has a primary key to a DB mech model in InfiniteBrain
%     % goto model detail page
%     web(sprintf('http://infinitebrain.org/models/%g/',dat{row,5}),'-browser');
%   end
% end
% if isequal(row,get(findobj('tag','mechtext'),'userdata'))
%   return;
% end
% ud=get(src,'userdata'); % storage (sql:id, disk:file), mechindex (index into allmechs struct)
% store=ud.storage{row}; % numeric id or filename
% index=ud.mechindex(row); % index in allmechs or 0
%
% id=dat{row,5};
% name=dat{row,1};
% islocal=(dat{row,4}==true);
% if islocal
%   mech = allmechs(index);
%   if exist(mech.file)
%     fid=fopen(mech.file); % open local mechanism file
%     txt={};
%     while (~feof(fid))
%       this = fgetl(fid);
%       if this == -1, break; end
%       txt{end+1}=this;
%     end
%     fclose(fid); % close mech file
%     set(findobj('tag','mechtext'),'string',txt,'userdata',row);
%   else
%     set(findobj('tag','mechtext'),'string',mech_spec2str(mech),'userdata',row);
%   end
% else
%   % download & convert mech.txt to mech structure; add to allmechs
%   %mech = getmechfromdb(id);
%   mech = download_get_models(id,cfg);
%   if iscell(mech), mech = mech{1}; end
%   mech.label = name;
%   mech.file = sprintf('#%g',id);
%   allmechs(end+1)=mech;
%   set(findobj('tag','mechtext'),'string',mech_spec2str(mech),'userdata',row);
%   ud.mechindex(row)=length(allmechs);
%   set(src,'userdata',ud);
%   dat{row,4}=true;
%   set(src,'Data',dat);
% end
% % -------------------------------------------------------------------------
% function BrowserChange(src,evnt)
% global allmechs
% row=evnt.Indices(1);
% col=evnt.Indices(2);
% dat=get(src,'Data');
% ud=get(src,'userdata');
% switch col % {name,site,notes,local,id}
%   case 1 % mechanism name column
%     ind=ud.mechindex(row);
%     if ind>0
%       allmechs(ind).label = dat{row,col};
%     end
%   case 2
%     if dat{row,5}>0 % has a primary key to a DB mech model in InfiniteBrain
%       % goto model detail page
%       web(sprintf('http://infinitebrain.org/models/%g/',dat{row,5}),'-browser');
%     end
% end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function result=mysqldb(query,fields)
% global cfg
% if isempty(cfg)
%   cfg.webhost = '104.131.218.171'; % 'infinitebrain.org','104.131.218.171'
%   cfg.dbname = 'modulator';
%   cfg.dbuser = 'querydb'; % have all users use root to connect to DB and self to transfer files
%   cfg.dbpassword = 'publicaccess'; % 'publicaccess'
% end
% [BIOSIMROOT,o]=fileparts(which('startup.m'));
% result=[];
% % check for database connector type and set cfg.mysql_connector
% if strcmp(query,'test')
%   % determine connection type
%   if exist('database.m')==2 % check for database toolbox
%     % MySQL JAR file
%     if exist('mysql-connector-java.jar')
%       jarfile = which('mysql-connector-java.jar');
%     elseif exist('mysql.jar')
%       jarfile = which('mysql.jar');
%     elseif exist('/usr/share/java/mysql-connector-java.jar')
%       jarfile = '/usr/share/java/mysql-connector-java.jar';
%     elseif exist(fullfile(BIOSIMROOT,'matlab','dependencies','mysql-connector-java-5.1.28.jar'))
%       jarfile = fullfile(BIOSIMROOT,'matlab','dependencies','mysql-connector-java-5.1.28.jar');
%     else
%       result='none';%cfg.mysql_connector = 'none';
%       msgbox('Database toolbox failed because of missing mysql-connector-java.jar');
%       return;
%     end
%     % Set this to the path to your MySQL Connector/J JAR
%     javaaddpath(jarfile); % WARNING: this might clear global variables
%     result='database'; %cfg.mysql_connector = 'database';
%   elseif exist('mym.m')==2  % check for mym
%     try
%       err=mym('open', cfg.webhost,cfg.dbuser,cfg.dbpassword);
%       mym('close');
%       result='mym';%cfg.mysql_connector = 'mym';
%     catch
%       result='none';%cfg.mysql_connector = 'none';
%     end
%   else
%     result='none';%cfg.mysql_connector = 'none';
%   end
%   if strcmp(result,'none')%strcmp(cfg.mysql_connector,'none')
%     %msgbox('Database connection cannot be established.');
%   end
%   return;
% end
% % query the DB
% try
%   switch cfg.mysql_connector
%     case 'database'
%       % JDBC Parameters
%       jdbcString = sprintf('jdbc:mysql://%s/%s',cfg.webhost,cfg.dbname);
%       jdbcDriver = 'com.mysql.jdbc.Driver';
%       % Create the database connection object
%       dbConn = database(cfg.dbname,cfg.dbuser,cfg.dbpassword,jdbcDriver,jdbcString);
%       if isconnection(dbConn)
%         data = get(fetch(exec(dbConn,query)), 'Data');
%       else
%         disp(sprintf('Connection failed:&nbsp;%s', dbConn.Message));
%       end
%       if isequal(data{1},'No Data')
%         result = [];
%       else
%         % convert result to structure
%         for i=1:numel(fields)
%           if isnumeric(data{1,i})
%             result.(fields{i}) = [data{:,i}]';
%           elseif ischar(data{1,i})
%             result.(fields{i}) = {data{:,i}}';
%           end
%         end
%       end
%       close(dbConn); % Close the connection so we don't run out of MySQL threads
%     case 'mym'
%       err=mym('open', cfg.webhost,cfg.dbuser,cfg.dbpassword);
%       if err
%         disp('there was an error opening the database.');
%       else
%         mym(['use ' cfg.dbname]);
%         result = mym(query);
%       end
%       mym('close');
%     case 'mysql'
%     otherwise
%   end
% catch
%   result = [];
%   disp('Database query failed.');
% end

