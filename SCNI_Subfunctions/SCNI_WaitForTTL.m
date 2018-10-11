function [ScannerOn] = SCNI_WaitForTTL(Params, NoTTLs, Polarity, Print)

%========================== SCNI_WaitForTTL.m =============================
% This function is used to temporally align with incoming TTL pulses, or to
% wait for a specified number of TTL pulses before proceeeding. For
% example, the Bruker vertical 4.7T outputs a constant +5V, with variable 
% width pulses of 0V that coincide with the start of either: 1) run, 2) volume,
% or 3) slice acquisition (this is set in the ParaVision console). 
%
% INPUTS:   Params: 
%           NoTTLS:     number of TTL pulses to wait for before returning
%           Polarity:   -1 = pulse goes low; 1 = pulse goes high
%           Print:      flag for whether to print updates to experimenter's display
%
%==========================================================================

Datapixx('RegWrRd');                                                        % Update registers for GetAdcStatus
status = Datapixx('GetAdcStatus');
Datapixx('RegWrRd');                                                        % Write local register cache to hardware
Datapixx('RegWrRd');                                                        % Give time for ADCs to convert, then read back data to local cache

ScannerThresh   = 2.5;                                                      % Set voltage threshold (V)
ScannerChannel  = find(~cellfun(@isempty, strfind(Params.DPx.AnalogInLabels, 'Scanner')));    % Find which ADC channel the scanner is connected to
TTLcount        = 0;
ScannerOn       = 0;

while TTLcount < NoTTLs
    
    if Print == 1 && NoTTLs > 1                                                     % Print update to experimenter's screen only if waiting for more than 1 TTL pulse
        DrawFormattedText(Params.Display.win, sprintf('Waiting for TTL pulse %d/ %d from scanner on DataPixx ADC channel %d...', TTLcount+1, NoTTLs, ScannerChannel-1), 500,'center', [1,1,1]*255);
        Screen('Flip', Params.Display.win);  
    end
    
    while ScannerOn == 0
        status = Datapixx('GetAdcStatus');
        Datapixx('RegWrRd')
        V 	= Datapixx('GetAdcVoltages');
        if V(ScannerChannel) < ScannerThresh
            ScannerOn = 1;
        end
        CheckPress(Params);                                         % Allow experimenter to abort if necessary
    end
    TTLcount = TTLcount+1;
    
    if TTLcount < NoTTLs                                            % If waiting for more TTL pulses...
        while ScannerOn == 1                                        % Wait for pulse to end
            status = Datapixx('GetAdcStatus');                      
            Datapixx('RegWrRd')
            V 	= Datapixx('GetAdcVoltages');
            if V(ScannerChannel) > ScannerThresh            
                ScannerOn = 0;
            end
            CheckPress(Params);                                     % Allow experimenter to abort if necessary
        end
    end
end
Datapixx('RegWrRd');

end

%================= Check experimenter keyboard
function CheckPress(Params)
    [keyIsDown, secs, keyCode, deltaSecs] = KbCheck();            	% Check if any key is pressed
    if keyIsDown 
        if keyCode(KbName('Escape'))                                % If so...
            Screen('CloseAll');
            Datapixx('Close');
            ShowCursor;
            error('User manually aborted run!');
        end
    end
end