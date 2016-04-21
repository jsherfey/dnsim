

function [h,lfps2,dat2] = plot_currents(data,spec,varlabels,varargin)
    h = [];
    screensize = get(0,'screensize');
    scy = screensize(end);
    default_fontsize = 14;
    
    % Import options
    parms = mmil_args2parms( varargin, ...
                   {  'plotmode',2,[],...           % One of several different types of plots
                      'comp2plot',1,[],...          % Node number to plot if length(data) > 1
                      'visible_flag',1,[],...
                      'scale_ylim_flag',1,[],...
                   }, false);
               
   comp2plot = parms.comp2plot;            
   plotmode = parms.plotmode;
   scale_ylim_flag = parms.scale_ylim_flag;
    
    % Load all currents
    [T, lfps2, dat2, lab2] = loadall_currents(data,spec,varlabels);
    
    
    % Plot compartments and multiplicities
    sz = size(dat2);
    Ncompartments = sz(2);
    Nmultiplicity = sz(3);
    Nlabels = length(varlabels);
    
    
    
    
    
    switch plotmode
        case {1,2}
            % Position figure
            position_figure(parms.visible_flag,Nlabels);
            
            
            % Get axis dimensions
            ind = strcmp(varlabels,'V');    % Exclude any voltage traces from y-axis max/min calculation
            temp = dat2(:,comp2plot,:,~ind);
            [ymin, ymax] = calc_ylims(temp(:));
            
            for i = 1:Nlabels
                if plotmode == 1; subplot(Nlabels,1,i); 
                elseif plotmode == 2; subplot(Nlabels,2,i*2);
                end
                
                h = plot(T,squeeze(dat2(:,comp2plot,:,i)));
                hold on; plot(T,squeeze(lfps2(:,comp2plot,i)),'k','LineWidth',2);
                lab = lab2{i}{comp2plot};
                if ~isempty(lab)
                    text(min(xlim)+.2*diff(xlim),ymin+.8*(ymax-ymin),strrep(lab,'_','\_'),'fontsize',default_fontsize*1200/scy,'fontweight','bold');
                    ylabel(strrep(lab,'_','\_'),'fontsize',default_fontsize*1200/scy,'fontweight','bold');
                end
                
                if i ~= find(ind) && scale_ylim_flag; ylim([ymin, ymax]); end
                if i == 1
                    title(['Compartment: ' spec.nodes(comp2plot).label],'fontsize',default_fontsize*1200/scy,'fontweight','bold');
                end
                set(gca,'FontSize',default_fontsize*1200/scy);        % Set font size
                
                if plotmode == 2
                    subplot(Nlabels,2,i*2-1);
                    h2 = imagesc(squeeze(dat2(:,comp2plot,:,i))'); axis xy; colormap(1-gray); colorbar
                    if i ~= find(ind) && scale_ylim_flag; caxis([ymin, ymax]); end
                    set(gca,'FontSize',default_fontsize*1200/scy);        % Set font size
                end
                
            end

    end
    
    
    %(data,spec,'varlabel','V','plot_flag',0,'visible_flag',0);
    
end

function position_figure(visible,nrows)
  screensize = get(0,'screensize');
  if visible == 0
    fig=figure('position',screensize.*[1 1 .8 min(.3*nrows,.9)],'visible','off');
  else
    fig=figure('position',screensize.*[1 1 .8 min(.3*nrows,.9)],'visible','on');
  end
end

function [ymin2, ymax2] = calc_ylims(temp)
    scale = 1.2;
    ymax = max(temp(:)); ymin = min(temp(:));
    ymu = mean([ymin,ymax]);
    ydiff = abs(ymax-ymin)/2;
    ymin2 = ymu-ydiff*scale;
    ymax2 = ymu+ydiff*scale;
    
    if ydiff < 1e-20
        ymin2 = 0; ymax2 = 1;
    end
    
end