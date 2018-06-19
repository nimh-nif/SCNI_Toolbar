function [m, s, c] = SCNI_Movie_settings(window, screenRect, refreshrate)   

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
    Prefix = '/Volumes/projects';
elseif IsWin
    Prefix = 'P:\';
elseif IsLinux
    Prefix = '/projects';
end
addpath(genpath(fullfile(fileparts(mfilename('fullpath')),'..')))          % Add subfunctions folder to path

ExpType = 1; 

if ExpType == 1     %====================== Monkey Thieves (1080p)
%     c.Movie.Dir         = fullfile(Prefix, '/murphya/Stimuli/Movies/MonkeyThieves1080p/Season 1');
%     c.Movie.Format      = '.mp4';
    c.Movie.Dir         = fullfile(Prefix, '/murphya/Stimuli/Movies/RussMoviesWMV/');
    c.Movie.Format      = '.wmv';
    c.Movie.Stereo      = 0;
	c.Movie.Dome        = 0;
    
elseif ExpType == 2 %====================== 3D Movies
	c.Movie.Dir         = fullfile(Prefix, '/murphya/Stimuli/Movies/3DMovies/ForestWalks');
    c.Movie.Dir         = fullfile(Prefix, '/murphya/IowaProject/CompiledMovies3D');
    c.Movie.Format      = '.mp4';
    c.Movie.Stereo      = 1;
    c.Movie.Format3D    = 'LR';       % Left-right squeeze frame
	c.Movie.Dome        = 0;
    
elseif ExpType == 3 %====================== Dome Movies
	c.Movie.Dir         = fullfile(Prefix, '/murphya/Stimuli/Movies/DomeMovies');
    c.Movie.Format      = '.mp4';
    c.Movie.Stereo      = 1;
    c.Movie.Format3D    = 'TB';        % Top-bottom 
    c.Movie.Dome        = 1;
    
elseif ExpType == 4 %====================== Dynamic face-patch localizer LONG clips
%     c.Movie.Dir         = fullfile('/projects/murphya/Stimuli/Movies/DynamicLocalizer/LongClip Runs/');
    c.Movie.Dir         = fullfile('/home/lab/Videos/DynamicLocalizer/LongClip Runs/');
    c.Movie.Format      = '.avi';
 	c.Movie.Stereo      = 0;
	c.Movie.Dome        = 0;
    
elseif ExpType == 5 %====================== Dynamic face-patch localizer SHORT (2s) clips
% 	c.Movie.Dir         = fullfile('/projects/murphya/Stimuli/Movies/DynamicLocalizer/ShortClip Runs/');
%     c.Movie.Format      = '.mpg';
	c.Movie.Dir         = fullfile('/home/lab/Videos/DynamicLocalizer/ShortClipV2/');
    c.Movie.Format      = '.avi';
 	c.Movie.Stereo      = 0;
	c.Movie.Dome        = 0;    
elseif ExpType == 6 %====================== Dynamic face-patch localizer SHORT (2s) clips
% 	c.Movie.Dir         = fullfile('/projects/murphya/Stimuli/Movies/DynamicLocalizer/ShortClip Runs/');
%     c.Movie.Format      = '.mpg';
	c.Movie.Dir         = fullfile(Prefix, '/khandhadiaap/AudioVisual Stim/Romanski/Macaque_video/Visual');
    c.Movie.Format      = '.avi';
 	c.Movie.Stereo      = 0;
	c.Movie.Dome        = 0;    
end
c.Movie.AllFiles        = wildcardsearch(c.Movie.Dir, sprintf('*%s', c.Movie.Format));  % List all movie files in specified directory
c.Movie.AllFiles
c.MovieNumber           = 1;
c.Movie.Filename        = c.Movie.AllFiles{c.MovieNumber};                              % Select one of the movies
c.Movie.Filename
%c.Movie.Filename        =fullfile(c.Movie.Dir, sprintf('Movie%d%s',c.MovieNumber, c.Movie.Format));

% c.Movie.Fullscreen    	= 0;                                     	% Scale movie to fit entire display?
% c.Movie.Rect            = [10.4,7.6];                            	% Rectangle to present movie in if not fullscreen (degrees visual angle, centered)
% c.Movie.MaintainAR      = 1;                                        % Maintain original aspect ratio (if not presenting full screen)
% c.Movie.BackgroundColor	= [0,0,0]*127;                           	% Background color (if move is not fullscreen)
% c.Movie.Mirror          = 0;                                        % Horizontally mirror invert the movie image?
% c.Movie.PlaybackRate    = 1;                                        % Proportion of original frame rate
% c.Movie.Volume          = 0.25;                                     % Set the audio volume for the movie (proportion of maximum)
% c.Movie.Contrast        = 1;                                        % Set the image contrast
% c.Movie.Rotation        = 0;                                        % Rotate the movie image (degrees)

c.Movie.Fullscreen    	= 0;                                     	% Scale movie to fit entire display?
% c.Movie.Rect            = [3 2];                            	% Rectangle to present movie in if not fullscreen (degrees visual angle, centered) for 9:16 aspect ratio
c.Movie.Rect            = [13.5,7.6];                            	% Rectangle to present movie in if not fullscreen (degrees visual angle, centered) for 9:16 aspect ratio
c.Movie.MaintainAR      = 1;                                        % Maintain original aspect ratio (if not presenting full screen)
c.Movie.BackgroundColor	= [0,0,0]*127;                           	% Background color (if move is not fullscreen)
c.Movie.Mirror          = 0;                                        % Horizontally mirror invert the movie image?
c.Movie.PlaybackRate    = 1;                                        % Proportion of original frame rate
c.Movie.Volume          = 0.25;                                     % Set the audio volume for the movie (proportion of maximum)
c.Movie.Contrast        = 1;                                        % Set the image contrast
c.Movie.Rotation        = 0;                                        % Rotate the movie image (degrees)

%================ Timing settings (Original)
% c.InitialFixDur     = 2;                                            % Duration of initial and final fixation periods (seconds)
% c.RunDuration       = 300;                                          % Duration of one run (seconds)
% c.MaxTrialDur       = 300;                                          % Estimate maximum trial duration (seconds) for preallocating I/O buffer
% c.WaitForScanner    = 0;                                            % Wait to receive TTL pulses from scanner before starting
% c.NumDummyTTLs      = 20;                                           % The number of TTL pulses to ignore before starting the run

%================ Timing settings (modified for Kenji 3/8/18)
c.InitialFixDur     = 2;                                            % Duration of initial and final fixation periods (seconds)
c.RunDuration       = 1000;                                          % Duration of one run (seconds)
c.MaxTrialDur       = 1000;                                          % Estimate maximum trial duration (seconds) for preallocating I/O buffer
c.WaitForScanner    = 0;                                            % Wait to receive TTL pulses from scanner before starting
c.NumDummyTTLs      = 35;                                           % The number of TTL pulses to ignore before starting the run

%================ Reward settings
c.Exit_Key          = 'Escape';
c.Reward_Key        = 'R';                                          % Set keyboard key for manual juice delivery
c.Key_LastPress     = GetSecs;                                      % Prepare variable
c.Key_MinRewardInt  = 0.1;                                          % Minimum time (seconds) between consecutive valid experimenter keypresses
c.Reward_MustFix    = 1;                                            % Require fixation for reward delivery
c.RewardEarned      = 0;                                            % Flag for whether fixation requirement was met in the current inter-reward period
c.Reward_MeanDur    = 2;                                            % Average duration between reward deliveries (seconds)
c.Reward_RandDur    = 0.5;                                          % Range of randomized variation in reward delivery time (seconds)
c.NextRewardInt     = c.Reward_MeanDur+rand(1)*c.Reward_RandDur;    % Generate random interval before first reward delivery (seconds)
c.RewardProportion  = 0.8;                                          % Proportion of each inter-reward period that fixation must be valid in order to receive reward
c.Reward_TTLDur     = 0.05;                                         % Duration of initial reward TTL pulse (seconds)
c.Reward_Increase   = 0;                                            % Duration to increase reward TTL pulse by per trial (seconds)

%=============== Eye tracking settings
c.Eye_BlinkDuration = 0.2;                                        	% Duration (seconds) that eye 'position' can exit fixation window without triggering a broken fixation event

%================ Appearance settings
c.InitialFixDur      = 2;                                           % Duration of initial fixation (seconds)
c.Fix_On             = 0;                                           % Draw fixation marker?
c.Fix_Type           = 1;                                           % 0 = dot; 1 = crosshair; 2 = solid square; 3 = binocular vernier
c.Fix_Color          = [0,255,0];                                 	% Color of main fixation marker component (RGB)
c.Fix_WinBorder      = 1;                                         	% Fixation window extent relative to frame (degrees visual angle)
c.Fix_MarkerSize     = 1;                                           % Diameter of fixation marker (degrees visual angle)
c.Fix_LineWidth      = 3;                                           % Line width (pixels)
c.Stim_Color         = 1;                                            % 0 = show grayscale images; 1 = show RGB images; 
c.GazeRectWidth      = 4;                                           
c.PhotodiodeOn       = 0;                                           % 1 = add photodiode marker to corner of screen
c.PhotodiodeOnCol    = [0,0,0];                                     % Color (RGB) corresponding to 'stimulus on'
c.PhotodiodeOffCol   = [1,1,1]*255;                                	% Color (RGB) corresponding to 'stimulus off'
c.PhotdiodeSize      = [0, 0, 60, 60];                              % Size of photodiode marker (pixels)
c.PhotodiodePos      = 'BottomLeft';                                % Which corner of the display is the photdiode attached to? Options: 'BottomLeft','TopLeft','BottomRight','TopRight'


%% ============= Define the m-files used for this protocol ===============
% The following values in this section must always be included and defined.
% These values are always shown in the GUI menu.

MfilePrefix           	= 'SCNI_Movie';
m.initialization_file   = sprintf('%s_init.m', MfilePrefix);
m.next_trial_file       = sprintf('%s_next.m', MfilePrefix);        % "next_trial" m-file
m.run_trial_file        = sprintf('%s_run.m', MfilePrefix);         % "run_trial" m-file
m.finish_trial_file     = sprintf('%s_finish.m', MfilePrefix);      % "finish_trial" m-file

m.action_1              = 'SCNI_savedata.m';                         % "SCNI_savedata" m-file
m.action_2              = 'SCNI_givejuice.m';   
m.action_3              = 'SCNI_PlaySound.m';
m.action_4              = 'SCNI_plotFixation.m'; 
m.action_5              = 'SCNI_Toolbar.m';

c.output_prefix         = 'SCNI_Movie';                               % Define the prefix for the Output File
c.protocol_title        = 'SCNI_Movie_PROTOCOL';                      % Define Banner text to identify the experimental protocol



%========= RGB color values for drawing overlay in PTB mode
c.Col_bckgrndRGB    = [128,128,128];        % Stimulus background color = mid-grey
c.Col_gridRGB       = [0,255,255];          % Experimenter overlay grid = cyan
c.TextColor         = [255,255,255];        % Experimenter overlay text = white


%% ==========================  Status values ==============================
%  Tracks progress through the current run.

s.trials        = 0;
s.trialno       = 1;
s.blockno       = 0;
s.RewardCount   = 0;
s.LastReward    = GetSecs;
s.current       = 0;

end
