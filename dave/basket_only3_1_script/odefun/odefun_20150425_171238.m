function [Y,T] = odefun_20150425_171238
tspan=[0 250]; dt=0.01;
T=tspan(1):dt:tspan(2); nstep=length(T);
nreports = 5; tmp = 1:(nstep-1)/nreports:nstep; enableLog = tmp(2:end);
fprintf('\nSimulation interval: %g-%g\n',tspan(1),tspan(2));
fprintf('Starting integration (euler, dt=%g)\n',dt);
B_B_itonic_offset = inf;
B_B_B_B_iSYN_UB = max((2),(2));
B_B_B_B_iSYN_Xpre = linspace(1,B_B_B_B_iSYN_UB,(2))'*ones(1,(2));
B_B_B_B_iSYN_Xpost = (linspace(1,B_B_B_B_iSYN_UB,(2))'*ones(1,(2)))';
B_B_B_B_iSYN_mask = abs(B_B_B_B_iSYN_Xpre-B_B_B_B_iSYN_Xpost)<=(0.5);
B_B_iSYNconvol_widthConvol = inf;
B_B_iSYNconvol_Nmax = max((2),(2));
B_B_iSYNconvol_srcpos = linspace(1,B_B_iSYNconvol_Nmax,(2))'*ones(1,(2));
B_B_iSYNconvol_dstpos = (linspace(1,B_B_iSYNconvol_Nmax,(2))'*ones(1,(2)))';
B_B_iSYNconvol_netcon = (abs(B_B_iSYNconvol_srcpos-B_B_iSYNconvol_dstpos)<=B_B_iSYNconvol_widthConvol)';
B_B_iSYNconvol_c_norm = (1/(((0.5)/(5))^((0.5)/((5)-(0.5)))-((0.5)/(5))^((5)/((5)-(0.5)))))/2;
B_V = zeros(2,nstep);
B_V(:,1) = [-65 -65];
B_B_iNaF_hNaF = zeros(2,nstep);
B_B_iNaF_hNaF(:,1) = [0.0049904   0.0059419];
B_B_iKDR_mKDR = zeros(2,nstep);
B_B_iKDR_mKDR(:,1) = [0.0087099   0.0024677];
B_B_B_B_iSYN_sSYNpre = zeros(2,nstep);
B_B_B_B_iSYN_sSYNpre(:,1) = [0.1         0.1];
B_B_iSYNconvol_s1 = zeros(2,nstep);
B_B_iSYNconvol_s1(:,1) = [0.1         0.1];
B_B_iSYNconvol_t1 = zeros(2,nstep);
B_B_iSYNconvol_t1(:,1) = [0.1         0.1];
B_B_iSYNconvol_s2 = zeros(2,nstep);
B_B_iSYNconvol_s2(:,1) = [0.1         0.1];
B_B_iSYNconvol_t2 = zeros(2,nstep);
B_B_iSYNconvol_t2(:,1) = [0.1         0.1];
B_B_iSYNconvol_s3 = zeros(2,nstep);
B_B_iSYNconvol_s3(:,1) = [0.1         0.1];
tstart = tic;
for k=2:nstep
  t=T(k-1);
  F=(((-B_B_itonic_Itonic(t))+(((1).*randn((2),1))+((-B_B_iNaF_INaF(B_V(:,k-1),B_B_iNaF_hNaF(:,k-1)))+((-B_B_iKDR_IKDR(B_V(:,k-1),B_B_iKDR_mKDR(:,k-1)))+((-B_B_leak_Ileak(B_V(:,k-1)))+((-B_B_B_B_iSYN_ISYN(B_V(:,k-1),B_B_B_B_iSYN_sSYNpre(:,k-1)))+((-B_B_iSYNconvol_iSYNconvol(B_V(:,k-1),B_B_iSYNconvol_s1(:,k-1),B_B_iSYNconvol_s2(:,k-1),B_B_iSYNconvol_s3(:,k-1)))+0))))))))/(0.9);
  B_V(:,k) = B_V(:,k-1) + dt*F;
  F=B_B_iNaF_aH(B_V(:,k-1)).*(1-B_B_iNaF_hNaF(:,k-1))-B_B_iNaF_bH(B_V(:,k-1)).*B_B_iNaF_hNaF(:,k-1);
  B_B_iNaF_hNaF(:,k) = B_B_iNaF_hNaF(:,k-1) + dt*F;
  F=B_B_iKDR_aM(B_V(:,k-1)).*(1-B_B_iKDR_mKDR(:,k-1))-B_B_iKDR_bM(B_V(:,k-1)).*B_B_iKDR_mKDR(:,k-1);
  B_B_iKDR_mKDR(:,k) = B_B_iKDR_mKDR(:,k-1) + dt*F;
  F=-B_B_B_B_iSYN_sSYNpre(:,k-1)./(5) + ((1-B_B_B_B_iSYN_sSYNpre(:,k-1))/(0.5)).*(1+tanh(B_V(:,k-1)/10));
  B_B_B_B_iSYN_sSYNpre(:,k) = B_B_B_B_iSYN_sSYNpre(:,k-1) + dt*F;
  F=((10)*((10)-B_B_iSYNconvol_s1(:,k-1))/(0.25)).*(1+tanh(B_V(:,k-1)/10)).*(B_B_iSYNconvol_t1(:,k-1) < (1-(0.1)))/2 - 1*(B_B_iSYNconvol_s1(:,k-1) > 0);
  B_B_iSYNconvol_s1(:,k) = B_B_iSYNconvol_s1(:,k-1) + dt*F;
  F=(1-B_B_iSYNconvol_t1(:,k-1))/(0.25).*(1+tanh((B_B_iSYNconvol_s1(:,k-1)-(10)*(1-(0.1)))))/2 - 1/(0.25)*B_B_iSYNconvol_t1(:,k-1).*(B_B_iSYNconvol_s1(:,k-1) < (10)*(0.1));
  B_B_iSYNconvol_t1(:,k) = B_B_iSYNconvol_t1(:,k-1) + dt*F;
  F=((10)*((10)-B_B_iSYNconvol_s2(:,k-1))/(0.25)).*(1+tanh(B_V(:,k-1)/10)).*(B_B_iSYNconvol_t2(:,k-1) < (1-(0.1)))/2.*(B_B_iSYNconvol_s1(:,k-1) > (10)*(0.1)).*(B_B_iSYNconvol_t1(:,k-1)>(1-(0.1))) - 1*(B_B_iSYNconvol_s2(:,k-1) > 0);
  B_B_iSYNconvol_s2(:,k) = B_B_iSYNconvol_s2(:,k-1) + dt*F;
  F=(1-B_B_iSYNconvol_t2(:,k-1))/(0.25).*(1+tanh((B_B_iSYNconvol_s2(:,k-1)-(10)*(1-(0.1)))))/2 - 1/(0.25)*B_B_iSYNconvol_t2(:,k-1).*(B_B_iSYNconvol_s2(:,k-1) < (10)*(0.1));
  B_B_iSYNconvol_t2(:,k) = B_B_iSYNconvol_t2(:,k-1) + dt*F;
  F=((10)*((10)-B_B_iSYNconvol_s3(:,k-1))/(0.25)).*(1+tanh(B_V(:,k-1)/10))/2.*(B_B_iSYNconvol_s2(:,k-1) > (10)*(0.1)).*(B_B_iSYNconvol_t2(:,k-1)>(1-(0.1))) - 1*(B_B_iSYNconvol_s3(:,k-1) > 0);;
  B_B_iSYNconvol_s3(:,k) = B_B_iSYNconvol_s3(:,k-1) + dt*F;
  if any(k == enableLog)
    elapsedTime = toc(tstart);
    elapsedTimeMinutes = floor(elapsedTime/60);
    elapsedTimeSeconds = rem(elapsedTime,60);
    if elapsedTimeMinutes
        fprintf('Processed %g of %g ms (elapsed time: %g m %.3f s)\n',T(k),T(end),elapsedTimeMinutes,elapsedTimeSeconds);
    else
        fprintf('Processed %g of %g ms (elapsed time: %.3f s)\n',T(k),T(end),elapsedTimeSeconds);
    end
  end
end
Y=cat(1,B_V,B_B_iNaF_hNaF,B_B_iKDR_mKDR,B_B_B_B_iSYN_sSYNpre,B_B_iSYNconvol_s1,B_B_iSYNconvol_t1,B_B_iSYNconvol_s2,B_B_iSYNconvol_t2,B_B_iSYNconvol_s3)';
