function StudyDriverUI
global H CURRSPEC
if isempty(CURRSPEC)
  fprintf('Must define global model in CURRSPEC before calling StudyDriverUI\n');
  return;
end
sz = get(0,'ScreenSize'); 
pos = [.25*sz(3) .25*sz(4) .5*sz(3) .5*sz(4)];
if isfield(H,'f_simdriver') && ishandle(H.f_simdriver)
  figure(H.f_simdriver); 
else
  H.f_simdriver = figure('MenuBar','none','name','Simulation study','NumberTitle','off','position',pos);  
end
DrawStudyInfo;

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
if ~isfield(H,'text_scope') || ~ishandle(H.text_scope)
  H.text_scope = uicontrol('parent',H.f_simdriver,'units','normalized',...
    'style','text','position',[.1 .86 .1 .04],'string','scope',...
    'HorizontalAlignment','center');%,'backgroundcolor','w'
  H.text_variable = uicontrol('parent',H.f_simdriver,'units','normalized',...
    'style','text','position',[.31 .86 .1 .04],'string','variable',...
    'HorizontalAlignment','center');%,'backgroundcolor','w'
  H.text_values = uicontrol('parent',H.f_simdriver,'units','normalized',...
    'style','text','position',[.52 .86 .1 .04],'string','values',...
    'HorizontalAlignment','center'); %,'backgroundcolor','w'
  H.btn_run_simstudy = uicontrol('parent',H.f_simdriver,'units','normalized',...
    'style','pushbutton','fontsize',10,'string','run','callback',@RunSimStudy,...
    'position',[.85 .9 .1 .06]);
  H.edit_clusterflag = uicontrol('parent',H.f_simdriver,'units','normalized',...
    'style','edit','position',[.96 .9 .035 .04],'backgroundcolor','w','string','1',...
    'HorizontalAlignment','left');
  H.edit_rootdir = uicontrol('parent',H.f_simdriver,'units','normalized',...
    'style','edit','position',[.1 .95 .5 .04],'backgroundcolor','w','string',pwd,...
    'HorizontalAlignment','left');
  H.edit_memlimit = uicontrol('parent',H.f_simdriver,'units','normalized',...
    'style','edit','position',[.62 .95 .1 .04],'backgroundcolor','w','string','8G',...
    'HorizontalAlignment','left');
  H.edit_dt = uicontrol('parent',H.f_simdriver,'units','normalized',...
    'style','edit','position',[.73 .95 .1 .04],'backgroundcolor','w','string','0.01',...
    'HorizontalAlignment','left');
  H.edit_timelimits = uicontrol('parent',H.f_simdriver,'units','normalized',...
    'style','edit','position',[.73 .91 .1 .04],'backgroundcolor','w','string','[0 40]',...
    'HorizontalAlignment','left');
  H.edit_dsfact = uicontrol('parent',H.f_simdriver,'units','normalized',...
    'style','edit','position',[.62 .91 .1 .04],'backgroundcolor','w','string','1',...
    'HorizontalAlignment','left');
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
  H.edit_scope(i) = uicontrol('parent',H.f_simdriver,'units','normalized',...
    'style','edit','position',[.1 .8-.1*(i-1) .2 .06],'backgroundcolor','w','string',study(i).scope,...
    'HorizontalAlignment','left','Callback',sprintf('global cfg; cfg.study(%g).scope=get(gcbo,''string'');',i));
  H.edit_variable(i) = uicontrol('parent',H.f_simdriver,'units','normalized',...
    'style','edit','position',[.31 .8-.1*(i-1) .2 .06],'backgroundcolor','w','string',study(i).variable,...
    'HorizontalAlignment','left','Callback',sprintf('global cfg; cfg.study(%g).variable=get(gcbo,''string'');',i));
  H.edit_values(i) = uicontrol('parent',H.f_simdriver,'units','normalized',...
    'style','edit','position',[.52 .8-.1*(i-1) .4 .06],'backgroundcolor','w','string',study(i).values,...
    'HorizontalAlignment','left','Callback',sprintf('global cfg; cfg.study(%g).values=get(gcbo,''string'');',i)); 
  H.btn_simset_delete(i) = uicontrol('parent',H.f_simdriver,'units','normalized',...
    'style','pushbutton','fontsize',10,'string','-','callback',{@DeleteSimSet,i},...
    'position',[.06 .8-.1*(i-1) .03 .06]);
  H.btn_simset_copy(i) = uicontrol('parent',H.f_simdriver,'units','normalized',...
    'style','pushbutton','fontsize',10,'string','+','callback',{@CopySimSet,i},...
    'position',[.93 .8-.1*(i-1) .03 .06]);
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
global cfg CURRSPEC H
scope = {cfg.study.scope};
variable = {cfg.study.variable};
values = {cfg.study.values};
dir=get(H.edit_rootdir,'string');
mem=get(H.edit_memlimit,'string');
dt=str2num(get(H.edit_dt,'string'));
lims=str2num(get(H.edit_timelimits,'string'));
dsfact=str2num(get(H.edit_dsfact,'string'));
clusterflag = str2num(get(H.edit_clusterflag,'string'));
simstudy(CURRSPEC,scope,variable,values,'dt',dt,'rootdir',dir,'memlimit',mem,...
  'timelimits',lims,'dsfact',dsfact,'sim_cluster_flag',clusterflag);

if 0
  allspecs = get_search_space(CURRSPEC,scope,variable,values)
  logfid=1; spec.simulation.rootdir=pwd;
  scopes = cellfun(@(x)x.simulation.scope,allspecs,'uni',0);
  vars = cellfun(@(x)x.simulation.variable,allspecs,'uni',0);
  uniqscopes = unique(scopes);
  outdirs={}; dirinds=zeros(size(allspecs));
  for k=1:length(uniqscopes)
    scopeparts = regexp(uniqscopes{k},'[^\(\)]*','match');
    inds = strmatch(uniqscopes{k},scopes,'exact');
    varparts = regexp(vars{inds(1)},'[^\(\)]*','match');
    dirname = '';
    for j=1:length(scopeparts)
      dirname = [dirname '_' strrep(scopeparts{j},',','_') '-' varparts{j}];
    end
    outdirs{end+1} = dirname(2:end);
    dirinds(inds) = k;
  end
  rootoutdir={}; prefix={}; outdirs
  for i=1:length(allspecs)
    rootoutdir{i} = fullfile(spec.simulation.rootdir,datestr(now,'yyyymmdd-HHMM'),outdirs{dirinds(i)});
    tmp=regexp(allspecs{i}.simulation.description,'[^\d_].*','match');
    prefix{i}=strrep([tmp{:}],',','_');
    fprintf(logfid,'%s: %s\n',rootoutdir{i},prefix{i});
  end
  keyboard
end


