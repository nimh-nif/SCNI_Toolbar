function [m, s, c] = SCNI_Training_settings(window, screenRect, refreshrate)   

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

%============= VALUES THAT WILL FIRST SHOW UP IN MENU
if ismac
    Prefix = '/Volumes/projects';
elseif IsWin
    Prefix = 'P:\';
elseif IsLinux
    Prefix = '/projects';
end
c.ImageDir          = fullfile(Prefix, 'murphya/Stimuli/CFS_fMRI_experiment/Objects/Processed/');
c.ImageFileFormat   = '.png';                                       % Image file format
c.MovieDir          = fullfile(Prefix, 'murphya/Stimuli/Movies/MonkeyThieves1080p/Season 1/');
c.MovieFormat       = '.mp4';                                       % Movie file format

%================ Timing settings

c.FixDuration       = 0.3;                                              % Fixation marker/ stimulus on duration (seconds)
c.ISI               = 0.3;                                              % Inter-stimulus interval duration (seconds)
c.MaxTrialDur       = (c.StimDuration+c.ISI)*2;                         % Estimate maximum trial duration (seconds) for preallocating I/O buffer
c.StimPerBlock      = 100;                                              % Number of stimulus presentations per block
c.Fix.LocNorm       = [0,1; 1,1; 1,0; 1,-1; 0,-1; -1,-1; -1,0; -1,1];   % 9-point locations (normalized coordinates)



%================ Reward settings
c.Exit_Key          = 'Escape';
c.Reward_Key        = 'R';                                          % Set keyboard key for manual juice delivery
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
c.Fix_Type           = 1;                                           % 0 = dot; 1 = crosshair; 2 = solid square; 3 = binocular vernier
c.Fix_Color          = [0,255,0];                                 	% Color of main fixation marker component (RGB)
c.Fix_WinRadius      = 2;                                         	% Radius of fixation window (degrees visual angle)
c.Fix_MarkerSize     = 1;                                           % Diameter of fixation marker (degrees visual angle)
c.Fix_LineWidth      = 3;                                           % Line width (pixels)
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


%% ============= Define the m-files used for this protocol ===============
% The following values in this section must always be included and defined.
% These values are always shown in the GUI menu.

MfliePrefix           	= 'SCNIblock';
m.initialization_file   = sprintf('%s_init.m', MfliePrefix);
m.next_trial_file       = sprintf('%s_next.m', MfliePrefix);        % "next_trial" m-file
m.run_trial_file        = sprintf('%s_run.m', MfliePrefix);         % "run_trial" m-file
m.finish_trial_file     = sprintf('%s_finish.m', MfliePrefix);      % "finish_trial" m-file

m.action_1              = 'SCNI_savedata.m';                         % "SCNI_savedata" m-file
m.action_2              = 'SCNI_givejuice.m';   
m.action_3              = 'SCNI_PlaySound.m';
m.action_4              = 'SCNI_plotFixation.m'; 
m.action_5              = 'SCNI_Toolbar.m';

c.output_prefix         = 'SCNIblock';                               % Define the prefix for the Output File
c.protocol_title        = 'SCNIblock_PROTOCOL';                      % Define Banner text to identify the experimental protocol


%% ========================== SET COLOR TABLES ============================
% Specify colours for experimenter display overlay

%========= RGB color values for drawing overlay in PTB mode
c.Col_bckgrndRGB    = [128,128,128];        % Stimulus background color = mid-grey
c.Col_gridRGB       = [0,255,255];          % Experimenter overlay grid = cyan
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

end
