% handles all callbacks for TTImain
% there is usually no need to modify this
function TTIcallback(varargin)

% control handles
global hTTITank;
global hTTIBlock;
global hTTIEvent;
global hLabel;

% variables to hold current selections
global CurrentServer;
global CurrentTank;
global CurrentBlock;
global CurrentEvent;

% grab the event and new value
event = varargin{end};
newvalue = varargin{3};

% handle the event
if strcmp(event, 'ServerChanged')
    CurrentServer = newvalue;
    disp(['new server is ' CurrentServer]);
    
    % Process Server selection for TTI.TankSelect
    set(hTTITank, 'UseServer', newvalue);
    hTTITank.Refresh;
    
elseif strcmp(event, 'TankChanged')
    CurrentTank = newvalue;    
    disp(['new tank is ' CurrentTank]);
    
    % Process Server and Tank selection for TTI.BlockSelect
    set(hTTIBlock, 'UseServer', CurrentServer);
    set(hTTIBlock, 'UseTank', newvalue);
    
    % Deselects the previously selected Block if the current Tank is changed
    set(hTTIBlock, 'ActiveBlock', '');
    hTTIBlock.Refresh;

    % Deselects the previously selected Event and clears the event list if the current Tank is changed
    set(hTTIEvent, 'UseBlock', '');
    set(hTTIEvent, 'ActiveEvent', '');
    hTTIEvent.Refresh;
       
elseif strcmp(event, 'BlockChanged')
    CurrentBlock = newvalue;
    disp(['new block is ' CurrentBlock]);
    
    % Process Server, Tank, and Block selection information for TTI.EventSelect
    set(hTTIEvent, 'UseServer', CurrentServer);
    set(hTTIEvent, 'UseTank', CurrentTank);
    set(hTTIEvent, 'UseBlock', CurrentBlock);
    
    % Deselects the previously selected Event if the current Block is changed
    set(hTTIEvent, 'ActiveEvent', '');
    hTTIEvent.Refresh;

elseif strcmp(event, 'ActEventChanged')    
    CurrentEvent = newvalue;
    disp(['new event is ' CurrentEvent]);
    
    % Process Event Selection and refresh
    hTTIEvent.Refresh;

end

s = sprintf('%s; %s; %s; %s', ...
    CurrentServer, CurrentTank, CurrentBlock, CurrentEvent);
set(hLabel, 'String', s);
end

