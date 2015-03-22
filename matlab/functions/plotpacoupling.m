function [fig]=plotpacoupling(data,spec,varargin)
% This function takes a DNSIM timesurfer-style 'sim_data' data object to
%   1. filter each voltage trace across presumably a 'slower' and
%      'faster' frequency band, and then
%   2. use a sliding window to calculate both
%     a. the distribution of the faster's analytic signal amplitude across
%        a single window's worth of the slower's analytic signal phase (a
%        window-long phase comodulogram)
%     b. the (Tort et al PNAS 2008) Modulation Index of that window
% Thus, this returns a figure that plots each celltype's
%   1. faster-filtered, normalized signal and slower analytic phase time
%      series and
%   2. the aforementioned phase comodulograms across time.
%
% Basic function call:
% [fig]=plotpacoupling(sim_data,...
%                      spec,...
%                      'plot_flag',parms.plotpacoupling_flag,...
%                      'slow_freq_range',slow_freq_range,...
%                      'fast_freq_range',fast_freq_range,...
%                      'window_length',window_length,...
%                      'window_overlap',window_overlap,...
%                      'number_bins',number_bins);
%
% REQUIRED INPUTS:
%  sim_data        - <struct> - the DNSIM-timesurfer-style data object
%  spec            - <struct> - I guess the model specification? what 'spec' is in 'biosimdriver'
%  plot_flag       - <integer> - whether or not to plot the results.
%  slow_freq_range - <1x2 vector of float> - The frequency range to ideal-filter the signal's slower component at, in Hertz.
%      - No, really! These are converted using Nyquist for you. Everyone else seems to lie about taking their args in Hz, especially MATLAB.
%  fast_freq_range - <1x2 vector of float> - The frequency range to ideal-filter the signal's faster component at, in Hertz.
%  window_length   - <float> - The length of the window to measure the coupling, in seconds. Note that you want to make this at least as long as a full cycle time of your slower signal.
%  window_overlap  - <float> - How long the windows should overlap, in seconds.
%  number_bins     - <integer> - How many bins to separate the slower signal's phase into. From Tort's code: We are breaking 0-360 degrees in 18 bins, i.e. each bin has 20 degrees
%
% OPTIONAL INPUTS:
%  none, right now
%
% Author: Austin Soplata, March 2015, although this is adapted/frankensteined
% from 'dnsim/matlab/functions/plotpow.m', and files by Angela Onslow and
% Adriano Tort (see below).

parms = mmil_args2parms( varargin, ...
                   {  'plot_flag',0,[],...
                      'slow_freq_range',[0 1.5],[],...
                      'fast_freq_range',[8 13],[],...
                      'window_length',2.0,[],...
                      'window_overlap',1.0,[],...
                      'number_bins',18,[],...
                      'varlabel','V',[],...
                   }, false);

if ~isfield(spec,'entities') && isfield(spec,'cells')
  spec.entities=spec.cells;
elseif ~isfield(spec,'entities') && isfield(spec,'nodes')
  spec.entities=spec.nodes;
end

npop = length(spec.entities);
Fs = fix(data(1).sfreq);

for pop=1:npop
  labels = {data(pop).sensor_info.label};
  var = find(~cellfun(@isempty,regexp(labels,['_' parms.varlabel '$'])),1,'first');
  if spec.entities(pop).multiplicity <= data(pop).epochs.num_trials
    n = spec.entities(pop).multiplicity;
  else
    n = data(pop).epochs.num_trials;
  end
  t = data(pop).epochs.time;
  dat = double(squeeze(data(pop).epochs.data(var,:,1:n))');
  if size(dat,2)>1
    lfp = mean(dat,1)';
  else
    lfp = dat;
  end
  try
    %% Filter the data
    % Note that `slow/fast_data` are thus TIMESERIES objects, not regular arrays.
    slow_data = idealfilter(timeseries(dat), [parms.slow_freq_range(1)/(Fs/2.0), parms.slow_freq_range(2)/(Fs/2.0)], 'pass');
    fast_data = idealfilter(timeseries(dat), [parms.fast_freq_range(1)/(Fs/2.0), parms.fast_freq_range(2)/(Fs/2.0)], 'pass');

    % HERE is probably where you'd want to use any of the available PAC
    % libraries, like the Eden/Kramer GLMCFC, since the signal has been
    % filtered, but not transformed into the analytic signal, and not windowed
    % yet (to get a phase-amplitude coupling "time-series" so to speak).

    %% Get angle and amplitude from the respective signals via Hilbert Transform
    % Kramer's GLMCFC code is espcially concise/informative. Note the '.Data'
    phi = angle(hilbert(slow_data.Data));
    amp = abs(hilbert(fast_data.Data));

    %% Construct windows across the time series
    %    Adapted & taken from Angela Onslow's 'pac_code_best/window_data.m' of
    %    her MATLAB Toolbox for Estimating Phase-Amplitude Coupling from
    %
    %    http://www.cs.bris.ac.uk/Research/MachineLearning/pac/
    %
    % Compute indices
    number_amp = size(amp,1);
    number_trials = size(amp,2);
    number_windows = ceil(parms.window_length*Fs);
    number_overlaps = ceil(parms.window_overlap*Fs);
    idx = bsxfun(@plus, (1:number_windows)', 1+(0:(fix((number_amp-number_overlaps)/(number_windows-number_overlaps))-1))*(number_windows-number_overlaps))-1;

    % Initialize the main data objects
    modulation_index_timeseries = [];
    modulogram_matrix = [];
    %% Loop over sliding windows
    for k=1:size(idx,2)
        amp_window = [];
        phi_window = [];
        % Loop over trials
        for j = 1:number_trials
            amp_window = [amp_window, amp(idx(:,k),j)];
            phi_window = [phi_window, phi(idx(:,k),j)];
        end

        %% Bin the faster frequency's amplitude in the slower's phase bins
        %    Adapted & taken from Adriano Tort's
        %    'Neurodynamics-master/16ch/Comodulation/ModIndex_v1.m' of the
        %    'Neurodynamics-Toolbox' repo on Github, at
        %
        %    https://github.com/cineguerrilha/Neurodynamics
        %
        phi_bin_beginnings = zeros(1,parms.number_bins); % this variable will get the beginning (not the center) of each bin (in rads)
        bin_size = 2*pi/parms.number_bins;
        for j=1:parms.number_bins
            phi_bin_beginnings(j) = -pi+(j-1)*bin_size;
        end

        % Now we compute the mean amplitude in each phase:
        amp_means = zeros(1,parms.number_bins);
        for j=1:parms.number_bins
            phi_indices = find((phi_window >= phi_bin_beginnings(j)) & (phi_window < phi_bin_beginnings(j)+bin_size));
            amp_means(j) = mean(amp_window(phi_indices));
        end
        modulogram_matrix = [modulogram_matrix, (amp_means/sum(amp_means))'];

        % Quantify the amount of amp modulation by means of a normalized entropy index (Tort et al PNAS 2008):
        modulation_index=(log(parms.number_bins)-(-sum((amp_means/sum(amp_means)).*log((amp_means/sum(amp_means))))))/log(parms.number_bins);
        modulation_index_timeseries = [modulation_index_timeseries, modulation_index];

        % % Debug, for mid-function plotting:
        % % So note that the center of each bin (for plotting purposes) is phi_bin_beginnings+bin_size/2
        % % at this point you might want to plot the result to see if there's any amplitude modulation
        % figure(10)
        % bar(10:10:360,(amp_means/sum(amp_means)),'k')
        % xlim([0 360])
        % set(gca,'xtick',0:180:360)
        % xlabel('Phase (Deg)')
        % ylabel('Amplitude')
    end
  catch
    fprintf('\n!\n!\n!\n whoa somethings wrong, debug\n!\n!\n!')
  end
end

% Fill screen with subplots:
nrows = npop;
ncols = 2;
nplots = nrows*ncols;

dx = 1 / ncols;
dy = 1 / nrows;
xstep = mod((1:ncols)-1,ncols);
ystep = mod((1:nrows)-1,nrows)+1;
xpos = .02+xstep*dx;
ypos = .02+1-ystep*dy;

fig=[];
if parms.plot_flag
  screensize = get(0,'screensize');
  fig = figure('position',screensize);
  set(gca,'Units','normalized','Position',[0 0 1 1]);
  for i = 1:nplots
    xi = mod(i-1,ncols)+1;
    yi = floor((i-1)./ncols)+1;
    subplot('Position',[xpos(xi) ypos(yi) .9/ncols .9/nrows]);
    set(gca,'units','normalized');
    pop = ceil(i/ncols); % index to this population
    labels = {data(pop).sensor_info.label};
    var = find(~cellfun(@isempty,regexp(labels,['_' parms.varlabel '$'])),1,'first');
    lab = data(pop).sensor_info(var).label;
    if mod(i,ncols)==1

      % plot normalized, filtered slow and fast signals
      normalized_phi = (phi - min(phi)) / (max(phi) - min(phi));
      plot(slow_data.Time, normalized_phi, 'b')

      hold on
      normalized_fast = (fast_data.Data - min(fast_data.Data)) / (max(fast_data.Data) - min(fast_data.Data));
      plot(fast_data.Time, normalized_fast, 'r')

      % normalized_slow = (slow_data.Data - min(slow_data.Data)) / (max(slow_data.Data) - min(slow_data.Data));
      % plot(slow_data.Time, normalized_slow, 'g')

      hold off

      if pop==npop
        xlabel('Time in seconds?');
      else
        set(gca,'xtick',[],'xticklabel',[]);
      end

   elseif parms.plot_flag
     imagesc([parms.window_length:parms.window_length:(parms.window_length*number_windows)], ...
             (phi_bin_beginnings+bin_size/2), ...
             modulogram_matrix);
     axis xy;
     axis tight;

     colorbar;
     ylabel('Phase of slow frequency component')
     title([strrep(lab,'_','\_') ' Phase comodulogram over time '],'fontsize',14,'fontweight','bold');
      if pop==npop
        xlabel('time [seconds]')
      else
        set(gca,'xtick',[],'xticklabel',[]);
      end
    end
  end
end
