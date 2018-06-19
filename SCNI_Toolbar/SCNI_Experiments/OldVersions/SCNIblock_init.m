 function [PDS, c, s] = SCNIblock_init(PDS, c, s)

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
addpath(genpath(fileparts(mfilename('fullpath'))))          % Add subfunctions folder to path
%temp                = SCNI_DisplaySettings_2D([],0);         % Load display parameters for 2D
temp                = SCNI_DisplaySettings([],0);           % Load display parameters
c.Display           = temp.Display;                         
c.Display.gamma     = 2.2;                                  % Set gamma value
c.OverlayMode       = 'PTB';                                % Options are 'M16','L48','PTB'. Use 'PTB' is video is NOT going through the DataPixx
c.UseDataPixx       = 1;                                    % Use DataPixx2 box for analog/ digital I/O?

c.EventCodes        = SCNI_LoadEventCodes;               	% Load SCNI event codes

%% ============== Initialize color lookup tables
% CLUTs may be customized as needed. CLUTS also need to be defined before initializing DataPixx
switch c.OverlayMode
    case 'L48'
        c.humanCLUT                                     = c.humanColors;
        c.monkeyCLUT                                    = c.monkeyColors;
%         c.humanCLUT(length(c.humanColors)+1:(256/2),:)      = repmat(linspace(0,1,(256/2)-length(c.humanColors))',[1,3]);
%         c.monkeyCLUT(length(c.monkeyColors)+1:(256/2),:)    = repmat(linspace(0,1,(256/2)-length(c.monkeyColors))',[1,3]);
     	c.humanCLUT((length(c.humanColors)+1):256,:)      = repmat(linspace(0,1,256-length(c.humanColors))',[1,3]);
        c.monkeyCLUT((length(c.monkeyColors)+1):256,:)    = repmat(linspace(0,1,256-length(c.monkeyColors))',[1,3]);
end

%% ============= Initialize DataPixx
c               = init_DataPixx(c);

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


%% ================= Generate counterbalanced pseudo-random block and stimulus order
c.Blocks        = SCNI_blockdesign(c.NoCond, c.BlocksPerCond, c.StimPerCond, c.StimPerBlock);    % Get pseudorandomized block & stimulus orders
c.Blocks.TrialNumber = 0;           % Set trial number to zero to compensate for the fact that 'SCNIblock_next.m' gets called BEFORE 'SCNIblock_run.m'
c.Blocks.CompletedRun = 0;
c.StimOnTime   	= [];
c.StimOffTime 	= [];
c.Run           = struct;  
c.Run.TotalTime = numel(c.Blocks.Order)*size(c.Blocks.Stimorder, 2)*(c.StimDuration+c.ISI);     % Caluculate duration of entire run
c.Run.TotalTrials = numel(c.Blocks.Order)*size(c.Blocks.Stimorder, 2);

%% ================= Prepare experimenter display components
c.CondColors    = jet(c.NoCond)*255;                                                            % Get RGB color for each block condition
if c.FixAfterEachBlock==1 %choose the color for the fixation block if requested
    c.CondColors(1,:)=[255 255 255];
end
c.BlockImg      = reshape(c.CondColors(c.Blocks.Order,:),[1,numel(c.Blocks.Order),3]);          % Generate color image of block design
c.BlockImg      = imresize(c.BlockImg, [100,200],'nearest');                                    % Resize image with nearest neighbour interpolation
c.BlockImgRect  = [100, c.Display.Rect(4)-100, 600, c.Display.Rect(4)-50];                      % Specify onscreen position to draw block design
c.BlockImgLen   = c.BlockImgRect(3)-c.BlockImgRect(1);                                          % Calculate length of block design rect
c.BlockImgTex   = Screen('MakeTexture', c.window, c.BlockImg);                                  % Generate texture handle for block design image
ProgOverlay     = zeros(size(c.BlockImg));                                                      % Generate a dark progress bar to overlay on block design
ProgOverlay(:,:,4) = 127;                                                                       % Set progress bar overlay opacity (0-255)
c.BlockProgTex  = Screen('MakeTexture', c.window, ProgOverlay);                                 % Create a texture handle for overlay

%% ================= Calculate screen coordinates
c = SCNI_InitScreenCoords(c);


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


%% ===================== Pre-load stimulus images =========================
% Static images can be pre-loaded into the GPU as PsychToolbox textures, or
% loaded on the fly during the experiment - depending on your timing
% requirements.

if ~isfield(c, 'BlockIMGs')                                                 % If images have not already been loaded to PTB textures...
    wbh         = waitbar(0, '');                                           % Open a waitbar figure
    TotalStim   = 0;                                                        % Begin total stimulus tally
    for Cond = 1:c.NoCond                                                   % For each experimental condition...
        
        switch c.OverlayMode
            case 'M16'
                Screen('FillRect', c.overlay, c.transparencyColor);               	% Clear background
                DrawFormattedText(c.overlay, sprintf('Loading stimuli for condition %d/%d...', Cond, c.NoCond), c.LoadingTextPosX, 80, c.ExpOverlayIndx);
            case 'PTB'
                currentbuffer = Screen('SelectStereoDrawBuffer', c.window, c.ExperimenterBuffer);
                Screen('FillRect', c.window, c.Col_bckgrndRGB);                         % Clear background
                DrawFormattedText(c.window, sprintf('Loading stimuli for condition %d/%d...', Cond, c.NoCond), c.LoadingTextPosX, 80, c.TextColor);
        end
        Screen('Flip', c.window, [], 0);                                   	% Draw to experimenter display
        
        c.StimFiles{Cond} = dir(fullfile(c.StimDir{Cond},['*', c.FileFormat]));      % Find all files of specified format in condition directory
        if c.Stim_AddBckgrnd == 1 && ~isempty(c.BckgrndDir{Cond})                                         
            c.BackgroundFiles{Cond} = dir([c.BckgrndDir{Cond},'/*', c.FileFormat]);    % Find all corresponding background files
        end
        TotalStim = TotalStim+numel(c.StimFiles{Cond});
        for Stim = 1:numel(c.StimFiles{Cond})                               % For each file...

            %============= Update experimenter display
            message = sprintf('Loading image %d of %d (Condition %d/ %d)...\n',Stim,numel(c.StimFiles{Cond}),Cond,c.NoCond);
            waitbar(Stim/numel(c.StimFiles{Cond}), wbh, message);           % Update waitbar
            [keyIsDown, secs, keyCode, deltaSecs] = KbCheck();            	% Check if escape key is pressed
            if keyIsDown && keyCode(c.Key_Exit)                               % If so...
                break;                                                      % Break out of loop
            end

            %============= Load next file
            img = imread(fullfile(c.StimDir{Cond}, c.StimFiles{Cond}(Stim).name));        	% Load image file
            [a,b, imalpha] = imread(fullfile(c.StimDir{Cond}, c.StimFiles{Cond}(Stim).name));  % Read alpha channel
            if ~isempty(imalpha)                                                            % If image file contains transparency data...
                img(:,:,4) = imalpha;                                                       % Combine into a single RGBA image matrix
            else
                img(:,:,4) = ones(size(img,1),size(img,2))*255;
            end
        	if [size(img,2), size(img,1)] ~= c.ImgSize                                      % If X and Y dimensions of image don't match requested...
                img = imresize(img, c.ImgSize([2,1]));                                    	% Resize image
            end
            if c.Stim_Color == 0                                                         	% If color was set to zero...
                img(:,:,1:3) = repmat(rgb2gray(img(:,:,1:3)),[1,1,3]);                      % Convert RGB(A) image to grayscale
            end
            if strcmp(c.OverlayMode, 'L48')                                                 % Scale RGB value range
                ColorRange = [length(c.humanColors)+1, 256];
                img = img/max(img(:))*diff(ColorRange)+ColorRange(1);
            end
            if ~isempty(imalpha) && c.Stim_AddBckgrnd == 1 && ~isempty(c.BckgrndDir{Cond})    	% If image contains transparent pixels...         
                Background = imread(fullfile(c.BckgrndDir{Cond}, c.BackgroundFiles{Cond}(Stim).name));   	% Read in phase scrambled version of stimulus
                Background = imresize(Background, c.ImgSize);                               % Resize background image
                if c.Stim_Color == 0
                    Background = repmat(rgb2gray(Background),[1,1,3]);
                end
                Background(:,:,4) = ones(size(Background(:,:,1)))*255;
                c.BlockBKGs{Cond}(Stim) = Screen('MakeTexture', c.window, Background);    	% Create a PTB offscreen texture for the background
            else
                c.BlockBKGs{Cond}(Stim) = 0;
            end
            c.BlockIMGs{Cond}(Stim) = Screen('MakeTexture', c.window, img);               	% Create a PTB offscreen texture for the stimulus
        end

    end
    delete(wbh);                                                                            % Close the waitbar figure window
    switch c.OverlayMode
     	case 'M16'
            Screen('FillRect', c.overlay, c.transparencyColor);                           	% Clear background
        case 'PTB'
            Screen('FillRect', c.window, c.Col_bckgrndRGB);                                 % Clear background
            DrawFormattedText(c.window, sprintf('All %d stimuli loaded!\n\nClick ''Run'' to start experiment.', TotalStim), c.LoadingTextPosX, 80, c.TextColor);
    end 
    Screen('Flip', c.window);
end


%% ====================== INITIALIZE AUDIO SETTINGS =======================
Audio.On = 1;                                           % Play audio feedback tones/ movie sound?
if Audio.On == 1
    [Audio.Beep, Audio.Noise] = AuditoryFeedback([],1); 	% Generate tones
%     if ~IsWin
%         Speak('Audio initialized.');                    % Inform user that audio is ready
%     elseif IsWin
%         Audio.a = actxserver('SAPI.SpVoice.1');
%         Audio.a.Speak('Audio initialized.');
%     end
    c.AudioBeep      = Audio.Beep(1);
    c.AudioError     = Audio.Beep(2);
    c.AudioPenalty   = Audio.Noise(1);
    PsychPortAudio('Start', c.AudioBeep, 1);
end

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
