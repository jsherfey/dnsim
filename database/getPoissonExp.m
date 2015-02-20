function G = getPoissonExp(lambda,tauD,Pmax,N,T,dt,overwrite_flag,poiss_id)
if nargin<8, poiss_id=1; end
if nargin<7, overwrite_flag=0; end
if nargin<6, dt=.01; end
if nargin<5, T=1000; end
if nargin<4, N=1; end
if nargin<3, Pmax=1; end
if nargin<2, tauD=10; end
if nargin<1, lambda=50; end

% file=sprintf('input_poissonexp_N%g_lambda%g_tau%g_%gms_%g.mat',N,lambda,tauD,T,poiss_id);
% if exist(file,'file') && overwrite_flag==0
%   fprintf('loading %s\n',file);
%   load(file,'G');
% else  
  nt=ceil(T/dt);
  spikes=poissrnd(lambda*(1e-4),[N nt]);
  G=zeros(N,nt);%G=zeros(N,T);
  for t=2:nt
    G(:,t)=G(:,t-1) - dt*G(:,t-1)/tauD;
    if spikes(t)==1
      G(:,t) = G(:,t) + Pmax.*(1-G(:,t));
    end
  end
  G=single(G);
%   fprintf('saving %s\n',file);
%   save(file,'G','spikes','lambda','tauD','Pmax','dt','T','N');
% end

% sel=1:10000;
% tt=(0:nt-1)*dt;
% figure; plot(tt(sel),G(1,sel));



