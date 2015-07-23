function specs = download_get_models(ModelIDs,cfg)
% Purpose: prepare list of model specs from list of Model IDs
if nargin<2
  global cfg;
end
if ~isstruct(cfg) || ~isfield(cfg,'xfruser')
  cfg.webhost = '104.131.218.171'; % 'infinitebrain.org','104.131.218.171'
  cfg.xfruser = 'publicuser';
  cfg.xfrpassword = 'publicaccess';
  cfg.ftp_port=21;
  cfg.MEDIA_PATH = '/project/infinitebrain/media';
end
target = pwd; % local directory for temporary files
specs={};
% Open MySQL DB connection
result = mysqldb(['select file from modeldb_modelspec where model_id=' num2str(ModelIDs(1))],{'file'});
if isempty(result)
  disp('there was an error opening the database.'); 
  return;
end
% Open ftp connection
try
  f=ftp([cfg.webhost ':' num2str(cfg.ftp_port)],cfg.xfruser,cfg.xfrpassword);
  pasv(f);
catch err
%   mym('close');
  disp('there was an error connecting (ftp) to the server.');
  rethrow(err);
end
% Get models from server
for i = 1:length(ModelIDs)
  ModelID=ModelIDs(i);
  % get file names of spec files on server
  fprintf('Model(uid=%g): getting file name and file from server\n',ModelID);
  result = mysqldb(['select file from modeldb_modelspec where model_id=' num2str(ModelID)],{'file'});
%   q = mym(['select file from modeldb_modelspec where model_id=' num2str(ModelID)]);
  jsonfile = result.file{1};
  % retrieve json spec file
  [usermedia,modelfile,ext] = fileparts(jsonfile); % remote server media directory
  if isempty(ext)
    ext='.json';
  end
  usermedia=fullfile(cfg.MEDIA_PATH,usermedia);
  modelfile=[modelfile ext];%'.json'];
  cd(f,usermedia);
  mget(f,modelfile,target); 
  % convert json spec to matlab spec structure
  fprintf('Model(uid=%g): converting model specification to matlab structure\n',ModelID);
  tempfile = fullfile(target,modelfile);
  if isequal(ext,'.json')
    [spec,jsonspec] = json2spec(tempfile);
    spec.model_uid=ModelID;
  elseif isequal(ext,'.txt')
    spec = parse_mech_spec(tempfile,[]);
  else
    spec = [];
  end
  specs{end+1}=spec;
  % clean up
  delete(tempfile);
end
close(f);