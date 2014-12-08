function O = PowerSpecTA(x,y,FreqRange,Bins,NormAbs,Notch)

%% Initial bits n bobs

warning('off')
Fs = fix(1/(x(2)-x(1))); %Fs = round(1/(data{1}(2,1)-data{1}(1,1)));
d = y.*1e6;

%% Actions

if ~isempty(Notch), d = Bsfft(d,Fs,Notch(1),Notch(2)); end
[Pxx,f] = pwelch(detrend(d),Bins,[],Bins,Fs);
FR = find(FreqRange(1)<=f & f<=FreqRange(end)); %FR = round(FreqRange(1)*(Bins/Fs)):round(FreqRange(end)*(Bins/Fs));
PeakPower = max(Pxx(FR));
AreaPower = trapz(f(FR),Pxx(FR));
maxPP = max(PeakPower);
maxAP = max(AreaPower);
if strcmp('Normalized',NormAbs)
    Pxx = Pxx./maxPP;
    AreaPower = AreaPower./maxAP;        
end
PeakPower = max(Pxx(FR));
[mn,n] = max(Pxx(FR));
FRup = ceil(FR(1)+n + 2*(Bins/Fs));
if FR(1)+n > 4*(Bins/Fs)
    FRdown = FR(1)+n - 2*(Bins/Fs);
else FRdown = FR(1)+n;
end
FRdown=floor(FRdown);
[~,n2] = findpeaks(Pxx(FRdown:FRup),'MinPeakHeight',mn*0.85);
if ~isempty(n2), n = round(nanmean(n2)); end
OscFreq = round(f(FR(1)-1+n));

%% data output

O.raw = y;
O.data = d;
O.t = x;
O.AreaPower = AreaPower;
O.PeakPower = PeakPower;
O.OscFreq = OscFreq;
O.FreqRange = FreqRange;
O.Pxx = Pxx;
O.f = f;
O.Fs = Fs;
O.Pxx_HzPerBin = Bins/Fs;

warning('on')

end

