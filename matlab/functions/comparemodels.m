function cost = comparemodels(expfeatures, simfeatures)%, searchspace)
% [expfeatures] = 1 x cells
% [simfeatures] = repetitions x models

% get feature means/medians and standard deviations from expfeatures
features = cellfun(@(x)x.features,expfeatures,'uni',0);
features_mat = cat(1,features{:});
expt_mu = nanmean(features_mat,1);
expt_sd = nanstd(features_mat,0,1);
%expt_mu = cellfun(@median,expfeatures,'uni',0);
%expt_sd = cellfun(@std,expfeatures,'uni',0);

feature_weights = ones(size(features{1}));
cost_weights = [1 1];

% compute experimentally-normalized simulated feature z-scores (for each simulation; i.e., N per model/simfile)
features = cellfun(@(x)x.features,simfeatures(~cellfun(@isempty,simfeatures)),'uni',0);
features = cat(1,features{:});
mu = repmat(expt_mu,[size(features,1) 1]);
sd = repmat(expt_sd,[size(features,1) 1]);
zfeatures = (features - mu)./sd;
%simfeatures = cellfun(@(x,y,z)(x-y)/z,features,expt_mu,expt_sd,'uni',0);

keyboard

% compute mean simulated feature z-scores (one per model <=> one per point in searchspace)
zmu = mean(cell2mat(zfeatures),1);
for k=1:length(zmu)
  MSWFZ(k) = mean((zmu(k).*feature_weights).^2);
end
% determine # params for each model
nparams = 1;
% compute model cost = f(feature z-scores, # params)
a = cost_weights(1);
b = cost_weights(2);
cost = a*MSWFZ - b*(nparams);

% % calculate z-scores on simulated feature vectors
% zfeatures = (features - expt_mu) ./ expt_sd;
% % calculate mean square feature z-scores (MSFZ)
% MSFZ = mean(zfeatures.^2);
% MSWFZ = mean((zfeatures.*feature_weights).^2); % weighted version
