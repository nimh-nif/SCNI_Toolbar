function [ScannerOn] = SCNI_WaitForTTL(PDS, c, s, NoTTLs)

%========================== SCNI_WaitForTTL.m =============================
% This function is used to temporally align with incoming TTL pulses, or to
% wait for a specified number of TTL pulses before proceeeding. For
% example, the Bruker vertical 4.7T outputs a constant +5V, with variable 
% width pulses of 0V that coincide with the start of either: 1) run, 2) volume,
% or 3) slice acquisition (this is set in the ParaVision console). 
%==========================================================================

Datapixx('RegWrRd');                                                        % Update registers for GetAdcStatus
status = Datapixx('GetAdcStatus');
Datapixx('RegWrRd');                                                        % Write local register cache to hardware
Datapixx('RegWrRd');                                                        % Give time for ADCs to convert, then read back data to local cache

ScannerThresh   = 2.5;                                                      % Set voltage threshold (V)
ScannerChannel  = find(~cellfun(@isempty, strfind(c.ADCchannelLabels, 'Scanner')));    % Find which ADC channel the scanner is connected to
TTLcount        = 0;
ScannerOn       = 0;
NoSamples       = 5; 

while TTLcount < NoTTLs
    if NoTTLs > 1                                                   % Print update to experimenter's screen only if waiting for more than 1 TTL pulse
        currentbuffer = Screen('SelectStereoDrawBuffer', c.window, c.ExperimenterBuffer);
        DrawFormattedText(c.window, sprintf('Waiting for TTL pulse %d/ %d from scanner...', TTLcount+1, NoTTLs), 'center','center', c.TextColor);
        Screen('Flip', c.window);  
    end
    while ScannerOn == 0
        status = Datapixx('GetAdcStatus');
        Datapixx('RegWrRd')
        V 	= Datapixx('GetAdcVoltages');
        if V(ScannerChannel) < ScannerThresh
            ScannerOn = 1;
        end
        CheckPress(PDS, c, s);                                      % Allow experimenter to abort if necessary
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
            CheckPress(PDS, c, s);                                  % Allow experimenter to abort if necessary
        end
    end
end
Datapixx('RegWrRd');

end

%================= Check experimenter keyboard
function CheckPress(PDS, c, s)
    [keyIsDown, secs, keyCode, deltaSecs] = KbCheck();            	% Check if any key is pressed
    if keyIsDown 
        if keyCode(KbName(c.Exit_Key))                            	% If so...
            Screen('CloseAll');
            Datapixx('Close');
            ShowCursor;
            error('User manually aborted run!');
        end
    end
end