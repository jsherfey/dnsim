
% ----------------------------------
% uncomment this line and remove the net-def when finished
% if nargin<1, net=[]; end
if nargin<1 && isempty(varargin)
  net=[];
%   cell = [];
%   cell.label = 'E';        % --> cell name
%   cell.multiplicity = 5;   % --> number of cells
%   cell.mechanisms = {'itonic' 'ileak','iK','iNa','noise'}; % predefined: get_mechlist
%   cell.parameters = {'E_l',-54.4,'g_l',.3,'Cm',1,'ENa',50,'gNa',120,'EKf',-77};
%   cell.dynamics = 'V''=(current)'; % note: set timelimits=[0 25000]
%   net.cells=cell;
%   net.connections.mechanisms='iSYN';
%   net.connections.parameters=[];
%   net.connections.label = 'E-E';
else
  net = varargin{1};
end
% ----------------------------------
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
if ischar(BIOSIMROOT)
  DBPATH = fullfile(BIOSIMROOT,'database');
else
  DBPATH = '/space/mdeh3/9/halgdev/projects/jsherfey/code/modeler/database';
end
if ~exist(DBPATH,'dir')
  DBPATH = 'C:\Users\jsherfey\Desktop\My World\Code\modelers\database';
end
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
if isempty(net.cells)
  net.cells.label='a';
  net.cells.multiplicity=1;
  net.cells.dynamics='V''=0';
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
for i=1:length(allmechfiles)
  this = parse_mech_spec(allmechfiles{i},[]);
  [fpath,fname,fext]=fileparts(allmechfiles{i});
  this.label = fname;
  this.file = allmechfiles{i};
  if i==1, allmechs = this;
  else allmechs(i) = this;
  end
end
% initialize config
cfg.focuscomp = 1; % index to component-of-focus in spec.cells (start w/ root)
cfg.focusmech = focusmech;
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
% cfg.selmechlist = selmechlist;
% cfg.allmechlist = allmechlist;
cfg.allmechfiles = allmechfiles;
cfg.allmechfiles_db = allmechfiles_db;
cfg.DBPATH = DBPATH;
cfg.T=(0:cfg.buffer-1)*cfg.dt; % ms
cfg.V=linspace(-100,100,cfg.buffer); % mV
cfg.colors  = 'kbrgmy';
cfg.lntype  = {'-',':','-.','--'};
cfg.newmechs={};

LASTSPEC = net;
CURRSPEC = net;
