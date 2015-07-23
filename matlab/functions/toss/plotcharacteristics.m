function fig=plotcharacteristics(results,spec)

maxshow=7; % max # single cells to plot
ylims=[-150 100];
fig=[];

for pop=1:length(results)

  result=results{pop};
  [ncell,nfunc]=size(result);
  ncell=min(ncell,maxshow);
  EL=spec.entities(pop).label;

  fig(end+1) = figure;
  for i=1:ncell
    for j=1:nfunc
      res=result{i,j};
      Fs=res.Fs;
      subplot(nfunc,ncell,i+(j-1)*ncell);
      switch res.function
        case 'CharHyperpolStepTA'
          x=res.step_sections;
  %         [nsamp,nsect]=size(x);
  %         plot(t,x); xlabel('time [s]'); ylabel('V'); title(sprintf('%s[%g]',EL,i));
  %         legend(cellfun(@(x) num2str(x),(num2cell(1:nsect)),'Uni',0));
        case 'CharDepolStepTA'
          x=res.y_Spiking_sect;
          if ~isempty(x), x=squeeze(mean(x,2)); end
  %           [nsamp,nsect]=size(x);
  %           plot(t,x); xlabel('time [s]'); ylabel('V'); title(sprintf('%s[%g]',EL,i));
  %           legend(cellfun(@(x) num2str(x),(num2cell(1:nsect)),'Uni',0));
        case 'CharDepolTonicSpikesTA'
          x=[];
      end
      if ~isempty(x)
        [nsamp,nsect]=size(x);
        t=(1:nsamp)/Fs;
        plot(t,x); xlabel('time [s]'); ylabel('V'); title(sprintf('%s[%g]',EL,i));
        legend(cellfun(@(x) num2str(x),(num2cell(1:nsect)),'Uni',0));    
        ylim(ylims);
      else
        axis off
      end
    end
  end

end

%% CharHyperpolStepTA
%   cmap2 = flipud(cmap2); cmap2(1:3,:) = []; cmap2 = num2cell(cmap2,2);
%   figure, hold on, cellfun(@(x,y) plot(1/Fs:1/Fs:length(x)/Fs,x,'Color',y),y_mean,cmap2','Uni',0);
%   legend(cellfun(@(x) num2str(x),(num2cell(sections_label_num)),'Uni',0))
%   gx = get(gca,'XLim'); gy = get(gca,'YLim');
%   GX = gx(1)+(range(gx)/20); GY = gy(1)+(range(gy)/20);
%   if isnan(offset_voltage), text(GX,GY,'(offset voltage unknown)'), end
%   for k = 1:length(IhSta1)
%       scatter([bl(1)/Fs bl(end)/Fs IhSta1{k}/Fs IhSta2{k}/Fs StepFin1{k}/Fs StepFin2{k}/Fs IhSta12{k}/Fs IhSta22{k}/Fs ],...
%           [O.Baseline_mV O.Baseline_mV O.Ih_Peak_mV{k} O.Ih_Peak_mV{k} O.Ih_End_mV{k} O.Ih_End_mV{k} O.Ih_Peak2_mV{k} O.Ih_Peak2_mV{k}],[],cmap,'filled');
%   end
%   axis tight, set(gca,'Box','on'), xlabel('Time (s)'), ylabel('Membrane Potential (mV)'), title('Plot to show accuracy in getting event points')
% end

%% CharDepolStepTA
% cmap = [0.7,0,0;0.7,0,0;0,0.7,0;0,0.7,0];
% if I<0
%     cmap2 = autumn(length(y_sections)+3);
% elseif I>0
%     cmap2 = winter(length(y_sections)+3);
% elseif I==0 || isnan(I)
%     cmap2 = bone(length(y_sections)+3);
% end
% if plot_flag
%   cmap2 = flipud(cmap2); cmap2(1:3,:) = []; cmap2 = num2cell(cmap2,2);
%   figure, hold on, cellfun(@(x,y) plot(1/Fs:1/Fs:length(x)/Fs,x,'Color',y),y_mean,cmap2','Uni',0);
%   cellfun(@(x,y) plot(1/Fs:1/Fs:length(x)/Fs,x(:,1),'-k'),y_mean2,'Uni',0);
%   legend(cellfun(@(x) num2str(x),(num2cell(sections_label_num)),'Uni',0))
%   gx = get(gca,'XLim'); gy = get(gca,'YLim');
%   GX = gx(1)+(range(gx)/20); GY = gy(1)+(range(gy)/20);
%   if isnan(offset_voltage), text(GX,GY,'(offset voltage unknown)'), end
%   for k = 1:length(O.VoltOff)
%       scatter([bl(1)/Fs bl(end)/Fs (mloc_off-200)/Fs (mloc_off-100)/Fs],...
%           [O.Baseline_mV O.Baseline_mV O.VoltOff{k} O.VoltOff{k}],[],cmap,'filled');
%       for k2 = 1:length(spike_rloc{k}), scatter((spike_rloc{k}{k2}+mloc_on)/Fs,spike_height{k}{k2},[],'*g'), end
%   end
%   axis tight, set(gca,'Box','on'), xlabel('Time (s)'), ylabel('Membrane Potential (mV)'), title('Plot to show accuracy in getting event points')
% end

%% CharDepolTonicSpikesTA

%     for k = 1:length(AngLoc)
%         if isnan(AngLoc{k})
%             [Ang_peak{k},~,Distrib_kurt{k},Peak_Density{k},DataE_st{k},DataE_en{k}] = deal(NaN);
%         else
%             [~,~,~,~,Ang_peak{k},~,Distrib_kurt{k},Peak_Density{k},DataE_st{k},DataE_en{k}] = HistFitTA2(25,0.5,AngLoc{k},PlotsYN);
%         end
%     end
%     if length(Ang_peak)>1 && strcmp('Y',PlotsYN), SpikeFieldCoh_RoseAll_TA(Ang_peak,DataE_st,DataE_en,rates,num_spikes), end
     
    