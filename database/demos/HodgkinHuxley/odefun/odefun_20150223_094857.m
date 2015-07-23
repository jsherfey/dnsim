function [Y,T] = odefun
pset=load('params.mat');
tspan=pset.p.timelimits; dt=pset.p.dt;
T=tspan(1):dt:tspan(2); nstep=length(T);
fprintf('\nSimulation interval: %g-%g\n',tspan(1),tspan(2));
fprintf('Starting integration (euler, dt=%g)\n',dt);
HH_input_offset = inf;
HH_v = zeros(5,nstep);
HH_v(:,1) = pset.p.IC_HH_v;
HH_K_n = zeros(5,nstep);
HH_K_n(:,1) = pset.p.IC_HH_K_n;
HH_Na_m = zeros(5,nstep);
HH_Na_m(:,1) = pset.p.IC_HH_Na_m;
HH_Na_h = zeros(5,nstep);
HH_Na_h(:,1) = pset.p.IC_HH_Na_h;
for k=2:nstep
  t=T(k-1);
  F=((-(pset.p.HH_K_gk*(HH_K_n(:,k-1).^4).*(HH_v(:,k-1)-pset.p.HH_K_vk)))+((-(pset.p.HH_Na_gna*HH_Na_h(:,k-1).*(HH_Na_m(:,k-1).^3).*(HH_v(:,k-1)-pset.p.HH_Na_vna)))+((-(pset.p.HH_leak_gl*(HH_v(:,k-1)-pset.p.HH_leak_vl)))+(((pset.p.HH_input_stim*(t>pset.p.HH_input_onset & t<HH_input_offset)))+(((pset.p.HH_randn_noise.*randn(pset.p.HH_Npop,1).*sqrt(dt)))+0)))))/pset.p.HH_K_c;
  HH_v(:,k) = HH_v(:,k-1) + dt*F;
  F=(.01*(HH_v(:,k-1)+55)./(1-exp(-(HH_v(:,k-1)+55)/10))).*(1-HH_K_n(:,k-1))-(.125*exp(-(HH_v(:,k-1)+65)/80)).*HH_K_n(:,k-1);
  HH_K_n(:,k) = HH_K_n(:,k-1) + dt*F;
  F=(.1*(HH_v(:,k-1)+40)./(1-exp(-(HH_v(:,k-1)+40)/10))).*(1-HH_Na_m(:,k-1))-(4*exp(-(HH_v(:,k-1)+65)/18)).*HH_Na_m(:,k-1);
  HH_Na_m(:,k) = HH_Na_m(:,k-1) + dt*F;
  F=(.07*exp(-(HH_v(:,k-1)+65)/20)).*(1-HH_Na_h(:,k-1))-(1./(1+exp(-(HH_v(:,k-1)+35)/10))).*HH_Na_h(:,k-1);;
  HH_Na_h(:,k) = HH_Na_h(:,k-1) + dt*F;
end
Y=cat(1,HH_v,HH_K_n,HH_Na_m,HH_Na_h)';
