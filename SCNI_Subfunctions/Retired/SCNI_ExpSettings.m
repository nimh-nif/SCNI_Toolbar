%========================= SCNI_ExpSettings.m =============================
% This function provides a graphical user interface for setting parameters 
% related to basic experimental settings in PLDAPS. Parameters can be saved
% and loaded, to and from .mat files, and the updated parameters are returned 
% in the structure 'Params'. This function replaces the need for the Krauzlis 
% lab GUI and separate XXX_settings.m file.
%
% INPUTS:
%   ParamsFile:   	optional string containing full path of a .mat file
%                	containing previously saved parameters. If no input is
%                	provided, the function will search for a .mat file with
%                	the name of the local computer. If no file is found,
%                	default parameters are loaded.
% OUTPUT:
%   Params:         a structure containing the parameters set in the GUI.
%
%==========================================================================

function ParamsOut = SCNI_ExpSettings(ParamsFile, OpenGUI)

persistent Params Fig;

%============ Initialize GUI
GUItag      = 'SCNI_ExpSettings';               % String to use as GUI window tag
Fieldname   = 'Exp';                            % Params structure fieldname for DataPixx info
if ~exist('OpenGUI','var')
    OpenGUI = 1;
end
if ~exist('ParamsFile','var')
    ParamsFile = [];
end
[Params, Success, Fig]   = SCNI_InitGUI(GUItag, Fieldname, ParamsFile, OpenGUI);

%=========== Load default parameters
if Success < 1

    Params.c.StimDir{1}    = fullfile('/projects/murphya/Stimuli/CFS_fMRI_experiment/Objects/Processed');
    Params.c.StimDir{2}    = fullfile('/projects/murphya/Stimuli/CFS_fMRI_experiment/Rhesus_neutral/Processed');
    Params.c.StimDir{3}    = fullfile('/projects/murphya/Stimuli/CFS_fMRI_experiment/Objects/SpectralScrambled');
    Params.c.StimDir{4}    = fullfile('/projects/murphya/Stimuli/CFS_fMRI_experiment/Rhesus_neutral/SpectralScrambled');
    Params.c.BckgrndDir{1} = fullfile('/projects/murphya/Stimuli/CFS_fMRI_experiment/Objects/SpectralScrambled');
    Params.c.BckgrndDir{2} = fullfile('/projects/murphya/Stimuli/CFS_fMRI_experiment/Rhesus_neutral/SpectralScrambled');
    Params.c.BckgrndDir{3} = [];
    Params.c.BckgrndDir{4} = [];
    Params.c.StimPerCond  	= 32;                                               % Number of individual stimuli per condition
    Params.c.FileFormat    = '.png';                                            % Stimulus file format

    %================ Timing settings
    Params.c.NoCond            = numel(Params.c.StimDir);                     	% Number of experimental conditions
    Params.c.StimDuration      = 0.3;                                        	% Stimulus on duration (seconds)
    Params.c.ISI               = 0.3;                                        	% Inter-stimulus interval duration (seconds)
    Params.c.MaxTrialDur       = (Params.c.StimDuration+Params.c.ISI)*2;      	% Estimate maximum trial duration (seconds) for preallocating I/O buffer


    %================ Reward settings
    Params.c.Exit_Key          = 'Escape';
    Params.c.Reward_Key        = 'R';                                          % Set keyboard key for manual juice delivery
    Params.c.Key_LastPress     = GetSecs;                                      % Prepare variable
    Params.c.Key_MinRewardInt  = 0.1;                                          % Minimum time (seconds) between consecutive valid experimenter keypresses
    Params.c.Reward_MustFix    = 1;                                            % Require fixation for reward delivery
    Params.c.RewardEarned      = 0;                                            % Flag for whether fixation requirement was met in the current inter-reward period
    Params.c.Reward_MeanDur    = 4;                                            % Average duration between reward deliveries (seconds)
    Params.c.Reward_RandDur    = 0;                                            % Range of randomized variation in reward delivery time (seconds)
    Params.c.NextRewardInt     = Params.c.Reward_MeanDur+rand(1)*Params.c.Reward_RandDur;    % Generate random interval before first reward delivery (seconds)
    Params.c.Reward_TTLDur     = 0.05;                                         % Duration of initial reward TTL pulse (seconds)
    Params.c.Reward_Increase   = 0;                                            % Duration to increase reward TTL pulse by per trial (seconds)

    %=============== Eye tracking settings
    Params.c.Eye_BlinkDuration = 0.2;                                        	% Duration (seconds) that eye 'position' can exit fixation window without triggering a broken fixation event

    %================ Appearance settings
    Params.c.Fix_On             = 1;                                            % Draw fixation marker?
    Params.c.Fix_Type           = 1;                                            % 0 = dot; 1 = crosshair; 2 = solid square; 3 = binocular vernier
    Params.c.Fix_Color          = [0,255,0];                                	% Color of main fixation marker component (RGB)
    Params.c.Fix_WinRadius      = 2;                                         	% Radius of fixation window (degrees visual angle)
    Params.c.Fix_MarkerSize     = 1;                                            % Diameter of fixation marker (degrees visual angle)
    Params.c.Fix_LineWidth      = 3;                                            % Line width (pixels)
    Params.c.Stim_Fullscreen    = 1;                                            % Present images at full screen size (this overrides Params.c.Stim_Diameter)
    Params.c.Stim_Diameter      = 10;                                           % Stimulus diameter (degrees visual angle)
    Params.c.Stim_Color         = 1;                                            % 0 = show grayscale images; 1 = show RGB images; 
    Params.c.Stim_Mirror        = 0;                                            % Mirror invert images about vertical axis?
    Params.c.Stim_Contrast      = 1;                                            % Image contrast (0-1)
    Params.c.Stim_Rotation      = 0;                                            % Image rotation (degrees)
    Params.c.Stim_AddBckgrnd    = 0;                                            % 1 = add background image from Params.c.BckgrndDir to images with alpha (transparency) channel
    Params.c.GazeRectWidth      = 4;                                            
    Params.c.PhotodiodeOn       = 1;                                            % 1 = add photodiode marker to corner of screen
    Params.c.PhotodiodeOnCol    = [0,0,0];                                      % Color (RGB) corresponding to 'stimulus on'
    Params.c.PhotodiodeOffCol   = [1,1,1]*255;                                	% Color (RGB) corresponding to 'stimulus off'
    Params.c.PhotdiodeSize      = [0, 0, 60, 60];                               % Size of photodiode marker (pixels)
    Params.c.PhotodiodePos      = 'BottomLeft';                                 % Which corner of the display is the photdiode attached to? Options: 'BottomLeft','TopLeft','BottomRight','TopRight'

    %============= Define the m-files used for this protocol ===============
    % The following values in this section must always be included and defined.
    % These values are always shown in the GUI menu.

    MfliePrefix           	= 'SCNIblock';
    m.initialization_file   = sprintf('%s_init.m', MfliePrefix);
    m.next_trial_file       = sprintf('%s_next.m', MfliePrefix);        % "next_trial" m-file
    m.run_trial_file        = sprintf('%s_run.m', MfliePrefix);         % "run_trial" m-file
    m.finish_trial_file     = sprintf('%s_finish.m', MfliePrefix);      % "finish_trial" m-file
    m.action_1              = 'SCNI_savedata.m';                     	% "SCNI_savedata" m-file
    m.action_2              = 'SCNI_givejuice.m';   
    m.action_3              = 'SCNI_PlaySound.m';
    m.action_4              = 'SCNI_plotFixation.m'; 
    m.action_5              = 'SCNI_Toolbar.m';

    Params.c.output_prefix         = MfliePrefix;                              % Define the prefix for the Output File
    Params.c.protocol_title        = sprintf('%s_PROTOCOL', MfliePrefix);     	% Define Banner text to identify the experimental protocol

    %========= RGB color values for drawing overlay in PTB mode
    Params.c.Col_bckgrndRGB    = [128,128,128];        % Stimulus background color = mid-grey
    Params.c.Col_gridRGB       = [0,255,255];          % Experimenter overlay grid = cyan
    Params.c.TextColor         = [255,255,255];        % Experimenter overlay text = white
   
    Params.Exp.Exp.EyeColor         = [1 0 0];
    Params.Exp.Exp.GazeWinColor     = [0 1 0];
    Params.Exp.Exp.BackgroundColor  = [0.5 0.5 0.5];
    Params.Exp.Exp.GridSpacing      = 5;
    Params.Exp.Exp.EyeSamples       = 1;
    Params.Exp.Exp.GazeWinAlpha     = 1;
    Params.Exp.PD.Position          = 2;
    
    %==========================  Status values ==============================
    % Tracks progress through the current run.

    s.trials        = 0;
    s.trialno       = 1;
    s.blockno       = 0;
    s.RewardCount   = 0;
    s.LastReward    = GetSecs;
    s.current       = 0;
    
    
    
elseif Success > 1
    ParamsOut = Params;
	return;
end
if OpenGUI == 0
    ParamsOut = Params;
    return;
end



%========================= OPEN GUI WINDOW ================================
Fig.Handle          = figure;                                       	% Open new figure window         
setappdata(0,GUItag,Fig.Handle);                                        % Assign tag
Fig.PanelYdim       = 130*Fig.DisplayScale;
Fig.Rect            = [0 200 500 900]*Fig.DisplayScale;              	% Specify figure window rectangle
set(Fig.Handle,     'Name','SCNI: Rig settings',...                     % Open a figure window with specified title
                    'Tag','SCNI_RigSettings',...                     	% Set figure tag
                    'Renderer','OpenGL',...                             % Use OpenGL renderer
                    'OuterPosition', Fig.Rect,...                       % position figure window
                    'NumberTitle','off',...                             % Remove figure number from title
                    'Resize', 'off',...                                 % Prevent resizing of GUI window
                    'Menu','none',...                                   % Turn off memu
                    'Toolbar','none');                                  % Turn off toolbars to save space
Fig.Background  = get(Fig.Handle, 'Color');                           	% Get default figure background color
Fig.Margin      = 20*Fig.DisplayScale;                               	% Set margin between UI panels (pixels)                                 
Fig.Fields      = fieldnames(Params);                                 	% Get parameter field names

%======== Set group controls positions
BoxPos{1} = [Fig.Margin,Fig.Rect(4)-230*Fig.DisplayScale-Fig.Margin*2,Fig.Rect(3)-Fig.Margin*2, 240*Fig.DisplayScale];         	
BoxPos{2} = [Fig.Margin,BoxPos{1}(2)-220*Fig.DisplayScale-Fig.Margin/2,Fig.Rect(3)-Fig.Margin*2, 220*Fig.DisplayScale];
BoxPos{3} = [Fig.Margin,BoxPos{2}(2)-140*Fig.DisplayScale-Fig.Margin/2,Fig.Rect(3)-Fig.Margin*2, 140*Fig.DisplayScale];
BoxPos{4} = [Fig.Margin,BoxPos{3}(2)-200*Fig.DisplayScale-Fig.Margin/2,Fig.Rect(3)-Fig.Margin*2, 200*Fig.DisplayScale];