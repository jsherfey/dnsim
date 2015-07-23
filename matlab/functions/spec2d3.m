function d3json = spec2d3(spec,outfile)
% Purpose: convert DNSim specification to d3 json format for graphical model view
% Created by JSS on 21-Aug-2014
if nargin<2, outfile=''; end
if ~isfield(spec,'cells') && isfield(spec,'entities')
  spec.cells=spec.entities;
end
ncells=length(spec.cells);
cnt=0; d3=[];
for i=1:ncells
  for k=1:length(spec.cells(i).mechanisms)
    cnt=cnt+1;
    d3(cnt).source=spec.cells(i).mechanisms{k};
    d3(cnt).target=spec.cells(i).label;
    d3(cnt).type='intrinsic';
    d3(cnt).label=spec.cells(i).mechanisms{k};
  end
end
for i=1:ncells
  for j=1:ncells
    for k=1:length(spec.connections(i,j).mechanisms)
      cnt=cnt+1;
      d3(cnt).source=spec.cells(i).label;
      d3(cnt).target=spec.cells(j).label;
      d3(cnt).type='connection';
      d3(cnt).label=spec.connections(i,j).mechanisms{k};
    end
  end
end
% outputs
if isempty(d3)
  d3='';
end
if ~isempty(outfile)
  d3json=savejson('',d3,outfile);
else
  d3json=savejson('',d3);
end
