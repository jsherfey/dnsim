function [features,feature_labels,featuredata] = extractfeatures(result,p)
% purpose: obtain one feature vector for each cell in result
% input: [result] = neurons x functions. each element is a output struct
% from one of tallie's analysis functions.
% output: cell array of feature vectors (one per neuron).

%features = {};

hyper=1; depol=2; tonic=3; Fs=[];
o1 = result{hyper}; 
o2 = result{depol};
o3 = result{tonic};
if isempty(o1)
  hypflag=0; 
else
  hypflag=1; 
  amp1=o1.sections_label_num;
  nsect1=length(amp1);
  Fs = o1.Fs; 
end
if isempty(o2)
  depflag=0; 
else
  depflag=1; 
  amp2=o2.sections_label_num;
  nsect2=length(amp2);
  Fs = o2.Fs; 
end
if isempty(o3)
  tonflag=0; 
else
  tonflag=1; 
  Fs = o3.Fs; 
end
if isempty(Fs)
  fprintf('Warning: empty result structure passed to extractfeatures()\n');
  features=[]; feature_labels=[]; featuredata=[];
  return;
end 
steptime = 400;
if numel(p)==1 % this is simulated data
  amp = p.stepsize; amp1=amp; amp2=amp;
  nsect = p.nsections; nsect1=nsect; nsect2=nsect;
  steptime = p.steptime;
end
tpulse = 0:1/Fs:(steptime/1000);

% passive membrane properties (Rin, gleak, Vrest, Cm)
if ~hypflag || ~isnumeric(o1.Resistance_Mohms), Rin1=nan; else Rin1=mean(o1.Resistance_Mohms); end
if ~depflag || ~isnumeric(o2.Resistance_Mohms), Rin2=nan; else Rin2=mean(o2.Resistance_Mohms); end
if hypflag, Vrest1 = o1.Baseline_mV; else Vrest1=nan; end
if depflag, Vrest2 = o2.Baseline_mV; else Vrest2=nan; end
% gL=1/Rin? Cm?

% calculate I/V and f/I curves from hyperpol and depol steps
% I/V
sel = round([.2 .8]*length(tpulse));
sel = sel(1):sel(2);
if hypflag
  hypdat = o1.step_sections; % time x sect, mean step per section
  Vlo = mean(hypdat(sel,:),1); Vlo(isnan(Vlo))=[];
  Ilo = -amp1(1)*(1:length(Vlo));
else
  Vlo=[]; Ilo=[];
end
if depflag
  depdat = o2.y_NoSpike_sect; % time x step x sect, step per section
  Vhi = mean(depdat(sel,:),1); Vhi(isnan(Vhi))=[];
  Ihi = amp2(1)*(1:length(Vhi));
else
  Vhi=[]; Ihi=[];
end
V = [Vlo Vhi]; IVv=V;
I = [Ilo Ihi]; IVi=I;
P = polyfit(I,V,1);
IVslope = P(1);
IVinter = P(2);
%figure; plot(I,V,'b*--','markersize',10); xlabel('current'); ylabel('voltage');

% f/I
if depflag && isfield(o2,'Spikes_ISI_median')
  rates = 1./cellfun(@median,o2.Spikes_ISI_median);
  Irate = (1:nsect2)*amp2(1);
  rateIC = nan(size(rates)); % instantaneous rate at second spike
  rateSS = nan(size(rates)); % steady state firing rate
  for i=1:nsect2
    if ~isnan(rates(i))
      spks = o2.Spikes_InstFreq{i}; % o2.Spikes_InstFreq{sect}{step}
      rateIC(i) = median(cellfun(@(x)x(1),spks));
      try
        rateSS(i) = median(cellfun(@(x)x(end-1),spks));
      catch
        rateSS(i) = nan;
      end
    end
  end
  P = polyfit(Irate,rates,1);
  FIslope = P(1);
  FIinter = P(2);
else
  rates=[]; Irate=[]; rateIC=[]; rateSS=[]; FIslope=nan; FIinter=nan;
end

% h-channel kinetic variability
% ...

% ISI histogram / spike accommodation (minimize MSE)
% ...

% collapse response properties into scalar features
% ...

% define response feature vector
features = [Rin1 Rin2 Vrest1 Vrest2 IVslope IVinter FIslope FIinter];
feature_labels = {'Rin1','Rin2','Vrest1','Vrest2','IVslope','IVinter','FIslope','FIinter'};

featuredata.I=I;
featuredata.V=V;
featuredata.fI.rateIC=rateIC;
featuredata.fI.rateSS=rateSS;
featuredata.fI.Irate=Irate;
featuredata.fI.rates=rates;
featuredata.features = features;
featuredata.feature_labels = feature_labels;


