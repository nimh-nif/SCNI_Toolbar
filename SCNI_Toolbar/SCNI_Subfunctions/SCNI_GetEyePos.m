function [EyeX, EyeY] = SCNI_GetEyePos(Params)

%============================ SCNI_GetEyePos ==============================
% This function returns the subject's current eye position in screen
% coordinates (pixels), for checking fixations and plotting gaze online. 
%

if ~isfield(Params, 'Eye')
    Params.Eye.UseMouse = 1;
end

if Params.Eye.UseMouse == 0                                                     %============= Use
    [EyeX, EyeY, V]     = GetEyePix(c);                                         % Get instantaneous eye position
    EyeChannels         = Params.DPx.ADCchannelsUsed([1,2]);
    Datapixx('RegWrRd');                                                        % Update registers for GetAdcStatus
    status = Datapixx('GetAdcStatus');          
    Datapixx('RegWrRd');                                                        % Update registers for GetAdcStatus
    V       = Datapixx('GetAdcVoltages');                                       % Read ADC voltages for all channels                
    Datapixx('RegWrRd'); 
    DVA     = (V(Params.Eye.DPxChannels)+ Params.Eye.Offset).*Params.Eye.Gain;  % Convert volts into degrees of visual angle
    EyeX    = Params.Display.Rect(3)/2 + DVA(1)*Params.Display.PixPerDeg(1);    % Convert degrees to pixels (sign change in X to account for camera invertion?)
    EyeY    = Params.Display.Rect(4)/2 + DVA(2)*Params.Display.PixPerDeg(2);      
    EyeXc   = EyeX - Params.Display.Rect(3)/2;
    EyeYc   = EyeY - Params.Display.Rect(4)/2;
    
elseif Params.Eye.UseMouse == 1                                             %============= Use mouse cursor to simulate eye position
    [EyeX, EyeY, buttons] = GetMouse(Params.Display.win);                   % Get mouse cursor position (relative to subject display)
    EyeXc                 = EyeX-Params.Display.Rect(3)/2;                  % Find pixel location relative to center of experimenter display
    EyeYc                 = EyeY-Params.Display.Rect(4)/2;                
    if EyeX > Params.Display.Rect(3) && EyeX < 2*Params.Display.Rect(3)     % If mouse cursor is entering monkey's display...
        HideCursor;                                                         % Turn cursor off!
    else                                                                    % Otherwise, mouse in on an experimenter display
        ShowCursor;                                                         % Show cursor
    end
end