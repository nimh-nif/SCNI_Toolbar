function [Eye] = SCNI_GetEyePos(Params)

%============================ SCNI_GetEyePos ==============================
% This function returns the subject's current (i.e instantaneous) eye 
% position in multiple coordinates (Volts, degrees, pixels), for checking 
% fixations and plotting gaze online. 
%

if ~isfield(Params, 'Eye')
    Params.Eye.CalMode  = 1;
    Params.Eye.EyeToUse = 1;
end

if Params.Eye.CalMode > 1                                        	%============= Use real eye position data
    Datapixx('RegWrRd');                                                                % Update registers for GetAdcStatus
    status = Datapixx('GetAdcStatus');                                                  % Check ADC status
    Datapixx('RegWrRd');                                                                % Update registers for GetAdcStatus
    V       = Datapixx('GetAdcVoltages');                                               % Read ADC voltages for all channels                
    Datapixx('RegWrRd'); 
    if Params.Eye.EyeToUse > 2
        EyeToUse = [1,2];
    else
        EyeToUse = Params.Eye.EyeToUse;
    end
    for e = EyeToUse                                                                            % For each eye...
        Eye(e).PupilV   = V(Params.Eye.Pupilchannels{e});                                       % Get Left pupil and Right pupil (V)
        Eye(e).Volts    = V(Params.Eye.XYchannels{e});                                          % Get Left X, Left Y, Right X, Right Y (V)
        Eye(e).Degrees  = (Eye(e).Volts + Params.Eye.Cal.Offset{e}).*Params.Eye.Cal.Gain{e}.*Params.Eye.Cal.Sign{e};	% Convert volts into degrees of visual angle from center
        Eye(e).PixCntr  = Eye(e).Degrees.*Params.Display.PixPerDeg;                             % Convert degrees into screen pixels
        Eye(e).Pixels   = Params.Display.Rect([3,4])/2 + Eye(e).PixCntr;                        % Center pixels relative to screen center
    end
    if Params.Eye.EyeToUse > 2                                      %============= Calculate version (both eyes)
        Eye(3).Degrees = mean([Eye(1).Degrees; Eye(2).Degrees]);   
        Eye(3).Pixels  = mean([Eye(1).Pixels; Eye(2).Pixels]);
        Eye(3).VergDeg = Eye(1).Degrees(1) - Eye(2).Degrees(1);     % Vergence (degrees) = difference between X-position for left and right eyes
        Eye(3).VergPix = Eye(1).Pixels(1) - Eye(2).Pixels(1); 
        Eye(3).VergCm  = [];
        EyeToUse       = Params.Eye.EyeToUse;
    end
    
    if Eye(EyeToUse).Pixels(1) > Params.Display.Rect(3)                     % If gaze cursor is entering monkey's display...
        HideCursor;                                                         % Turn cursor off!
    else                                                                    % Otherwise, mouse is on an experimenter display
        ShowCursor;                                                         % Show cursor
    end

elseif Params.Eye.CalMode == 1                                   	%============= Use mouse cursor to simulate eye position
    [EyeX, EyeY, buttons]   = GetMouse(Params.Display.win);                                	% Get mouse cursor position (relative to top left corner)
    Eye(1).PupilV  = [];                                                                    % Return empty for pupil size 
    Eye(1).Pixels  = [EyeX, EyeY];                                                          % 
    Eye(1).PixCntr = Eye(1).Pixels-Params.Display.Rect([3,4])/2;                           	% Center coordinates
    Eye(1).Degrees = Eye(1).Pixels./Params.Display.PixPerDeg;                              	% Convert pixels to degrees
	Eye(1).Volts   = (Eye(1).Degrees./Params.Eye.Cal.Gain{1})+Params.Eye.Cal.Offset{1};     % Convert degrees to volts
end
