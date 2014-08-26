function actogram(t,x,th,per,days,rep)

%%% Plot time series as actogram
%%%
%%% Didier Gonze
%%% Created: 21/10/2010
%%% Updated: 10/1/2011
%%%
%%% t = time vector (length = T)
%%% x = time series (length = T)
%%% th = threshold on variable to define "activity" (e.g. mean(x))
%%% per = period (typically 24h)
%%% days = number of days (usually around 20)
%%% rep = number of repetited days (typically: 2)

clf;

%%% Draw dotted horizontal lines

for i=1:days
   h=i;
   plot([0 per*rep],[h h],'k--') 
   hold on;
   xp=-(rep*per)/20;
   text(xp,h,sprintf('%g',days-i+1),'fontsize',12)   % numbering of the lines (i.e. days)
end


%%% Plot data

for td=0:days-1
        
    t1=td*per;
    t2=t1+(rep*per);

    k=find(t>t1 & t<t2);

    y=x(k);
    
    k=find(y>th);

    ta=t(k);

    h=days-td;

    plot(ta,h*ones(1,length(k)),'k.')
    hold on;
    
end


%%% Axis limits and labels

xlim([0 per*rep])
ylim([0.01 days+0.99])

set(gca,'YTickLabel',{''})

xlabel('Time','fontsize',18);
ylabel('Days','fontsize',18);

ylabh = get(gca,'yLabel'); 
set(ylabh,'Position',get(ylabh,'Position') - [2.5 0 0]);  % shift y-label to left 












