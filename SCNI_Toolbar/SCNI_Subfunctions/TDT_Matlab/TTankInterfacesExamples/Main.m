% handles to the controls, used in TTIcallback
global hTTIServer;
global hTTITank;
global hTTIBlock;
global hTTIEvent;
global hLabel;

% variables to store selected information, used in TTIcallback
global CurrentServer;
global CurrentTank;
global CurrentBlock;
global CurrentEvent;

% data object that is loaded by RunAnalysis
global data;

CurrentServer = 'Local';
CALLBACK = 'TTIcallback';

% prog ID constants
SERVER_PROGID = 'SERVERSELECT.ServerSelectActiveXCtrl.1';
TANK_PROGID   = 'TANKSELECT.TankSelectActiveXCtrl.1';
BLOCK_PROGID  = 'BlockSelect.BlockSelectActiveXCtrl.1';
EVENT_PROGID  = 'EVENTSELECT.EventSelectActiveXCtrl.1';

% control positions
SERVER_POS = [12  319 221 90];
TANK_POS   = [12  19  221 286];
BLOCK_POS  = [250 219 202 190];
EVENT_POS  = [250 19  202 180];
BUTTON_POS = [468 19  87  51];
LABEL_POS  = [12  4   449 12];

% create a figure
h = figure;

% add the TTI controls to the figure
hTTIServer = actxcontrol(SERVER_PROGID, SERVER_POS, h, CALLBACK);
hTTITank   = actxcontrol(TANK_PROGID,   TANK_POS,   h, CALLBACK);
hTTIBlock  = actxcontrol(BLOCK_PROGID,  BLOCK_POS,  h, CALLBACK);
hTTIEvent  = actxcontrol(EVENT_PROGID,  EVENT_POS,  h, CALLBACK);

% add button that links to RunAnalysis.m
hButton = uicontrol('Position', BUTTON_POS, ...
    'Parent',    h, ...
    'Style',    'pushbutton', ...
    'String',   'Run Analysis', ...
    'Callback', @(src, event)(RunAnalysis));

% add status label controlled by TTIcallback
hLabel = uicontrol('Position', LABEL_POS, ...
    'Parent',   h, ...
    'Style',    'text', ...
    'String',   'Status', ...
    'HorizontalAlignment', 'left', ...
    'Callback', @(src, event)(RunAnalysis));
