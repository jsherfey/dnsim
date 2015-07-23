function out = splitstr( str, sep, max_iter )
% out = splitstr( str, sep )
%
% Purpose: 
%   cuts a string into parts based on sep,
%   returns a cell array of the parts.
%
% Input Arguments:
%   str  : string to split
%   sep  : delimiter that indicates where in the string to split.
%          Can be a string or a cell array of strings
%   max  : max # of cuts to parse
% 
% Output Arguments:
%   out  : cell array of the parts contained within str
%
% Created By:       Ben Cipollini on 07/15/2007
% Last Modified By: Ben Cipollini on 12/12/2007

  % Default separator: any whitespace char
  if (~exist('sep','var'))
    sep = {' ' '\t' '\r' '\n'};
  end;
  if (~exist('max','var'))
    max_iter = Inf;
  end;
  
  out     = {};

  %  Allow multiple delimiters
  if (iscell(sep))
    for i=1:length(sep)
      tmp   =  splitstr(str, sep{i});
      out   = {out{:} tmp{:}};
    end;
    out = unique(out);

  %  Do a single delimiter
  else
    
    % Find the indices of the delimiter
    delimIdx    = regexp( str, regexptranslate('escape', sep) );

    % Find the start (1) and end (2) indices for each non-separator
    % substring
    strIdx(:,1) = [1 length(sep)+delimIdx(1:end)]; 
    strIdx(:,2) = [delimIdx(1:end)-1 length(str)];

    %
    strIdx      = strIdx(intersect(find(strIdx(:,2)>0), find(strIdx(:,1)<=length(str))), :);

    out = cell( min(size(strIdx,1), max_iter), 1);
    for i=1:length(out)
      out{i}    = str(strIdx(i,1):strIdx(i,2));
    end;
    out{end} = [out{end} str(strIdx(i,2)+1:end)];
    
  end;
