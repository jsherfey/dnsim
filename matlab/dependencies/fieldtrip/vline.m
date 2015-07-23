function varargout = vline(x, varargin)
% modified by JSS on 12-Oct-2010: added handle output

% VLINE plot a vertical line in the current graph

abc = axis;
x = [x x];
y = abc([3 4]);
if length(varargin)==1
  varargin = {'color', varargin{1}};
end
h = line(x, y);
set(h, varargin{:});
if nargout > 0
  varargout{1} = h;
end