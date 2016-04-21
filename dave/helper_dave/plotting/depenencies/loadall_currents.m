

function [T, lfps2, dat2, lab2] = loadall_currents(data,spec,varlabels)
    % Returns lfps2 and dat2 containing all currents (requested by
    % varlabels) for all compartments and all multiplicities. Format is
    %   dat2  - data x compartments x multiplicity x varlabels
    %   lfps2 - data x compartments x varlabels
    % Lfps2 is just dat2 averaged across all multiplicities.


    % Params
    N = length(varlabels);
    
    % Load the 1st compartment and define variable size
    i=1;
    [fig, lfps, T, dat, lab2{1}] = plotv_dav(data,spec,'varlabel',varlabels{i},'plot_flag',0,'visible_flag',0);
    sz = size(dat);
    dat2 = zeros([sz, N]);
    dat2(:,:,:,1) = dat;
    
    sz = size(lfps);
    lfps2 = zeros([sz, N]);
    lfps2(:,:,1) = lfps;
    
    % Load the remaining compartments
    for i = 2:length(varlabels)
        [fig, lfps, T, dat, lab2{i}] = plotv_dav(data,spec,'varlabel',varlabels{i},'plot_flag',0,'visible_flag',0);
        lfps2(:,:,i) = lfps;
        dat2(:,:,:,i) = dat;
    end
    
    
end