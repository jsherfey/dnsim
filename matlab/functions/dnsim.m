function dnsim(varargin)
modeler(varargin);

%{
if nargin<1
  dnsim_loader;
else
  modeler(varargin);
end

function dnsim_loader

figure('tag','loader');

% draw controls:

% build model
% uicontrol callback: @builmodel

% load model from disk
% uicontrol callback: @loadmodel

% download model from DB
% uicontrol callback: @downloadmodel

% figure;
% uicontrol('style','pushbutton','units','normalized','position',[0 0 1 .2],...
%   'string','load model(s) from disk','callback',{@load_models,1});
% uicontrol('style','pushbutton','units','normalized','position',[0 .2 1 .2],...
%   'string','append model(s) from disk','callback',{@load_models,0});
% uicontrol('style','pushbutton','units','normalized','position',[0 .4 1 .2],...
%   'string','load model(s) from DB','callback',{@download_models,1});
% uicontrol('style','pushbutton','units','normalized','position',[0 .6 1 .2],...
%   'string','append model(s) from DB','callback',{@download_models,0});

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CALLBACKS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function buildmodel(src,evnt)
modeler;

function loadmodel(src,evnt)
% load model => spec
modeler(spec);

function downloadmodel(src,evnt)
% download model => spec
modeler(spec);

function loader(spec)
if nargin<1, spec=[]; end
try
  modeler(spec);
  close(findobj('tag','loader'));
catch err
  errordlg('error loading model; choose another.');
end
%}
