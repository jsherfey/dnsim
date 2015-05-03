function plot_search_space(datapath,plotvar,paramvaried,paramset,varargin)
% datapath='/home/jason/code/dnsim/database/private/Tallie-cells/old-characterization/Type2/20141021-195608/PYs-gcatbar/data';
% plotvar='v';
% paramvaried='gcatbar';
% plot_search_space(datapath,plotvar,paramvaried);

% batchdir='/home/jason/code/dnsim/database/private/Tallie-cells/old-characterization/Type2/20141021-195608/PYs-gcatbar';
% [allspecs,allspaces,allscopes,allvariables,uniq_allscopes,uniq_allvars, allfiles] = loadbatchmodels(batchdir)
% if ~ismember(paramvaried,uniq_allvars), return; end

cfg = mmil_args2parms( varargin, ...
                   {  'xlims',[],[],...
%                       'variable',[],[],...
%                       'parameter',[],[],...
%                       'values',[],[],...
                   }, false);

if nargin<4 || isempty(paramset) || isequal(paramset,'[]'), paramset=[]; end
if nargin<3 || isempty(paramvaried), paramvaried='stim'; end
if nargin<2 || isempty(plotvar), plotvar='V'; end
if nargin<1 || isempty(datapath), datapath=pwd; end
if ischar(cfg.xlims), cfg.xlims=str2double(cfg.xlims); end

if ~exist(datapath), disp('directory not found'); return; end
d=dir(datapath);
f={d(~[d.isdir]).name};
files={};
for i=1:length(f), files{i}=fullfile(datapath,f{i}); end

matches=regexp(f,[paramvaried '[\da-zA-Z(pt)-]+'],'match');
files=files(~cellfun(@isempty,matches));
files=files(cellfun(@exist,files)~=0);
if isempty(files), disp('no files found in directory'); return; end

% get parameter values from file names
paramvals=cell(1,length(files));
for i=1:length(files)
  tmp=matches{i};
  tmp=strrep(tmp,paramvaried,'');
  tmp=strrep(tmp,'pt','.');
  for j=1:length(tmp)
    if any(regexp(tmp{j},'^-?[\d\.]+-?')) % any(regexp(tmp{j},'^-?[\d\.]+-'))
      tmp2=regexp(tmp{j},'^-?[\d\.]+','match');
      tmp2=tmp2{1};
      if iscell(tmp2), tmp2=tmp2{1}; end
      tmp{j}=tmp2;
    elseif any(regexp(tmp{j},'-[\d\.]+$'))
      tmp2=regexp(tmp{j},'[\d\.]+$','match');
      tmp2=tmp2{1};
      if iscell(tmp2), tmp2=tmp2{1}; end
      tmp{j}=tmp2;
    end
  end
  try
    paramvals{i}=cellfun(@str2num,tmp); % parameter values assoicated with this file
  catch
    paramvals{i}=tmp;
  end
end
if isnumeric(paramvals{1})
  parms1 = cellfun(@(x)x(1),paramvals);
else
  parms1=cellfun(@(x)x(1),paramvals,'uni',0);
  parms1=[parms1{:}];
end
% limit values of varied param
if ~isempty(paramset)
  if isnumeric(paramset)
    if numel(paramset)==2
      sel = find(parms1>=paramset(1)&parms1<=paramset(2));
    else
      sel = find(ismember(parms1,paramset));
    end
  elseif ischar(paramset) || iscellstr(paramset)
    if ischar(paramset)
      paramset=strread(paramset,'%s','delimiter',',');
    end
    sel = [];
    for i=1:length(parms1)
      matched = find(~cellfun(@isempty,regexp(parms1{i},paramset)));
      if any(matched)
        sel(end+1) = i;
      end
    end
  end
  parms1=parms1(sel);
  %paramvals=paramvals(sel);
  files=files(sel);
end
% sort files/params by the first instance in each file name
[parms1,I] = sort(parms1);
%paramvals = paramvals(I);
files = files(I);
uniqparms1 = unique(parms1);
nparms = numel(uniqparms1);
file_index=cell(1,nparms);
for i=1:nparms
  file_index{i}=find(ismember(parms1,uniqparms1(i)));
end

% get sim info from first file
load(files{file_index{1}(1)},'sim_data','spec');
npop=length(sim_data);
plotpops=[];
for i=1:npop
  varind=find(~cellfun(@isempty,regexp({sim_data(i).sensor_info.label},sprintf('(_%s)|(%s)',plotvar,plotvar))),1,'first');
  if ~isempty(varind)
    plotpops=[plotpops i]; % sim_data indices of nodes with vars to plot
  end
end
nfigs=numel(plotpops); % # of nodes with vars to plot
for i=1:nfigs
  hfigs(i)=figure('visible','off');
end

nrows = nparms;
ncols = max(cellfun(@length,file_index));
cnt = 0;

% figure
for i=1:nrows
  for j=1:ncols
    cnt = cnt + 1;
    if j>length(file_index{i})
      continue;
    end
    file = files{file_index{i}(j)};
    if cnt>1
      load(file,'sim_data','spec');
    end
    if npop~=length(sim_data)
      fprintf('skipping b/c different number of populations than first file\n');
      continue;
    end
    for k=1:nfigs%npop
      figure(hfigs(k));
      data=sim_data(plotpops(k));
      vars={data.sensor_info.label};
      varind=find(~cellfun(@isempty,regexp(vars,sprintf('(_%s)|(%s)',plotvar,plotvar))),1,'first');
      t=data.epochs.time;
      if ~isempty(cfg.xlims),
        sel=t>=cfg.xlims(1)&t<=cfg.xlims(2);
      else
        sel=ones(size(t))==1;
      end
      dat=squeeze(data.epochs.data(varind,sel,:));
      subplot(nrows,ncols,cnt); plot(t,dat(sel)); axis tight
      if ~isempty(cfg.xlims), xlim(cfg.xlims); end
      xlabel('time'); ylabel(strrep(data.sensor_info(varind).label,'_','\_'));
      if isnumeric(uniqparms1(i))
        title(strrep(sprintf('%s=%g',paramvaried,uniqparms1(i)),'_','\_'));
      elseif iscell(uniqparms1(i)) && ischar(uniqparms1{i})
        title(strrep(sprintf('%s: %s',paramvaried,uniqparms1{i}),'_','\_'));
      end
    end
    %fprintf('row %g, col %g: %s\n',i,j,file);
  end
end

% set(hfigs,'visible','on')

%%
% get files with parameter in filename
% use regexp to get parameter value from filename
% group files by parameter value

% ncols = # files at each parameter value
% nrows = # parameter values

% loop nrows,ncols
    % load file sim_data
    % extract plotvar
    % plot traces
        % - one figure for each cell type
        % - overlay multiple cells of each type

