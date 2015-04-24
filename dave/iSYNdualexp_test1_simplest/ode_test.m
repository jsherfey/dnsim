

function deleteme


% Parameters:
gsyn = [0]
Esyn = [0]
IC = [0]
IC_noise = [0]
dt = [0.01]

tauDx = [10]
tauRx = [0.25]

    Npre=1;
    Npost=1;

    % Auxiliary variables:
    width = inf
    Nmax = max(Npre,Npost)
    srcpos = linspace(1,Nmax,Npre)'*ones(1,Npost)
    dstpos = (linspace(1,Nmax,Npost)'*ones(1,Npre))'
    netcon = (abs(srcpos-dstpos)<=width)'
    c = (1/((tauRx/tauDx)^(tauRx/(tauDx-tauRx))-(tauRx/tauDx)^(tauDx/(tauDx-tauRx))))/2
    f = @(t) 1*(exp(-(t)/tauDx) - exp(-(t)/tauRx))

    % Functions:
    % ISYN(V,s1) = (gsyn.*(netcon*(f(smax-s1))).*(V-Esyn))

    % ODEs:
    
    s0 = 0.5;
    t=0:0.01:1;
    
    [t,s] = ode45(@odefun,0:0.01:1,s0);

    % Interface:
    % current => -ISYN(OUT,s1)

    figure; plot(t,s)



end


function s1pr = odefun(t,s1)
    tauD = [1];
    tauR = [0.25];
    smax = [20];
    
    
    if t >= 0.3 && t <= 0.6
        IN=60;
    else
        IN=-60;
    end
    
    dt = 0.01;
    s1pr = (smax*(smax-s1)/tauR).*(1+tanh(IN/10)) - 1/dt*(s1 > 0);

end




