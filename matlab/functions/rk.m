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

% h=1.5;                                             % step size
% x = 0:h:3;                                         % Calculates upto y(3)
% y = zeros(1,length(x)); 
% y(1) = 5;                                          % initial condition
% F_xy = @(t,r) 3.*exp(-t)-0.4*r;                    % change the function as you desire
% 
% for i=1:(length(x)-1)                              % calculation loop
%     k_1 = F_xy(x(i),y(i));
%     k_2 = F_xy(x(i)+0.5*h,y(i)+0.5*h*k_1);
%     k_3 = F_xy((x(i)+0.5*h),(y(i)+0.5*h*k_2));
%     k_4 = F_xy((x(i)+h),(y(i)+k_3*h));
%     y(i+1) = y(i) + (1/6)*(k_1+2*k_2+2*k_3+k_4)*h;  % main equation
% end

% h = 0.5;
% t = 0;
% w = 0.5;
% for i=1:4
%   k1 = h*f(t,w);
%   k2 = h*f(t+h/2, w+k1/2);
%   k3 = h*f(t+h/2, w+k2/2);
%   k4 = h*f(t+h, w+k3);
%   w = w + (k1+2*k2+2*k3+k4)/6;
%   t = t + h;
% end