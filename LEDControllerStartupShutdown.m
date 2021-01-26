function paramsfile = LEDControllerStartupShutdown(mode,paramsfile)

% set up path
% obsolete
% if isempty(which('flyBowl_LED_control')) && exist('../flyBowl','dir'),
%   addpath('../flyBowl');
% end

if ~ismember(mode,{'startup','shutdown'}),
  error('mode should be either startup or shutdown');
end

if nargin < 2,

  defaultparamsfile = '';
  if exist('.FlyBowlDataCapture_rc.mat','file'),
    tmp = load('.FlyBowlDataCapture_rc.mat');
    if isfield(tmp,'params_file'),
      defaultparamsfile = tmp.params_file;
    end
  end
  if isempty(defaultparamsfile) && exist('C:\Users\bransonk\Documents\FlyBubbleParamFiles','dir'),
    defaultparamsfile = 'C:\Users\bransonk\Documents\FlyBubbleParamFiles';
  end
  [n,p] = uigetfile('*.txt','Select FBDC config file',defaultparamsfile);
  if ~ischar(p),
    return;
  end
  paramsfile = fullfile(p,n);

end
  
params = ReadParams(paramsfile,...
  'fns_list',{'ChR_serial_port_for_LED_Controller'},...
  'fns_numeric',{'ChR_IrInt'});

[~,ComputerName] = system('hostname');
ComputerName = strtrim(ComputerName);
m = regexp(params.ChR_serial_port_for_LED_Controller,':','split');
m = cat(1,m{:});
i = find(strcmp(ComputerName,m(:,1)));
if numel(i) ~= 1,
  error('Error matching computer name to ChR_serial_port_for_LED_Controller parameter');
end
params.ChR_serial_port_for_LED_Controller = m{i,2};

global FBDC_CHR_LED_CONTROLLER_FID;

hLEDController = LEDController(params.ChR_serial_port_for_LED_Controller);
% hLEDController = serial(params.ChR_serial_port_for_LED_Controller,...
%   'BaudRate', 115200, 'Terminator', 'CR');
% fopen(hLEDController);

if isempty(FBDC_CHR_LED_CONTROLLER_FID)
  FBDC_CHR_LED_CONTROLLER_FID = {};
end
FBDC_CHR_LED_CONTROLLER_FID{end+1} = hLEDController;

% reset LED controller
hLEDController.resetController();
% flyBowl_LED_control(hLEDController,'RESET',[],false);

% set IR LED intensity
switch mode,
  case 'startup'
    hLEDController.setIRLEDPower(params.ChR_IrInt);
    %flyBowl_LED_control(hLEDController,'IR',params.ChR_IrInt,false);
  case 'shutdown'
    hLEDController.setIrBacklightsOff();
    %flyBowl_LED_control(hLEDController,'IR',0,false);
end

hLEDController.stopPulse();
%flyBowl_LED_control(hLEDController, 'STOP',[],false);
hLEDController.turnOffLED();
%flyBowl_LED_control(hLEDController, 'OFF',[],false);
hLEDController.close();
%fclose(hLEDController);
RemoveLEDController(handles.ChRStuff.hLEDController);
%FBDC_CHR_LED_CONTROLLER_FID = setdiff(FBDC_CHR_LED_CONTROLLER_FID,hLEDController);
