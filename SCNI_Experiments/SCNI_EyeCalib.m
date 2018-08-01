function Params = SCNI_EyeCalib(Params)

%=========================== SCNI_EyeCalib.m ==============================
% This function runs an eye position calibration routiune by intermittently
% presenting a fixation marker either centrally or at one of 8 peripheral
% locations. Through manual input by teh experimenter, or via statistical
% analysis, values are calculated to convert the raw eye position voltages
% into scree-centered coordinates (pixels and degrees of visual angle).
%
%==========================================================================



%============= Initialize Eye Calibration
Params.Eye.Cal.CalibFile = fullfile('SCNI_calib.mat');
load(Params.Eye.Cal.CalibFile)

Params.Eye.Cal 	= SCNI_ManualCalibration(Params.Eye.Cal);        	% Open manual calibration GUI window
Params.Eye.Cal  = SCNI_GenerateCalTargets(Params.Eye.Cal);        	% Generate target locations


c.Stim_Diameter = c.Fix_MarkerSize;     

c = SCNI_InitScreenCoords(c);           % Calculate screen coordinates

%================= Draw fixation marker to texture
FixSize         = round(c.Fix_MarkerSize*c.Display.PixPerDeg);
FixIm           = zeros(FixSize(1)+2, FixSize(2)+2, 4);
c.FixTexture    = Screen('MakeTexture', c.window, FixIm); 
FixRect         = [0,0,FixSize];
switch c.Fix_Type
    case 0                                                          %============== FILLED CIRCLE
        Screen('FillOval', c.FixTexture, c.Fix_Color, [0,0,FixSize]);
    case 1                                                          %============== CROSS
        FixPos = [FixSize(1)/2, -FixSize(2)/2, 0, 0; 0, 0, FixSize(1)/2, -FixSize(2)/2];        % Specify line positions
        Screen('FillOval', c.FixTexture, c.Col_bckgrndRGB, [0,0,FixSize]);                      % Draw filled circle same color as background
        Screen('DrawLines', c.FixTexture, FixPos, c.Fix_LineWidth, c.Fix_Color, FixSize/2);     % Draw cross in center
    case 2                                                          %============== SOLID SQUARE
        Screen('FillRect', c.FixTexture, c.Fix_Color, [0,0,FixSize]);
    case 3                                                          %============== BINOCULAR CROSSHAIRS
        FixPos = [FixSize(1)/2, FixSize(2)/4, 0, 0; 0, 0, FixSize(1)/2, FixSize(2)/4];
        Screen('DrawLines', c.FixTexture, FixPos, c.Fix_LineWidth, c.Fix_Color, FixSize/2);
        Screen('FrameRect', c.FixTexture, c.Fix_Color, CenterRect([0 0 FixSize]/2, FixRect), c.Fix_LineWidth);
end










    %=========== Draw to monkey's screen
    Screen('FillRect', c.window, c.Col_bckgrndRGB);                                         % Clear previous frame
    for e = 1:size(c.MonkeyFixRect{1},1)
        Screen('DrawTexture', c.window, c.FixTexture, [], c.MonkeyFixRect{s.CondNo}(e,:));	% Draw fixation marker
    end
