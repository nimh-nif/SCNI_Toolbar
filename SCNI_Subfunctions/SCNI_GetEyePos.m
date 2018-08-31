function [Eye] = SCNI_GetEyePos(Params)

%============================ SCNI_GetEyePos ==============================
% This function returns the subject's current (i.e instantaneous) eye 
% position in multiple coordinates (Volts, degrees, pixels), for checking 
% fixations and plotting gaze online. 
%

if ~isfield(Params, 'Eye')
    Params.Eye.CalMode = 1;
end

if Params.Eye.CalMode > 1                                        	%============= Use real eye position data
    Datapixx('RegWrRd');                                                                % Update registers for GetAdcStatus
    status = Datapixx('GetAdcStatus');                                                  % Check ADC status
    Datapixx('RegWrRd');                                                                % Update registers for GetAdcStatus
    V       = Datapixx('GetAdcVoltages');                                               % Read ADC voltages for all channels                
    Datapixx('RegWrRd'); 
    Eye.PupilV  = V(Params.Eye.DPxChannels([3,6]));                                     % Get Left pupil and Right pupil (V)
    Eye.Volts   = V(Params.Eye.DPxChannels([1,2,4,5]));                                 % Get Left X, Left Y, Right X, Right Y (V)
    Eye.Degrees = (Eye.Volts + Params.Eye.Cal.Offset).*Params.Eye.Cal.Gain;             % Convert volts into degrees of visual angle from center
    Eye.Pixels  = Eye.Degrees.*Params.Display.PixPerDeg;                                % Convert degrees into screen pixels
    Eye.PixCntr = Params.Display.Rect([3,4])/2 + Eye.Pixels;                            % Center pixels relative to screen center
    
elseif Params.Eye.CalMode == 1                                   	%============= Use mouse cursor to simulate eye position
    [EyeX, EyeY, buttons] = GetMouse(Params.Display.win);                               % Get mouse cursor position (relative to subject display)
    Eye.PupilV  = [];                                                                   % Return empty for pupil size
    Eye.Volts   = []; 
    Eye.Pixels  = [EyeX, EyeY];                                                         
    Eye.PixCntr = Eye.Pixels-Params.Display.Rect([3,4])/2;                              % Center coordinates
    Eye.Degrees = Eye.Pixels./Params.Display.PixPerDeg;                                 % Convert pixels to degrees
end

if Eye.Pixels(1) > Params.Display.Rect(3)                               % If gaze cursor is entering monkey's display...
    HideCursor;                                                         % Turn cursor off!
else                                                                    % Otherwise, mouse is on an experimenter display
    ShowCursor;                                                         % Show cursor
end