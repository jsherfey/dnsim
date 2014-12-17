function browse_dnsim(username,password,posteval)
% posteval: string to evaluate after setting global CURRSPEC
% usage: in modeler() GUI: browse btn callback = 'global cfg; browse_dnsim(cfg.username,cfg.password,''global CURRSPEC H; close(H.fig); modeler(CURRSPEC);''');
if nargin<1, username='anonymous'; end
if nargin<2, password='anonymous'; end
if nargin<3, posteval=''; end

global cfg
if isempty(cfg) || ~isfield(cfg,'bgcolor')
  cfg.bgcolor = [204 204 180]/255;
end
if ~isfield(cfg,'mysql_connector')
  cfg.mysql_connector = mysqldb('setup');
end

% Draw figure
% pos=get(findobj('tag','mainfig'),'position'); % if iscell(pos), pos=pos{1}; end;  pos(4)=.8*pos(4);
pos=[300 25 1400 975];
pos = .95*get(0,'ScreenSize'); pos(1)=pos(1)+50; pos(2)=pos(2)+50;
fig=findobj('tag','modelbrowser');
if ~any(strfind(version,'R2014b')) && any(fig)
  figure(fig);
else
  userdata.level='node';
  userdata.group='published';
  userdata.posteval=posteval;
  userdata.userquery='';
  if strcmp(cfg.mysql_connector,'none')
    userdata.mysql_flag=0;
  else
    userdata.mysql_flag=1;
    result = mysqldb(sprintf('select id from auth_user where username=''%s''',username),{'id'});
    if ~isempty(result)
      userdata.userquery = sprintf(' user_id=%g and',result.id);
    end
  end
  fig=figure('tag','modelbrowser','position',pos,'color',cfg.bgcolor,'name','Browse Models','NumberTitle','off','MenuBar','none','userdata',userdata);

  % DRAW CONTROLS
  % btn_mechanism: tag='model_level', userdata='mechanism', @update_model_lists
  uicontrol('style','pushbutton','tag','model_level','string','mechanism','userdata','mechanism','callback',@update_model_lists,...
    'units','normalized','position',[0 .95 .1 .05],'backgroundcolor',[1 1 1]);
  % btn_node: tag='model_level', userdata='node', @update_model_lists
  uicontrol('style','pushbutton','tag','model_level','string','node','userdata','node','callback',@update_model_lists,...
    'units','normalized','position',[.1 .95 .1 .05],'backgroundcolor',[.7 .7 .7]);
  % btn_network: tag='model_level', userdata='network', @update_model_lists
  uicontrol('style','pushbutton','tag','model_level','string','network','userdata','network','callback',@update_model_lists,...
    'units','normalized','position',[.2 .95 .1 .05],'backgroundcolor',[1 1 1]);

  % Local models:
  % uipanel: panel_local
  panel_local = uipanel('units','normalized','position',[0 .5 .3 .43],'backgroundcolor',cfg.bgcolor);
  % txt: 'local models' (tooltip: /path/to/dnsim/database)
  uicontrol('parent',panel_local,'style','text','string','local models',...
    'units','normalized','position',[0 .95 1 .05],'horizontalalignment','center','fontsize',14,'backgroundcolor',cfg.bgcolor);
  % lst_localmodels: tag='localmodels', @select_local_model
  uicontrol('parent',panel_local,'style','listbox','tag','localmodels','callback',@select_local_model,...
    'units','normalized','position',[0 0 1 .95],'background',[.9 .9 .9],'Max',20,'ButtonDownFcn','i=get(gcbo,''userdata''); v=get(gcbo,''value''); web(sprintf(''http://infinitebrain.org/models/%g/'',i(v(1))),''-browser'');');%,'TooltipString','right-click to open model web page for discussion');

  % Remote models:
  % uipanel: panel_remote
  panel_remote = uipanel('units','normalized','position',[0 0 .3 .49],'backgroundcolor',cfg.bgcolor);
  % txt: 'remote models' (tooltip: infinitebrain.org)
  uicontrol('parent',panel_remote,'style','text','string','remote models','tooltipstring','infinitebrain.org',...
    'units','normalized','position',[0 .95 1 .05],'horizontalalignment','center','fontsize',14,'backgroundcolor',cfg.bgcolor);
  % btn_user: tag='remote_group', userdata='user', @update_model_lists
  uicontrol('parent',panel_remote,'style','pushbutton','tag','remote_group','string',username,'userdata','user','callback',@update_model_lists,...
    'units','normalized','position',[0 .85 .34 .1],'backgroundcolor',[1 1 1]);
  % btn_public: tag='remote_group', userdata='public', @update_model_lists
  uicontrol('parent',panel_remote,'style','pushbutton','tag','remote_group','string','public','userdata','public','callback',@update_model_lists,...
    'units','normalized','position',[.34 .85 .33 .1],'backgroundcolor',[1 1 1]);
  % btn_published: tag='remote_group', userdata='published', @update_model_lists
  uicontrol('parent',panel_remote,'style','pushbutton','tag','remote_group','string','published','userdata','published','callback',@update_model_lists,...
    'units','normalized','position',[.67 .85 .33 .1],'backgroundcolor',[.7 .7 .7]);
  % lst_remotemodels: tag='remotemodels', @select_remote_model
  uicontrol('parent',panel_remote,'style','listbox','tag','remotemodels','callback',@select_remote_model,...
    'units','normalized','position',[0 0 1 .85],'background',[.9 .9 .9],'Max',20,'ButtonDownFcn','i=get(gcbo,''userdata''); v=get(gcbo,''value''); web(sprintf(''http://infinitebrain.org/models/%g/'',i(v(1))),''-browser'');');%,'TooltipString','right-click to open model web page for discussion');

  % Metadata area:
  % uipanel: panel_metadata
  panel_metadata = uipanel('units','normalized','position',[.3 0 .7 1],'backgroundcolor',cfg.bgcolor);
  % txt_metatitle
  uicontrol('parent',panel_metadata,'style','text','string','Model info','tag','modelname',...
    'units','normalized','position',[0 .96 .2 .03],'fontsize',16,'backgroundcolor',cfg.bgcolor);
  % chk_details: tag='show_details'
  uicontrol('parent',panel_metadata,'style','checkbox','string','show details?','tag','show_details','value',1,...
    'units','normalized','position',[.3 .96 .2 .03],'fontsize',12,'backgroundcolor',cfg.bgcolor);
  % txt_metadata: ... 
  uicontrol('parent',panel_metadata,'style','edit','tag','contentarea','string','',...
    'units','normalized','position',[0 0 1 .95],'ForegroundColor','k','FontName','Monospaced','FontSize',10,'HorizontalAlignment','Left','Max',100,'BackgroundColor',[.9 .9 .9]);
  % btn_load: {@load_models_callback,0,posteval}
  xshift=.5;
  uicontrol('parent',panel_metadata,'style','pushbutton','string','load','callback',{@load_models_callback,1},...
    'units','normalized','position',[0+xshift .96 .15 .04],'fontsize',12,'tag','btn_loader');
  % btn_append: {@load_models_callback,1,posteval}
  uicontrol('parent',panel_metadata,'style','pushbutton','string','append','callback',{@load_models_callback,0},...
    'units','normalized','position',[.16+xshift .96 .15 .04],'fontsize',12,'tag','btn_loader');
  % btn_web
  uicontrol('parent',panel_metadata,'style','pushbutton','string','web','callback','u=get(findobj(''tag'',''contentarea''),''userdata''); if ~isempty(u.id), web(sprintf(''http://infinitebrain.org/models/%g/'',u.id),''-browser''); end',...
    'units','normalized','position',[.32+xshift .96 .15 .04],'fontsize',12,'tag','goweb','visible','off');
  % txt_mechusage:
  uicontrol('parent',panel_metadata,'style','text','string','(list mechanism name to use)',...
    'units','normalized','position',[0+xshift .96 .3 .04],'fontsize',12,'tag','txt_mechusage','visible','off');

end

% initialize model lists
update_model_lists;

function update_model_lists(src,evnt)
% Purpose: set strings and userdata for local and remote listboxes
fig = findobj('tag','modelbrowser');
figdata = get(fig,'userdata'); % level, group, mysql_flag
update_remote_flag = figdata.mysql_flag;
update_local_flag = 1;
levels = {'mechanism','node','network'};
groups = {'user','public','published'};
% adjust settings for pressed button
if nargin>0
  caller=get(src,'userdata');
  if ismember(caller,levels)
    % model level was selected; adjust colors of mechanism, node, and network buttons
    set(findobj('tag','model_level'),'backgroundcolor',[1 1 1]);
    set(src,'backgroundcolor',[.7 .7 .7]);
    figdata.level = caller;
    if strcmp(caller,'mechanism')
      set(findobj('tag','btn_loader'),'visible','off');
      set(findobj('tag','txt_mechusage'),'visible','on');
    else
      set(findobj('tag','btn_loader'),'visible','on');      
      set(findobj('tag','txt_mechusage'),'visible','off');
    end
  elseif ismember(caller,groups)
    % remote model group was selected; no need to update local list
    set(findobj('tag','remote_group'),'backgroundcolor',[1 1 1]);
    set(src,'backgroundcolor',[.7 .7 .7]);
    figdata.group = caller;
    update_local_flag=0; 
  end
  set(fig,'userdata',figdata);
end
% update local list
if update_local_flag
  [list,data]=find_local_models(figdata.level);
  set(findobj('tag','localmodels'),'string',list,'userdata',data,'value',[]);
end
% update remote list
if update_remote_flag
  [list,data]=find_remote_models(figdata.level,figdata.group);
  set(findobj('tag','remotemodels'),'string',list,'userdata',data,'value',[]);
end

function [list,data]=find_local_models(level)
% Purpose: get list of local models; organize their info for listboxes ('string','userdata')
% if nargin<1, level='node'; end
if exist('startup.m'), [BIOSIMROOT,o]=fileparts(which('startup.m')); else BIOSIMROOT=pwd; end  
if ischar(BIOSIMROOT),   DBPATH = fullfile(BIOSIMROOT,'database'); else DBPATH = ''; end
if ~exist(DBPATH,'dir'), DBPATH = pwd; end
d=dir(DBPATH);
files={d.name};
switch level
  case 'mechanism'
    list = {d(cellfun(@(x)any(regexp(x,'.txt$')),files)).name};
    if ~isempty(list)
      list = cellfun(@(x)strrep(x,'.txt',''),list,'unif',0);
    end
    data.files = cellfun(@(x)fullfile(DBPATH,[x '.txt']),list,'unif',0);
    data.level = 'mechanism';
  case {'node','network'}
    files=files(~cellfun(@isempty,regexp(files,'\w*.mat$','match')));
    list = cellfun(@(x)strrep(x,'.mat',''),files,'unif',0);
    data.files=cellfun(@(x)fullfile(DBPATH,x),files,'unif',0);
    data.level = 'node';
end

function [list,data]=find_remote_models(level,group)
% Purpose: get list of remote models; organize their info for listboxes ('string','userdata')
% if nargin<1, level='node'; end
% if nargin<2, group='published'; end
fig = findobj('tag','modelbrowser');
userinfo = getfield(get(fig,'userdata'),'userquery');
fields = {'id','name','level','notes','ispublished','project_id'};
switch group
  case 'user'
    query=sprintf('select id,name,level,notes,ispublished,project_id from modeldb_model where%s level=''%s''',userinfo,level);
  case 'public'
    query=sprintf('select id,name,level,notes,ispublished,project_id from modeldb_model where level=''%s'' and privacy=''public''',level);
  case 'published'
    query=sprintf('select id,name,level,notes,ispublished,project_id from modeldb_model where level=''%s'' and ispublished=1',level);
end
data = mysqldb(query,fields);
if ~isempty(data), list = data.name; else list = {}; end
data.level = level;

function select_local_model(src,evnt)
% Purpose: update readable metadata for the select local model
if numel(get(src,'value'))>1
  % do nothing if more than one model is selected  
  return;
end
details_flag = get(findobj('tag','show_details'),'value');
% get content
v=get(src,'value');
s=get(src,'string');
u=get(src,'userdata');
content = sprintf('Model: %s\nFile: %s\n',s{v},u.files{v});
if details_flag
  file=u.files{v};
  dashline='--------------------------------------------------------------------------------';
  switch u.level
    case 'mechanism'
      % parse mech file
      txt={};
      if exist(file)
        fid=fopen(file); % open local mechanism file
        while (~feof(fid))
          this = fgetl(fid);
          if this == -1, break; end      
          txt{end+1}=this;
        end
        fclose(fid); % close mech file
      end
      content=sprintf('%s\n%s\nDETAILS\n%s\n',content,dashline,dashline);
      content=cat(2,{content},txt);
    case 'node'
      % load single model, use buildmodel2() to get description
      res=load(file);
      fld=fieldnames(res);
      [model,IC,functions,auxvars,spec,sodes,svars,txt] = buildmodel2(res.(fld{1}),'verbose',0,'nofunctions',0);
      txt=regexp(txt,'.*Specification files:','match');
      txt=strrep(txt{1},'Specification files:','');
      % append to content
      content=sprintf('%s\n%s\nDETAILS\n%s\n\n%s',content,dashline,dashline,txt);
  end
end
% update metadata
umeta.source='local';
umeta.id=[];
set(findobj('tag','contentarea'),'string',content,'userdata',umeta);
set(findobj('tag','remotemodels'),'value',[]);
set(findobj('tag','goweb'),'visible','off');
% set(findobj('tag','modelname'),'string',s{v});

function select_remote_model(src,evnt)
% Purpose: update readable metadata for the select remote model
if numel(get(src,'value'))>1
  % do nothing if more than one model is selected  
  return;
end
details_flag = get(findobj('tag','show_details'),'value');
v=get(src,'value');
s=get(src,'string');
u=get(src,'userdata');
% get content
content = sprintf('Model: %s',u.name{v});
if ~isnan(u.project_id(v))
  result=mysqldb(sprintf('select project_id from modeldb_model where id=%g',u.id(v)),{'project_id'});
  if ~isempty(result)
    result=mysqldb(sprintf('select name,owner_id from modeldb_project where id=%g',result.project_id),{'name','owner_id'});
    content = sprintf('%s (of project ''%s'')',content,result.name{1});
%     if ~isempty(result)
%       result2=mysqldb(sprintf('select username from auth_user where id=%g',result.owner_id),{'username'});
%       content = sprintf('%s (of project %s started by %s)',content,result.name{1},result2.username{1});
%     end
  end
end
content = sprintf('%s\nSite: infinitebrain.org/models/%g\n',content,u.id(v));
if ~isempty(u.notes{v})
  content = sprintf('%s\nDescription:\n%s\n',content,u.notes{v});
end
if u.ispublished(v)==1
  % use mysqldb() to get citations (for model_id=id)
  query=sprintf('select title,citation,url,about from modeldb_citation where model_id=%g',u.id(v));
  fields={'title','citation','url','about'};
  result=mysqldb(query,fields);
  % format citations for content area (add after Description)
  for i=1:numel(result.title)
    tmp=sprintf('\nCitation: %s',result.title{i});
    if ~isempty(result.citation{i})
      tmp=[tmp sprintf('\n%s',result.citation{i})];
    end
    if ~isempty(result.url{i})
      tmp=[tmp sprintf('\nURL: %s',result.url{i})];
    end
    if ~isempty(result.about{i})
      tmp=[tmp sprintf('\nAbout: %s',result.about{i})];
    end
  end
  % append to content
  content = sprintf('%s%s\n\n',content,tmp);
end
if details_flag
  dashline='--------------------------------------------------------------------------------';
  % download single model
  spec = download_get_models(u.id(v));
  if iscell(spec), spec=spec{1}; end
  switch u.level
    case 'mechanism'      
      txt = mech_spec2str(spec);     
      content=sprintf('%s\n%s\nDETAILS\n%s\n',content,dashline,dashline);
      content=cat(2,{content},txt);      
    case {'node','network'}
      [model,IC,functions,auxvars,spec,sodes,svars,txt] = buildmodel2(spec,'verbose',0,'nofunctions',0);
      txt=regexp(txt,'.*Specification files:','match');
      txt=strrep(txt{1},'Specification files:','');
      content=sprintf('%s\n%s\nDETAILS\n%s\n\n%s',content,dashline,dashline,txt);
  end  
end
% update metadata
umeta.source='remote';
umeta.id=u.id(v);
set(findobj('tag','contentarea'),'string',content,'userdata',umeta);
set(findobj('tag','localmodels'),'value',[]);
set(findobj('tag','goweb'),'visible','on');
% set(findobj('tag','modelname'),'string',s{v});

function load_models_callback(src,evnt,replace_flag)
% Purpose: load all selected local or remote models
% models to load
umeta=get(findobj('tag','contentarea'),'userdata');
lst = findobj('tag',[umeta.source 'models']);
data = get(lst,'userdata'); % listbox userdata (local or remote models)
v = get(lst,'value'); % selected models
% load models
switch umeta.source
  case 'local'
    models = load_get_models(data.files(v));
  case 'remote'
    models = download_get_models(data.id(v));    
end
% process loaded models
global CURRSPEC
if replace_flag
  spec = combine_models(models);
  spec.model_uid=[];
  if isfield(models,'model_uid')
    spec.parent_uids=unique(cellfun(@(m)m.model_uid,models));  
  else
    spec.parent_uids=[];
  end
  CURRSPEC = spec;
else
  spec = combine_models({CURRSPEC,models{:}});
  spec.model_uid=[];
  if isfield(models,'model_uid')
    spec.parent_uids=unique([CURRSPEC.model_uid spec.parent_uids cellfun(@(m)m.model_uid,models)]);  
  else
    spec.parent_uids=[];
  end
  CURRSPEC = spec;
end
% pass model to base workspace
fig=findobj('tag','modelbrowser');
u=get(fig,'userdata');
assignin('base','spec',CURRSPEC);
if ~isempty(u.posteval)
  eval(u.posteval)
end
fprintf('models loaded successfully and based to base workspace in ''spec''.\n');

