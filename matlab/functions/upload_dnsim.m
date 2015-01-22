function upload_dnsim(spec,username,password,cfg)
% check inputs
if nargin<4
  global cfg
  if ~isfield(cfg,'uploadname')
    cfg.uploadname='';
    cfg.projectname='';
    cfg.uploadnotes='';
    cfg.uploadtags='';
    cfg.citationtitle='';
    cfg.citationstring='';
    cfg.citationurl='';
    cfg.citationabout='';
  end
end
if nargin<3
  if isfield(cfg,'password'), password=cfg.password; else password='anonymous'; end
end
if nargin<2
  if isfield(cfg,'username'), username=cfg.username; else username='anonymous'; end
end
if isempty(cfg.citationtitle)
  cfg.citationtitle=cfg.uploadname;
end
if nargin<1
  global CURRSPEC
  if isempty(CURRSPEC)
    % prompt user to select file containing spec structure
    return;
  else
    spec=CURRSPEC;
  end
end
if ~isdeployed
  try
    if ~exist('ganymed-ssh2-build250','dir')
      sshfrommatlabinstall(1); % run at tool launch before setting global vars
    else
      sshfrommatlabinstall;
    end
  end
end

% create upload figure
% function GetUploadInfo(src,evnt)
if any(findobj('tag','uploadfig'))
  pos=get(findobj('tag','uploadfig'),'position');  
  close(findobj('tag','uploadfig'));
else
  pos=[680 100 560 900];  
end
fig=figure('name','Upload model to infinitebrain.org','tag','uploadfig','position',pos,'NumberTitle','off','MenuBar','none');

up=uipanel('parent',fig,'tag','uploadinfo','units','normalized','position',[0 .5 1 .5]);
dn=uipanel('parent',fig,'tag','citationinfo','units','normalized','position',[0 0 1 .5],'visible','off'); % 'off'
% -------------------------------------------------------------------------
% upload info panel
uicontrol('parent',up,'style','text','units','normalized','position',[.1 .9 .8 .05],'string','Model name (required)','fontweight','bold');
uicontrol('parent',up,'style','edit','units','normalized','position',[.1 .82 .8 .08],'string',cfg.uploadname,'backgroundcolor','w','horizontalalignment','left','tag','uploadname');
uicontrol('parent',up,'style','text','units','normalized','position',[.1 .75 .8 .05],'string','Description (optional)');
uicontrol('parent',up,'style','edit','units','normalized','position',[.1 .55 .8 .2],'string',cfg.uploadnotes,'max',3,'backgroundcolor','w','horizontalalignment','left','tag','uploadnotes');
uicontrol('parent',up,'style','text','units','normalized','position',[.1 .48 .8 .05],'string','Tags (optional)');
uicontrol('parent',up,'style','edit','units','normalized','position',[.1 .4 .8 .08],'string',cfg.uploadtags,'backgroundcolor','w','horizontalalignment','left','tag','uploadtags');
uicontrol('parent',up,'style','text','units','normalized','position',[.1 .33 .8 .05],'string','Project (optional)');
uicontrol('parent',up,'style','edit','units','normalized','position',[.1 .25 .8 .08],'string',cfg.projectname,'backgroundcolor','w','horizontalalignment','left','tag','projectname');
uicontrol('parent',up,'style','text','units','normalized','position',[.1 .15 .3 .05],'string',['Privacy (' cfg.username '):'],'horizontalalignment','left');
if strcmp(cfg.username,'anonymous')
  uicontrol('parent',up,'style','popupmenu','units','normalized','position',[.1 .06 .3 .1],'string',{'Public'},'value',1,'backgroundcolor','w','tag','uploadprivacy');
else
  uicontrol('parent',up,'style','popupmenu','units','normalized','position',[.1 .06 .3 .1],'string',{'Unlisted','Public'},'value',1,'backgroundcolor','w','tag','uploadprivacy');  
end
uicontrol('parent',up,'style','pushbutton','units','normalized','position',[.6 .04 .3 .15],'string','Upload','fontsize',14,'callback',{@DB_SaveModel,spec},'busyaction','cancel','Interruptible','off');
uicontrol('parent',up,'style','checkbox','units','normalized','position',[.1 .04 .3 .05],'string','published?','value',0,'callback',@ToggleCitation,'tag','chkpublished');
% -------------------------------------------------------------------------
% citation info panel
uicontrol('parent',dn,'style','text','string','Citation info','fontsize',18,'units','normalized','position',[.3 .85 .4 .1]);
uicontrol('parent',dn,'style','text','units','normalized','position',[.1 .8 .8 .05],'string','Title (required)','fontweight','bold','tooltipstring','This will be listed in the published model list');
uicontrol('parent',dn,'style','edit','units','normalized','position',[.1 .72 .8 .08],'string',cfg.citationtitle,'tag','citationtitle','backgroundcolor','w','horizontalalignment','left','tooltipstring','This will be listed in the published model list');
uicontrol('parent',dn,'style','text','units','normalized','position',[.1 .65 .8 .05],'string','Citation (required)','fontweight','bold','tooltipstring','formal (e.g., APA, MLA) or informal (e.g., author email) reference');
uicontrol('parent',dn,'style','edit','units','normalized','position',[.1 .45 .8 .2],'string',cfg.citationstring,'tag','citationstring','max',3,'backgroundcolor','w','horizontalalignment','left','tooltipstring','formal (e.g., APA, MLA) or informal (e.g., author email) reference');
uicontrol('parent',dn,'style','text','units','normalized','position',[.1 .38 .8 .05],'string','URL (optional)','tooltipstring','web link (e.g., pubmed, personal site)');
uicontrol('parent',dn,'style','edit','units','normalized','position',[.1 .3 .8 .08],'string',cfg.citationurl,'tag','citationurl','backgroundcolor','w','horizontalalignment','left','tooltipstring','web link (e.g., pubmed, personal site)');
uicontrol('parent',dn,'style','text','units','normalized','position',[.1 .23 .8 .05],'string','About (optional)','tooltipstring','extra citation info (e.g., abstract, comments, description)');
uicontrol('parent',dn,'style','edit','units','normalized','position',[.1 .03 .8 .2],'string',cfg.citationabout,'tag','citationabout','max',3,'backgroundcolor','w','horizontalalignment','left','tooltipstring','extra citation info (e.g., abstract, comments, description)');

% -------------------------------------------------------------------------
function ToggleCitation(src,evnt)
if get(src,'value')==1
  set(findobj('tag','citationinfo'),'visible','on');
else
  set(findobj('tag','citationinfo'),'visible','off');
end

function DB_SaveModel(src,evnt,spec) % (depends on server inbox/addmodel.py)
global cfg %CURRSPEC
% spec = CURRSPEC;
oldspec=spec;
if isfield(spec,'history'), spec=rmfield(spec,'history'); end

% get model info
projectname = get(findobj('tag','projectname'),'string');
modelname = get(findobj('tag','uploadname'),'string');
tags = get(findobj('tag','uploadtags'),'string');
notes = get(findobj('tag','uploadnotes'),'string');
str = get(findobj('tag','uploadprivacy'),'string');
val = get(findobj('tag','uploadprivacy'),'value');
privacy = str{val};
if isempty(modelname)
  warndlg('Model name required. Nothing was uploaded.');
  return; 
end
cfg.uploadname = modelname;
cfg.uploadnotes = notes;
cfg.uploadtags = tags;
cfg.projectname = projectname;
published_flag=get(findobj('tag','chkpublished'),'value');
% get citation info
if published_flag==1
  citationtitle = get(findobj('tag','citationtitle'),'string');
  citationstring = get(findobj('tag','citationstring'),'string');
  citationurl = get(findobj('tag','citationurl'),'string');
  citationabout = get(findobj('tag','citationabout'),'string');
  ispublished=1;
  cfg.citationtitle=citationtitle;
  cfg.citationstring=citationstring;
  cfg.citationurl=citationurl;
  cfg.citationabout=citationabout;
else
  ispublished=0;
  citationtitle='';
  citationstring='';
  citationurl='';
  citationabout='';
end
% check for required info
if isempty(modelname),disp('need model name'); return; end
if published_flag
%   if isempty(citationstring) && ~isempty(citationurl)
%     citationstring=citationurl; 
%     set(findobj('tag','citationstring'),'string',citationstring);
%   end
  if isempty(citationtitle)
    citationtitle=modelname;
    set(findobj('tag','citationtitle'),'string',citationtitle);
  end
  if isempty(citationstring) && isempty(citationurl), disp('need citation or URL'); return; end
end

% prepare files for uploading
tempfile=['temp' datestr(now,'YYMMDDhhmmss')];

% save spec MAT file
matfile = [tempfile '_spec.mat'];
if 1
  save(matfile,'spec');
end

% add Django model Model attributes (modelname, username, level, notes, d3file, readmefile, ispublished)
spec.modelname = modelname;
spec.username = cfg.username;
if any(~cellfun(@isempty,{spec.connections.mechanisms}))
  spec.level='network';
else
  spec.level = 'node';
end
if ~isfield(spec,'parent_uids')
  spec.parent_uids=[];
end
spec.notes=notes; 
  % todo: construct notes from CURRSPEC.history
spec.specfile=[tempfile '_spec.json'];
spec.d3file=[tempfile '_d3.json'];
spec.readmefile=[tempfile '_report.txt'];
spec.tags=tags;
  % todo: add checkbox-optional auto-list of tags from cell and mech labels
spec.privacy=privacy;
spec.ispublished=ispublished;
% add Django Project attributes (projectname)
spec.projectname=projectname;
% add Django Citation attributes (Citation title, citation, url, about)
spec.citationtitle=citationtitle;
spec.citationstring=citationstring;
spec.citationurl=citationurl;
spec.citationabout=citationabout;

% convert model to d3
fprintf('preparing model d3 .json...');
try
  d3json = spec2d3(oldspec,spec.d3file);
  fprintf('success!\n');
catch
  spec.d3file='';
  fprintf('failed!\n');
end

% convert model to human-readable descriptive report
try
  txt=cfg.modeltext;
  txt=regexp(txt,'.*Specification files:','match');
  txt=strrep(txt{1},'Specification files:','');
  fid = fopen(spec.readmefile,'w+');
  fprintf(fid,'%s\n',txt);
  fclose(fid);
catch
  spec.readmefile='';
end

% convert model to json
fprintf('converting model into .json format...');
[json,jsonspec] = spec2json(spec,spec.specfile); % ss=loadjson(json); isequal(jsonspec,ss)
fprintf('success!\n');

% transfer files to server
fprintf('transfering .json specification to server...');
target='/project/infinitebrain/inbox';
f=ftp([cfg.webhost ':' num2str(cfg.ftp_port)],cfg.xfruser,cfg.xfrpassword);
pasv(f);
cd(f,target);
% json specification
mput(f,spec.specfile); 
delete(spec.specfile);
% mat-file specification
if exist(matfile)
  mput(f,matfile);
  delete(matfile);
end
% d3 graphical model schematic
if exist(spec.d3file)
  mput(f,spec.d3file); 
  delete(spec.d3file);
end
% human-readable model description + equations
if exist(spec.readmefile)
  mput(f,spec.readmefile); 
  delete(spec.readmefile);
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
close(findobj('tag','uploadfig'));

% goto web page
if ~strcmp(cfg.mysql_connector,'none')
  %result = mysqldb(sprintf('select id from modeldb_model where user_id=%g and level=''%s''',cfg.user_id,level),{'id','name','level'});
  result = mysqldb(sprintf('select id from modeldb_model where name=''%s''',modelname),{'id'});
  if ~isempty(result)
    web(sprintf('http://infinitebrain.org/models/%g/',max(result.id)),'-browser');
  end
end
