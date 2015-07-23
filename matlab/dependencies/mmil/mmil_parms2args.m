function args = mmil_parms2args(parms)
%function args = parms2args(parms)
% 
% Purpose:
%   Convert from mmil parms object to 
%   a named_argument-value pair list.
%
% Parameters:
%   parms - mmil parms object to convert
%
% See also: mmil_args2parms
%
%
% Created By:       Ben Cipollini on 08/01/2007
% Last Modified By: Ben Cipollini on 08/20/2007

  mmil_check_nargs(nargin, 1);
  
  % Grab the field names
  fields = fieldnames(parms);
  args   = {};
  
  % Loop over the field names, grab the value, and
  % append both to the output args list
  for i=1:length(fields)
    args{end+1} = fields{i};
	args{end+1} = getfield(parms, fields{i});
  end;
  
