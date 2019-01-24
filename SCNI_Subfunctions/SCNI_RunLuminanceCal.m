function [Params] = SCNI_RunLuminanceCal(Params)

%========================= SCNI_RunLuminanceCal.m =========================
% Luminance calibration routine to display grey-scale and/or colour patches
% on screen. An alternative to PTB's CalibrateMonitorPhotometer.m, that
% allows easier normalization of gamma between two displays (or multiple 
% channels of a single display) for binocular presentation.
%
% INPUTS:
%   AppendFile:     name of .mat file to append luminance data to
%   DisplayName:    String input used to specify display being calibrated 
%   Manual:         Next value, 0 = automated, 1 = keypress
%   GammaTable:     .mat file containing normalized gamma values for each grey level
%                   e.g.[Lum] = LuminanceCal('MRproj_L',1)
%   StereoBuffer:   which stereobuffer to display on (0 = left, 1 = right)
%
% Konica-Minolta CS210 Colorimeter Serial Communication
%     'MDS,[][]'
%       00 : MINOLTA Standard Calibration Mode
%       01 : Optional Calibration Mode
%       04 : Chromaticity Measurement Mode
%       05 : Color Difference Measurement Mode
%       06 : Measurement Response Time --- 100ms Fast Mode
%       07 : Measurement Response Time --- 400ms Slow Mode
%
% Error Check Command Description
%       ER00 : Command Error, or Parameters Error
%       ER10 : Remote button not pressed
%       ER11 : Memory Values Error
%       ER20 : EEPROM Error
%       ER30 : Battely Out Error
%
%
% REVISIONS:
%   12/03/2013 - Written by APM
%   14/03/2013 - Updated for RGB calibration
%   22/03/2014 - Updated for serial communication & GUI inputs added
%   09/04/2015 - Updated to pause if 'remote button' error occurs
%   01/09/2019 - Updated for SCNI_Toolbar compatbility.
%     ___  ______  __   __
%    /   ||  __  \|  \ |  \    APM SUBFUNCTIONS
%   / /| || |__/ /|   \|   \   Aidan P. Murphy - apm909@bham.ac.uk
%  / __  ||  ___/ | |\   |\ \  Binocular Vision Lab
% /_/  |_||_|     |_| \__| \_\ University of Birmingham
%==========================================================================

global Auto CS210 Key Lum

%% ========================== GET USER INPUTS =============================
prompt      = {'Filename:', 'Number of displays:','Photometer model:','Auto measurement?','Apply CLUT?'};
dlg_title   = 'Calibration settings';
num_lines   = 1;
def         = {['Epson_',date],'2','CS210','yes','no'};
Inputs      = inputdlg(prompt,dlg_title,num_lines,def);
if isempty(Inputs)
    return;
end
Filename    = [Inputs{1},'.mat'];
NoDisplays  = str2num(Inputs{2});
Photometer  = Inputs{3};
Auto        = strcmpi(Inputs{4}(1),'Y');
ApplyCLUT   = strcmpi(Inputs{5}(1),'Y');

%========= CHECK DISPLAYS
switch NoDisplays
    case 1
        Inputs = inputdlg('Display ID:',dlg_title,num_lines,{['Epson_top_',date]});
        DisplayID{1} = Inputs;
    case 2
        Inputs = inputdlg({'Display #1 ID:','Display #2 ID:'},dlg_title,num_lines,{'Epson_top+filt','Epson_bottom+filt'});
        DisplayID = Inputs;
    otherwise
        h = warndlg(sprintf('Really, you have %d displays?! Give me a break!', NoDisplays),'Input error!','modal');
end

%========= CHECK FILENAME
if exist(Filename,'file')
    Msg = sprintf('The file ''%s'' already exists. What would you like to do?',Filename);
    Choice = questdlg(Msg,'File already exists','Replace','Append','Cancel','Cancel');
    switch Choice
        case 'Cancel'
            return;                 
        case 'Replace'
            delete(Filename);           
            D = 1;
        case 'Append'
            load(Filename);             
            D = numel(Lum)+1;
    end
else
    D = 1;
end

%========== FIND CLUT(s) TO APPLY
if ApplyCLUT
    FileTypes = {'*.mat;', 'CLUT (*.mat)'};
    [Filename, Pathname, filterindex] = uigetfile(FileTypes, 'Select color look up table(s) (CLUT)', 'MultiSelect', 'off');
    CLUTfile = fullfile(Pathname, Filename);
    load(CLUTfile);
end

%========== SET UP SERIAL PORT COMMUNICATION
if Auto == 1
    if ~strcmpi(Photometer,'CS210')
        Msg = sprintf('The photometer model specified is not recognized. What would you like to do?');
        Choice = questdlg(Msg,'Photometer not recognized','Try my luck','Cancel','Cancel');
        if strcmpi(Choice,'Cancel')
            return;
        end
    end
    CS210.COMportNo     = 3;
    CS210.BaudRate      = 4800;
    CS210.Parity        = 'even';
    CS210.DataBits      = 7;
    CS210.StopBits      = 2;
    CS210.Terminator    = 'CR';
    CS210.ErrorMsg = {  'ER00 : Command Error, or Parameters Error',...
                        'ER10 : Remote button not pressed',...
                        'ER11 : Memory Values Error',...
                        'ER20 : EEPROM Error',...
                        'ER30 : Battery out Error'};
    delete(instrfindall);                                   
    CS210.rscom = serial(sprintf('COM%d', CS210.COMportNo)); 	% Create serial port object
    set(CS210.rscom,'DataBits',CS210.DataBits,...               % Set defaults for CS210
                    'BaudRate',4800,...
                    'Parity',CS210.Parity,...
                    'StopBits',CS210.StopBits,...
                    'Terminator',CS210.Terminator);
 	try
        fopen(CS210.rscom);                                     % Try opening serial port
    catch
    	Msg = sprintf('Serial port connection failed! What would you like to do?');
        Choice = questdlg(Msg,'Serial connection failed','Try again','Manual calibration','Cancel','Cancel');
        switch Choice
            case 'Try again'
                fopen(CS210.rscom);                             % Open serial port
            case 'Manual calibration'
                Auto = 0;                                       % Set manual calibration flag
                CS210 = rmfield(CS210,'rscom');                 % Remove serial port object field
            case 'Cancel'
                return;
        end
    end
    if Auto
        fprintf(CS210.rscom, 'MDS,00');                         % Set measurement type
        WaitSecs(1);                                            % Wait for setting changes...
        Measurement = MeasureLum;                               % Perform dummy measurement
        fprintf('\nDummy measurement: Luminance = %.2f cd/m^2\n\n', Measurement); 
    end
end

%======================== GET USER DEFINED PARAMETERS =====================
UIControl_FontSize_bak = get(0, 'DefaultUIControlFontSize');
set(0, 'DefaultUIControlFontSize', 18);
prompt={'Number of pixel intensities (2-256)','Samples per intensity','Include RGB? (y/n)','Sample duration (s)'};
defaults= {'10','3','n','0.5'};
answer = inputdlg(prompt,'Luminance Calibration',1,defaults);


%======================== SET CALIBRATION PARAMETERS ======================
Lum(D).NoLevels         = str2num(answer{1});                               % How many pixel intensities to sample (2 - 256)                         
Lum(D).Levels           = round(linspace(0,255,Lum(D).NoLevels));           % Which pixel intensities
Lum(D).SamplesPerLevel  = str2num(answer{2});                               % How many samples for each pixel intensity
Lum(D).GreyScale       	= strcmpi(answer{3}(1),'n');                        % Present grey scale?
Lum(D).RGB              = strcmpi(answer{3}(1),'y');                     	% Present RGB?
Lum(D).SampleOrder      = repmat(Lum(D).Levels', [Lum(D).SamplesPerLevel, 1]);
if Lum(D).RGB == 1
    Lum(D).SampleColor = [repmat([1,0,0],[numel(Lum(D).SampleOrder), 1]); repmat([0,1,0],[numel(Lum(D).SampleOrder), 1]); repmat([0,0,1],[numel(Lum(D).SampleOrder), 1])];
  	Lum(D).SampleOrder = repmat(Lum(D).SampleOrder, [3,1]);                 % Triple number of samples
else
    Lum(D).SampleColor = repmat([1 1 1],[numel(Lum(D).SampleOrder), 1]);
end
NewOrder                = randperm(length(Lum(D).SampleOrder));
Lum(D).SampleOrder      = Lum(D).SampleOrder(NewOrder);
Lum(D).SampleColor      = Lum(D).SampleColor(NewOrder,:);
Lum(D).SampleDuration   = str2double(answer{4});                            % For automated calibration, how long should each sample display for (seconds)?
Lum(D).DisplayUpdate    = 1;                                                % Print text update to display screen?
Lum(D).FullScreen       = 1;
Lum(D).DisplayName      = Params.Display.ScreenID;
Lum(D).StereoBuffer     = 0;                                                % 0 = left buffer, 1 = right buffer, 2 = both


%======================== DEFINE KEYBOARD INPUTS
KbName('UnifyKeyNames');
Key.Abort       = KbName('Escape');
Key.Next        = KbName('rightarrow');
Key.Previous    = KbName('leftarrow');
Key.WaitTime    = 0.3;
Key.LastPress   = GetSecs;


%======================== OPEN ONSCREEN WINDOW(S) 
try
    Display = Params.Display;
    if Lum(D).FullScreen ~= 1
        Lum(D).DestRect = CenterRect(Display.Rect/2,Display.Rect);
    else
        Lum(D).DestRect = Display.XScreenRect;
    end
    if Lum(D).StereoBuffer == 2    
        Lum(D).DestRect = Lum(D).DestRect+[Display.Rect(3),0,Display.Rect(3),0];
        Lum(D).DestRect = Screen('rect',0);
    end

    [Display.win, Display.Rect] = Screen('OpenWindow', Display.ScreenID, Display.Exp.BackgroundColor*255,Lum(D).DestRect,[],[], Display.Stereomode);
    HideCursor;                                         
    MaxLevel = Screen('ColorRange', Display.win);                   % Get white value (e.g. 255?)


    %================== APPLY GAMMA TABLE?
    if ApplyCLUT
        if NoDisplays == 1
            OriginalGammaTable = Screen('LoadNormalizedGammaTable', Display.ScreenID, GammaTable); 	% Apply specified gamma table(s)
        elseif NoDisplays == 2

        end  
    elseif ~ApplyCLUT
        LoadIdentityClut(Display.win);                                                              % Load identity CLUT
    end

    %================== DISPLAY START SCREEN
    Text.String = sprintf('Press any key to begin measurement.');
    if Auto == 0
        Text.String = [Text.String, '\n\nUse the arrow keys to advance to next sample.'];
    end
    DisplayText(Text, Display);
    KbWait;
    WaitSecs(Key.WaitTime);


    %% ========================== BEGIN CALIBRATION ===========================
    S = 1;
    while S <= numel(Lum(D).SampleOrder)

        if Lum(D).DisplayUpdate == 1
            if ~isfield(CS210,'rscom')
                Text.String = sprintf('Current sample: %d / %d\nCurrent luminance = ? cd/m2\n[Input value and press Return]', S, numel(Lum(D).SampleOrder));
            elseif isfield(CS210,'rscom')
                Lum(D).TimeRemaining = (numel(Lum(D).SampleOrder)-S+1)*Lum(D).SampleDuration;
                if numel(num2str(ceil(rem(Lum(D).TimeRemaining, 60)))) < 2
                    TimeS = ['0', num2str(ceil(rem(Lum(D).TimeRemaining, 60)))];
                else
                    TimeS = num2str(ceil(rem(Lum(D).TimeRemaining, 60)));
                end
                Text.String = sprintf('Time remaining: %d:%s', floor(Lum(D).TimeRemaining/60),TimeS);
            end
            Text.Xpos = Display.Rect(1)+20;
            Text.Ypos = Display.Rect(4)-120;
            if Lum(D).SampleOrder(S) > 128
                Text.Colour = [0 0 0];
            else
                Text.Colour = [255 255 255];
            end
        end

        RGB = Lum(D).SampleOrder(S)*Lum(D).SampleColor(S,:);
        for Eye = 1:2
            currentbuffer = Screen('SelectStereoDrawBuffer', Display.win, Eye-1);
            Screen('FillRect', Display.win, RGB);
            if Lum(D).DisplayUpdate == 1
                DrawFormattedText(Display.win, Text.String, Text.Xpos, Text.Ypos, Text.Colour, []);
            end
        end
        [VBL FrameOnset] = Screen('Flip', Display.win);

        %=================== AUTOMATED LUMINANCE MEASUREMENT
        if isfield(CS210,'rscom')
            while GetSecs < FrameOnset + Lum(D).SampleDuration
                CheckPress;
            end
            Measurement = [];
            while isempty(Measurement)
                Measurement = MeasureLum;      
            end
            Lum(D).Measurement(S) = Measurement;                                    % Save luminance number to matrix
            Text.String = sprintf('Sample %d: Pixel intensity %d, Luminance = %.2f cd/m^2\n', S, Lum(D).SampleOrder(S), Lum(D).Measurement(S));
            fprintf(Text.String);
            S = S+1;    
    %         DrawFormattedText(Display.win, Text.String, Text.Xpos, Text.Ypos, Text.Colour, []);
    %         [VBL FrameOnset] = Screen('Flip', Display.win);
    %         WaitSecs(0.5);

     	%=================== MANUAL LUMINANCE MEASUREMENT
        elseif ~isfield(CS210,'rscom')
            Input = '?';
            while ischar(Input)
                Input = input('Input luminance measured for sample:');
            end
            Text.String = sprintf('Current sample: %d / %d\nCurrent luminance = %.2f cd/m2\n[Press right arrow for next sample]', S, numel(Lum(D).SampleOrder), Input);
            fprintf(Text.String);
    %         for Eye = 1:2
%                 currentbuffer = Screen('SelectStereoDrawBuffer', Display.win, Lum(D).StereoBuffer);
                Screen('FillRect', Display.win, RGB);
                DrawFormattedText(Display.win, Text.String, Text.Xpos, Text.Ypos, Text.Colour, []);
%                 currentbuffer = Screen('SelectStereoDrawBuffer', Display.win, double(~Lum(D).StereoBuffer));
%                 Screen('FillRect', Display.win, 0);
    %         end
            [VBL FrameOnset] = Screen('Flip', Display.win);
            NextSample = 0;
            while NextSample == 0
                [keyIsDown,secs,keyCode] = KbCheck;                         % Check keyboard for 'escape' press        
                if keyIsDown && secs > Key.LastPress+Key.WaitTime
                    Key.LastPress = secs;
                    if keyCode(Key.Abort)                                    % Press Esc for abort
                        Abort;
                    elseif keyCode(Key.Next)
                        Lum(D).Measurement(S) = Input;
                        S = S+1;
                        NextSample = 1;
                    elseif keyCode(Key.Previous) && S > 1
                        S = S-1;
                        NextSample = 1;
                    end
                end
            end

        end
        
    end

    %========================== CLOSE WINDOW AND SAVE DATA ====================
    RestoreCluts;               
    Screen('CloseAll');
    ShowCursor;
    filename = sprintf('%s_%s.mat',DisplayID{1},datestr(now,29));
    Lum(D).Time = datestr(now,29);
    save(filename, 'Lum'); 
    if isfield(CS210,'rscom')
        fclose(CS210.rscom);
    end

    %======================== ANALYSE AND PLOT DATA ===========================
    % AnalyseLuminances(filename,2,0);


catch
    RestoreCluts;
    Screen('CloseAll');
    ShowCursor;
    psychrethrow(psychlasterror);
    rethrow(lasterror);
    
end
end

%======================= CHECK FOR USER KEYBOARD INPUT ====================
function CheckPress
global Key
[keyIsDown,secs,keyCode] = KbCheck;                      	% Check keyboard for 'escape' press        
if keyIsDown && secs > Key.LastPress+Key.WaitTime
    Key.LastPress = secs;
    if keyCode(Key.Abort) == 1                           	% Press Esc for abort
        Abort;
    end
end
end

%============================ ABORT CALIBRATION ===========================
function Abort
global CS210
RestoreCluts;               
Screen('CloseAll');
ShowCursor;
if isfield(CS210,'rscom')
    fclose(CS210.rscom);
end
return;
end

%========================= GET LUMINANCE MEASUREMENT ======================
function Measurement = MeasureLum
global CS210
Measurement = [];                                               % Measurement output defaults to empty
try
    fprintf(CS210.rscom, 'MES');                                % Take a luminance measurement
    [line, nlin] = fscanf(CS210.rscom);                         % Read the output string
    ErrorType = strncmp(CS210.ErrorMsg, strtrim(line),4);       % Check whether the output is an error
    if ismember(ErrorType, [1,3,4,5])   
        Abort;
        error('Error reading luminance from CS210: %s\n', CS210.ErrorMsg{ErrorType});
    elseif ErrorType == 2                                        
        fprintf('Error: remote button not pressed! Press remote button on CS210 and then press any key to continue...\n');
        KbWait;
        
    else                                                        % If no error...
        ColonSep = findstr(line,';');                       	% Search for colon seperator
        if ~isempty(ColonSep)                                   % If colon seperator found...
            Measurement = str2num(line((ColonSep(end)+1):end));	% Save luminance number to variable  
        end
    end
catch
    Abort;
end
end

%========================= DisplayText.m
function DisplayText(Text, Display)

% Displays text provided in the input string 'Text.Text', on the screen with
% settings specified by structures 'Text' and 'Display'. See 'DisplaySettings.m' 
% for information on generating the Display sturcture. 
%
% INPUTS:
%   Text.String     Text string (string)
%   Text.Font       Text font name (string)
%   Text.Size       Text font size (double)
%   Text.Colour     Text color (RGB)

if nargin < 2, help DisplayText; end 
if ischar(Text), String = Text; clear Text; Text.String = String; end
if ~isfield(Text,'Font'), Text.Font = 'Arial'; end
if ~isfield(Text,'Size'), Text.Size = 36; end
if ~isfield(Text,'Colour'), Text.Colour = [0 0 0]; end
if isfield(Display,'Background')
    if Display.Background(1) == 0
        Text.Colour = [255 255 255];
    end
end 

if Display.Stereomode ~= 0
    Eyes = 2;
elseif Display.Stereomode == 0
    Eyes = 1;
end
Screen('TextFont', Display.win, Text.Font);                                 % Set text font
Screen('TextSize', Display.win, Text.Size);                                 % Set text size
for Eye = 1:Eyes
    currentbuffer = Screen('SelectStereoDrawBuffer', Display.win, Eye-1);  	% Draw to screen
    DrawFormattedText(Display.win, Text.String, 'center', 'center', Text.Colour, []);% Draw text
end
Screen('DrawingFinished',Display.win, 2);                                   % Drawing is finished
Screen('Flip',Display.win,[],[],[],1);                                      % Flip to all screens
return
end