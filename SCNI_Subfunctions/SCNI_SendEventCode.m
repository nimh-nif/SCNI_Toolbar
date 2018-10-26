function Params = SCNI_SendEventCode(event, Params)

%========================== SCNI_SendEventCode.m ==========================
% Sends the provided event code number to the appropriate neurophysiology
% recording system(s). 
%
% EXAMPLE:
%   Params.EventCodes  = SCNI_LoadEventCodes;           % Load standard event codes
%   Params      = SCNI_TDTSettings(Params, 0);          % Load TDT parameters
%   SCNISendEventCode('Fix_on', Params);                % Send event code for fixation onset
%   SCNISendEventCode(8003, Params);                  	% Send event code for stimulus onset
%   SCNISendEventCode(24, Params);                      % Send event code for stimulus condition #24
%
%==========================================================================

if ~isfield(Params,'EventCodes')                                    % If event codes were not already loaded...
    Params.EventCodes  = SCNI_LoadEventCodes;                       % Load standard event codes
end
    
if isa(event,'double')      %================== Event input is a double
    EventNumber     = event;
    if EventNumber > 8000	
        EventIndx       = [Params.EventCodes.Number] == EventNumber;
        EventString     = Params.EventCodes(EventIndx).String;
    elseif EventNumber <= 8000
        EventString     = num2str(event);
    end
    NumToSend = EventNumber;
    
elseif ischar(event)    %================== Event input is a string
    EventNumber = find(~cellfun(@isempty, strfind(lower({Params.EventCodes.String}), lower(event))));
    if isempty(EventNumber)                                             % If the provided string does not match a standard event string...
        EventString = strfind(EventString, '_');                        % Try removing whitespace and underscores from input string
        EventNumber	= find(~cellfun(@isempty, strfind(lower({Params.EventCodes.String}), lower(event))));
        if isempty(EventNumber) 
            error('''%s'' is not a recognized event string!', event);   
        end
    end
 	EventString	= event;
    NumToSend   = Params.EventCodes(EventNumber).TDTnumber; 
end

%================= Send event number to TDT over digital output
if Params.DPx.TDTonDOUT == 1                    % Is TDT connected to DataPixx via Digital outputs?
    if Params.DPx.UseInterface == 0             % If TDT is NOT connected to DataPixx via the SCNI interface box...
        DirectConnect = 1; 
    elseif Params.DPx.UseInterface == 1         % If TDT IS connected to DataPixx via the SCNI interface box...
        DirectConnect = 0;
    end
    SCNI_SetBitsTDT(NumToSend, DirectConnect);
end

%================= Send event string to TDT over UDP socket
if isfield(Params,'TDT') && Params.TDT.UDPsocket > 0
    
end

%================= Send event string to OpenEphys over ethernet
if isfield(Params,'OE') && Params.OE.Enabled == 1
    if ~isfield(Params.OE, 'handle')
        error('Handle to ZeroMQ connection must be provided in ''Params.OE.handle''!');
    end
    zeroMQwrapper('Send', Params.OE.handle, EventString);
end