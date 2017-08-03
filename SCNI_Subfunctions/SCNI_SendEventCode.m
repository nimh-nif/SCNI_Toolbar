function SCNI_SendEventCode(event, Params)

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

if isdouble(event)      %================== Event input is a double
    EventNumber     = event;
    if EventNumber > 8000	
        EventIndx       = [Params.EventCodes.Number] == EventNumber;
        EventString     = Params.EventCodes(EventIndx).String;
    elseif EventNumber <= 8000
        EventString     = num2str(event);
    end
    
elseif ischar(event)    %================== Event input is a string
    if ~isfield(Params,'EventCodes')                                    % If event codes were not already loaded...
        Params.EventCodes  = SCNI_LoadEventCodes;                       % Load standard event codes
    end
    EventNumber = find(~cellfun(@isempty, strfind(lower({EventCodes.String}), lower(event))));
    if isempty(EventNumber)                                             % If the provided string does not match a standard event string...
        EventString = strfind(EventString, '_');                        % Try removing whitespace and underscores from input string
        EventNumber	= find(~cellfun(@isempty, strfind(lower({EventCodes.String}), lower(event))));
        if isempty(EventNumber) 
            error('''%s'' is not a recognized event string!', event);   
        end
    end
 	EventString     = event;
end

%================= Send event number to TDT over digital output
if isfield(Params,'TDT') && Params.TDT.Enabled == 1
    SCNI_SetBitsTDT(Params.EventCodes(EventNumber).TDTnumber);
end

%================= Send event string to OpenEphys over ethernet
if isfield(Params,'OE') && Params.OE.Enabled == 1
    if ~isfield(Params.OE, 'handle')
        error('Handle to ZeroMQ connection must be provided in ''Params.OE.handle''!');
    end
    zeroMQwrapper('Send', Params.OE.handle, EventString);
end