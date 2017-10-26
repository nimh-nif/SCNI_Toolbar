function [m, s, c] = SCNI_calib_settings(window, screenRect, refreshrate)   

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
%   2017-06-28 - Updated for eye calibration
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

%================ Fixation settings
c.FixArray          = {'Grid', 'Radial'};           % 
c.CenterOnly        = 1;                            % 1 = present only central fixation; 0 = present at all locations
c.FixEccentricity   = 5;                           % Eccentricity of non-central targets (degrees visual angle from center)
c.Disparities       = [0];                          % List of binocular disparities to present targets at (degrees visual angle)
c.FlipVertical      = 0;                            % Flip eye Y position?
c.FlipHorizontal    = 0;                            % Flip eye X position?
c.EyeToMeasure      = 2;                            % 0 = left eye; 1 = right eye; 2 = both (calculates version) 
c.EyeToPresent      = 2;                            % 0 = left eye; 1 = right eye; 2 = both
FixType             = 1;                            % Fixation marker type: 1 = standard; 2 = image(s); 3 = movie(s)

if FixType == 2     %====================== present 2D face images
    c.StimDir{1}    = fullfile(Append, 'murphya/Stimuli/CFS_fMRI_experiment/Objects/Processed');
    c.FileFormat    = '.png';                                       % Stimulus file format
    
elseif FixType == 3 %====================== present stereo 3D faces
 	c.StimDir{1} = fullfile(Append, '/murphya/MacaqueFace3D/BlenderFiles/DataPixxTest');
    c.FileFormat    = '.png';                                       % Stimulus file format
end

%================ Timing settings
c.StimPerTrial      = 1;                                          	% Total number of stimulus presentations per trial
c.TrialsPerRun      = 1000;                                      	% Number fo trials per experimental run
c.StimDuration      = 1.0;                                        	% Stimulus on duration (seconds)
c.ISI               = 0.8;                                        	% Inter-stimulus interval duration (seconds)
c.ITI               = 2;                                            % Inter-trial interval duration (seconds)
c.TimeToFix         = 0.3;                                          % Maximum allowed duration between fixation target onset and valid fixation
c.FixDur            = 0.5;                                          % Minimum duration of a valid fix
c.MaxTrialDur       = (c.StimDuration+c.ISI)*c.StimPerTrial*2;      % Preallocate appropriate buffer memory on DataPixx2

%================ Reward settings
c.Exit_Key          = 'Escape';
c.Reward_Key        = 'R';                                          % Set keyboard key for manual juice delivery
c.Key_LastPress     = GetSecs;                                      % Prepare variable
c.Key_MinRewardInt  = 0.1;                                          % Minimum time (seconds) between consecutive valid experimenter keypresses
c.Reward_MustFix    = 1;                                            % Require fixation for reward delivery
c.RewardEarned      = 0;                                            % Flag for whether fixation requirement was met in the current inter-reward period
c.TrialsPerReward   = 1;                                            % Average duration between reward deliveries (seconds)
c.Reward_RandDur    = 0;                                            % Range of randomized variation in reward delivery time (seconds)
c.Reward_TTLDur     = 0.05;                                         % Duration of initial reward TTL pulse (seconds)
c.Reward_Increase   = 0;                                            % Duration to increase reward TTL pulse by per trial (seconds)

%=============== Eye tracking settings
c.Eye_BlinkDuration = 0.2;                                        	% Duration (seconds) that eye 'position' can exit fixation window without triggering a broken fixation event

%================ Appearance settings
c.Fix_Type           = 0;                                           % 0 = dot; 1 = crosshair; 2 = solid square; 3 = binocular vernier
c.Fix_Color          = [255,0,0];                                 	% Color of main fixation marker component (RGB)
c.Fix_WinRadius      = 6;                                         	% Radius of fixation window (degrees visual angle)
c.Fix_MarkerSize     = 0.5;                                           % Diameter of fixation marker (degrees visual angle)
c.Fix_LineWidth      = 3;                                           % Line width (pixels)
c.MaxFixBreakDur     = 100;                                         % Maximum duration allowed to break fixation (ms)
c.Stim_Mirror        = 0;                                            % Mirror invert images about vertical axis?
c.Stim_Contrast      = 1;                                            % Image contrast (0-1)
c.Stim_Rotation      = 0;                                            % Image rotation (degrees)
c.GazeRectWidth      = 4;                                           
c.PhotodiodeOn       = 0;                                           % 1 = add photodiode marker to corner of screen
c.PhotodiodeOnCol    = [0,0,0];                                     % Color (RGB) corresponding to 'stimulus on'
c.PhotodiodeOffCol   = [1,1,1]*255;                                	% Color (RGB) corresponding to 'stimulus off'
c.PhotdiodeSize      = [0, 0, 60, 60];                              % Size of photodiode marker (pixels)
c.PhotodiodePos      = 'BottomLeft';                                % Which corner of the display is the photdiode attached to? Options: 'BottomLeft','TopLeft','BottomRight','TopRight'

%% ============= Define the m-files used for this protocol ===============
% The following values in this section must always be included and defined.
% These values are always shown in the GUI menu.

MfliePrefix           	= 'SCNI_calib';
m.initialization_file   = sprintf('%s_init.m', MfliePrefix);
m.next_trial_file       = sprintf('%s_next.m', MfliePrefix);        % "next_trial" m-file
m.run_trial_file        = sprintf('%s_run.m', MfliePrefix);         % "run_trial" m-file
m.finish_trial_file     = sprintf('%s_finish.m', MfliePrefix);      % "finish_trial" m-file

m.action_1              = 'SCNI_savedata.m';                         % "SCNI_savedata" m-file
m.action_2              = 'SCNI_givejuice.m';   
m.action_3              = 'SCNI_PlaySound.m';
m.action_4              = 'SCNI_plotFixation.m'; 

c.output_prefix         = 'SCNI_calib';                               % Define the prefix for the Output File
c.protocol_title        = 'SCNI_calib_PROTOCOL';                      % Define Banner text to identify the experimental protocol


%% ========================== SET COLOR TABLES ============================
% Specify colours for experimenter display overlay

%========= RGB color values for drawing overlay in PTB mode
c.Col_bckgrndRGB    = [128,128,128];        % Stimulus background color = mid-grey
c.Col_gridRGB       = [0,255,255];          % Experimenter overlay grid = cyan
c.TextColor         = [255,255,255];        % Experimenter overlay text = white


%% ==========================  Status values ==============================
%  Tracks progress through the current run.
s.trials        = 0;
s.TrialNumber 	= 1;
s.StimNumber 	= 0;
s.RewardCount   = 0;
s.LastReward    = GetSecs;
s.current       = 0;

end