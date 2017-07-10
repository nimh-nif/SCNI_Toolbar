function [CalWin] = EyelinkCalibration1(initials, Trial, SessionDir, ReturnWin)
% [CalWin] = EyelinkCalibration1(initials, Trial, SessionDir, ReturnWin)

%========================== EYELINK CALIBRATION ===========================
% Calibrates EyeLink by acquiring saccade data for targets at known onscreen
% positions.  Analyses eye position to allow subsequent conversion of 
% EyeLink eye position values from host PC pixels to presentation PC pixels
% or visual angle.
%
% For Windows, install necessary eyelink.dll in PTB directory
% Download: http://www.psychtoolbox.org/eyelinktoolbox/downloads/EyelinkToolbox144.zip 
% Copy EyelinkToolbox144\EyelinkToolbox\EyelinkBasic\eyelink.dll to
% Psychtoolbox\PsychHardware\EyelinkToolbox\EyelinkBasic\Eyelink.dll
%
% INPUTS:
%   initials:   Subject identifier.
%   Trial:      Calibration trial number.
%   SessionDir: Path to save the calibration results to.
%   ReturnWin:  Flag to indicate whether to keep PTB window open after
%               calibration has finished. If set to 0 the window will
%               close, while if set to 1 the window pointer will be
%               returned in the output 'CalWin'.
%
% DEPENDENCIES:
%   Psychtoolbox v3
%   APMSubfunctions\DisplaySettings.m
%   APMSubfunctions\EyeLinkSubfunctions\CalAnalysis.m
%
% REFERENCES:
% Cornelissen FW, Peters EM, Palmer J (2002).  The Eyelink Toolbox: Eye tracking
%       with MATLAB and the Psychophysics Toolbox.  Behaviour Research Methods,
%       34(4): 613-617. DOI: 10.3758/BF03195489
% Brainard DH (1997) The Psychophysics Toolbox. Spat Vis 10:433-436.
% Pelli DG (1997) The VideoToolbox software for visual psychophysics: 
%       transforming numbers into movies. Spat Vis 10:437-442.
%
% REVISIONS:
% 10/12/10: Created apm909@bham.ac.uk
% 16/02/11: updated for dual screen use (APM)
% 16/11/11: updated to optionally return PTB window (APM)
%     ___  ______  __   __
%    /   ||  __  \|  \ |  \    APM SUBFUNCTIONS
%   / /| || |__/ /|   \|   \   Aidan P. Murphy - apm909@bham.ac.uk
%  / __  ||  ___/ | |\   |\ \  Binocular Vision Lab
% /_/  |_||_|     |_| \__| \_\ University of Birmingham
%
%=========================================================================

if nargin < 2
    fprintf('EYELINK: Insufficient input arguments supplied!  I will assume this is a test run.\n');
    initials = 'TEST';
    Trial = 0;
    Test = 1;
end
if nargin < 3
    ExperimentPath = fileparts(mfilename('fullpath'));                                             % Get just the directory path 
    sessionDir = fullfile(ExperimentPath, initials, datestr(now, 'dd.mm.yyyy'), strcat('Cal', num2str(Trial)));
    ReturnWin = 0;
else
    sessionDir = SessionDir;
end
CalDir = fullfile(sessionDir, strcat('Cal', num2str(Trial)));
if exist(CalDir, 'dir')~=7 
    mkdir(CalDir);
end
edfFile = strcat('Cal', num2str(Trial));
fprintf('EYELINK: EyeLink Toolbox test performed on %s.\n', datestr(now,0));


%====================== OPEN PTB3 WINDOW ==================================
OpenWin = Screen('Windows');                                        % Check if a PTB3 window is currently open
if numel(OpenWin)>0                                                 % If a PTB window is currently open...
    CalWin = OpenWin(1);                                            % Use that window for calibration
elseif numel(OpenWin) == 0                                        	% If a PTB window is not currently open...
    HideCursor;         
    ListenChar(2);                                                  % supress keyboard input to command window
    warning off all;
    Display = DisplaySettings(1);                                	% Get display settings
    Screen('Preference', 'VisualDebugLevel', 1);                	% Make initial screen black instead of white
    [CalWin , rect] = Screen('OpenWindow', Display.ScreenID, [127 127 127], [], [], 2, Display.Stereomode , [], []);
end
[x,y] = RectCenter(rect);                                           % find centre of screen


%======= Draw gaze position tolerance window on the Eyelink host PC =======
el.backgroundcolour = gray;                                                 % Modify default colour settings
el.foregroundcolour = white;                                                

TargetSize = 10;        
TargetWindow = [0 0 TargetSize TargetSize];
TargetColour = [255 255 255];
TargetTolerance = 100;                                                      % Set target window tolerance (pixels)

FixBox = TargetSize + TargetTolerance*2;                                    % Calculate width of target window (pixels)
FixBoxRect = [(x-FixBox/2) (y-FixBox/2) (x+FixBox/2) (y+FixBox/2)];         % Fixation window  
CentreRect = [x-TargetSize/2, y-TargetSize/2, x+TargetSize/2, y+TargetSize/2];


%====================== CALCULATE TARGET POSITIONS ========================
rand('twister',sum(100*clock));                                 % seed random number generator using the current time
FixDur = 1.5;                                                   % Set fixation duration for targets (seconds)
InitialFixation = 2;                                            % Set initial and final fixation duration (seconds)
Repeats = 2;                                                    % Number of presentations of target at each target lcoation
TargetEcc = 6;                                                  % Set target eccentricity (degrees from edge of screen)
DisplayDeg = (Display.Rect([3 4])/2)/Display.Pixels_per_deg;    % Calculate display size in degrees
Offsets = floor(DisplayDeg)-TargetEcc;                      	% Set horizontal and vertical target offset intervals (degrees)   
TargetPos(1, [1 2]) = [Offsets(1), Offsets(2)];
TargetPos(2, [1 2]) = [Offsets(1), 0];
TargetPos(3, [1 2]) = [Offsets(1), -Offsets(2)];
TargetPos(4, [1 2]) = [0, -Offsets(2)];
TargetPos(5, [1 2]) = [-Offsets(1), -Offsets(2)];
TargetPos(6, [1 2]) = [-Offsets(1), 0];
TargetPos(7, [1 2]) = [-Offsets(1), Offsets(2)];
TargetPos(8, [1 2]) = [0, Offsets(2)];
TargetPos(9, [1 2]) = [0, 0];
TargetOrder = [];
for Rep = 1:Repeats
    TargetOrder(end+1:end+numel(TargetPos(:,1)),[1 2]) = TargetPos(randperm(numel(TargetPos(:,1))),:);
end
TargetPos = TargetOrder;            
for n = 1:numel(TargetPos(:,1))
    TargetOffset(n, :) = ([1 0 1 0]*TargetPos(n,1) + [0 1 0 1]*TargetPos(n,2))*Display.Pixels_per_deg;
    TargetRect(n,:) = CentreRect + TargetOffset(n,:);  
end

% NoTargets = 8;                                  % Set the total number of targets to present
% TargetPos = zeros(3, NoTargets);
% TargetPos(1, 1:NoTargets/2) = repmat(Offsets, [1, NoTargets/2/numel(Offsets)]);
% TargetPos(2, ((NoTargets/2)+1):end) = repmat(Offsets, [1, NoTargets/2/numel(Offsets)]);
% TargetPos(3, :) = ones(1,NoTargets);
% TargetPos(3, 1:numel(Offsets)*2:end) = -1;      
% TargetPos(3, 2:numel(Offsets)*2:end) = -1;
% TargetPos(4, :) = randperm(NoTargets);          % Randomize target order
% TargetPos = sortrows(TargetPos', 4);           
% for n = 1:numel(TargetPos(:,1))
%     TargetOffset(n,:) = ([1 0 1 0]*TargetPos(n,1) + [0 1 0 1]*TargetPos(n,2))*TargetPos(n,3)*Display.Pixels_per_deg;
%     TargetRect(n,:) = CentreRect + TargetOffset(n,:);  
% end

Posfile = fullfile(CalDir, strcat(initials, num2str(Trial), '_pos.mat'));
save(Posfile, 'TargetPos');
Background = [127 127 127];
DotTexture = Screen('MakeTexture', CalWin, ones(TargetSize, TargetSize)*Background(1));
Screen('FillOval', DotTexture, TargetColour);  

%====================== PRESENT INSTRUCTION SCREEN ========================
Instructions = sprintf(['CALIBRATION INSTRUCTIONS:\n\n\n\n',...
    'Keep looking at the white dot\n\n', ...
    'as it moves around the screen.\n\n\n\n', ...
    'Please press any key when you are ready to begin.']);                             % Instruction screen text
Display.win = CalWin;
DisplayText(Instructions, Display, 'Arial', 32);
KbWait;              

%======================== INITIALIZE EYELINK ==============================
if Test ~= 1
    edfFile = EyeLinkSetup(edfFile, Display, CalWin);
    Eyelink('command','clear_screen 0');                                        % clears the Eyelink-operator screen
    Eyelink('command','draw_box %d %d %d %d 7', FixBoxRect(1),FixBoxRect(2),FixBoxRect(3),FixBoxRect(4));   % Draw fixation window box to Eyelink-operator screen
end

%==================== PRESENT CENTRAL FIXATION TARGET =====================
currentbuffer = Screen('SelectStereoDrawBuffer', CalWin, 0);                               % Draw to LEFT eye
Screen('DrawTexture', CalWin, DotTexture, [], CentreRect);                                  % Draw left eye stimulus
currentbuffer = Screen('SelectStereoDrawBuffer', CalWin, 1);                               % Draw to RIGHT eye
Screen('DrawTexture', CalWin, DotTexture, [], CentreRect);                               	% Draw left eye stimulus
[VBL FixationOnset] = Screen('Flip', CalWin); 

if Test ~= 1
    Eyelink('message', 'FixationOn');
    Eyelink('StartRecording');                              % Start EyeLink recording
    if Eyelink('CheckRecording') ~=0                        % Check that EyeLink is recording
       error('Problem with Eyelink!');
    end
end
WaitSecs(InitialFixation);

%========================== PRESENT TARGETS ===============================
for Target = 1:numel(TargetRect(:,1))
%     Eyelink('message', 'TargetCoordinates: %d,%d,%d,%d', TargetRect(Target,:)); % Save target coordinates to EyeLink message
    currentbuffer = Screen('SelectStereoDrawBuffer', CalWin, 0);                % Draw to LEFT eye
    Screen('DrawTexture', CalWin, DotTexture, [], TargetRect(Target,:));        % Draw left eye stimulus
    currentbuffer = Screen('SelectStereoDrawBuffer', CalWin, 1);                % Draw to RIGHT eye
    Screen('DrawTexture', CalWin, DotTexture, [], TargetRect(Target,:));        % Draw left eye stimulus
    [VBL StimulusOnsetTime] = Screen('Flip', CalWin);                           % Present target screen
    if Test ~= 1
        Eyelink('message', 'TargetOn');                                             % Tell EyeLink that next target is on
    end
    while GetSecs < StimulusOnsetTime+FixDur
        [keyIsDown,secs,keyCode] = KbCheck;                                     % Check for keyboard key press
        if keyCode(27)                                                          % Abort if ESC key is pressed
            Cleanup;
            return;
        end

%         if Eyelink('NewFloatSampleAvailable') > 0           % If the next sample is available...
%             event = Eyelink( 'NewestFloatSample');          % get the sample in the form of an event structure
%             PosX = event.gx;                                % get x and y coordinates for both eyes
%             PosY = event.gy;
%             if PosX(1) ~= el.MISSING_DATA && PosY(1) ~= el.MISSING_DATA && event.pa(1)>0           % If LEFT eye data are valid...
%     %             DiffX = abs(PosX - TargetPos(1)) - FixBox/2;       
%     %             DiffY = abs(PosY - TargetPos(2)) - FixBox/2;
%     %             if (DiffX > 0 || DiffY > 0)
%     %                 Target = Target+1;
%     %             end
%             end
%     %         if PosX(2) ~= el.MISSING_DATA && PosY(2) ~= el.MISSING_DATA && event.pa(2)>0           % If RIGHT eye data are valid...
%     %             
%     %         
%     %         end
%         end

    end
    
%     %============== PRESENT CENTRAL FIXATION TARGET =======================
%     currentbuffer = Screen('SelectStereoDrawBuffer', CalWin, 0);        % Draw to LEFT eye
%     Screen('DrawTexture', CalWin, DotTexture, [], CentreRect);          % Draw left eye stimulus
%     currentbuffer = Screen('SelectStereoDrawBuffer', CalWin, 1);        % Draw to RIGHT eye
%     Screen('DrawTexture', CalWin, DotTexture, [], CentreRect);          % Draw left eye stimulus
%     [VBL FixationOnsetTime] = Screen('Flip', CalWin); 
%     if Test ~= 1
%         Eyelink('message', 'FixationOn');
%     end
%     WaitSecs(FixDur);
end

%============== PRESENT CENTRAL FIXATION TARGET =======================
currentbuffer = Screen('SelectStereoDrawBuffer', CalWin, 0);        % Draw to LEFT eye
Screen('DrawTexture', CalWin, DotTexture, [], CentreRect);          % Draw left eye stimulus
currentbuffer = Screen('SelectStereoDrawBuffer', CalWin, 1);        % Draw to RIGHT eye
Screen('DrawTexture', CalWin, DotTexture, [], CentreRect);          % Draw left eye stimulus
[VBL FixationOnsetTime] = Screen('Flip', CalWin); 
if Test ~= 1
    Eyelink('message', 'FixationOn');
end
WaitSecs(InitialFixation);

% WaitSecs(InitialFixation-FixDur);
Eyelink('message', 'StimulusOff');                              % Send 'stimulus off' message to EyeLink
currentbuffer = Screen('SelectStereoDrawBuffer', CalWin, 0);    % Draw to LEFT eye
Screen('FillRect', CalWin, Background);                         % Clear screen
currentbuffer = Screen('SelectStereoDrawBuffer', CalWin, 1);    % Draw to RIGHT eye
Screen('FillRect', CalWin, Background);                         % Clear screen
[VBL StimulusOnsetTime] = Screen('Flip', CalWin);               % Present blank screen
Eyelink('Stoprecording');                                       % stop recording eye-movements
Eyelink('CloseFile');                                           % close data file
DisplayText('Saving eye movement data...', Display, 'Arial', 32);

% try
    cd(CalDir);        
    fprintf('EYELINK: Receiving data file ''%s''\n', edfFile );  
    status = Eyelink('ReceiveFile');
    if status > 0
        fprintf('EYELINK: ReceiveFile status %d\n', status);     
    end
    if exist(edfFile, 'file') ==2                       % If the .edf file was sucessfully received...
        fprintf('EYELINK: Data file ''%s'' can be found in ''%s''\n\n', edfFile, pwd);
    end
% catch
%     fprintf('EYELINK: Problem receiving data file ''%s''\n\n', edfFile);
%     Eyelink('Shutdown');                                    % shut down tracker
%     Screen('Close', CalWin);                                % Close PTB window 
%     ListenChar(0);                                          % Restore keyboard output
%     ShowCursor;                                             % Show cursor
%     return;
% end

Eyelink('Shutdown');                                    % shut down tracker
if ReturnWin == 0
    Screen('Close', CalWin);                           	% Close PTB window 
    ListenChar(0);                                      % Restore keyboard output
    ShowCursor;                                         % Show cursor
    CalWin = nan;
end

%=========================== ANALYSE DATA =================================
cd(CalDir);                                   % Find folder to save .mat files to
fullfile(CalDir, edfFile)
E = dat2mat(fullfile(CalDir, edfFile));       % Convert .edf file to .mat file
EVT = evt2mat(fullfile(CalDir, edfFile));     % Convert .edf file to .mat file and events log

MatFile = fullfile(CalDir, strcat(edfFile(1:end-4), 'DAT.mat'));
[EL] = CalAnalysis(TargetPos, MatFile);


function Cleanup
Eyelink('Stoprecording');   % stop recording eye-movements
Eyelink('CloseFile');       % close data file
Waitsecs(1.0);              % give tracker time to execute commands
Eyelink('Shutdown');        % shut down tracker
sca;                        % Close PTB window 
ListenChar(0);              % Restore keyboard output
ShowCursor;                 % Show cursor