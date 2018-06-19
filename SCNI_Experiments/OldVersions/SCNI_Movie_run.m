function [PDS ,c ,s]= SCNI_Movie_run(PDS ,c ,s)

%============================ SCNIblock_run.m ==============================
% Execution of this m-file accomplishes one complete 'trial'. For the
% purpose of an fMRI block design, we consider one stimulus presentation
% to be a trial. It is part of the loop controlled by the 'Run' action from 
% the GUI; it is preceded by 'next_trial' and followed by 'finish_trial'
%
%
% HISTORY:
%   2017-01-23 - Written by murphyap@mail.nih.gov based on psychmetic_run.m
%   2017-06-08 - Fixed ADC issues with help from Krauzlis lab members
%   2017-06-26 - Updated for use with SCNI passive 3D display
%   2017-10-04 - Created movie experiment version
%     ____    ___ __  _______
%    /    |  /  //  //  ____/    Neuro Imaging Facility Core
%   /  /| | /  //  //  /___      Building 49 Convent Drive
%  /  / | |/  //  //  ____/      NATIONAL INSTITUTES OF HEALTH
% /__/  |____//__//__/          
%==========================================================================

if c.UseDataPixx == 1
    PDS.datapixxtime(c.Movie.FrameNumber)	= Datapixx('GetTime');
end
% HideCursor(c.Display.ScreenID);                                                 % Turn off cursor display

%% ================== SETUP DATAPIXX ANALOG & DIGITAL I/O
if c.RestartDataPixx == 1
    SCNI_StartADC(c.Params.DPx)
    c.RestartDataPixx = 0;
end


%% ===================== DRAW NEXT FRAME TO SCREEN ========================

if ~isfield(s,'framecount')
 
    %% ====================== LOAD MOVIE
%     c.Movie.Filename        =fullfile(c.Movie.Dir, sprintf('Movie%d%s',c.MovieNumber, c.Movie.Format));
    c.Movie.Filename        = c.Movie.AllFiles{c.MovieNumber};                              % Select one of the movies
    [c.mov, c.Movie.duration,  c.Movie.fps,  c.Movie.width,  c.Movie.height,  c.Movie.count,  c.Movie.AR]= Screen('OpenMovie', c.window, c.Movie.Filename); 
    c.Movie.StartTime   = 1;
    c.Movie.FrameNumber = 1;
    % Screen('PlayMovie',c.mov,1);
    % Screen('SetmovieTimeIndex',c.mov, c.Movie.StartTime,0);  
    c.Movie.SourceRect{2} = [0 0 c.Movie.width, c.Movie.height];

    if c.Movie.MaintainAR == 0
        if c.Movie.Fullscreen == 1
            c.Movie.DestRect = c.Display.Rect;
        elseif c.Movie.Fullscreen == 0
            c.Movie.DestRect = [0 0 MovieDims]*c.Display.PixPerDeg(1);
        end
    elseif c.Movie.MaintainAR == 1
        if c.Movie.Fullscreen == 1
            c.Movie.WidthDeg = c.Display.Rect(3);
        else
            c.Movie.WidthDeg = c.Movie.Rect(1)*c.Display.PixPerDeg(1);
        end
        c.Movie.DestRect = (c.Movie.SourceRect{2}/c.Movie.width)*c.Movie.WidthDeg;
    end
    if ~isempty(find(c.Movie.DestRect > c.Display.Rect))
        c.Movie.DestRect = c.Movie.DestRect*min(c.Display.Rect([3, 4])./c.Movie.Rect([3, 4]));
        fprintf('Requested movie size > screen size! Defaulting to maximum size.\n');
    end
    c.Movie.MonkeyDestRect  = CenterRect(c.Movie.DestRect, c.Display.Rect)+c.Display.Rect([3,1,3,1]);
    c.Movie.ExpDestRect     = CenterRect(c.Movie.DestRect, c.Display.Rect);
    if c.Movie.Stereo == 1
        if strcmpi(c.Movie.Format3D, 'LR')          % Horizontal split screen
            c.Movie.SourceRect{1} = c.Movie.SourceRect{2}./[1 1 2 1];
            c.Movie.SourceRect{2} = c.Movie.SourceRect{1}+[c.Movie.SourceRect{1}(3),0, c.Movie.SourceRect{1}(3),0];     
        elseif strcmpi(c.Movie.Format3D, 'RL')          
            c.Movie.SourceRect{2} = c.Movie.SourceRect{2}./[1 1 2 1];
            c.Movie.SourceRect{1} = c.Movie.SourceRect{2}+[c.Movie.SourceRect{2}(3),0, c.Movie.SourceRect{2}(3),0];  
        elseif strcmpi(c.Movie.Format3D, 'TB')      % Vertical split screen
            c.Movie.SourceRect{1} = c.Movie.SourceRect{2}./[1 1 1 2];
            c.Movie.SourceRect{2} = c.Movie.SourceRect{1}+[0,c.Movie.SourceRect{1}(4),0, c.Movie.SourceRect{1}(4)];
        else
            fprintf('\nERROR: 3D movie format must be specified in filename!\n');
        end
    else
        c.Movie.SourceRect{1} = c.Movie.SourceRect{2};
    end

    if c.Movie.Mirror == 1
        SourceRect = c.Movie.SourceRect{1}.*[1 1 2 1];
    end
    c.GazeRect = c.Movie.ExpDestRect + [repmat(-c.Fix_WinBorder,[1,2]).*c.Display.PixPerDeg, repmat(c.Fix_WinBorder,[1,2]).*c.Display.PixPerDeg];

    Screen('FillRect', c.window, c.Col_bckgrndRGB); 
    Screen('flip', c.window);
    
    %% =====================
    
    c.ValidFixations = nan(c.MaxTrialDur*c.Params.DPx.AnalogInRate, 2);
    c.LastRewardTime = GetSecs;
    
    %============ Wait for dummy TTLs from MRI scanner
    c.ScanStartedTime = GetSecs;
    SCNI_SendEventCode('Trial_Start', c);
    if c.WaitForScanner == 1 && c.NumDummyTTLs > 0                          % If dummy TTLs were requested
        ScannerOn   = getMRpulse(PDS, c, s, c.NumDummyTTLs);            	% Wait for N x TTL pulses from scanner indicating next MR acquisition
        c.ScanStartedTime = GetSecs;
    end
    
    %============ Present initial fixation
    if c.InitialFixDur > 0
        SCNI_SendEventCode('Fix_on', c);
        FixStart = GetSecs;
        while GetSecs < FixStart + c.InitialFixDur
            
            %====================== Get instantaneous eye position
            [s.EyeX,s.EyeY,V]       = GetEyePix(c);                                
            s.EyeXc = s.EyeX - c.Display.Rect(3)/2;
            s.EyeYc = s.EyeY - c.Display.Rect(4)/2;
            EyeRect = repmat([round(s.EyeX), round(s.EyeY)],[1,2])+[-10,-10,10,10];
            [In, Dist]              = CheckFixationRect(s, c);                              % Check whether gaze position is within window
            ValidFixNans            = find(isnan(c.ValidFixations));                        % Find NaN elements in fix vector
            c.ValidFixations(ValidFixNans(1),:) = [GetSecs, In];                           	% Save current fixation result to matrix
            if GetSecs > c.LastRewardTime + c.NextRewardInt                                 % If next reward is due...                       
                FixPeriodIndx   = find(c.ValidFixations(:,1) > c.LastRewardTime & c.ValidFixations(:,1) < c.LastRewardTime+c.NextRewardInt);
                ProportionValid = mean(c.ValidFixations(FixPeriodIndx,2));                  % Calulate proportion of interval that fixations were valid
                if ProportionValid > c.RewardProportion                                     % If proportion meets required proportion...
                    [PDS,c,s] = SCNI_givejuice(PDS, c, s);                                  % Give reward
                end
                c.NextRewardInt     = c.Reward_MeanDur+rand(1)*c.Reward_RandDur;           	% Generate random interval before first reward delivery (seconds)
                c.LastRewardTime    = GetSecs;
            end
            
            if In == 1
                GazeColor = [0,255,0];
            else
                GazeColor = [255,0,0];
            end
            
            %====================== Draw sceen elements
            Screen('FillRect', c.window, c.Movie.BackgroundColor);                        	% Clear previous frame
            for e = 1:size(c.MonkeyFixRect,1)                                               % For each eye...
                Screen('DrawTexture', c.window, c.FixTexture, [], c.MonkeyFixRect(e,:));  	% Draw fixation marker
            end
            Screen('DrawTexture', c.window, c.FixTexture, [], c.FixRect);                   % Draw fixation marker
            Screen('FrameOval', c.window, c.Col_gridRGB, c.Bullseye, c.BullsEyeWidth);     	% Draw grid lines
            Screen('FrameOval', c.window, c.Col_gridRGB, c.Bullseye(:,2:2:end), c.BullsEyeWidth+2); % Draw even lines thicker
            Screen('DrawLines', c.window, c.Meridians, 1, c.Col_gridRGB);
            Screen('FrameRect', c.window, GazeColor, c.GazeRect, c.GazeRectWidth);         	% Draw border of gaze window that subject must fixate within
            Screen('FillOval', c.window, GazeColor, EyeRect);
            c = UpdateStats(c,s);
            DrawFormattedText(c.window, c.TextString, c.TextRect(1), c.TextRect(2), c.TextColor);
            Screen('Flip', c.window);                                                       % Present fixation now
        end
    end
    s.framecount    = 1;
    s.FrameOnTimes  = zeros(1,1000);
    Screen('PlayMovie',c.mov,c.Movie.PlaybackRate,0,c.Movie.Volume);
    Screen('SetmovieTimeIndex',c.mov, c.Movie.StartTime,0);  
end

    
%============ Check current eye position
if c.SimulateEyes ==0
    [s.EyeX,s.EyeY,V]       = GetEyePix(c);                                % Get instantaneous eye position
    s.EyeXc = s.EyeX - c.Display.Rect(3)/2;
    s.EyeYc = s.EyeY - c.Display.Rect(4)/2;
    
elseif c.SimulateEyes == 1
    [s.EyeX,s.EyeY,buttons]	= GetMouse(c.window);                           % Get mouse cursor position (relative to subject display)
    s.EyeXc = s.EyeX-c.Display.Rect(3)/2;                                   % Find pixel location relative to center of experimenter display
    s.EyeYc = s.EyeY-c.Display.Rect(4)/2;
    if s.EyeX > c.Display.Rect(3) && s.EyeX < 2*c.Display.Rect(3)           % If mouse cursor is entering monkey's display...
        HideCursor;                                                         % Turn cursor off!
    else                                                                    % Otherwise, mouse in on an experimenter display
        ShowCursor;                                                         % Show cursor
    end
end
EyeRect = repmat([round(s.EyeX), round(s.EyeY)],[1,2])+[-10,-10,10,10];
[In, Dist]              = CheckFixationRect(s, c);                              % Check whether gaze position is within window
if In == 1
    GazeColor = [0,255,0];
else
    GazeColor = [255,0,0];
end

%=========== 
if GetSecs < c.RunStartTime + c.RunDuration
    ValidFixNans            = find(isnan(c.ValidFixations));                        % Find NaN elements in fix vector
    c.ValidFixations(ValidFixNans(1),:) = [GetSecs, In];                           	% Save current fixation result to matrix
    if GetSecs > c.LastRewardTime + c.NextRewardInt                                 % If next reward is due...                       
        FixPeriodIndx   = find(c.ValidFixations(:,1) > c.LastRewardTime & c.ValidFixations(:,1) < c.LastRewardTime+c.NextRewardInt);
        ProportionValid = mean(c.ValidFixations(FixPeriodIndx,2));                  % Calulate proportion of interval that fixations were valid
        if ProportionValid > c.RewardProportion                                     % If proportion meets required proportion...
            [PDS,c,s] = SCNI_givejuice(PDS, c, s);                                  % Give reward
        end
        c.NextRewardInt     = c.Reward_MeanDur+rand(1)*c.Reward_RandDur;           	% Generate random interval before first reward delivery (seconds)
        c.LastRewardTime    = GetSecs;
    end
end



%% =========== Draw to monkey's screen
if ~IsLinux
    currentbuffer = Screen('SelectStereoDrawBuffer', c.window, c.MonkeyBuffer);     % Draw to monkey's screen first
end
Screen('FillRect', c.window, c.Movie.BackgroundColor);                              % Clear previous frame
if GetSecs < c.RunStartTime + c.RunDuration                                         % If the current block is not a fixation block...
    MovieTex = Screen('GetMovieImage', c.window, c.mov);                            % Get the next frame texture
    for Eye = 1:2                                                                   
        currentbuffer = Screen('SelectStereoDrawBuffer', c.window, Eye-1);        	
        Screen('DrawTexture', c.window, MovieTex, c.Movie.SourceRect{Eye}, c.Movie.MonkeyDestRect, c.Movie.Rotation, [], c.Movie.Contrast);
    end
end
if c.Fix_On == 1                                                                    % If fixation marker was requested...
    for e = 1:size(c.MonkeyFixRect,1)                                               % For each eye...
        Screen('DrawTexture', c.window, c.FixTexture, [], c.MonkeyFixRect(e,:));  	% Draw fixation marker
    end
end
if c.PhotodiodeOn == 1                                                              % If photodiode marker was requested...
    for e = 1:size(c.MonkeyDiodeRect,1)                                             % For each eye...
        Screen('FillOval', c.window, c.PhotodiodeOnCol, c.MonkeyDiodeRect(e,:));  	% Draw photodiode 'on' marker
    end
end

%% =========== Draw to experimenter's screen
if ~IsLinux
    currentbuffer = Screen('SelectStereoDrawBuffer', c.window, c.ExperimenterBuffer);
    Screen('FillRect', c.window, c.Col_bckgrndRGB);
end
if GetSecs < c.RunStartTime + c.RunDuration
    if c.Display.UseSBS3D == 0 
        currentbuffer = Screen('SelectStereoDrawBuffer', c.window, 1);
        Screen('DrawTexture', c.window, MovieTex, [], c.Movie.ExpDestRect, c.Movie.Rotation, [], c.Movie.Contrast);
    elseif c.Display.UseSBS3D == 1
        currentbuffer = Screen('SelectStereoDrawBuffer', c.window, 1);
        Screen('DrawTexture', c.window, MovieTex, c.Movie.SourceRect{1}, c.Movie.ExpDestRect, c.Movie.Rotation, [], c.Movie.Contrast);
    end
end
if c.Fix_On == 1                                                                    % If fixation marker was requested...
    Screen('DrawTexture', c.window, c.FixTexture, [], c.FixRect);                   % Draw fixation marker
end
if c.PhotodiodeOn == 1                                                              % If photodiode marker was requested...
    for e = 1:size(c.ExpDiodeRect,1)                                                % For each eye...
        Screen('FillOval', c.window, c.PhotodiodeOnCol, c.ExpDiodeRect);            % Draw photodiode 'on' marker
    end
end
Screen('FrameOval', c.window, c.Col_gridRGB, c.Bullseye, c.BullsEyeWidth);          % Draw grid lines
Screen('FrameOval', c.window, c.Col_gridRGB, c.Bullseye(:,2:2:end), c.BullsEyeWidth+2); % Draw even lines thicker
Screen('DrawLines', c.window, c.Meridians, 1, c.Col_gridRGB);
Screen('FrameRect', c.window, GazeColor, c.GazeRect, c.GazeRectWidth);              % Draw border of gaze window that subject must fixate within
Screen('FillOval', c.window, GazeColor, EyeRect);
c = UpdateStats(c,s);
DrawFormattedText(c.window, c.TextString, c.TextRect(1), c.TextRect(2), c.TextColor);


%============= Present stimulus
s.FrameOnTimes(s.framecount) = Screen('Flip', c.window);                           	% Present visual stimulus now
if s.framecount == 1
    SCNI_SendEventCode('Stim_on', c);
end
if GetSecs < c.RunStartTime + c.RunDuration
    Screen('Close', MovieTex);
    c.Movie.FrameNumber = c.Movie.FrameNumber+1;    
    s.framecount = s.framecount + 1;
end
CheckPress(PDS, c, s);                                                  % Check experimenter's input


% if s.framecount > 1000
%     figure; hist(diff(s.FrameOnTimes),100);
%     s.framecount = 1;
% end

%============= DataPixx video timestamping
if ~strcmp(c.OverlayMode, 'PTB')
    PsychDataPixx('LogOnsetTimestamps', 1);
end
% if c.Blocks.TrialNumber == 1
%     c.Blocks.BlockStartTime(c.Blocks.Number) = c.StimOnTime-c.ScanStartedTime;
%     c.timeStamps(c.Blocks.Number,3)=c.Blocks.BlockStartTime(c.Blocks.Number);
% end
if ~strcmp(c.OverlayMode, 'PTB')
    moleTimetag = PsychDataPixx('GetLastOnsetTimestamp');
end


                                       


%================= Read continuously sampled Eye data
% if c.UseDataPixx == 1
%     Datapixx('RegWrRd');                                                            % Update registers for GetAdcStatus
%     status = Datapixx('GetAdcStatus');                                              
%     nReadSpls = status.newBufferFrames;                                             % How many samples can we read?
%     [NewData, NewDataTs]= Datapixx('ReadAdcBuffer', nReadSpls, c.Params.DPx.adcBuffBaseAddr); 	% Read all available samples from ADCs
% 	Datapixx('StopAdcSchedule'); 
%     PDS.EyeXYP{c.Blocks.Number, c.Blocks.TrialNumber}	= NewData(1:6,:);
%     PDS.AnalogIn{c.Blocks.Number, c.Blocks.TrialNumber}	= NewData(7:8,:);           
%     PDS.Ts{c.Blocks.Number, c.Blocks.TrialNumber}       = NewDataTs;
%     save(c.Matfilename, '-append', 'PDS','c','s');
%     
% end

% %================ Reward animal?
% if c.Reward_MustFix == 1                    %========== If fixation is required for reward
% 	Valid = FindFixBreak(PDS.EyeXYP{c.Blocks.Number, c.Blocks.TrialNumber}, c);	% Check whether fixation criteria were met for this trial
%     if Valid == 1
%         c.RewardEarned = 1;
%     else
%         c.RewardEarned = 0;
%     end
% end
% 
% if c.Reward_MustFix == 0 || c.RewardEarned == 1                                 % If fixation is not required OR fixation requirement has been met...
%     if GetSecs >= s.LastReward + c.NextRewardInt                                % If the time since the last automated reward exceeds the reward interval
%         SCNI_DigitalOutJuice(c.Reward_TTLDur);                                  % Deliver reward
%         disp('SCNI digital juice out')
%         s.RewardCount   = s.RewardCount + 1;
%         s.LastReward    = GetSecs;                                              % Record time of last automated reward delivery
%         c.NextRewardInt = c.Reward_MeanDur+rand(1)*c.Reward_RandDur;            % Generate random interval for next automated rward delivery
%         c.RewardEarned  = 0;
%     end
% end





end
 

%% ==================== SCNIBLOCK SUBFUNCTIONS =============================


%================= Check experimenter's keyboard input
function CheckPress(PDS, c, s)
    [keyIsDown, secs, keyCode, deltaSecs] = KbCheck();            	% Check if any key is pressed
    if keyIsDown 
        if keyCode(c.Key_Exit)                                      % If so...
            ManualAbort;                                            % Perform manual abort
        elseif keyCode(c.Key_Reward)                                % Manual reward delivery
            if secs > c.Key_LastPress+c.Key_MinRewardInt            % If last registered
                c.Key_LastPress = secs;                             % Update last valid reward delivery
                [PDS, c, s] = SCNI_givejuice(PDS, c, s);           	% Give reward
            end
        end
    end
end

%================= Manual Abort
function ManualAbort
    Screen('CloseAll');
    Datapixx('Close');
    ShowCursor;
    error('User manually aborted run!');
end


%================= Check subject's gaze is within specified radius
function [In, Dist] = CheckFixation(s, c)
    Dist = sqrt(s.EyeXc^2 + s.EyeYc^2);                   % Gaze distance from center of screen (pixels)
    if Dist <= c.Fix_WinRadius*c.Display.PixPerDeg          % Is gaze within specified radius?
        In = 1;
    else
        In = 0;
    end
end

%================= Check subject's gaze is within specified rectangle
function [In, Dist] = CheckFixationRect(s, c)
    In = IsInRect(s.EyeX, s.EyeY, c.GazeRect);
    Dist = [];
end


%================= Check gaze period 
function [ValidTrial] = FindFixBreak(EyeData, c)
    Dists           = sqrt(EyeData(1,:).^2 + EyeData(2,:).^2);           	% Calculate gaze distance from center of screen (pixels)
    InFix           = zeros(1, numel(Dists));                           	% Preallocate vector
    InFix(find(Dists <= mean(c.Fix_WinRadius*c.Display.PixPerDeg))) = 1;  	% If gaze was within specified radius, code as 1
    ProportionIn    = numel(find(InFix==1))/numel(InFix);                   % Calculate proportion of samples that gaze position was within fixation window
    FixBreakIndx    = find(diff(InFix)==-1);                                % Find samples at which gaze left fixation window
    FixReturnIndx   = find(diff(InFix)==1);                                 % Find samples at which gaze entered fixation window
    FixAbsentSmpls  = FixReturnIndx-FixBreakIndx;                           % Calculate duration of each fixation break period (samples)
    MaxBreakSamples = c.Eye_BlinkDuration*c.Params.DPx.AnalogInRate;                        % Calculate maximum acceptable number of samples gaze can leave fixation window without being penalized
    if any(FixAbsentSmpls > MaxBreakSamples)                                % If any fixation breaks exceeded permitted duration...
        ValidTrial = 0;                                                     % Invalid trial!
    else
        ValidTrial = 1;                                                     % Valid trial!
    end
end

%================= Update statistics for experimenter display =============
function c = UpdateStats(c, s)

    ValidFixPercent = nanmean(c.ValidFixations(:,2))*100;

    %========= Update clock
    c.Run.CurrentTime   = GetSecs-c.RunStartTime;                                % Calulate time
    c.Run.CurrentMins   = floor(c.Run.CurrentTime/60);
    c.Run.TotalMins     = floor(c.RunDuration/60);
    c.Run.CurrentSecs   = rem(c.Run.CurrentTime, 60);
    c.Run.CurrentPercent = (c.Run.CurrentTime/c.RunDuration)*100;
    c.TextFormat        = ['Movie ID        %d\n\n',...
                           'Time elapsed    %02d:%02.0f\n\n',...
                           'Time remaining  %02d:%02.0f\n\n',...
                           'Reward count    %d\n\n',...
                           'Valid fix (%%)   %.0f'];
	c.TextContent   = [c.MovieNumber, c.Run.CurrentMins, c.Run.CurrentSecs, c.Run.TotalMins-c.Run.CurrentMins-1, 60-c.Run.CurrentSecs, s.RewardCount, ValidFixPercent];
    c.TextString    = sprintf(c.TextFormat, c.TextContent);

    %========= Update stats
    currentbuffer = Screen('SelectStereoDrawBuffer', c.window, c.ExperimenterBuffer);
    Screen('DrawTexture', c.window, c.BlockImgTex, [], c.BlockImgRect);
    Screen('FrameRect', c.window, [0,0,0], c.BlockImgRect, 3);
    c.BlockProgLen      = c.BlockImgLen*(c.Run.CurrentPercent/100);
    c.BlockProgRect     = [c.BlockImgRect([1,2]), c.BlockProgLen+c.BlockImgRect(1), c.BlockImgRect(4)];
    Screen('DrawTexture', c.window, c.BlockProgTex, [], c.BlockProgRect);
    Screen('FrameRect', c.window, [0,0,0], c.BlockProgRect, 3);
end


%================ Get current eye position in pixels from bottom left corner of screen
function [EyeX,EyeY,V] = GetEyePix(c)
	if c.SimulateEyes == 0
     	EyeChannels = c.Params.DPx.ADCchannelsUsed([1,2]);
        Datapixx('RegWrRd');                                                % Update registers for GetAdcStatus
        status = Datapixx('GetAdcStatus');          
        Datapixx('RegWrRd');                                                % Update registers for GetAdcStatus
      	V       = Datapixx('GetAdcVoltages');                               % Read ADC voltages for all channels                
        Datapixx('RegWrRd'); 
        DVA     = (V(EyeChannels)+ c.EyeOffset).*c.EyeGain;                	% Convert volts into degrees of visual angle
     	EyeX    = c.Display.Rect(3)/2 + DVA(1)*c.Display.PixPerDeg(1);      % Convert degrees to pixels (sign change in X to account for camera invertion?)
        EyeY    = c.Display.Rect(4)/2 + DVA(2)*c.Display.PixPerDeg(2);      
  
    elseif c.SimulateEyes == 1
        [EyeX, EyeY] = GetMouse;
    end
end

%================ Wait for N x TTL pulse(s) from scanner ==================
% The Bruker vertical 4.7T outputs a constant +5V, with variable width 
% pulses of 0V that coincide with the start of either: 1) run, 2) volume,
% or 3) slice acquisition (this is set in the ParaVision console). 

function [ScannerOn] = getMRpulse(PDS, c, s, NoTTLs)
%
% while 1
Datapixx('RegWrRd');   % Update registers for GetAdcStatus
status = Datapixx('GetAdcStatus');
%     if (~status.scheduleRunning)
%         break;
%     end
% end
%if status.scheduleRunning == 0 && status.freeRunning == 0
% Datapixx('EnableAdcFreeRunning');                               % enable free running mode if ADC schedule stopped

Datapixx('RegWrRd');    % Write local register cache to hardware
Datapixx('RegWrRd');    % Give time for ADCs to convert, then read back data to local cache
%end
ScannerThresh   = 2.5;
ScannerChannel 	= find(~cellfun(@isempty, strfind(c.Params.DPx.AnalogInLabels,'Scanner TTL'))); % Find which ADC channel the scanner is connected to
TTLcount        = 0;
ScannerOn       = 0;
NoSamples       = 5;
SampleTime      = [];
LoopStartTime   = GetSecs;

while TTLcount < NoTTLs
    if NoTTLs > 1                                                   % Print update to experimenter's screen only if waiting for more than 1 TTL pulse
        currentbuffer = Screen('SelectStereoDrawBuffer', c.window, c.ExperimenterBuffer);
        DrawFormattedText(c.window, sprintf('Waiting for TTL pulse %d/ %d from scanner...', TTLcount+1, NoTTLs), 100,'center', c.TextColor);
        Screen('Flip', c.window);
    end
    while ScannerOn == 0
        % Wait for the ADC to finish acquiring its scheduled dataset
        %         while 1
        %             Datapixx('RegWrRd');   % Update registers for GetAdcStatus
        % % % % % % % % %         status = Datapixx('GetAdcStatus');
        % % % % % % % % %         if GetSecs > LoopStartTime+5
        % % % % % % % % %             status
        % % % % % % % % %             LoopStartTime = GetSecs;
        % % % % % % % % %         end
        %             if (~status.scheduleRunning)
        %                 break;
        %             end
        %         end
        
        Datapixx('RegWrRd');
        V 	= Datapixx('GetAdcVoltages');
        SampleTime(end+1) = GetSecs;
        if V(ScannerChannel) < ScannerThresh
            ScannerOn = 1;
            fprintf('Threshold crossing detected %.3f s\n', GetSecs-c.RunStartTime);
            fprintf('Mean sampling rate of loop = %.3f +/- %.3f ms\n', mean(diff(SampleTime))*1000, std(diff(SampleTime))*1000);
        end
        %         V2   = Datapixx('ReadAdcBuffer', NoSamples, c.adcBuffBaseAddr); 	% Read last 10 samples from ADCs
        %         ScannerSmpls = V2(ScannerChannel, :);                       % Check scanner ADC channel (+1 because Matlab indexing starts at 1)
        %         if any(ScannerSmpls < ScannerThresh)                        % If any samples drop below 2.5V...
        %             ScannerOn = 1;                                          % Scanner TTL has been received
        %         end
        CheckPress(PDS, c, s);                                      % Allow experimenter to abort if necessary
    end
    TTLcount = TTLcount+1;
    if TTLcount < NoTTLs                                            % If waiting for more TTL pulses...
        while ScannerOn == 1                                        % Wait for pulse to end
            %========== Method 1
            % Wait for the ADC to finish acquiring its scheduled dataset
            %             while 1
            %                 Datapixx('RegWrRd');   % Update registers for GetAdcStatus
            status = Datapixx('GetAdcStatus');
            %                 if (~status.scheduleRunning)
            %                     break;
            %                 end
            %             end
            Datapixx('RegWrRd');
            V 	= Datapixx('GetAdcVoltages');
            %                 AllVs(end+1) = V(ScannerChannel);
            if V(ScannerChannel) > ScannerThresh
                ScannerOn = 0;
            end
            %             %========== Method 2
            %             Datapixx('RegWrRd')
            %             V2   = Datapixx('ReadAdcBuffer', NoSamples, c.adcBuffBaseAddr);                % Read last 10 samples from ADCs
            %             ScannerSmpls = V2(ScannerChannel, :);                   % Check scanner ADC channel
            %             %                 AllV2s = [AllV2s, V2(ScannerChannel, :)];
            %             if any(ScannerSmpls > ScannerThresh)                    % If any samples drop below 2.5V...
            %                 ScannerOn = 0;                                      % Scanner TTL has been received
            %             end
            
            CheckPress(PDS, c, s);                                  % Allow experimenter to abort if necessary
        end
    end
end
% Datapixx('DisableAdcFreeRunning');
Datapixx('RegWrRd');

end

