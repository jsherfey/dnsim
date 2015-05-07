function [Y,T] = odefun_20150428_044838
tspan=[0 250]; dt=0.01;
T=tspan(1):dt:tspan(2); nstep=length(T);
nreports = 5; tmp = 1:(nstep-1)/nreports:nstep; enableLog = tmp(2:end);
fprintf('\nSimulation interval: %g-%g\n',tspan(1),tspan(2));
fprintf('Starting integration (euler, dt=%g)\n',dt);
B_B_itonic_offset = inf;
B_B_iSYNconvols5_widthConvol = inf;
B_B_iSYNconvols5_Nmax = max((1),(1));
B_B_iSYNconvols5_srcpos = linspace(1,B_B_iSYNconvols5_Nmax,(1))'*ones(1,(1));
B_B_iSYNconvols5_dstpos = (linspace(1,B_B_iSYNconvols5_Nmax,(1))'*ones(1,(1)))';
B_B_iSYNconvols5_netcon = (abs(B_B_iSYNconvols5_srcpos-B_B_iSYNconvols5_dstpos)<=B_B_iSYNconvols5_widthConvol)';
B_B_iSYNconvols5_c = (1/(((0.5)/(5))^((0.5)/((5)-(0.5)))-((0.5)/(5))^((5)/((5)-(0.5)))));
