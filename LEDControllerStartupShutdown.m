function paramsfile = LEDControllerStartupShutdown(mode,paramsfile)

% set up path
if isempty(which('flyBowl_LED_control')) && exist('../flyBowl','dir'),
  addpath('../flyBowl');
end

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

hLEDController = serial(params.ChR_serial_port_for_LED_Controller,...
  'BaudRate', 115200, 'Terminator', 'CR');
fopen(hLEDController);

if isempty(FBDC_CHR_LED_CONTROLLER_FID)
  FBDC_CHR_LED_CONTROLLER_FID = hLEDController;
else
  FBDC_CHR_LED_CONTROLLER_FID(end+1) = hLEDController;
end

% reset LED controller
flyBowl_LED_control(hLEDController,'RESET',[],false);

% set IR LED intensity
switch mode,
  case 'startup'
    flyBowl_LED_control(hLEDController,'IR',params.ChR_IrInt,false);
  case 'shutdown'
    flyBowl_LED_control(hLEDController,'IR',0,false);
end

flyBowl_LED_control(hLEDController, 'STOP',[],false);
flyBowl_LED_control(hLEDController, 'OFF',[],false);
fclose(hLEDController);
FBDC_CHR_LED_CONTROLLER_FID = setdiff(FBDC_CHR_LED_CONTROLLER_FID,hLEDController);
