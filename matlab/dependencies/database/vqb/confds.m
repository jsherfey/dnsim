function confds(x)
%CONFDS JDBC data sources.
%   CONFDS configures JDBC data sources.

%   Copyright 1984-2008 The MathWorks, Inc.

%Load datasource information
jdbcfile = setdbprefs('JDBCDataSourceFile');
if exist(jdbcfile)
  load(jdbcfile,'-mat')
  if ~exist('srcs')
    errordlg('Datasource file DATASOURCE.MAT corruption.')
    set(findobj('Type','figure'),'Pointer','arrow')
    return
  end
else
   srcs = cell(1,3);
   srcs(1,:) = [];   %This line to get 0 x 3 cell array
end

%Spacing parameters
dfp = get(0,'DefaultFigurePosition');
mfp = [560 420];    %Reference width and height
bspc = mean([5/mfp(2)*dfp(4) 5/mfp(1)*dfp(3)]);
bhgt = 20/mfp(2) * dfp(4);
bwid = 80/mfp(1) * dfp(3);


%Frame parameters
fwid1 = 5*bspc+4*bwid;
fhgt1 = 10*bspc+6*bhgt;
fwid2 = 2*bspc+bwid;
fhgt2 = 4*bspc+3*bhgt;
fwid3 = 4*bspc+bwid;
fhgt3 = 6*bspc+2*bhgt;

%Open dialog if not open
fobj = findobj('Tag','ConfDS');
if ~isempty(fobj)
  figure(fobj)
  set(findobj('Type','figure'),'Pointer','arrow')
  return
end

f = figure('Numbertitle','off','Name','Define JDBC Data Sources','Integerhandle','off',...
    'Menubar','none','Tag','ConfDS','Resize','off');
  
%Build frames 
uipanel('Units','pixels','Bordertype','beveledout','Position',[bspc 2*bspc+bhgt fwid1 fhgt1]);

%Set datasource data and save data flag
setappdata(gcf,'dsdata',srcs)
setappdata(gcf,'unsaved',0)

%Build JDBC Data Source File uicontrols
prefs = setdbprefs;
jdbcfile = prefs.JDBCDataSourceFile;
uipanel('Units','pixels','Bordertype','beveledout','Position',[bspc 9*bspc+8*bhgt fwid1 fhgt3]);
uicontrol('Style','text','String','JDBC data sources',...
  'Position',[3*bspc 12*bspc+10*bhgt bwid bhgt]);
uicontrol('Style','text','String','JDBC data source file:','Fontweight','bold',...
  'Position',[4*bspc 10*bspc+8*bhgt bwid bhgt]);
ui.jdbcdatasourcefile = uicontrol('Style','text','Tag','JDBCDataSourceFile','String',jdbcfile,...
  'Callback',{@getjdbcfile,f,'def'},'Tooltip',jdbcfile,...
  'Position',[2*bwid 10*bspc+8*bhgt 5*bspc+2*bwid bhgt]);
try %If filename is too long, truncate and add ...
  set(ui.jdbcdatasourcefile,'String',[jdbcfile(1:30) '...'])
end
uicontrol('String','Create New File...','Callback',{@getjdbcfile,f,'new'},...
  'Position',[3*bspc+0.5*bwid 12*bspc+9*bhgt 1.5*bwid bhgt]);
uicontrol('String','Use Existing File...','Callback',{@getjdbcfile,f,'use'},...
  'Position',[4*bspc+2*bwid 12*bspc+9*bhgt 1.5*bwid bhgt]);

%Build datasource uicontrols
ui.sources = uicontrol('Style','listbox','String',srcs(:,1),'Callback',{@source,f},'Tag','source',...
  'Tooltip','List of available datasources',...
  'Max',2,'Value',[],'Position',[2*bspc 4*bspc+2*bhgt 1.5*bwid 6*bspc+4*bhgt]);
ui.ds = uicontrol('Style','text','String','Data source:','Position',[2*bspc 6*bspc+7*bhgt bwid bhgt]);
ui.namestr = uicontrol('Style','text','String','Name:',...
  'Position',[4*bspc+1.5*bwid 6*bspc+7*bhgt bwid bhgt]);
ui.name = uicontrol('Style','edit','Tag','Name','Tooltip','Datasource name','Callback',{@cfdsname,f},...
  'Position',[4*bspc+1.5*bwid 6*bspc+6*bhgt bspc+2.5*bwid bhgt]);
ui.driverstr = uicontrol('Style','text','String','Driver:',...
  'Position',[4*bspc+1.5*bwid 5*bspc+5*bhgt bwid bhgt]);
ui.driver = uicontrol('Style','edit','Tag','Driver','Tooltip','Datasource driver','Callback',{@cfdsname,f},...
  'Position',[4*bspc+1.5*bwid 5*bspc+4*bhgt bspc+2.5*bwid bhgt]);
ui.urlstr = uicontrol('Style','text','String','URL:',...
  'Position',[4*bspc+1.5*bwid 4*bspc+3*bhgt bwid bhgt]);
ui.url = uicontrol('Style','edit','Tag','URL','Tooltip','Datasource URL','Callback',{@cfdsname,f},...
  'Position',[4*bspc+1.5*bwid 4*bspc+2*bhgt bspc+2.5*bwid bhgt]);

%Build datasource Add, Remove, Test pushbuttons
ui.test = uicontrol('String','Test','Callback',{@cfdstest,f},'Tooltip','Test datasource connection',...
  'Position',[5*bspc+2.75*bwid 3*bspc+bhgt bwid bhgt]);
ui.remove = uicontrol('String','Remove','Callback',{@cfdsremove,f},'Tooltip','Remove selected datasource',...
  'Position',[5*bspc 3*bspc+bhgt bwid bhgt]);
ui.add = uicontrol('String','Add / Update','Callback',{@cfdsadd,f},'Tooltip','Add datasource',...
  'Position',[3*bspc+1.75*bwid 3*bspc+bhgt bwid bhgt]);

%Set up for disabling and enabling source uicontrols
if isempty(jdbcfile), enflag = 'off'; else, enflag = 'on'; end
set([ui.sources ui.ds ui.namestr ui.name ui.driverstr ui.driver ui.urlstr ui.url ui.test ui.remove ui.add],...
    'Enable',enflag,'Userdata','scuis');

%Build OK, Cancel, Help pushbuttons
uicontrol('String','Help','Callback',{@cfdshelp,f},...
  'Tooltip','Datasource configuration help',...
  'Position',[4*bspc+2.5*bwid bspc bwid bhgt]);
uicontrol('String','Cancel','Callback',{@cfdscancel,f},'Tooltip','Close dialog',...
  'Position',[3*bspc+1.5*bwid bspc bwid bhgt]);
uicontrol('String','OK','Callback',{@cfdsok,f},'Tooltip','Close dialog',...
  'Position',[2*bspc+0.5*bwid bspc bwid bhgt]);
  
%Reset figure position to match frames
pos = get(f,'Position');
set(f,'Position',[pos(1) pos(2) 2*bspc+fwid1 5*bspc+bhgt+fhgt1+fhgt3])

setappdata(f,'uidata',ui)

%Cleanup dialog
w = warning;
warning('off','database:vqb:FunctionToBeRemoved')
querybuilder('cleanupdialog',f)
warning(w)

function cfdsadd(obj,evd,frame)

sdata = getappdata(frame,'dsdata');
ui = getappdata(frame,'uidata');
ustr = get(ui.url,'String');
dstr = get(ui.driver,'String');
nstr = get(ui.name,'String');
sstr = get(ui.sources,'String');
if (isempty(ustr) | isempty(dstr) | isempty(nstr))   %Check for missing entry
  errordlg('Missing datasource Name, Driver or URL.')
  set(findobj('Type','figure'),'Pointer','arrow')
  return  
end

j = find(strcmp(nstr,sdata(:,1)));   %Prevent duplicate datasource names
  
[m,n] = size(sdata);     %Update datasource data and unsaved flag
if isempty([sdata{:}])
  sdata = {nstr dstr ustr};
  sstr = {nstr};
  set(ui.sources,'String',sstr,'Value',m+1)
elseif ~isempty(j)
  sdata(j,1:3) = {nstr dstr ustr};
  sstr{j} = nstr;
else
  sdata(m+1,1:3) = {nstr dstr ustr};
  sstr = [sstr;{nstr}];
  set(ui.sources,'String',sstr,'Value',m+1)
end  
setappdata(frame,'dsdata',sdata)


function cfdscancel(obj,evd,frame)

close(frame)


function cfdshelp(obj,evd,frame)

qbhelp('Configure DataSource')


function cfdsname(obj,evd,frame)

setappdata(gcf,'unsaved',1)


function cfdsok(obj,evd,frame)
%CFDSOK Close confds dialog and update data sources list.

%Get uicontrol data
ui = getappdata(frame,'uidata');

%Prevent losing any unsaved data
namestr = get(ui.name,'String');
driverstr = get(ui.driver,'String');
urlstr = get(ui.url,'String');
if ~isempty(namestr) || ~isempty(driverstr) || ~isempty(urlstr)
  cfdsadd(obj,evd,frame)
end

%Set JDBCDataSourceFile
jdbcfile = get(ui.jdbcdatasourcefile,'Tooltip');
setdbprefs('JDBCDataSourceFile',jdbcfile)
closeflag = cfdssave(obj,evd,frame);
if closeflag
  close(frame)
  updatesources(obj,evd,frame)
end
  
function cfdsremove(obj,evd,frame)

ui = getappdata(frame,'uidata');
sdata = getappdata(frame,'dsdata');
sval = get(ui.sources,'Value');
sstr = get(ui.sources,'String');
if isempty(sdata) | isempty(sval)
  set(findobj('Type','figure'),'Pointer','arrow')
  return  
end
sdata(sval,:) = [];
sstr(sval) = [];
setappdata(frame,'dsdata',sdata)
set(ui.sources,'String',sstr,'Value',[])
set([ui.name ui.driver ui.url],'String',[])
setappdata(gcf,'unsaved',1)


function closeflag = cfdssave(obj,evd,frame)

%Save data to file
sdata = getappdata(frame,'dsdata');
srcs = sdata;

%Get JDBC data sources from confds configuration file
jdbcfile = setdbprefs('JDBCDataSourceFile');
if isempty(jdbcfile) && getappdata(frame,'unsaved')
  b = questdlg(['No JDBC data source file has been specified.  ',...
                'Would you like to specify one now?'],...
                'JDBC data source file','Yes','No','Cancel','Yes');
  switch b
    case 'Yes'
      [f,p] = uiputfile('*.mat','Specify a MAT file');
      jdbcfile = [ p  f ]; 
      if ~isa(jdbcfile,'double')
        setdbprefs('JDBCDataSourceFile',jdbcfile)
      else
        set(findobj('Type','figure'),'Pointer','arrow')
        return  
      end
      closeflag = 1;
    case 'No'
      closeflag = 1;
      set(findobj('Type','figure'),'Pointer','arrow')
      return 
    case 'Cancel'
      closeflag = 0;
      set(findobj('Type','figure'),'Pointer','arrow')
      return
  end
elseif ~getappdata(frame,'unsaved')
  closeflag = 1;
  set(findobj('Type','figure'),'Pointer','arrow')
  return
else
  closeflag = 1;
end

try
  save(jdbcfile,'srcs','-mat')
catch exception
  errordlg(exception.message)
  set(findobj('Type','figure'),'Pointer','arrow')
  return
end

setappdata(gcf,'unsaved',0)


function source(obj,evd,frame)

sdata = getappdata(frame,'dsdata');
ui = getappdata(frame,'uidata');
sval = get(ui.sources,'Value');
sval = min(sval);
set(ui.sources,'Value',sval) 
if isempty(sval)
  set(findobj('Type','figure'),'Pointer','arrow')
  return
end
set(ui.name,'String',sdata{sval,1})
set(ui.driver,'String',sdata{sval,2})
set(ui.url,'String',sdata{sval,3})


function cfdstest(obj,evd,frame)

ui = getappdata(frame,'uidata');
ustr = get(ui.url,'String');
dstr = get(ui.driver,'String');
nstr = get(ui.name,'String');
if (isempty(ustr) | isempty(dstr) | isempty(nstr))   %Check for missing entry
  errordlg('Missing datasource Name, Driver or URL.')
  set(findobj('Type','figure'),'Pointer','arrow')
  return  
end
sourcestr = get(ui.name,'String');
c = loginconnect(sourcestr,frame);

if ~isa(c.Handle,'double')
  msgbox(['Connection to ' sourcestr ' successful.'],['Datasource: ' sourcestr])
  close(c)
end




function jdbcfile = getjdbcfile(obj,evd,frame,bname)
%GETJDBCFILE JDBC data source file location.

ui = getappdata(frame,'uidata');

jdbcfile = setdbprefs('JDBCDataSourceFile');

switch bname
  case 'new'
    [f,p] = uiputfile('*.mat','Specify new JDBC data source MAT file');
  case 'use'
    [f,p] = uigetfile('*.mat','Specify existing JDBC data source MAT file');
end

%JDBC file
jdbcfile = [ p  f ]; 

%Check for cancel click in getfile dialogs and set preference if given
if ~isa(jdbcfile,'double')
  try
    set(ui.jdbcdatasourcefile,'String',[jdbcfile(1:30) '...'])
  catch
    set(ui.jdbcdatasourcefile,'String',jdbcfile)
  end
  set(ui.jdbcdatasourcefile,'Tooltip',jdbcfile)
  set([ui.sources ui.ds ui.namestr ui.name ui.driverstr ui.driver ui.urlstr ui.url ui.test ui.remove ui.add],...
    'Enable','on','Userdata','scuis');
  set([ui.name ui.driver ui.url],'String',[])
  if exist(jdbcfile)
    load(jdbcfile,'-mat')
    if ~exist('srcs')
      errordlg('Datasource file DATASOURCE.MAT corruption.')
      set(findobj('Type','figure'),'Pointer','arrow')
      return
    end
  else
    srcs = cell(1,3);
    srcs(1,:) = [];   %This line to get 0 x 3 cell array
  end
  set(ui.sources,'String',srcs(:,1),'Value',[]);
  setappdata(frame,'dsdata',srcs)
  source(obj,evd,frame)
  %Make text boxes proper width
  textuis = findobj(frame,'Style','text');
  for i = 1:length(textuis)
    pos = get(textuis(i),'Position');
    ext = get(textuis(i),'Extent');
    set(textuis(i),'Position',[pos(1) pos(2) ext(3) pos(4)])
  end
  set(textuis,'Backgroundcolor',get(0,'Defaultuicontrolbackgroundcolor'))
end


function updatesources(obj,evd,frame)
%UPDATESOURCES Refresh data source list

fig = getappdata(0,'SQLDLG');
if isempty(fig)
  %If querybuilder is not open, return
  return
end

%Get uicontrol data
ui = getappdata(fig,'uidata');

%Generate data source list
jdbcfile = setdbprefs('JDBCDataSourceFile');
[datasources,jdbcinfo] = getdatasources;
set(ui.sources,'String',datasources,'Value',[],'Max',2)
source([],[],fig)
