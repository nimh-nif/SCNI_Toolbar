 function [PDS, c, s] = SCNI_Movie_init(PDS, c, s)

%======================= Initialization function ==========================
% This is executed only once, after the settings file is loaded by pressing 
% the 'Initialize' button in the GUI. This is where values are defined for 
% the entire experiment.
%
% HISTORY:
%   2017-01-23 - Written by murphyap@mail.nih.gov based on psychmetic_init.m
%   
%     ____    ___ __  _______
%    /    |  /  //  //  ____/    Neuro Imaging Facility Core
%   /  /| | /  //  //  /___      Building 49 Convent Drive
%  /  / | |/  //  //  ____/      NATIONAL INSTITUTES OF HEALTH
% /__/  |____//__//__/          
%==========================================================================

%% ============== Load SCNI viewing geometry parameters
temp                = SCNI_DisplaySettings([],0);           % Load display parameters
c.Display           = temp.Display;                         
c.Display.gamma     = 2.2;                                  % Set gamma value
c.OverlayMode       = 'PTB';                                % Options are 'M16','L48','PTB'. Use 'PTB' is video is NOT going through the DataPixx
c.UseDataPixx       = 1;                                    % Use DataPixx2 box for analog/ digital I/O?
c.EventCodes        = SCNI_LoadEventCodes;               	% Load SCNI event codes
c.TDT.Enabled       = 1;

%% ============= Initialize calibration settings
c.SimulateEyes      = 0;            % Use mouse cursor position to simulate eye position?
c.LoadDefaultCal    = 0;            % Load the default calibration parameters file, or ask user to specify calibration file?
if c.LoadDefaultCal == 1 
    c.CalibrationFile = fullfile('NIF_calib.mat');
else
    [file,path] = uigetfile('*_calib.mat', 'Select calibration parameters file');
    c.CalibrationFile = fullfile(path, file);
end
load(c.CalibrationFile)
c.Cal           = Cal;
c.EyeGain       = Cal.EyeGain;
c.EyeOffset     = Cal.EyeOffset;

%% ============= Initialize DataPixx
c               = init_DataPixx(c);
c.RestartDataPixx = 1;

%% ======================= Settings for block design ======================
% One 'run' consists of multiple 'blocks'. Each block contains just one
% condition or stimulus class, but many individual stimuli. These should be
% stored in separate folders and the full paths specified in the cell array 
% 'c.StimDir'. 'c.BckgrndDir' is an optional array of paths to corresponding
% images to be drawn as background for images with transparency (e.g. pink
% noise/ Fourier scrambled background to cropped object/ face images).

if ismac
    Append = '/Volumes/projects';
elseif IsWin
    Append = 'P:\';
elseif IsLinux
    Append = '/projects';
end

if IsOSX == 1
    c.SaveDir       = fullfile('/Volumes/rawdata/murphya/fMRI/Behaviour/');   % Full path to save Matlab data to
elseif IsLinux == 1
%      c.SaveDir       = fullfile('/rawdata/murphya/fMRI/Behaviour/'); 
    c.SaveDir       = fullfile('/projects/murphya/fMRI/Behaviour/');      	% <<<<<< TEMPORARY fix for lack of write permissions in Rawdata
end
c.FilePrefix    = sprintf('%s_%s', datestr(now,'yyyymmdd'), mfilename);     % File prefix
c.Matfilename   = fullfile(c.SaveDir, [c.FilePrefix, '_1.mat']);
if ~exist(c.SaveDir, 'dir')                                                 % If save path doesn't exit, create it
    mkdir(c.SaveDir);
end

%% ================= Prepare experimenter display components
c.BlockImg      = ones([100,200]).*255;                                                         % Create blank background
c.BlockImgRect  = [100, c.Display.Rect(4)-100, 600, c.Display.Rect(4)-50];                      % Specify onscreen position to draw block design
c.BlockImgLen   = c.BlockImgRect(3)-c.BlockImgRect(1);                                          % Calculate length of block design rect
c.BlockImgTex   = Screen('MakeTexture', c.window, c.BlockImg);                                  % Generate texture handle for block design image
ProgOverlay     = zeros(size(c.BlockImg));                                                      % Generate a dark progress bar to overlay on block design
ProgOverlay(:,:,4) = 127;                                                                       % Set progress bar overlay opacity (0-255)
c.BlockProgTex  = Screen('MakeTexture', c.window, ProgOverlay);                                 % Create a texture handle for overlay

%% ================= Calculate screen coordinates
c.Stim_Fullscreen   = c.Movie.Fullscreen;
c.Stim_Diameter     = c.Movie.Rect(1);
c                   = SCNI_InitScreenCoords(c);

%% ================= Draw fixation marker to texture
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

%========== Prepare grid for experimenter display
CircleSpacing   = c.Display.Exp.GridSpacing*c.Display.PixPerDeg;     	% Increase in diameter with each concentric circle
NoCircles       = floor(c.Display.Rect(3)/CircleSpacing(1));          	% Caclulate number of circles to fill screen width
c.BullsEyeWidth = 1;                                                    % Pen width for bulls eye lines (pixels)
for circleno = 1:NoCircles
    CircleDiameter(circleno,:)  = CircleSpacing*circleno;               
    c.Bullseye(:,circleno)      = CenterRect([0,0,CircleDiameter(circleno,:)], c.Display.ExpRect)'; 
end
c.Meridians     = [c.Display.ExpRect([3,3])/2, 0, c.Display.ExpRect(3); 0, c.Display.ExpRect(4), c.Display.ExpRect([4,4])/2];
c.TextBoxDims   = [300 200];
c.TextPos       = 'TopLeft';
if c.Display.UseSBS3D == 1
	c.LoadingTextPosX = c.Display.ExpRect(3)/2;
else
    c.LoadingTextPosX = 'center';
end
if c.Display.Rect(3) > 1920
   Screen('TextSize', c.window, 60);
end
switch c.TextPos
    case 'TopLeft'
        c.TextRect      = [100, 100, [100, 100]+[c.TextBoxDims]];   
    case 'BottomRight'
        c.TextRect      = [c.Display.ExpRect([3,4])-[c.TextBoxDims], c.Display.ExpRect([3,4])];   
end

%========== Preapre photodiode marker
if c.PhotodiodeOn == 1
    if IsLinux == 1                                                                                  % If using dual displays on Linux...
        if c.Display.UseSBS3D == 0  
             switch c.PhotodiodePos
                case 'BottomLeft'
                    c.ExpDiodeRect      = c.PhotdiodeSize + c.Display.Rect([1,4,1,4]) - c.PhotdiodeSize([1,4,1,4]);
                    c.MonkeyDiodeRect   = c.PhotdiodeSize + c.Display.Rect([3,4,3,4]) - c.PhotdiodeSize([1,4,1,4]);	% Specify subject's portion of the screen 
                case 'TopLeft'
                    c.ExpDiodeRect      = c.PhotdiodeSize;
                    c.MonkeyDiodeRect   = c.PhotdiodeSize + c.Display.Rect([3,1,3,1]);
                case 'TopRight'
                    c.ExpDiodeRect      = c.PhotdiodeSize + c.Display.Rect([3,1,3,1]) - c.PhotdiodeSize([3,2,3,2]);
                  	c.MonkeyDiodeRect   = c.PhotdiodeSize + c.Display.Rect([3,1,3,1]).*[2,1,2,1] - c.PhotdiodeSize([3,2,3,2]);
             	case 'BottomRight'
                    c.ExpDiodeRect      = c.PhotdiodeSize + c.Display.Rect([3,4,3,4]) - c.PhotdiodeSize([3,4,3,4]);
                  	c.MonkeyDiodeRect   = c.PhotdiodeSize + c.Display.Rect([3,4,3,4]).*[2,1,2,1] - c.PhotdiodeSize([3,4,3,4]);
            end
        elseif c.Display.UseSBS3D == 1                                                                              % For presenting side-by-side stereoscopic 3D images...
            c.ExpDiodeRect          = c.PhotdiodeSize + c.Display.Rect([1,4,1,4]) - c.PhotdiodeSize([1,4,1,4]);
            c.MonkeyDiodeRect(1,:)  = (c.PhotdiodeSize./[1,1,2,1]) + c.Display.Rect([3,1,3,1]) + c.Display.Rect([1,4,1,4]) - c.PhotdiodeSize([1,4,1,4]);         	% Center a horizontally squashed fixation rectangle in a half screen rectangle
            c.MonkeyDiodeRect(2,:)  = (c.PhotdiodeSize./[1,1,2,1]) + c.Display.Rect([3,1,3,1])*1.5 + c.Display.Rect([1,4,1,4]) - c.PhotdiodeSize([1,4,1,4]);         
        end
    elseif c.LinuxDisplay == 0                            
        c.MonkeyDiodeRect  = c.MonkeyDiodeRect;     
    end
end


%========== Preapre experimenter keyboard controls
KbName('UnifyKeyNames')                                             
c.Key_Exit    = KbName(c.Exit_Key);                                             % Set 'Esc' key to allow user to abort during file loading loop
c.Key_Reward  = KbName(c.Reward_Key);


%% ===================== Initialize movie handle =========================
% [c.mov, c.Movie.duration,  c.Movie.fps,  c.Movie.width,  c.Movie.height,  c.Movie.count,  c.Movie.AR]= Screen('OpenMovie', c.window, c.Movie.Filename); 
% c.Movie.StartTime   = 1;
% c.Movie.FrameNumber = 1;
% % Screen('PlayMovie',c.mov,1);
% % Screen('SetmovieTimeIndex',c.mov, c.Movie.StartTime,0);  
% c.Movie.SourceRect{2} = [0 0 c.Movie.width, c.Movie.height];
% 
% if c.Movie.MaintainAR == 0
% 	if c.Movie.Fullscreen == 1
%         c.Movie.DestRect = c.Display.Rect;
%     elseif c.Movie.Fullscreen == 0
%         c.Movie.DestRect = [0 0 MovieDims]*c.Display.PixPerDeg(1);
%     end
% elseif c.Movie.MaintainAR == 1
%     if c.Movie.Fullscreen == 1
%         c.Movie.WidthDeg = c.Display.Rect(3);
%     else
%         c.Movie.WidthDeg = c.Movie.Rect(1)*c.Display.PixPerDeg(1);
%     end
%     c.Movie.DestRect = (c.Movie.SourceRect{2}/c.Movie.width)*c.Movie.WidthDeg;
% end
% if ~isempty(find(c.Movie.DestRect > c.Display.Rect))
%     c.Movie.DestRect = c.Movie.DestRect*min(c.Display.Rect([3, 4])./c.Movie.Rect([3, 4]));
%     fprintf('Requested movie size > screen size! Defaulting to maximum size.\n');
% end
% c.Movie.MonkeyDestRect  = CenterRect(c.Movie.DestRect, c.Display.Rect)+c.Display.Rect([3,1,3,1]);
% c.Movie.ExpDestRect     = CenterRect(c.Movie.DestRect, c.Display.Rect);
% if c.Movie.Stereo == 1
%     if strcmpi(c.Movie.Format3D, 'LR')          % Horizontal split screen
%         c.Movie.SourceRect{1} = c.Movie.SourceRect{2}./[1 1 2 1];
%         c.Movie.SourceRect{2} = c.Movie.SourceRect{1}+[c.Movie.SourceRect{1}(3),0, c.Movie.SourceRect{1}(3),0];     
%     elseif strcmpi(c.Movie.Format3D, 'RL')          
%         c.Movie.SourceRect{2} = c.Movie.SourceRect{2}./[1 1 2 1];
%         c.Movie.SourceRect{1} = c.Movie.SourceRect{2}+[c.Movie.SourceRect{2}(3),0, c.Movie.SourceRect{2}(3),0];  
%     elseif strcmpi(c.Movie.Format3D, 'TB')      % Vertical split screen
%         c.Movie.SourceRect{1} = c.Movie.SourceRect{2}./[1 1 1 2];
%         c.Movie.SourceRect{2} = c.Movie.SourceRect{1}+[0,c.Movie.SourceRect{1}(4),0, c.Movie.SourceRect{1}(4)];
%     else
%         fprintf('\nERROR: 3D movie format must be specified in filename!\n');
%     end
% else
%     c.Movie.SourceRect{1} = c.Movie.SourceRect{2};
% end
% 
% if c.Movie.Mirror == 1
%     SourceRect = c.Movie.SourceRect{1}.*[1 1 2 1];
% end
% c.GazeRect = c.Movie.ExpDestRect + [repmat(-c.Fix_WinBorder,[1,2]).*c.Display.PixPerDeg, repmat(c.Fix_WinBorder,[1,2]).*c.Display.PixPerDeg];
% 
% Screen('FillRect', c.window, c.Col_bckgrndRGB); 
% Screen('flip', c.window);
c.Movie.FrameNumber = 1;


% %% ====================== INITIALIZE AUDIO SETTINGS =======================
% Audio.On = 0;                                           % Play audio feedback tones/ movie sound?
% if Audio.On == 1
%     [Audio.Beep, Audio.Noise] = AuditoryFeedback([],1); 	% Generate tones
% %     if ~IsWin
% %         Speak('Audio initialized.');                    % Inform user that audio is ready
% %     elseif IsWin
% %         Audio.a = actxserver('SAPI.SpVoice.1');
% %         Audio.a.Speak('Audio initialized.');
% %     end
%     c.AudioBeep      = Audio.Beep(1);
%     c.AudioError     = Audio.Beep(2);
%     c.AudioPenalty   = Audio.Noise(1);
%     PsychPortAudio('Start', c.AudioBeep, 1);
% end

Screen('TextFont', c.window, 'Courier'); 
Screen('TextStyle', c.window, 1); 

%================ SAVE PARAMS TO MAT FILE
save(c.Matfilename, 'PDS','c','s');     % Create new matfile


    
 end


%% ========================= init_DataPixx ================================
function [c] = init_DataPixx(c)

switch c.OverlayMode
    case 'M16' %===========================================================
        % This version of init_DataPixx function is based on DataPixxM16Demo
        % and requires functions from the DataPixx toolbox (such as DataPixx.mex) 
        % that are included in PsychToolbox. To install, follow instructions 
        % provided here: http://www.vpixx.com/manuals/psychtoolbox/html/install.html. 
        %
        % 04/14/2017 - Written by APM

        AssertOpenGL;
        PsychImaging('PrepareConfiguration');
        PsychImaging('AddTask', 'General', 'FloatingPoint32Bit');
        PsychImaging('AddTask', 'General', 'EnableDataPixxM16OutputWithOverlay');
        PsychImaging('AddTask', 'FinalFormatting', 'DisplayColorCorrection', 'SimpleGamma');

        oldVerbosity    = Screen('Preference', 'Verbosity', 1);                                	% Don't log the GL stuff
        [c.window, c.screenRect]  = PsychImaging('OpenWindow',  c.Display.ScreenID, c.Col_background);
        Screen('Preference', 'Verbosity', oldVerbosity);
        PsychColorCorrection('SetEncodingGamma', c.window, 1/c.Display.gamma);                 	% Set gamma
        Screen('BlendFunction', c.window, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);                % Enable alpha channel

        % Ensure that the graphics board's gamma table does not transform our pixels
%         Screen('LoadNormalizedGammaTable', c.window, linspace(0, 1, 256)' * [1, 1, 1]);
        LoadIdentityClut(c.window);

        % DATAPixx overlay window can hold a seperate 255-colour image.  We'll use a blue ramp.
        c.overlay = PsychImaging('GetOverlayWindow', c.window);

        % We'll arbitrarily use full green as a CLUT's "transparent" color
        c.ExpOverlayColor   = [0,0,1];      % Color of anything that only the experimenter sees
        c.ExpOverlayColor2  = [1,0,0];      
        c.ExpOverlayIndx    = 248;
        c.ExpOverlayIndx2   = 253;
        c.SubOverlayColor   = [1,0,0];      % Color of anything that only the subject sees
        c.transparencyColor = [0,1,0];      % Arbitrary color for transparent pixels in overlay
        c.ColorSpan         = 4;            % Span of RGB values (0-256) to use for overlay

        Datapixx('Open');
        Datapixx('SetVideoClutTransparencyColor', c.transparencyColor);
        Datapixx('EnableVideoClutTransparencyColorMode');
        Datapixx('RegWr');

        % On some systems (Win?) LoadNormalizedGammaTable doesn't support 512 CLUT entries,
        % so we'll use our own CLUT load function.
        clutTestDisplay = repmat(c.transparencyColor, [256,1]);   % By default, all overlays are transparent
        clutConsoleDisplay = repmat(c.transparencyColor, [256,1]);   % By default, all overlays are transparent

        % ! ON WINDOWS, DrawFormattedText scales the color by 255/256, therefore
        % the color is off by 1 for the upper half of the CLUT 
        % On OS-X, DrawFormattedText seems to apply a grossly non-linear mapping
        % between the argument intensity and the actual draw intensity.
        % Other draw commands like DrawRect do not seem to show this bug.
        % For the purposes of this demo, we will draw the text in the center of a
        % 5-colour span, at the top of the 256-entry CLUT.
        % This seems to work for all systems tested so far.
        clutTestDisplay(242+(0:c.ColorSpan-1),:) = repmat(c.SubOverlayColor, [c.ColorSpan,1]);      % Items drawn with 255 show on test display as blue % FOR MAC
        %clutTestDisplay(252+(0:c.ColorSpan-1),:) = repmat([0, 0, 1], [c.ColorSpan,1]);              % Items drawn with 255 show on test display as blue % FOR MAC
        clutConsoleDisplay(c.ExpOverlayIndx-1+(0:c.ColorSpan-1),:) = repmat(c.ExpOverlayColor, [c.ColorSpan,1]);   % Items drawn with 255 show on test display as blue % FOR MAC
        clutConsoleDisplay(c.ExpOverlayIndx2-1+(0:c.ColorSpan-1),:) = repmat(c.ExpOverlayColor2, [c.ColorSpan,1]);	% Items drawn with 255 show on test display as blue % FOR MAC

        Datapixx('SetVideoClut', [clutTestDisplay;clutConsoleDisplay]);
        Screen('Preference', 'TextAntiAliasing', 0);                                                % Overlay looks best w/o antialiasing

    case 'L48' %===========================================================
        % This original version of INITDATAPIXX (from Krauzlis lab) intializes the DataPixx using 
        % 'L48' mode. Critically, the PSYCHIMAGING calls sets up the dual CLUTS
        % (Color Look Up Table) for two screens.  These two CLUTS are in the
        % condition file "c".

        PsychImaging('PrepareConfiguration');                 
%         PsychImaging('AddTask', 'General', 'NormalizedHighresColorRange'); %% <<< TEST
        PsychImaging('AddTask', 'General', 'FloatingPoint32Bit');                               % Configure PsychToolbox imaging pipeline to use 32-bit floating point numbers
        PsychImaging('AddTask', 'General', 'EnableDataPixxL48Output');                          % Enable overlay
        PsychImaging('AddTask', 'FinalFormatting', 'DisplayColorCorrection', 'SimpleGamma');    % Apply inverse gamma for correction of display gamma
        [c.window, c.screenRect] = PsychImaging('OpenWindow', c.Display.ScreenID, c.Col_background); 	% Open a PTB window
        Screen('BlendFunction', c.window, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);                % Enable alpha channel
        PsychColorCorrection('SetEncodingGamma', c.window, 1/c.Display.gamma);                 	% Set gamma
        
        c.combinedClut = [c.monkeyCLUT;c.humanCLUT];
        Screen('LoadNormalizedGammaTable', c.window, c.combinedClut, 2);                        % Load color look up table to VPixx
%         Screen('LoadNormalizedGammaTable', c.window, repmat(linspace(0,1,256)',1,3));       % Load identity CLUT to GPU
        % Screen('LoadNormalizedGammaTable', c.window, repmat(linspace(0,1,256)',1,3),2);     % Load identity CLUT to VPixx

        %=========== Added for consistency with M16 mode
        c.L48background     = 1;
        c.ExpOverlayColor   = [0,0,1];      % Color of anything that only the experimenter sees
        c.ExpOverlayColor2  = [1,0,0];      
        c.ExpOverlayIndx    = 248;
        c.ExpOverlayIndx2   = 253;
        c.SubOverlayColor   = [1,0,0];      % Color of anything that only the subject sees
        c.transparencyColor = [0,1,0];      % Arbitrary color for transparent pixels in overlay
        
    case 'PTB'  %==========================================================
        % This final mode is a last resort effort to draw full color stimuli
        % with an experimenter 'overlay'. Instead of using an overlay, we
        % actually set the two DataPixx screens to act as a single screen,
        % and draw separately into each half of that screen, as we do for 
        % haploscopes.
        c = SCNI_InitPTBwin(c);
        
    otherwise
        error('Unrecognized DataPixx/ PTB overlay mode ''%s''!', OverlayMode);
end

%===================== PREPARE DATAPIXX DAC
if c.UseDataPixx == 1
    c = SCNI_DataPixxInit([],c);
end


end
