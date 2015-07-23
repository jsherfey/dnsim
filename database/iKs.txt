% iks: Slowly inactivating K+ channel
% from Durstewitz & Gabriel (2006), Cerebral Cortex
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Parameters
ek=-80 % [mV], 25*log(ko/ki), ko0=3.82, ki0=140
gKsbar= 0.285 % (mho/cm2) <0,1e9>
a_IC=0; b_IC=1; IC_noise=0

% Functions
va(v)=v+34
va2(v)=(abs(va(v))<1e-4).*(va(v)+1e-4)+(abs(va(v))>=1e-4).*(va(v))
vb(v)=v+65
vb2(v)=(abs(vb(v))<1e-4).*(vb(v)+1e-4)+(abs(vb(v))>=1e-4).*(vb(v))
vd(v)=v+63.6
vd2(v)=(abs(vd(v))<1e-4).*(vd(v)+1e-4)+(abs(vd(v))>=1e-4).*(vd(v))
ainf(v) = 1./(1+exp(-va2(v)/6.5))
atau = 10
binf(v) = 1./(1+exp(vb2(v)/6.6))
btau(v) = 200+3200./(1+exp(-vd2(v)/4))
ik(v,a,b) = gKsbar.*a.*b.*(v-ek)

% ODEs
a' = (ainf(IN)-a)/atau
b' = (binf(IN)-b)/btau(IN)
a(0)=a_IC+IC_noise.*rand(Npop,1)
b(0)=b_IC+IC_noise.*rand(Npop,1)

% Interface
current => -ik(IN,a,b)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% Reference: http://senselab.med.yale.edu/modeldb/ShowModel.asp?model=155057&file=\L5microcircuit\mechanism\iks.mod
