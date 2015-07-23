function codegen_odefun(file)

% Create a MEX configuration object
cfg = coder.config('mex');
% Turn on dynamic memory allocation
cfg.DynamicMemoryAllocation = 'AllVariableSizeArrays';
% Generate MEX function
eval(['codegen -d codemex -config cfg ',sprintf(file)]);
disp('MEX generation complete!')
