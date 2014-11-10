function c = loginconnect(datasource,f)
%LOGINCONNECT Datasource connection.
%   LOGINCONNECT(DATASOURCE) Prompts for the datasource username and password.

%   Author(s): C.F.Garvin, 08-25-98
%   Copyright 1984-2005 The MathWorks, Inc.

%Try connection with stored or no username or password
f = findobj('Tag','SQLDLG');
cfdlg = findobj('Tag','ConfDS');
uobj = findobj(f,'Tag','UserNames');
pobj = findobj(f,'Tag','Passwords');
sobj = findobj(f,'Tag','sources');
sval = get(sobj,'Value');
uudata = get(uobj,'Userdata');
pudata = get(pobj,'Userdata');
if isempty(uudata) || ~isempty(cfdlg) || (sval > length(uudata))
  u = '';
  p = '';
else
  u = uudata{sval};
  p = pudata{sval};
end

%Check for selected source in JDBC sources
jdbcfile = setdbprefs('JDBCDataSourceFile');

if nargin == 2
  ui = getappdata(cfdlg,'uidata');
  c = database(datasource,u,p,deblank(get(ui.driver,'String')),deblank(get(ui.url,'String')));
  usingjdbc = 1;
  
elseif ~isempty(jdbcfile) && (exist(jdbcfile) == 2)
  load(jdbcfile)
  i = find(strcmp(datasource,srcs(:,1)));
  if ~isempty(i)
    c = database(datasource,u,p,deblank(srcs{i,2}),deblank(srcs{i,3}));
    usingjdbc = 1;
  else
    c = database(datasource,u,p);
    usingjdbc = 0;
  end
else 
  c = database(datasource,u,p);
  usingjdbc = 0;
end
if ~strcmp(class(c.Handle),'double')
  return
end

%Build dialog to prompt for username and password
h = figure('Numbertitle','off','Menubar','none');

try
  pos = get(h,'Position');
catch
  querybuilder('sources')   %Trap double click of source list
  return
end

dfp = get(0,'DefaultFigurePosition');
mfp = [560 420];    %Reference width and height
bspc = mean([5/mfp(2)*dfp(4) 5/mfp(1)*dfp(3)]);
bhgt = 20/mfp(2) * dfp(4);
bfr = bhgt;
bwid = 80/mfp(1) * dfp(3);
set(h,'Name',['Datasource: ' datasource],'Tag','usernamepassworddialog',...
  'Position',[pos(1) pos(2) 2*bfr+3*bspc+2*bwid 2*bfr+5*bspc+4*bhgt])
pos = get(h,'Position');
rgt = pos(3);
top = pos(4);

uicontrol('Style','text','String','UserName:',...
  'Horizontalalignment','left','Backgroundcolor',get(gcf,'Color'),...
  'Position',[bspc+bfr top-bhgt-bspc-bfr bwid bhgt]);
uicontrol('Style','text','String','Password:',...
  'Horizontalalignment','left','Backgroundcolor',get(gcf,'Color'),...
  'Position',[bspc+bfr top-2*(bhgt+bspc)-bfr bwid bhgt]); 
uicontrol('Style','edit','Tag','username',...
  'Horizontalalignment','left','Backgroundcolor','white',...
  'Position',[2*bspc+bfr+bwid top-bhgt-bspc-bfr bwid bhgt]); 
uicontrol('Style','edit','Tag','password','Fontname','symbol',...
  'Horizontalalignment','left','Backgroundcolor','white',...
  'Position',[2*bspc+bfr+bwid top-2*(bhgt+bspc)-bfr bwid bhgt]);
uicontrol('String','OK','Callback','uiresume',... 
  'Position',[bspc+bfr+bwid/2 top-3*(bhgt+bspc)-bfr-bspc bwid bhgt]);
uicontrol('String','Cancel','Callback','close',...
  'Position',[bspc+bfr+bwid/2 top-4*(bhgt+bspc)-bfr-bspc bwid bhgt]);
set(gcf,'Keypressfcn','uiresume')

uiwait;

%Retrieve username and password and try to make connection
u = get(findobj('Tag','username'),'String');
p = get(findobj('Tag','password'),'String');

if nargin == 2
  c = database(datasource,u,p,deblank(get(ui.driver,'String')),deblank(get(ui.url,'String'))); 
elseif usingjdbc  
  c = database(datasource,u,p,deblank(srcs{i,2}),deblank(srcs{i,3}));
else
  c = database(datasource,u,p);
end

if ~strcmp(class(c.Handle),'double')
  if ~isempty(uobj) && isempty(cfdlg)
    uudata{sval} = u;
    pudata{sval} = p;
    set(uobj,'Userdata',uudata)
    set(pobj,'Userdata',pudata)
  end
else
  errordlg(c.Message)
  set(findobj('Type','figure'),'Pointer','arrow')
end
close(findobj('Tag','usernamepassworddialog'));
