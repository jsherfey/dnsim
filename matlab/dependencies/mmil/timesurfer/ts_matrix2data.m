function epoch_data = ts_matrix2data(y,varargin)
ind=find(cellfun(@(x)isequal(x,'continuous'),varargin));
% force continuous data
if ndims(y)==2
  if isempty(ind)
    varargin = {varargin{:} 'continuous' 1};
  else
    varargin{ind+1} = 1;
  end
end
epoch_data = ts_matrix2epoch(y,varargin{:});