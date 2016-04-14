% set DNS root directory
global BIOSIMROOT
[BIOSIMROOT,o]=fileparts(which(mfilename));
clear o
if ~isdeployed
  %addpath(genpath(BIOSIMROOT));
  
  % Instead of adding everything to the path as Jason had, I'll onl add the
  % core DNSim code. This can keep my code better separated.
  addpath(genpath(fullfile(BIOSIMROOT,'csh')));
  addpath(genpath(fullfile(BIOSIMROOT,'database/')));
  addpath(genpath(fullfile(BIOSIMROOT,'ganymed-ssh2-build250/')));
  addpath(genpath(fullfile(BIOSIMROOT,'matlab')));
  
  
end

% randomize seed
% see: http://www.mathworks.com/help/matlab/math/updating-your-random-number-generator-syntax.html
try
  rng('shuffle'); % - exception: rand in parfor does not use this new seed
  % rng(now);
catch
  %if any(regexp(version,'(19\d\d)|(200\d)|(2010)')) % if version before 2011a
  warning('on','MATLAB:RandStream:ActivatingLegacyGenerators')
  warning('on','MATLAB:RandStream:ReadingInactiveLegacyGeneratorState') 
  rand('seed',sum(100*clock));
end

