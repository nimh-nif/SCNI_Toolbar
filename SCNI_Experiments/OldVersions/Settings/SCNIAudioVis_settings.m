function [m, s, c] = SCNIAudioVis_settings(window, screenRect, refreshrate)   

%========================= Parameter Configuration ======================== 
% Parameters specified in this file will be loaded into the GUI and can be
% modified there. To change the default settings, edit the values in this
% file. Parameters are stored in 3 structures, organized as follows:
%       m: m-file references
%       c: most variables
%       s: status values
%
% HISTORY:
%   2017-01-23 - Written by murphyap@mail.nih.gov
%   
%     ____    ___ __  _______
%    /    |  /  //  //  ____/    Neuro Imaging Facility Core
%   /  /| | /  //  //  /___      Building 49 Convent Drive
%  /  / | |/  //  //  ____/      NATIONAL INSTITUTES OF HEALTH
% /__/  |____//__//__/          
%==========================================================================

%% ============= VALUES THAT WILL FIRST SHOW UP IN MENU
if ismac
    Append = '/Volumes/projects';
elseif IsWin
    Append = 'P:\';
elseif IsLinux
    Append = '/projects';
end

ExpType = 1;

    
if ExpType == 1 %====================== MonkeyVocalizationsAndVideos
 	c.StimDir{1} = fullfile(Append, '/khandhadiaap/AudioVisual Stim/Romanski/Macaque_video/AudioVisual');
    c.StimDir{2} = fullfile(Append, '/khandhadiaap/AudioVisual Stim/Romanski/Macaque_video/Visual');
    c.StimDir{3} = fullfile(Append, '/khandhadiaap/AudioVisual Stim/Romanski/Macaque_video/Audio');
    c.BckgrndDir{1} = [];
    c.BckgrndDir{2} = [];
    c.BckgrndDir{3} = [];
    c.StimPerCond  	= 15; 
    c.FileFormat{1}    = '.avi';
    c.FileFormat{2}    = '.avi';
    c.FileFormat{3}    = '.wav'; 
    c.Movie.Stereo    = 0;
% elseif ExpType ==2
%     c.StimDir{1} = fullfile(Append, '/leathersml/Stimuli/BodyHead');
%     c.StimDir{2} = fullfile(Append, '/leathersml/Stimuli/BodyHead/Silhouettes');
%     c.BckgrndDir{1} = [];
%     c.BckgrndDir{2} = [];
%     c.StimPerCond  	= 49; 
end
                                  % Stimulus file format

%================ Timing settings
c.FixEveryBlock     = 1;                                            % Present fixation marker in every block?
c.FixAfterEachBlock = 1;                                            % Present 1 block of fixation only after each stimulus block?
c.NoCond            = numel(c.StimDir);                            	% Number of experimental conditions
c.NoBlocks          = 1;                                          	% Total number of blocks per run
c.BlockDuration     = 540;                                          	% Block duration (seconds)
c.RunDuration       = c.NoBlocks*c.BlockDuration;                 	% Duration of one run (seconds)
c.StimDuration      = 1.5;                                        	% Stimulus on duration (seconds)
c.ISI               = 2;                                        	% Inter-stimulus interval duration (seconds)
c.MaxTrialDur       = (c.StimDuration+c.ISI)*2;                  	% Estimate maximum trial duration (seconds) for preallocating I/O buffer
c.StimPerBlock      = 45;                                          	% Number of stimulus presentations per block
c.BlocksPerCond     = c.NoBlocks/c.NoCond;                        	% Number of blocks of each condition in 1 run
c.WaitForScanner    = 0;                                            % Wait to receive TTL pulses from scanner before starting
c.SyncStimToScanner = 0;                                            % Wait for scanner TTL before each stimulus presentation
c.NumDummyTTLs      = 4;                                            % The number of TTL pulses to ignore before starting the run
c.TimePenalty       = 2;
%================ Reward settings
c.Exit_Key          = 'Escape';
c.Reward_Key        = 'R';     
c.Center_Key        = 'C';
c.Key_LastPress     = GetSecs;                                      % Prepare variable
c.Key_MinRewardInt  = 0.1;                                          % Minimum time (seconds) between consecutive valid experimenter keypresses
c.Reward_MustFix    = 1;                                            % Require fixation for reward delivery
c.RewardEarned      = 0;                                            % Flag for whether fixation requirement was met in the current inter-reward period
c.Reward_MeanDur    = 4;                                            % Average duration between reward deliveries (seconds)
c.Reward_RandDur    = 0;                                            % Range of randomized variation in reward delivery time (seconds)
c.NextRewardInt     = c.Reward_MeanDur+rand(1)*c.Reward_RandDur;    % Generate random interval before first reward delivery (seconds)
c.Reward_TTLDur     = 0.05;                                         % Duration of initial reward TTL pulse (seconds)
c.Reward_Increase   = 0;                                            % Duration to increase reward TTL pulse by per trial (seconds)

%=============== Eye tracking settings
c.Eye_BlinkDuration = 0.2;                                        	% Duration (seconds) that eye 'position' can exit fixation window without triggering a broken fixation event

%================ Appearance settings
c.Fix_On             = 1;                                           % Draw fixation marker?
c.InitialFixTime     = 1;
c.Fix_Type           = 1;                                           % 0 = dot; 1 = crosshair; 2 = solid square; 3 = binocular vernier
c.Fix_Color          = [0,255,0];                                 	% Color of main fixation marker component (RGB)
c.Fix_WinRadius      = 4;                                         	% Radius of fixation window (degrees visual angle)
c.Fix_MarkerSize     = 1;                                           % Diameter of fixation marker (degrees visual angle)
c.Fix_LineWidth      = 3;                                           % Line width (pixels)
c.Fix_WinBorder      = 1; 
c.Stim_Fullscreen    = 1;                                           % Present images at full screen size (this overrides c.Stim_Diameter)
c.Stim_Diameter      = 10;                                           % Stimulus diameter (degrees visual angle)
c.Stim_Color         = 1;                                            % 0 = show grayscale images; 1 = show RGB images; 
c.Stim_Mirror        = 0;                                            % Mirror invert images about vertical axis?
c.Stim_Contrast      = 1;                                            % Image contrast (0-1)
c.Stim_Rotation      = 0;                                            % Image rotation (degrees)
c.Stim_AddBckgrnd    = 0;                                            % 1 = add background image from c.BckgrndDir to images with alpha (transparency) channel
c.GazeRectWidth      = 4;                                           
c.PhotodiodeOn       = 1;                                           % 1 = add photodiode marker to corner of screen
c.PhotodiodeOnCol    = [0,0,0];                                     % Color (RGB) corresponding to 'stimulus on'
c.PhotodiodeOffCol   = [1,1,1]*255;                                	% Color (RGB) corresponding to 'stimulus off'
c.PhotdiodeSize      = [0, 0, 60, 60];                              % Size of photodiode marker (pixels)
c.PhotodiodePos      = 'BottomLeft';                                % Which corner of the display is the photdiode attached to? Options: 'BottomLeft','TopLeft','BottomRight','TopRight'
c.Movie.Fullscreen    	= 0;                                     	% Scale movie to fit entire display?
% c.Movie.Rect            = [3 2];                            	% Rectangle to present movie in if not fullscreen (degrees visual angle, centered) for 9:16 aspect ratio
c.Movie.Rect            = [13.5,7.6];                            	% Rectangle to present movie in if not fullscreen (degrees visual angle, centered) for 9:16 aspect ratio
c.Movie.MaintainAR      = 1;                                        % Maintain original aspect ratio (if not presenting full screen)
c.Movie.BackgroundColor	= [1,1,1]*128;                           	% Background color (if move is not fullscreen)
c.Movie.Mirror          = 0;                                        % Horizontally mirror invert the movie image?
c.Movie.PlaybackRate    = 1;                                        % Proportion of original frame rate
c.Movie.Volume          = 0.25;                                     % Set the audio volume for the movie (proportion of maximum)
c.Movie.Contrast        = 1;                                        % Set the image contrast
c.Movie.Rotation        = 0;                                        % Rotate the movie image (degrees)


%% ============= Define the m-files used for this protocol ===============
% The following values in this section must always be included and defined.
% These values are always shown in the GUI menu.

MfliePrefix           	= 'SCNIAudioVis';
m.initialization_file   = sprintf('%s_init.m', MfliePrefix);
m.next_trial_file       = sprintf('%s_next.m', MfliePrefix);        % "next_trial" m-file
m.run_trial_file        = sprintf('%s_run.m', MfliePrefix);         % "run_trial" m-file
m.finish_trial_file     = sprintf('%s_finish.m', MfliePrefix);      % "finish_trial" m-file

m.action_1              = 'SCNI_savedata.m';                         % "SCNI_savedata" m-file
m.action_2              = 'SCNI_givejuice.m';   
m.action_3              = 'SCNI_PlaySound.m';
m.action_4              = 'SCNI_plotFixation.m'; 
m.action_5              = 'SCNI_Toolbar.m';

c.output_prefix         = 'SCNIAudioVis';                               % Define the prefix for the Output File
c.protocol_title        = 'SCNIAudioVis';                      % Define Banner text to identify the experimental protocol


%% ========================== SET COLOR TABLES ============================
% Specify colours for experimenter display overlay

%========= RGB color values for drawing overlay in PTB mode
c.Col_bckgrndRGB    = [128,128,128];        % Stimulus background color = mid-grey
c.Col_gridRGB       = [255,255,255];          % Experimenter overlay grid = cyan
c.TextColor         = [255,255,255];        % Experimenter overlay text = white

% %========= CLUT index color values for DataPixx video modes 'M16' and 'L48'
% c.Col_background 	= 0.5;              % background grey value (0-1)
% c.Col_grid          = 248;              % Color of grid lines on experiment
% c.backdindex        = 0;                % background index in LUT
% c.fixindex          = 3;                % fixation point index in LUT
% c.cueboxindex       = 1;                % fixation point box index in LUT
% 
% %========== Experimenter CLUT
% c.humanColors	= [0.5,0.5,0.5;    	% 0 = mid-grey
%                    1, 0, 0;       	% 1 = red
%                    0, 1, 0;         % 2 = green
%                    0, 0, 1;         % 3 = blue
%                    0, 0, 0;         % 4 = black
%                    c.Col_background, c.Col_background, c.Col_background]; 	% 5
% 
% %========== Monkey's CLUT
% c.monkeyColors = [0.5,0.5,0.5;    	% 0 = mid-grey
%     c.Col_background, c.Col_background, c.Col_background; 	% 1 = transparent
%     c.Col_background, c.Col_background, c.Col_background;   % 2 = transparent
%     c.Col_background, c.Col_background, c.Col_background;   % 3 = transparent
%     c.Col_background, c.Col_background, c.Col_background;   % 4 = transparent
%     c.Col_background, c.Col_background, c.Col_background];  % 5
   

%% ==========================  Status values ==============================
%  Tracks progress through the current run.

s.trials        = 0;
s.trialno       = 1;
s.blockno       = 0;
s.RewardCount   = 0;
s.LastReward    = GetSecs;
s.current       = 0;
s.framecount    = 1;
s.Fixated       = 1;
end
