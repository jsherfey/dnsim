function [spec,json,xml] = loadspec(inspec,varargin)
% Purpose: load model and sim spec and return a standard spec structure
% common to all biosim matlab functions.
% input:
%   files = string or cellarrstr listing spec files
%       Supported formats:
%       - model spec: csv (x4), matlab struct, json, xml
%       - sim spec: json
% output:
%   spec = structure with model and sim info (whatever is available)
% 
% Example:
% spec = loadspec('cellspecs','cellspecs.csv',...
%                 'connections','connections.csv',...
%                 'fanout','fanout.csv',...
%                 'netspecs','netspecs.csv');
% 
% Created on 2012/08/24 by Jason Sherfey

% use mmil_args2parms() or varargin2struct() ??
% ...

spec = [];

% Load spec
if nargin > 0 && isstruct(inspec)     % loadspec(spec) => return spec
  spec = inspec; 
  return;
elseif nargin==0                      % loadspec => load example spec
  fpath = '/space/mdeh3/9/halgdev/projects/jsherfey/inbox/20120824-182925_1';
  prefix = '2012-08-24_21-29-11_';
  cwd = pwd; cd(fpath);
  % Load model &/or simulation specification(s)
  [spec,json,xml] = loadspec('cellspecs',[prefix 'cellspecs.csv'],...
                  'connections',[prefix 'connections.csv'],...
                  'netspecs',[prefix 'netspecs.csv'],...
                  'simspecs',[prefix 'simulation.json']);
%                   'fanout',[prefix 'fanout.csv'],...
  cd(cwd);
  return;
elseif exist(inspec,'dir')          
  cwd = pwd; cd(inspec);
  if nargin>1 && isstr(varargin{1})   % loadspec(fpath,prefix) 
    prefix = varargin{1};
  else                                % loadspec(fpath) 
    if exist(fullfile(inspec,'cellspecs.csv'),'file')
      prefix = '';
    else
      d = dir;
      f = {d(~[d.isdir]).name};
      prefix = regexp(f{1},'^[\d-_]+','match');
      prefix = prefix{1};
      if isempty(prefix), prefix = ''; end
    end
  end
  % Load model &/or simulation specification(s)
%   [spec,json,xml] = loadspec('cellspecs',[prefix 'cellspecs.csv'],...
%                   'connections',[prefix 'connections.csv'],...
%                   'netspecs',[prefix 'netspecs.csv'],...
%                   'simspecs',[prefix 'simulation.json'],...
%                   'prefix',prefix);
  [spec,json,xml] = loadspec('cellspecs',fullfile(inspec,[prefix 'cellspecs.csv']),...
                  'connections',fullfile(inspec,[prefix 'connections.csv']),...
                  'netspecs',fullfile(inspec,[prefix 'netspecs.csv']),...
                  'simspecs',fullfile(inspec,[prefix 'simulation.json']),...
                  'prefix',prefix);
  cd(cwd);
  return;
elseif exist(inspec,'file')           % loadspec(specfile)
  [fpath,fname,fext] = fileparts(inspec);
  if strcmp(fext,'.mat')
    load(inspec,'spec');
    return
  end
else                                  % loadspec('key',value,...) => load & return spec
  % load files input 
  varargin = {inspec,varargin{:}};
  cfg = mmil_args2parms( varargin, ...
         {  'connections',[],[],...%'connection.csv',[],...
            'netspecs',[],[],...%'netspecs.csv',[],...
            'cellspecs',[],[],...%'cellspecs.csv',[],...
            'simspecs',[],[],...%'simspecs.json',[],...
            'prefix','',[],...
         }, ...
         false );
%             'fanout',[],[],...%'fanout.csv',[],...

  files = struct2cell(cfg);
  names = fieldnames(cfg);
  names = names(cellfun(@exist,files)~=0);
  files = files(cellfun(@exist,files)~=0);
  if isempty(files), error('Could not find an existing specification file.'); end

  extensions = cellfun(@(f)f(find(f=='.',1,'last'):end),files,'uniformoutput',false);
  ext_code = [extensions{:}];

  if any(strfind(ext_code,'.csv'))
    spec = loadcsv(files,names); 
  end
  if any(strfind(ext_code,'.json'))
    simspec = loadjsonsim(files(strmatch('simspecs',names)),names(strmatch('simspecs',names))); 
    spec.simulation = simspec;
  else
    spec.simulation = [];
  end
  
  % create list of files associated with this spec
  for k=1:length(files)
    [a,b,c] = fileparts(files{k});
    if isempty(a) && exist([pwd '/' b c],'file')
      spec.files{k} = [pwd '/' b c];
    elseif ~isempty(a) && exist([a '/' b c],'file')
      spec.files{k} = [a '/' b c];
    else
      %spec.files{k} = which(files{k}); 
    end
  end
  files = {};
  flds = {'entities','connections'};
  for f = 1:length(flds)
    for i = 1:numel(spec.(flds{f}))
      if issubfield(spec,[flds{f} '.mechanisms'])
        m = spec.(flds{f})(i).mechanisms; if ischar(m), m = {m}; end
      else
        m = [];
      end
      if iscell(m) && ~isempty(m) && ~isempty(m{1})
        m=cellfun(@(x)splitstr(x,' '),m,'uniformoutput',false);
        m=[m{:}];
      end
      for j = 1:length(m)
        tmp = m{j};
        if     exist([cfg.prefix tmp '.txt'],'file'), tmp = fullfile(pwd,[cfg.prefix tmp '.txt']);
        elseif exist([cfg.prefix tmp '.m'  ],'file'), tmp = fullfile(pwd,[cfg.prefix tmp '.m'  ]);          
%         elseif exist([tmp '.txt'],'file'), tmp = which([tmp '.txt']);
%         elseif exist([tmp '.m'  ],'file'), tmp = which([tmp '.m']);          
        end
        if exist(tmp,'file'), files = {files{:} tmp}; end
      end
    end
  end
  spec.files = unique({spec.files{:} files{:}});
  spec.files = spec.files(cellfun(@exist,spec.files)~=0);
  
  % covert matlab structure in generic formats:
  % if any(strfind(ext_code,'.mat'))
  % if any(strfind(ext_code,'.xml'))
  json = savejson('model',spec);
%   xml = xml_formatany(spec,'model');
  xml = '';
end  

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTIONS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function simspec = loadjsonsim(files,names)
if ~ismember('simspecs',names), error('You must supply a simspecs file when giving json files.'); end
simspec = loadjson(files{1});
try simspec.scope = correct_loadjson_arrstr(simspec.scope); end
try simspec.variable = correct_loadjson_arrstr(simspec.variable); end
try simspec.values = correct_loadjson_arrstr(simspec.values); end
sz = [numel(simspec.scope) numel(simspec.variable) numel(simspec.values)];
flds = {'scope','variable','values'};
for f = 1:length(flds)
  if sz(f)==1 && max(sz)>1
    tmp = simspec.(flds{f}){1};
    if numel(tmp)==max(sz)
      tmp = correct_loadjson_arrstr(reshape(tmp,[max(sz) numel(tmp)/max(sz)]));
    else
      tmp = correct_loadjson_arrstr(reshape(tmp,[max(sz) numel(tmp)/max(sz)])');
    end
    simspec.(flds{f}) = tmp;
  end
end
if iscell(simspec.scope) && numel(simspec.scope)==1, simspec.scope=simspec.scope{1}; end
if iscell(simspec.variable) && numel(simspec.variable)==1, simspec.variable=simspec.variable{1}; end
if iscell(simspec.values) && numel(simspec.values)==1, simspec.values=simspec.values{1}; end
% if sz(1)==1 && max(sz)>1, simspec.scope = repmat({simspec.scope{1}(1:(numel(simspec.scope{1})/max(sz)))},[1 max(sz)]); end
% if sz(2)==1 && max(sz)>1, simspec.variable = repmat({simspec.variable{1}(1:(numel(simspec.variable{1})/max(sz)))},[1 max(sz)]); end
% if sz(3)==1 && max(sz)>1, simspec.values = repmat({simspec.values{1}(1:(numel(simspec.values{1})/max(sz)))},[1 max(sz)]); end
  
function spec = loadcsv(files,names)
if ~ismember('cellspecs',names)
  error('You must supply a cellspecs file when giving csv files.');
end
if ~ismember('connections',names) && numel(files)>1
  error('You must supply a connections file listing mechanisms to define networks.');
end

% Entities
[cellspecs,res] = mmil_readtext(files{strcmp('cellspecs',names)});
cellspecs = parsecell(cellspecs(res.numberMask(:,2),:));
del = cellfun(@(x)isequal(x(1),'%')||isequal(x(1),'#'),cellspecs(:,1));
cellspecs(del,:)=[];

[npop,ncol] = size(cellspecs);
[Edynamics{1:npop}] =  deal('');
if ncol > 5
  for k=1:npop
    cellspecs{k,3} = [cellspecs{k,3} cellspecs{k,4}]; 
    cellspecs{k,5} = [cellspecs{k,5} cellspecs{k,6}]; 
  end
  cellspecs = cellspecs(:,[1 2 3 5]);
elseif ncol > 4
  Edynamics = cellspecs(:,5);
end
% only keep entities with at least one instance in model (ie. N>0)
keep = find([cellspecs{:,2}]>0);
npop = length(keep);
cellspecs = cellspecs(keep,:);
% extract different kinds of info
tmp = cellfun(@(x)cellspecs(:,x),num2cell(1:min(4,size(cellspecs,2))),'uniformoutput',false);
if numel(tmp)<4
  [popID,popSize,popMechs] = deal(tmp{1:3});
  [popParms{1:npop}] = deal([]);
else
  [popID,popSize,popMechs,popParms] = deal(tmp{1:4});
end
popSize = [popSize{:}];

% Network connections
try
  % connections
  [connections,res] = mmil_readtext(files{strcmp('connections',names)});
%   connections = connections(keep,keep);
%   res.stringMask = res.stringMask(keep,keep);
  connections = connections(2:end,2:end);
  res.stringMask = res.stringMask(2:end,2:end);
  [~,I] = match_str(popID,connections(res.stringMask(:,1),1)); % rearrange to match PopID
  connType = parsecell(connections(I+1,I+1));
  % fanout
  if exist(files{strcmp('fanout',names)},'file')
    [fanout,res] = mmil_readtext(files{strcmp('fanout',names)});
%     fanout = fanout(keep,keep);
    fanout = fanout(2:end,2:end);
    res.stringMask = res.stringMask(2:end,2:end);
    [~,I] = match_str(popID,fanout(res.stringMask(:,1),1)); % rearrange to match PopID
    fanout = parsecell(fanout(I+1,I+1));
  else
    fanout = cell(npop,npop);
  end
  % params
  if exist(files{strcmp('netspecs',names)},'file')
    [netspecs,res] = mmil_readtext(files{strcmp('netspecs',names)});
%     netspecs = netspecs(keep,keep);
    netspecs = netspecs(2:end,2:end);
    res.stringMask = res.stringMask(2:end,2:end);
    [~,I] = match_str(popID,netspecs(res.stringMask(:,1),1)); % rearrange to match PopID
    SynParm = parsecell(netspecs(I+1,I+1));
  else
    SynParm = cell(npop,npop);
  end
catch
%   fprintf('failed to read network specification\n');
  connType = cell(npop,npop);
  fanout = cell(npop,npop);
  SynParm = cell(npop,npop);
end

for i = 1:npop
  spec.entities(i).label = popID{i};
  spec.entities(i).multiplicity = popSize(i);
  try spec.entities(i).mechanisms = parsecell(popMechs{i});
  catch spec.entities(i).mechanisms = popMechs{i}; end
  try spec.entities(i).parameters = parsecell(popParms{i});
  catch spec.entities(i).parameters = popParms{i}; end  
  spec.entities(i).dynamics = Edynamics{i};
end
for i = 1:npop
  for j = 1:npop
    spec.connections(i,j).label = sprintf('%s-%s',popID{i},popID{j});
    if ~all(cellfun(@isempty,fanout(:)))
      spec.connections(i,j).fanout = fanout{i,j}; 
    end
    if ~all(cellfun(@isempty,connType(:)))
      try spec.connections(i,j).mechanisms = parsecell(connType{i,j});
      catch spec.connections(i,j).mechanisms = connType{i,j}; end
    else
      spec.connections(i,j).mechanisms = {};
    end
    if ~all(cellfun(@isempty,SynParm(:)))
      try spec.connections(i,j).parameters = parsecell(SynParm{i,j});
      catch spec.connections(i,j).parameters = SynParm{i,j}; end
    else
      spec.connections(i,j).parameters = {};
    end
  end
end
% if all(cellfun(@isempty,{spec.connections.mechanisms}))
%   spec.connections = [];
% end
  % NOTE: spec.connections must be defined empty for buildmodel() to work
  
function val = correct_loadjson_arrstr(this)
if size(this,1)>1 && ndims(this)==2
  val = cellfun(@(i)this(i,:),num2cell(1:size(this,1)),'uniformoutput',false);
elseif length(unique(this))==1
  val = repmat({this(1)},[1 numel(this)]);
elseif ~iscell(this)
  val = {this};
else
  val = this;
end
