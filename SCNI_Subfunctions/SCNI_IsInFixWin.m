%=========================== SCNI_IsInFixWin.m ============================
% Check gaze position coordinates (pixels) relative to circular or rectangular 
% fixation window. 
%
% INPUTS:   EyeXY:      1x2 vector specifying eye position in pixels
%           TargetXY:   1x2 vector specifying target location in pixels
%           Shape:      flag: 0 = circular ROI; 1 = rectangular ROI; 
%           Params:     Full SCNI Params structure.
%
%==========================================================================

function [inside, distance] = SCNI_IsInFixWin(EyeXY, TargetXY, shape, Params)

    if isempty(TargetXY)                            % If target coordinates were not provided...                       
        TargetXY = Params.Display.Rect([3,4])/2;  	% Calculate eye position relative to center of screen
    end
    if isempty(shape)
        shape = 0;
    end
    rect    = Params.Eye.GazeRect;                  % Gaze window rectangle
    DiffXY  = EyeXY - TargetXY;                     % Calculate distance between eye and target
         
    switch shape
        case 1  %========= Rectangular ROI
            if (EyeXY(1) >= rect(RectLeft) && EyeXY(1) <= rect(RectRight) && ...
                    EyeXY(2) >= rect(RectTop) && EyeXY(2) <= rect(RectBottom) )
                inside = 1;
            else
                inside = 0;
            end
            
        case 0  %========= Circular ROI
            if sqrt(sum(DiffXY.^2)) > diff(rect([RectLeft, RectRight]))/2
                inside = 0;
            elseif sqrt(sum(DiffXY.^2)) <= diff(rect([RectLeft, RectRight]))/2
                inside = 1;
            end
    end
    distance = sqrt(sum((DiffXY./Params.Display.PixPerDeg).^2));    % Distance in degrees
end