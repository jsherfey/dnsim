function [x,y]=rk4(F,tspan,IC,h)
% Usage: [x,y]=rk4(ODEFUN,TSPAN,IC,dt)

if nargin<4, h=.05; end
if nargin<3, IC=0; end
if nargin<2, tspan=[0 1]; end

x=tspan(1):h:tspan(2);
n=length(x);
m=length(IC);
y=zeros(m,n);
y(:,1)=IC;

fprintf('Runge-Kutta 4: Processing simulation %g-%g (dt=%g)\n',tspan,h);
%tic
for i=1:n-1
    k1 = F(x(i),y(:,i));
    k2 = F(x(i)+h/2,y(:,i)+(h/2)*k1);
    k3 = F((x(i)+h/2),(y(:,i)+(h/2)*k2));
    k4 = F((x(i)+h),(y(:,i)+h*k3));
    y(:,i+1) = y(:,i) + (h/6)*(k1+2*k2+2*k3+k4);  % main equation
end  
%toc
