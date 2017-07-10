function [edfFile] = EyeLinkSetup(EDFfilename, Display, win)

%============================ EyeLinkSetup.m ==============================
% This wrapper function initializes connection to an EyeLink 1000 (SR Research)
% infra-red eye tracker using EyeLinkToolbox commands from PsychToolbox.
% Eye position data is recorded on the EyeLink PC in EDFfilename. Input
% structure Display allows the display screen size (in pixels) to be
% recorded in the .edf file. Finally, this function starts EyeLink
% recording as it is advisable to start recording before presentation of 
% initial fixation.
%`
% INPUTS:
% 	EDFfilename:    String containing the name to save the .edf file as.
%   Display:        Structure containing display settings provided by
%                   subfunction DisplaySettings.m
%   win:            PTB window identifier
%
% REFERENCES:
% Cornelissen FW, Peters EM, Palmer J (2002).  The Eyelink Toolbox: Eye tracking
%   with MATLAB and the Psychophysics Toolbox.  Behaviour Research Methods,
%   34(4): 613-617. DOI: 10.3758/BF03195489
% Brainard DH (1997) The Psychophysics Toolbox. Spat Vis 10:433-436.
% Pelli DG (1997) The VideoToolbox software for visual psychophysics: 
%   transforming numbers into movies. Spat Vis 10:437-442.
%
% REVISIONS:
%   10/07/2011 - Written by Aidan Murphy (apm909@bham.ac.uk)
%   29/02/2012 - Updated to use Shadlen lab default parameters (APM)
%     ___  ______  __   __
%    /   ||  __  \|  \ |  \    APM SUBFUNCTIONS
%   / /| || |__/ /|   \|   \   Aidan P. Murphy - apm909@bham.ac.uk
%  / __  ||  ___/ | |\   |\ \  Binocular Vision Lab
% /_/  |_||_|     |_| \__| \_\ University of Birmingham
%
%==========================================================================

if nargin < 3                                   % If a PTB window pointer was not provided...
    win = Screen('Windows');                 	% Check if a PTB3 window is currently open
    if isempty(win)                             % If not then abort...
        EDFfilename = 'TEST';
        win = Screen('OpenWindow',max(Screen('screens')), 0, [0 0 10 10]);      % Open small temporary window
%         fprintf('EYELINK: No open PTB window was detected!  Defaults cannot be loaded.\n');
%         return
    end
end
%===================== Initialize connection to EyeLink ===================
try
    Initialized = Eyelink('Initialize');    
catch
    fprintf('EYELINK: Initialization failed!');
    return
end
if Initialized ~= 0         
    error('EYELINK: Could not initialize connection to Eyelink');           
end

%===================== Check .edf filename and open =======================
MaxEDFchar = 8;
if length(EDFfilename)>4 && strcmp(EDFfilename(end-3:end), '.edf')
    EDFfilename = EDFfilename(1:end-4);
end
if length(EDFfilename) > 8
    h = errordlg(sprintf('EDF filename must be %d of less characters long!', MaxEDFchar), 'EDF filename error');
end
edfFile = [EDFfilename, '.edf'];                                        % Set .edf file name for this trial
i       = Eyelink('Openfile', edfFile);                                 % Open .edf file to record data to
if i~=0
    Cleanup;
    error('EYELINK: Cannot create EDF file ''%s''.\n', edfFile);
end

%==================== Configure EyeLink parser parameters =================
el = EyelinkInitDefaults(win);                                        	% Initialize EyeLink default settings
PsychEyelinkDispatchCallback(el);
% myEyelinkDispatchCallback(el);
Eyelink('Command', 'add_file_preamble_text ''Recorded by EyelinkToolbox'''); 
Eyelink('command', 'active_eye = BOTH');                                % set eye(s) to record
Eyelink('command', 'binocular_enabled = YES');                         	% enamble binocular tracking
Eyelink('command', 'head_subsample_rate = 0');                          % normal (no anti-reflection)
Eyelink('command', 'heuristic_filter = ON');                            % ON for filter (normal)	
Eyelink('command', 'pupil_size_diameter = NO');                         % no to diameter (= yes for pupil area)
Eyelink('command', 'simulate_head_camera NO');                          % NO to use head camera

Eyelink('Command', 'calibration_type = HV9');                           % Use a 9 point calibration
Eyelink('command', 'enable_automatic_calibration = YES');               % YES (default)
Eyelink('command', 'automatic_calibration_pacing = 1000');              % 1000ms (default)
Eyelink('Command', 'recording_parse_type = GAZE');                      
Eyelink('Command', 'saccade_velocity_threshold = 35');              	% set parser (conservative saccade thresholds)
Eyelink('Command', 'saccade_acceleration_threshold = 9500'); 
Eyelink('Command', 'saccade_motion_threshold = 0.0');                                           
Eyelink('Command', 'saccade_pursuit_fixup = 60');                                               
Eyelink('Command', 'fixation_update_interval = 0');                                             
Eyelink('Command', 'file_event_filter = LEFT,RIGHT,FIXATION,SACCADE,BLINK,MESSAGE,BUTTON');     % set EDF file contents
Eyelink('Command', 'link_event_filter = LEFT,RIGHT,FIXATION,BUTTON');                           % set link data (used for gaze cursor)
Eyelink('Command', 'link_sample_data  = LEFT,RIGHT,GAZE,AREA');                                 

if exist('Display','var')
    Eyelink('Message', 'DISPLAY_COORDS %d %d %d %d',Display.Rect(1),Display.Rect(2),Display.Rect(3),Display.Rect(4));               
end

eye_used = Eyelink('EyeAvailable');                                     % get eye that's tracked
if eye_used == -1
    eye_used = el.RIGHT_EYE;
end

SendKey = {'c','d','v',13};                           	% 1 = calibration; 2 = drift correction; 3 = validation; 4 = show eye
EyelinkDoTrackerSetup(el);%,SendKey{1}); 




Eyelink('message', 'EyeLinkSetup.m');                 	% Send message to EyeLink that setup has started
Eyelink('StartRecording');                              % Start EyeLink recording for current trial
WaitSecs(1);
if Eyelink('CheckRecording') ~=0                        % Check that EyeLink is recording
	Eyelink('CheckRecording')
    error('Problem with Eyelink!');
end
Eyelink('Stoprecording');                               % stop recording eye-movements


end

function Cleanup
Eyelink('Stoprecording');       % stop recording eye-movements
Eyelink('CloseFile');           % close data file
WaitSecs(1.0);                  % give tracker time to execute commands
Eyelink('Shutdown');            % shut down tracker
end