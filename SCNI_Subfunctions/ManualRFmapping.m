%=========================== ManualRFmapping ==============================
% This function presents a specified stimulus on the screen at coordinates
% determined by the mouse pointer location. The additional controls are:
%
% INPUT: Offset:    [x, y] offset of fixation marker from center of screen
%                   (degrees). E.g. if recording from the RIGHT LGN, use a
%                   negative x offset to increase maximum eccentricity in
%                   the contralateral hemifield.
%
% MOUSE CONTROLS:
%   Left click:     toggle stimulus on/ off
%   Middle click:   print current stimulus parameters to command line
%   Right click:    toggle stimulus + fixation on/off
%
% KEYBOARD CONTROLS;
%   'm'         toggle stimulus motion on/ off
%   'e'         toggle eye of presentation (left, right, both)
%   'f'         toggle fixation marker and stimulus on/off
%   'r'         rotate stimulus in 45 degree increments
%   'Esc'       exit experiment
%   left arrow 	decrease stimulus speed
%   rigth arrow	increase stimulus speed
%   up arrow    increase stimulus size
%   down arrow  decrease stimulus size
%
% REFERENCES:
%   (Derrington & Lennie 1984)
%
%==========================================================================

function ManualRFmapping(Offset)

global Key Exit Pointer Fix Params Display
if nargin == 0
    Offset = [0 0];
end
addpath('P:/murphya/APMSubfunctions');
Stereo  = 0;
Display = DisplaySettings(Stereo);



%==================== SET PARAMETERS
Pointer.On          = 1;
Pointer.Type        = 1;                                            % 1 = Gabor; 2 = Checkboard noise; 3 = solid dot
Pointer.Colors    	= [255 255 255; 0 0 0];
Pointer.ColorIndx   = 0;
Pointer.AutoScale   = 1;                                            % Automatically scale stimulus diameter with eccentricity?
Pointer.Sequence.On  = 0;
Pointer.Alpha       = 0.5;                                          % Minimum stimulus diameter (degrees)
Pointer.Beta        = 0.2;                                          % Coefficient
Pointer.BetaInc     = 0.05;                                         % Increment of change in beta coefficient
Pointer.Diameter    = 1*Display.Pixels_per_deg(1);                  % Default stimulus diameter when autoscaling is turned off       
Pointer.SourceRect  = [0 0 Pointer.Diameter Pointer.Diameter];      
Pointer.AllEyes     = {[1],[2],[1,2]};
Pointer.Eye        	= 3;                                            % 
Pointer.RectInc     = 0.1*Display.Pixels_per_deg(1);                % Step size of stimulus diameter increase
Pointer.LastToggle  = GetSecs;
Pointer.Angle       = 0;                                            
Pointer.Motion      = 0;                                            % Toggle stimulus motion on/ off
Pointer.MaxDuration = [];%0.3;                                      % Duration stimulus appears for on each mouse click. Leave empty to control stimulus offset with mouse click
Pointer.OnsetTime   = GetSecs;
Exit                = 0;

Params.BackgroundNo = 0;
Params.AllBackgrounds = [0, 0, 0; 127 127 127];
Params.Background  	= [127 127 127];
Display.Background  = Params.Background;

Pointer.Sequence.Started    = 0;
Pointer.Sequence.Duration   = 0.3;
Stim.Eccentricities         = [0.8 2.2 4 6.5 10];       % Set eccentiricities of stimulus centers (deg)
Stim.NoPolarAngles          = [4 8 12 14 16];          	% Set the number of polar angles for each eccentricity
Stim.Disparities            = [-10,-5,0,5,10];          % Set the binocular disparities (arcmin) 
Stim.NoDirections           = 1;
for e = 1:numel(Stim.Eccentricities)
    Stim.PolarAngles{e} = 0:(360/Stim.NoPolarAngles(e)):(360-(360/Stim.NoPolarAngles(e)));
    x = 1+sum(Stim.NoPolarAngles(1:e-1));
    Indx = x:(x+Stim.NoPolarAngles(e)*Stim.NoDirections-1);
    Stim.Variables(Indx,1) = Stim.Eccentricities(e);
    for p = 1:Stim.NoPolarAngles(e)
        x = 1+sum(Stim.NoPolarAngles(1:e-1))+((p-1)*Stim.NoDirections);
        Indx = x:(x+Stim.NoDirections-1);
        Stim.Variables(Indx,2) = Stim.PolarAngles{e}(p);
    end
end
if Stereo == 1
  for d = 1:numel(Stim.Disparities)
    DispOffset(d) = Stim.Disparities(d)/60*Display.Pixels_per_deg/2;    % Convert disparity from arcmin to pixels
  end
end


%=================== SET PHOTODIODE TARGET
Photodiode.On       = 1;                              	% Photodiode target defaults to 'on'
Photodiode.Diameter = 0.018*Display.Pixels_per_m(1); 	% size of target (pixels)
Photodiode.Position = 1;                                % bottom left corner (2 = bottom right corner)
if Photodiode.On == 0
    Photodiode.OnColour     = Display.Background;
    Photodiode.OffColour    = Display.Background;             
elseif Photodiode.On == 1
    Photodiode.OffColour    = [128 128 128];
    Photodiode.OnColour     = [0 0 0];   
end
Photodiode.Rect{1} = [Display.Rect(1),Display.Rect(4)-Photodiode.Diameter, Display.Rect(1)+Photodiode.Diameter, Display.Rect(4)];   % Bottom LEFT for RIGHT eye
Photodiode.Rect{2} = [Display.Rect(3)-Photodiode.Diameter,Display.Rect(4)-Photodiode.Diameter, Display.Rect(3), Display.Rect(4)];   % Bottom RIGHT for LEFT eye
    
%================== DEFINE MATLAB KEYBOARD INPUTS
KbName('UnifyKeyNames');
Key.Exit        = KbName('Escape');
Key.AutoScale	= KbName('a');
Key.Sequence    = KbName('s');
Key.Eye         = KbName('e');
Key.ToggleMov   = KbName('m');
Key.Rotate      = KbName('r');
Key.FixOn     	= KbName('f');
Key.FixMove   	= KbName('x');
Key.Background 	= KbName('b');
Key.BlobColor   = KbName('c');
Key.SizeInc     = KbName('uparrow');
Key.SizeDec     = KbName('downarrow');
Key.SpeedInc    = KbName('rightarrow');
Key.SpeedDec    = KbName('leftarrow');
Key.MinInterval = 0.2;
Key.LastPress   = GetSecs;


%==================== PREPARE PTB WINDOWS AND TEXTURES
HideCursor;                                                                                                                             % Make mouse pointer invisible
%ListenChar(2);                                                                                                                          % Block keyboard input to command line
PsychImaging('PrepareConfiguration');                                                                                                   % Setup psychimaging pipeline
Screen('Preference', 'VisualDebugLevel', 1);                                                                                          	% Make initial screen black instead of white
% [Display.win, Display.Rect] = PsychImaging('OpenWindow', Display.ScreenID, Params.Background(1), [], [], [], Display.Stereomode);       % Open PTB window
[Display.win, Display.Rect] = Screen('OpenWindow', Display.ScreenID, Params.Background(1), [], [], [], Display.Stereomode);       % Open PTB window
Display.IFI = Screen('GetFlipInterval', Display.win);                                                                                   % Get inter-frame interval
Priority(MaxPriority(Display.win));                                                                                                   	% Make PTB top priority level
Screen('BlendFunction', Display.win, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);                                                             % Enable alpha channel

%==================== PREPARE FIXATION MARKER
Fix.On          = 1;
Fix.Type       	= 1;
Fix.Size      	= 0.5*Display.Pixels_per_deg(1);
Fix.PosIndx     = 1;
Fix.Pos         = [0,0; -12,-10; -12,0; -12, 10];
Fix.Offset     	= Offset.*Display.Pixels_per_deg;
Fix.Rect        = ceil([0 0 Fix.Size Fix.Size]);
Fix.DestRect    = CenterRect(Fix.Rect, Display.Rect)+[Fix.Offset Fix.Offset];
Fix.Background  = ones(ceil(Fix.Size), ceil(Fix.Size), 4)*Display.Background(1);
Fix.Background(:,:,4) = 0;
Fix.LineWidth   = 3;
Fix.Colour      = [255 255 255 255];
Fix.Texture 	= Screen('MakeTexture', Display.win, Fix.Background);                         
switch Fix.Type
    case 0                                                          %============== FILLED CIRCLE
        Screen('FillOval', Fix.Texture, [Fix.Colour, 255], Fix.Rect);
    case 1                                                          %============== CROSS
        Fix.Position = [Fix.Size/2, -Fix.Size/2, 0, 0; 0, 0, Fix.Size/2, -Fix.Size/2];
        Screen('FillOval', Fix.Texture, [Display.Background 255], Fix.Rect);
        Screen('DrawLines', Fix.Texture, Fix.Position, Fix.LineWidth, Fix.Colour, [Fix.Size/2, Fix.Size/2]);
end

%==================== PREPARE TARGET TXTURE
if Pointer.Type == 1
    Gabor.Speed         = 180;       % drift speed (degrees/ second)
    Gabor.CyclesPerDeg  = 5;        % number of cycles of sinusoid per degree
    Gabor.Sigma         = 0.5;      % standard deviation of the Gaussian envelope (degrees)
    Gabor.Dimensions	= 2;        % dimensions of stimulus texture (degrees)
    Gabor.Capture       = 0;
    Gabor.Background	= Params.Background(1);
    PTB                 = 1;
    Pointer.Textures    = GenerateDriftingGabor(Gabor, Display, PTB);
elseif Pointer.Type == 2
    NoTextels                   = 10;
    NoFrames                    = 10;
    for f = 1:NoFrames
        Checkerboard            = round(rand(NoTextels))*255;
        Checkerboard            = repmat(Checkerboard, [1,1,3]);
        Pointer.Textures{f} 	= Screen('MakeTexture', Display.win, Checkerboard);
    end
end
f	= 1;
Pointer.Polar = 0;

%==================== RUN EXPERIMENT
while Exit == 0
    
    if Pointer.Sequence.On == 0              %==================== CHECK MOUSE INPUT
        [x,y,buttons] = GetMouse(Display.win);
        if any(buttons) && Pointer.LastToggle < GetSecs-Key.MinInterval;
            if buttons(1)
                Pointer.On = ~Pointer.On;
                if Pointer.On == 1
                    Pointer.OnsetTime = FrameOnset;
                end
            elseif buttons (2)
                fprintf('\nEccentricity \t= %.2f deg\nDiameter \t\t= %.2f deg\nPolar angle \t= %.2f deg\nOrientation \t= %d deg\nMotion \t\t\t= %.2f deg/s\n', Pointer.Eccentricity/Display.Pixels_per_deg(1), Pointer.Diameter/Display.Pixels_per_deg(1), Pointer.Polar, Pointer.Angle, Pointer.Motion);
            elseif buttons(3)
                Fix.On = ~Fix.On;
            end
            Pointer.LastToggle = GetSecs;
        end
        Pointer.Eccentricity    = sqrt((x-Display.Centre(1)-Fix.Offset(1))^2 + (y-Display.Centre(2)-Fix.Offset(2))^2);
        if (y-Display.Centre(2)-Fix.Offset(2)) > 0
          Pointer.Polar           = asind((x-Display.Centre(1)-Fix.Offset(1))/(y-Display.Centre(2)-Fix.Offset(2)));
        else
          Pointer.Polar           = asind((x-Display.Centre(1)-Fix.Offset(1))/(abs(y)-Display.Centre(2)-Fix.Offset(2)));
        end
        
    %     Pointer.Diameter    = exp((Pointer.Beta*Pointer.Eccentricity) + Pointer.Alpha);
        if Pointer.AutoScale == 1
            Pointer.Diameter    = (Pointer.Beta*Pointer.Eccentricity) + (Pointer.Alpha*Display.Pixels_per_deg(1));
            Pointer.SourceRect  = [0 0 Pointer.Diameter Pointer.Diameter];
        end
        Pointer.DestRect = CenterRectOnPoint(Pointer.SourceRect, x, y);
        if ~isempty(Pointer.MaxDuration)
            if Pointer.On == 1 && GetSecs >= Pointer.OnsetTime+Pointer.MaxDuration
                Pointer.On = ~Pointer.On;
            end
        end
        
    elseif Pointer.Sequence.On == 1              %==================== IGNORE MOUSE INPUT
        if Pointer.Sequence.Started == 0
            Pointer.Sequence.Started    = 1;
            Pointer.Sequence.LocationNo = 1;
            Pointer.Sequence.StartTime  = GetSecs;
        end
        x = Stim.Variables(Pointer.Sequence.LocationNo, 1)*Display.Pixels_per_deg(1)*sind(Stim.Variables(Pointer.Sequence.LocationNo, 2))+Display.Centre(1);
        y = Stim.Variables(Pointer.Sequence.LocationNo, 1)*Display.Pixels_per_deg(1)*cosd(Stim.Variables(Pointer.Sequence.LocationNo, 2))+Display.Centre(2);
        Pointer.DestRect = CenterRectOnPoint(Pointer.SourceRect, x, y);
        if GetSecs > Pointer.Sequence.StartTime+Pointer.Sequence.Duration
            Pointer.Sequence.LocationNo = Pointer.Sequence.LocationNo+1;
            Pointer.Sequence.StartTime  = GetSecs;
            if Pointer.Sequence.LocationNo > size(Stim.Variables, 1)
                Pointer.Sequence.On     	= 0;
                Pointer.Sequence.Started	= 0;
            end
        end
    end
        
    
    %==================== DRAW NEXT FRAME
    for Eye = 1:2
        currentbuffer = Screen('SelectStereoDrawBuffer', Display.win, Eye-1);  
        Screen('FillRect', Display.win, Params.Background);                                     % Clear screen
        if Fix.On == 1
            Screen('DrawTexture', Display.win, Fix.Texture, Fix.Rect, Fix.DestRect);            % Draw fixation marker
            if ismember(Eye, Pointer.AllEyes{Pointer.Eye}) && Pointer.On == 1                                                
                Screen('FillOval', Display.win, Photodiode.OnColour, Photodiode.Rect{Eye});     % Draw photodiode marker
                if Pointer.Type < 3
                    Screen('DrawTexture', Display.win, Pointer.Textures{f}, [], Pointer.DestRect, Pointer.Angle);
                elseif Pointer.Type == 3
                     Screen('FillOval', Display.win,Pointer.Colors(Pointer.ColorIndx+1,:), Pointer.DestRect);
                end
            else
                Screen('FillOval', Display.win, Photodiode.OffColour, Photodiode.Rect{Eye});  	% Draw photodiode marker
            end
        else
            Screen('FillOval', Display.win, Photodiode.OffColour, Photodiode.Rect{Eye});        % Draw photodiode marker
        end
    end
    Screen('DrawingFinished', Display.win, 1);                                                  % Let PBT know that drawing is completed
    FrameOnset = Screen('Flip', Display.win);
    CheckPress
    if Pointer.Motion == 1
        f = f+1;
        if f > numel(Pointer.Textures)
            f = 1;
        end
    end
end

%==================== END TEST
ShowCursor;
ListenChar(0);
Screen('CloseAll');

end


function CheckPress
global Key Exit Pointer Fix Params Display
[keyIsDown,secs,keyCode] = KbCheck;                                                 % Check if a key is currently pressed 
    if keyIsDown && secs > Key.LastPress+Key.MinInterval
     	Key.LastPress = secs;
        if keyCode(Key.Exit) == 1                                                     	% If the key was 'Esc'...
            Exit = 1;
        elseif keyCode(Key.Eye) == 1
            Pointer.Eye = Pointer.Eye+1;
            if Pointer.Eye > numel(Pointer.AllEyes)
                Pointer.Eye = 1;
            end
        elseif keyCode(Key.SizeInc) == 1
            if Pointer.AutoScale == 0
              Pointer.SourceRect = Pointer.SourceRect+[0 0 Pointer.RectInc Pointer.RectInc];
            elseif Pointer.AutoScale == 1
              Pointer.Beta = Pointer.Beta+Pointer.BetaInc;
            end
        elseif keyCode(Key.SizeDec) == 1
            if Pointer.AutoScale == 0
              Pointer.SourceRect = Pointer.SourceRect-[0 0 Pointer.RectInc Pointer.RectInc];
            elseif Pointer.AutoScale == 1
              Pointer.Beta = Pointer.Beta-Pointer.BetaInc;
            end
        elseif keyCode(Key.ToggleMov) == 1
            Pointer.Motion = ~Pointer.Motion;
        elseif keyCode(Key.Rotate) == 1
            Pointer.Angle = Pointer.Angle+45;
        elseif keyCode(Key.FixOn) == 1
            Fix.On = ~Fix.On;
        elseif keyCode(Key.FixMove) == 1
            Fix.PosIndx = Fix.PosIndx+1;
            if Fix.PosIndx > size(Fix.Pos,1), Fix.PosIndx = 1; end
            Fix.Offset      = Fix.Pos(Fix.PosIndx,:).*Display.Pixels_per_deg;
            Fix.DestRect    = CenterRect(Fix.Rect, Display.Rect)+[Fix.Offset Fix.Offset];
        elseif keyCode(Key.AutoScale) == 1
            Pointer.AutoScale = ~Pointer.AutoScale;
        elseif keyCode(Key.Sequence) == 1
            Pointer.Sequence.On = ~Pointer.Sequence.On;
        elseif keyCode(Key.BlobColor) == 1
            Pointer.ColorIndx = ~Pointer.ColorIndx;
        elseif keyCode(Key.Background) == 1
            Params.BackgroundNo = ~Params.BackgroundNo;
            Params.Background = Params.AllBackgrounds(Params.BackgroundNo+1,:);
        end
    end
end