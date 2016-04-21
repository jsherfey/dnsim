

function save_allfigs(currfname,currfigname)
    %% save_allfigs
    % % For loop for saving figs
%     if ~exist('currfname'); currfname = 'kramer_IB'; end
%     if ~exist('currfigname'); currfigname = '3_single_comp_only_Mcurr'; end
    currfname = 'kramer_IB'; 
    currfigname = '9b-CaH_and_iM_Michelles_lower_gleak'; 
    savenames={'fig1','fig2','fig3','fig4','fig5','fig6','fig7','fig8','fig9','fig10','fig11','fig12','fig13','fig14','fig15','fig16','fig17','fig18','fig19','fig20','fig21','fig22','fig23','fig24'};
    mydate = datestr(datenum(date),'yy/mm/dd'); mydate = strrep(mydate,'/','');
    c=clock;
    sp = ['d' mydate '_t' num2str(c(4),'%10.2d') '' num2str(c(5),'%10.2d') '' num2str(round(c(6)),'%10.2d')];
    sp = [sp '__' currfname '_' currfigname];
    basepath = '.';
    % basepath = '~/figs_tosave';
    mkdir(fullfile(basepath,sp));
    for i=[1,3]
        figure(i); %ylim([0 0.175])
        title('');
        ylabel('');
        %xlim([-1.5 2.2]);
        %ylabel('Avg z-score |\Delta FFC|')
        set(gcf,'PaperPositionMode','auto');
        %print(gcf,'-dpng','-r200',fullfile(basepath,sp,savenames{i}))
        print(gcf,'-dpng',fullfile(basepath,sp,savenames{i}))
        %close
    end
    
    mycomment = ['I think the reduced Gleak allows it to sit at a lower resting; slows iM recovery'];
    currd = pwd;
    cd ..
    system('git add *');
    system(['git commit -am "' currfigname ' ' mycomment '"']);
    cd(currd);


end