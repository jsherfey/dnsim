function specs = load_get_models(modelfiles)
% -- prepare list of model specs from list of local model files
specs = {};
if ~iscell(modelfiles), modelfiles={modelfiles}; end
for i=1:numel(modelfiles)
  file=modelfiles{i};
  if exist(file,'file')
    try
      o=load(file);
      if isfield(o,'modelspec') && ~isfield(o,'spec') % standardize spec name
        o.spec=o.modelspec;
      end
      if isfield(o,'spec')
        specs{end+1}=o.spec;
      end
    catch
      fprintf('failed to load ''spec'' from %s\n',file);
    end
  else
    fprintf('model file not found: %s\n',file);
  end
end