function [results,parms] = CharacterizeCells(file,type,funlist,parms,plot_flag)
% Purpose: extract feature set from a single file
%   if experimental file: return one feature set for the one cell it contains
%   if simulation file: return one feature set for each cell in the population

funnames = {'CharHyperpolStepTA','CharDepolStepTA','CharDepolTonicSpikesTA'};
if nargin<5, plot_flag=0; end

%features = {};
%feature_labels = {};
results = {};

if nargin<4, parms = []; end
if nargin<3, funlist = funnames; end
if nargin<2
  % determine if experimental or simulated data file
  type = 'experimental';
  if ~isempty(regexp(file,'.mat$')) && ismember('sim_data',who('-file',datafile))
    type = 'simulated';
  end
end

var='V'; 
SimMech='iStepProtocol';
if ~any(which(funnames{1}))
  addpath(genpath('/project/crc-nak/sherfey/code/research/external/tallie'));
end
tictime = tic;
switch type
  case {'experimental','exp','experiment'}
    % load exp data
    data = load(file);
    t = data.t;
    intra = data.e1;
    field = data.e2;
    selfun = ismember(funnames,funlist);%1:length(funnames);
    if isstruct(parms)
      parms = getCharParms(parms,'exp');
    elseif isempty(parms)
      parms = getCharParms(file,'exp');
    end
    results = characterize(parms,funnames(selfun));
    %[features,feature_labels] = extractfeatures(results);
    
  case {'simulated','sim','simulation'}
    % load sim data
    if ischar(file) && exist(file,'file')
      load(file,'sim_data','spec');
    elseif isstruct(file) && isfield(file,'spec') && isfield(file,'sim_data')
      sim_data=file.sim_data;
      spec=file.spec;
    end
    cellnames={spec.entities.label};
    nmax=max([spec.entities.multiplicity]);
    npop=length(cellnames);
    results = cell(nmax,length(funnames),npop);
    %features = cell(nmax,npop);
    prestep_time_offset = -.01; % shift sections and artifacts so onset artifact can be detected by tallie's cell characterization scripts
    sz=200/1000; % artifact size, [V]
    % loop over populations and cells
    for thispop = 1:npop
      % select info for this population
      cellname = cellnames{thispop}; %'E'; 
      datavar = [cellname '_' var]; % 'E_V';
      cellind = find(strcmp(cellname,{spec.entities.label}));
      dataind = find(strcmp(datavar,{sim_data(cellind).sensor_info.label}));
      ind = strcmp(SimMech,spec.entities(cellind).mechanisms);
      p = spec.entities(cellind).mechs(ind).params;   
      t = sim_data(cellind).epochs.time;
      dt = t(2)-t(1);
      fprintf('processing population %g of %g (n=%g) at %g min\n',thispop,npop,spec.entities(cellind).multiplicity,toc(tictime)/60);
      for thiscell = 1:spec.entities(cellind).multiplicity
        % select data for this cell
        intra = double(sim_data(cellind).epochs.data(dataind,:,thiscell)/1000);
        field = double(mean(sim_data(cellind).epochs.data(dataind,:,:),3)/1000);
        % get parameters for cell characterization
        parms = getCharParms(spec,'sim','cellind',cellind,'mechanism',SimMech,'prestep_time_offset',prestep_time_offset,'time',t);
        intra = artifact(intra,parms);
        result = characterize(parms,funnames);
        %[features{thiscell,thispop},feature_labels] = extractfeatures(result,p,1/dt);
        results(thiscell,:,thispop) = result;
      end
    end
end

% nested functions
function intra = artifact(intra,parms)
  % add artifact to hyperpolarization and depolarization steps
  for f=1:2
    % make hyperpol artifacts up=>down; depol down=>up
    tstart=parms.(funnames{f}).sections_start_sec - prestep_time_offset;
    tinf=tstart+((0:p.nsteps*p.nsections-1)*p.isi)/1000;
    tind=round(tinf/dt);
    intra(tind)=sz*((-1)^(f-1)); % onset artifact
    tinf=tinf+p.steptime/1000;
    tind=round(tinf/dt);
    intra(tind)=-sz*((-1)^(f-1)); % offset artifact
    %figure('position',[25 420 1550 250]); plot(t,intra);
  end
end
function result = characterize(parms,funlist)
  % characterize cells
  rmfields={'y_orig','yIC','yF','Time'};
  result = cell(1,length(funnames));
  dataargs = {{t,intra},{t,intra},{t,field,intra}};
  for f=1:length(funnames)
    if ismember(funnames{f},funlist)
      if isfield(parms,funnames{f})
        args = struct2cell(parms.(funnames{f}));
        args = {dataargs{f}{:},args{:}};
        result{f} = feval(funnames{f},args{:},plot_flag);
        result{f}.function = funnames{f};
        for rmf=1:length(rmfields)
          if isfield(result{f},rmfields{rmf})
            result{f} = rmfield(result{f},rmfields{rmf});
          end
        end
      end
    end
  end % end loop over cell characterization functions
end

end

