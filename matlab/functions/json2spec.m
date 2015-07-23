function [spec,jsonspec] = json2spec(json)
% purpose: convert Modulator spec from json to Matlab struct
% json: string or filename (.json)

jsonspec = loadjson(json);

% convert jsonspec into standard spec format
ncells=length(jsonspec.cells);
% cells/compartments
for i=1:ncells
  c=copyfields(jsonspec.cells(i));
  c.multiplicity = jsonspec.cells(i).multiplicity;
  if ischar(jsonspec.cells(i).dynamics)
    c.dynamics = {jsonspec.cells(i).dynamics};
  else
    c.dynamics = jsonspec.cells(i).dynamics;
  end
  s.cells(i) = c;
end
% connections
for i=1:ncells^2
  s.connections(i) = copyfields(jsonspec.connections(i));
end
if ncells>1
  s.connections = reshape(s.connections,[ncells ncells]);
end
% outputs
spec=s;

function c=copyfields(s)
  c.label = s.label;
  if ischar(s.mechanisms)
    c.mechanisms = {s.mechanisms};
  else
    c.mechanisms = s.mechanisms;
  end
  c.parameters = s.parameters;
  for j=1:length(c.mechanisms)
    a = s.mechs(j);
    clear m
    m.params = a.params;
    m.auxvars = [];
    for k=1:length(a.auxvars)
      m.auxvars{k,1} = a.auxvars(k).lhs;
      m.auxvars{k,2} = a.auxvars(k).rhs;
    end
    m.functions = [];
    for k=1:length(a.functions)
      m.functions{k,1} = a.functions(k).lhs;
      m.functions{k,2} = a.functions(k).rhs;
    end
    m.statevars = {};
    for k=1:length(a.statevars)
      m.statevars{k,1} = a.statevars(k).value;
    end
    m.odes = {};
    for k=1:length(a.odes)
      m.odes{k,1} = a.odes(k).value;
    end
    m.ic = {};
    if ~isempty(a.ic)
      if isnumeric(a.ic)
        m.ic = num2cell(a.ic);
      elseif ischar(a.ic)
        m.ic = cellstr(a.ic);
      elseif isstruct(a.ic)
        for k=1:length(a.ic)
          m.ic{k,1} = a.ic(k).value;
        end
      end
      if size(m.ic,1)<size(m.ic,2)
        m.ic=m.ic'; 
      end      
    end       
%     flds={'statevars','odes','ic'};
%     for f=1:length(flds)
%       fd=flds{f};
%       if ~isempty(a.(fd))
%         if ischar(a.(fd))
%           m.(fd) = cellstr(a.(fd));
%         elseif isnumeric(a.(fd))
%           m.(fd) = num2cell(a.(fd));%a.(fd);
%         end
%       else
%         m.(fd) = {};
%       end
%     end
    m.substitute = [];
    for k=1:length(a.substitute)
      m.substitute{k,1} = a.substitute(k).lhs;
      m.substitute{k,2} = a.substitute(k).rhs;
    end        
    if isfield(a,'label')
      m.label = a.label;
    end
    c.mechs(j) = m;
  end
  if isempty(s.mechanisms)
    c.mechs=[];
  end
  