function [json,spec] = spec2json(spec,outfile)
% purpose: convert Modulator spec from Matlab struct to json
% spec: Matlab structure with Modulator specification
% outfile: optional file to write json
if nargin<2, outfile=[]; end

% convert Matlab struct into form compatible with json-converter
ncells=length(spec.cells);
% cells/compartments
for i=1:ncells
  c=copyfields(spec.cells(i));
  c.multiplicity = spec.cells(i).multiplicity;
  if numel(spec.cells(i).dynamics)==1 % remove?? (addressed in json2spec)
    c.dynamics = spec.cells(i).dynamics{1};
  else % keep:
    c.dynamics = spec.cells(i).dynamics;
  end  
  s.cells(i) = c;
end
% connections
for i=1:ncells^2
  s.connections(i) = copyfields(spec.connections(i));
end
if isfield(spec,'modelname'), s.modelname = spec.modelname; end
if isfield(spec,'username') , s.username = spec.username;   end
if isfield(spec,'level') , s.level = spec.level;   end
if isfield(spec,'notes') , s.notes = spec.notes;   end
if isfield(spec,'d3file') , s.d3file = spec.d3file;   end
if isfield(spec,'readmefile') , s.readmefile = spec.readmefile;   end
if isfield(spec,'tags') , s.tags = spec.tags;   end
if isfield(spec,'parent_uids') , s.source = spec.parent_uids;   end

% outputs
if ~isempty(outfile)
  json=savejson('',s,outfile);
else
  json=savejson('',s);
end
spec=s;

function c=copyfields(s)
  c.label = s.label;
  % TODO: remove this if, keep else, do string=>cell in json2spec()
  if numel(s.mechanisms)==1 % remove: (address in json2spec)
    c.mechanisms = s.mechanisms{1};
  else % keep:
    c.mechanisms = s.mechanisms;
  end
  c.parameters = s.parameters;
  for j=1:length(s.mechanisms)
    a = s.mechs(j);
    clear m
    m.params = a.params;
    m.auxvars = [];
    for k=1:size(a.auxvars,1)
      m.auxvars(k).lhs = a.auxvars{k,1};
      m.auxvars(k).rhs = a.auxvars{k,2};
    end
    m.functions = [];
    for k=1:size(a.functions,1)
      m.functions(k).lhs = a.functions{k,1};
      m.functions(k).rhs = a.functions{k,2};
    end    
    flds={'statevars','odes','ic'};
    for f=1:length(flds)
      fd=flds{f};
      if iscell(a.(fd)) && numel(a.(fd))==1 % remove: (address in json2spec)
        m.(fd) = a.(fd){1};
      elseif numel(a.(fd))>1 % keep:
        m.(fd) = cell2mat(a.(fd));
      elseif numel(a.(fd))==0
        m.(fd) = [];
      else
        m.(fd) = a.(fd);
      end    
    end
    m.substitute = [];
    for k=1:size(a.substitute,1)
      m.substitute(k).lhs = a.substitute{k,1};
      m.substitute(k).rhs = a.substitute{k,2};
    end        
    if isfield(a,'label')
      m.label = a.label;
    end
    c.mechs(j) = m;
  end
  if isempty(s.mechanisms)
    c.mechs=[];
  end
  
%         params: [1x1 struct]
%        auxvars: {}
%      functions: {5x2 cell}
%      statevars: {2x1 cell}
%           odes: {2x1 cell}
%             ic: {2x1 cell}
%     substitute: {'current'  '-INaf(V,mNaf,hNaf)'}
%      inputvars: {'V'  'h'  'm'}
%          label: 'iNa'

