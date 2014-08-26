function I=holdstim(V,I,k,thresh,isi,nsteps,nsections,dt,bltime)%,procidx)
if nargin<9, bltime=100; end
  overshootfactor=1.1; 
  global statedata
if ~isfield(statedata,'Iinj')
  statedata.Iinj = I;
  statedata.current=0;
  statedata.threshcrossing=inf;
end
if k<((bltime+isi*nsteps*nsections*2)/dt), I=0; return; end
% if k<procidx, I=0; return; end
  if isfield(statedata,'current') && isnumeric(statedata.current) && statedata.current~=0
    if k<=2
      statedata.current=[];
      statedata.threshcrossing=[];
    else
      I=statedata.current;
      return;
    end
  end
  if k<1, k=1; end
  if k<=length(I)
    I=I(k);
  else
    I=0;%I(end);
  end
  if nargin<4, thresh=0; end
  if any(V(:)>=thresh)
    statedata.current=I*overshootfactor;
    statedata.threshcrossing=k;
  end
