function [frates, tmins, ordered_elec] = frate(dn, params)
% [frates, tmins, ordered_elec] = frate(dn, params)
%
% frate.m
% By Grant Fiddyment, Boston University, May 2012
%
% Computes the firing rate of a point process dn (specified in binary
% increments) over given windows.
% Returns the firing rate (frates) over time (tmins) as well as a sorted
% list of cells/trials/etc over which the firing rate is greatest.
%
%
% params has fields:
% doPlot -- boolean indicating whether to plot firing rate/ISIs
% tmin -- beginning time of point process dn
% tmax -- end time of point process dn
% dt -- temporal resolution (typically ~2-6 ms)
% window_size -- window over which to compute firing rate (in sec)
% dW -- step size between windows (in sec)
% outputFigure -- figure on which to plot parameters
%
% plotType -- specifies which plot to show:
% (NOTE: options with a * assume dn to be a matrix whose rows are
% simultaneous point processes, perhaps representing the
% activity of many individual cells)
%
% (empty) = plot windowed firing rate (if dn is a
% single spike train)
% * 'psth' = sums activity over all cells
% * 'heat' = plots all cells' individual spike rates in color
% * 'isi' = plot distribution of ISIs over time
% * 'mean' = average firing rate across cells
% * 'cortical' = displays individual firing rate activity
% on an anatomical map (in this case an ECoG
% montage)
%
%
%
%
%
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%[tmin,tmax,dt,fitType,doPlot,doSave] = getparams(params);
tmin=params.tmin;
tmax=params.tmax;
dt=params.dt;
doPlot=params.doPlot;
fitType='discrete';

if isfield(params, 'window_size') && ~isempty(params.window_size)
  window_size = params.window_size;
else
  window_size = 1;
end
if isfield(params, 'dW') && ~isempty(params.dW)
  dW = params.dW;
else
  dW = floor(0.5/dt);
end
if isfield(params, 'plotType') && ~isempty(params.plotType)
  plotType = params.plotType;
elseif size(dn,1)==1
  plotType = [];
else
  plotType = 'heat'; % 'heat' (for all cells) or 'mean' (for avg)
end
if isfield(params, 'outputFigure') && ~isempty(params.outputFigure)
  outputFigure = params.outputFigure;
elseif doPlot
  outputFigure = figure('units','normalized','outerposition',[0 0 1 1]);
end
if isfield(params, 'orderByRate') && ~isempty(orderByRate)
  orderByRate = params.orderByRate;
else
  orderByRate = false;
end
if isfield(params, 'plot_color') && ~isempty(params.plot_color)
  plot_color = params.plot_color;
else
  plot_color = 'b';
end
if isfield(params, 'max_lag') && ~isempty(params.max_lag)
  max_lag=params.max_lag;
else
  max_lag=100;
end
N_cells = size(dn, 1);
t_axis = tmin+dt:dt:tmax;
T = length(t_axis);
bin_size=dt*1e3;
tmins = tmin:dW:tmax-window_size;
tmaxs = tmins+window_size;
window_bins = ceil(window_size/dt);
t_ind=round(1:dW/dt:T-window_bins+1);
N_windows = length(tmins);
t_axis0=sort([tmins, tmaxs]);
if ~isequal(plotType,'isi')
  frates = zeros(N_cells,N_windows);
  for t = 1:N_windows
    frates(:, t) = sum(dn(:, t_ind(t):t_ind(t)+window_bins-1)')'/window_size;
  end
else
  ISI_axis = [.5:.015:3];%[bin_size:bin_size:max_lag+bin_size];
  ISIs=zeros(length(ISI_axis)-1,N_windows);
  for t = 1:N_windows
    temp=[];
    for c=1:size(dn,1)
      temp=[temp diff(find(dn(c,t_ind(t):t_ind(t)+window_bins-1)))*bin_size];
    end
    [a,b] = hist(temp, ISI_axis);
    ISIs(:,t)=a(1:end-1)/length(temp);
  end
  frates=ISIs;
end
if N_cells==1
  ordered_elec=1;
else
  [~,ordered_elec] = sort(mean(dn'));
end
resort_ind=sort([1:N_windows, 1:N_windows]);
frates0=frates(resort_ind);
if doPlot
  figure(outputFigure)
  if N_cells==1
    ordered_elec=[];
    if doPlot
      if isequal(plotType,'isi')
        imagesc(tmins,ISI_axis,frates);
        ylabel('ISI [ms]');
        title('distribution of ISIs');
      else
        plot(t_axis0, frates0, plot_color, 'LineWidth', 3); hold on
        M=1.3*max(frates);
        ylim([0,1.3*M]);
        xlim([tmin,tmax]);
        spikes=t_axis(find(dn));
        for n=1:length(spikes)
          text(double(spikes(n)),M,'|','color',plot_color);
        end
        ylabel('firing rate [Hz]');
      end
      xlabel('time [s]');
    end
  else
    [~,ordered_elec] = sort(mean(dn'));
    switch plotType
      case 'psth'
        plot(t_axis, sum(dn)/N_cells, 'LineWidth', 3);
        xlabel('time [s]');
        ylabel('% electrodes active');
        ylim([0, 1]);
        xlim([tmin,tmax]);
      case 'heat'
        if orderByRate
          my_cells = ordered_elec;
        else
          my_cells = 1:N_cells;
        end
        imagesc(tmins, 1:N_cells, frates(my_cells, :));
        xlabel('time [s]');
        ylabel('electrode');
        title('firing rates');
      case 'mean'
        if isequal(plotType, 'mean')
          t_axis0=sort([tmins, tmaxs]);
          frates=mean(frates);
          resort_ind=sort([1:N_windows, 1:N_windows]);
          frates0=frates(resort_ind);
        end
        plot(t_axis0, frates0, 'LineWidth', 3);
        xlabel('time [s]');
        ylabel('firing rate [Hz]');
        title(['mean firing rate - ', num2str(N_cells), ' electrodes']);
        xlim([tmin,tmax]);
      case 'cortical'
        tmins = t_axis(1:N_windows);
        tmaxs = t_axis(window_bins+1:end);
        coupling=frates;
        mn_c = 0;
        mx_c = 50;
        draw_networks;
      case 'isi'
        imagesc(tmins,ISI_axis,ISIs);
        xlabel('time [s]');
        ylabel('ISI [ms]');
        title('ISI distribution over time');
    end
  end
end
end
