function [PDS ,c ,s]= SCNI_calib_run(PDS ,c ,s)

%============================ SCNI_calib_run.m ==============================
% Execution of this m-file accomplishes a single fixation target presentation. 
% It is part of the loop controlled by the 'Run' action from the GUI; it is 
% preceded by 'next_trial' and followed by 'finish_trial'
%
%
% HISTORY:
%   2017-01-23 - Written by murphyap@mail.nih.gov based on psychmetic_run.m
%   2017-06-08 - Fixed ADC issues with help from Krauzlis lab members
%   2017-06-26 - Updated for use with SCNI passive 3D display
%   2017-07-06 - Adapted from SCNIblock_run.m
%   
%     ____    ___ __  _______
%    /    |  /  //  //  ____/    Neuro Imaging Facility Core
%   /  /| | /  //  //  /___      Building 49 Convent Drive
%  /  / | |/  //  //  ____/      NATIONAL INSTITUTES OF HEALTH
% /__/  |____//__//__/          
%==========================================================================

if c.UseDataPixx == 1
    PDS.datapixxtime(s.TrialNumber)	= Datapixx('GetTime');
end
% HideCursor(c.Display.ScreenID);                                                 % Turn off cursor display

%% ================== SETUP DATAPIXX ANALOG & DIGITAL I/O
if c.UseDataPixx == 1
    
    %================== Start ADC for recording analog signals
    Datapixx('RegWrRd');
    AdcStatus = Datapixx('GetAdcStatus');
    while AdcStatus.scheduleRunning == 1
        Datapixx('RegWrRd');
        AdcStatus = Datapixx('GetAdcStatus');
        WaitSecs(0.01);
    end
    Datapixx('SetAdcSchedule', 0, c.adcRate, c.nAdcLocalBuffSpls, c.ADCchannels, c.adcBuffBaseAddr, c.nAdcLocalBuffSpls);
    Datapixx('StartAdcSchedule');
    Datapixx('RegWrRd');                                                % Make sure a DAC schedule is not running before setting a new schedule

    %================== Set DAC schedule for reward delivery
    if c.AnalogReward == 1
        Dacstatus = Datapixx('GetDacStatus');                               % Check DAC status
        while Dacstatus.scheduleRunning == 1
            Datapixx('RegWrRd');
            Dacstatus = Datapixx('GetDacStatus');
        end
        Datapixx('RegWrRd');
        Datapixx('WriteDacBuffer', c.reward_Voltages, c.dacBuffAddr, c.RewardChnl);
        nChannels = Datapixx('GetDacNumChannels');
        Datapixx('SetDacVoltages', [0:nChannels-1; zeros(1, nChannels)]);    	% Set all DAC channels to 0V
    end
end



%% =================== Run main experiment loop ===========================
StimOn = 0;                     % Stimulus is not currently presented
c.StimOnTime = GetSecs;
while GetSecs < c.StimOnTime + c.StimDuration
    
    %============ Check current eye position
    if c.SimulateEyes ==0
        [s.EyeX,s.EyeY,V]       = GetEyePix(c);                                % Get instantaneous eye position
        s.EyeXc = s.EyeX - c.Display.Rect(3)/2;
        s.EyeYc = s.EyeY - c.Display.Rect(4)/2;
        
    elseif c.SimulateEyes == 1
        [s.EyeX,s.EyeY,buttons]	= GetMouse(c.window);                       % Get mouse cursor position (relative to subject display)
        s.EyeXc = s.EyeX-c.Display.Rect(3)/2;
        s.EyeYc = s.EyeY-c.Display.Rect(4)/2;
        if s.EyeX > c.Display.Rect(3) && s.EyeX < 2*c.Display.Rect(3)       % If mouse cursor is entering monkey's display...
            HideCursor;                                                     % Turn cursor off!
        else                                                                % Otherwise, mouse in on an experimenter display
            ShowCursor;                                                     % Show cursor
        end
    end
    EyeRect = repmat([round(s.EyeX), round(s.EyeY)],[1,2])+[-10,-10,10,10];
    [In, Dist]              = CheckFixation(s, c);                          % Check whether gaze position is within window
    if In == 1
        GazeColor = [0,255,0];
    else
        GazeColor = [255,0,0];
    end
    
    
    %% ============== Draw overlay
    %=========== Draw to monkey's screen
    if ~c.LinuxDisplay
        currentbuffer = Screen('SelectStereoDrawBuffer', c.window, c.MonkeyBuffer);     % Draw to monkey's screen first
    end
    Screen('FillRect', c.window, c.Col_bckgrndRGB);                                     % Clear previous frame
    for e = 1:size(c.MonkeyFixRect{1},1)
        Screen('DrawTexture', c.window, c.FixTexture, [], c.MonkeyFixRect{s.CondNo}(e,:));        % Draw fixation marker
    end
    if c.PhotodiodeOn == 1 
        for e = 1:size(c.MonkeyDiodeRect,1)
            Screen('FillOval', c.window, c.PhotodiodeOnCol, c.MonkeyDiodeRect(e,:));  	% Draw photodiode 'on' marker
        end
    end

    %=========== Draw to experimenter's screen
    if ~c.LinuxDisplay
        currentbuffer = Screen('SelectStereoDrawBuffer', c.window, c.ExperimenterBuffer);
        Screen('FillRect', c.window, c.Col_bckgrndRGB);
    end
%     if c.UseSBS3D == 0 
%         Screen('DrawTexture', c.window, c.ImageTexH, [], c.StimRect, c.Stim_Rotation, [], c.Stim_Contrast);
%     elseif c.UseSBS3D == 1
%         Screen('DrawTexture', c.window, c.ImageTexH, c.ExpStimRect, c.StimRect, c.Stim_Rotation, [], c.Stim_Contrast);
%     end
    for e = 1:size(c.FixRects{1},1)
        Screen('DrawTexture', c.window, c.FixTexture, [], c.FixRects{s.CondNo}(e,:));         	% Draw fixation marker
    end
    Screen('FrameOval', c.window, c.Col_gridRGB, c.Bullseye, c.BullsEyeWidth);                  % Draw grid lines
    Screen('FrameOval', c.window, c.Col_gridRGB, c.Bullseye(:,2:2:end), c.BullsEyeWidth+2);     % Draw even lines thicker
    Screen('DrawLines', c.window, c.Meridians, 1, c.Col_gridRGB);
    Screen('FrameOval', c.window, GazeColor, c.GazeRect{s.CondNo}, c.GazeRectWidth);          	% Draw border of gaze window that subject must fixate within
    Screen('FillOval', c.window, GazeColor, EyeRect);
    c = UpdateStats(c,s);
    DrawFormattedText(c.window, c.TextString, c.TextRect(1), c.TextRect(2), c.TextColor);


    %============= Present stimulus
    StimOnTime = Screen('Flip', c.window);                                  % Present visual stimulus now
    if StimOn == 0                                                          % If stimulus was not previously on the screen...
        c.StimOnTime = StimOnTime;                                          % Record stimulus onset timestamp
        StimOn = 1;                                                         % Change stimulus on flag
        fprintf('Stim on\n\n');
    end
    CheckPress(PDS, c, s);                                                  % Check experimenter's input
    
end
          

%============= DataPixx video timestamping
if ~strcmp(c.OverlayMode, 'PTB')
    PsychDataPixx('LogOnsetTimestamps', 1);
end
% if c.TrialNumber == 1
%     c.Blocks.BlockStartTime(s.TrialNumber) = c.StimOnTime-c.ScanStartedTime;
%     c.timeStamps(s.TrialNumber,3)=c.Blocks.BlockStartTime(s.TrialNumber);
% end
if ~strcmp(c.OverlayMode, 'PTB')
    moleTimetag = PsychDataPixx('GetLastOnsetTimestamp');
end



c.StimOffTime = GetSecs;
while GetSecs < c.StimOffTime + c.ISI     %=============== Stimulus off period
    
    %============ Check current eye position
    if c.SimulateEyes ==0
        [s.EyeX,s.EyeY,V]       = GetEyePix(c);                                % Get instantaneous eye position
        s.EyeXc = s.EyeX - c.Display.Rect(3)/2;
        s.EyeYc = s.EyeY - c.Display.Rect(4)/2;
        
    elseif c.SimulateEyes == 1
        [s.EyeX,s.EyeY,buttons]	= GetMouse(c.window);                       % Get mouse cursor position (relative to subject display)
        s.EyeXc = s.EyeX-c.Display.Rect(3)/2;
        s.EyeYc = s.EyeY-c.Display.Rect(4)/2;
        if s.EyeX > c.Display.Rect(3) && s.EyeX < 2*c.Display.Rect(3)       % If mouse cursor is entering monkey's display...
            HideCursor;                                                     % Turn cursor off!
        else                                                                % Otherwise, mouse in on an experimenter display
            ShowCursor;                                                     % Show cursor
        end
        if any(buttons)                                             

        end
        
    end

    EyeRect = repmat([round(s.EyeX), round(s.EyeY)],[1,2])+[-10,-10,10,10];
  	[In, Dist]              = CheckFixation(s, c);                          % Check whether gaze position is within window
    if In == 1
        GazeColor = [0,255,0];
    else
        GazeColor = [255,0,0];
    end
    
    %============== Check experimenter keyboard input
    CheckPress(PDS, c, s);

    
    %============== Draw overlay
    switch c.OverlayMode
        case 'M16'
            Screen('FillRect', c.overlay, c.transparencyColor);                     % Clear overlay
            Screen('FrameOval', c.overlay, c.Col_grid, c.Bullseye, 1);          	% draw grid lines on experimenter's display
            Screen('DrawLines', c.overlay, c.Meridians, 1, c.Col_grid);             % Draw vertical and horizontal meridians
            Screen('FrameOval', c.overlay, c.ExpOverlayIndx2, c.GazeRect{s.CondNo}, c.GazeRectWidth);      	% Draw border of gaze window that subject must fixate within
            Screen('FillOval', c.overlay, GazeColor, EyeRect);                      % Draw current gaze position
            DrawFormattedText(c.overlay, c.TextString, c.TextRect(1), c.TextRect(2), GazeColor);
            %Screen('DrawText', c.overlay, c.TextString, [], [],
            %c.ExpOverlayIndx);%
        case 'L48'
            Screen('FillRect', c.window, c.backdindex); 
            Screen('FrameOval', c.window, c.L48background, c.Bullseye, 1);          	% draw grid lines
            Screen('DrawLines', c.window, c.Meridians, 1, c.L48background);
            Screen('FrameOval', c.window, c.L48background, c.GazeRect{s.CondNo}, c.GazeRectWidth);            % Draw border of gaze window that subject must fixate within
            Screen('FillOval', c.window, c.L48background, EyeRect);   
            DrawFormattedText(c.window, c.TextString, c.TextRect(1), c.TextRect(2), c.L48background);
        case 'PTB'
            %=========== Draw to monkey's screen
            if ~c.LinuxDisplay
                currentbuffer = Screen('SelectStereoDrawBuffer', c.window, c.MonkeyBuffer); % Draw to monkey's screen first
            end
            Screen('FillRect', c.window, c.Col_bckgrndRGB);                             % Clear previous frame
          	if c.PhotodiodeOn == 1
                for e = 1:size(c.MonkeyDiodeRect,1)
                    Screen('FillOval', c.window, c.PhotodiodeOffCol, c.MonkeyDiodeRect(e,:));  	% Draw photodiode off marker
                end
            end
            
            %=========== Draw to experimenter's screen
            if ~c.LinuxDisplay
                currentbuffer = Screen('SelectStereoDrawBuffer', c.window, c.ExperimenterBuffer);
                Screen('FillRect', c.window, c.Col_bckgrndRGB);                       	% Clear previous frame
            end
            Screen('FrameOval', c.window, c.Col_gridRGB, c.Bullseye, c.BullsEyeWidth); 	% Draw experimenter's radial grid lines
            Screen('FrameOval', c.window, c.Col_gridRGB, c.Bullseye(:,2:2:end), c.BullsEyeWidth+2);
            Screen('DrawLines', c.window, c.Meridians, 1, c.Col_gridRGB);               % Draw meridians
            Screen('FrameOval', c.window, GazeColor, c.GazeRect{s.CondNo}, c.GazeRectWidth);    	% Draw border of gaze window that subject must fixate within
            Screen('FillOval', c.window, GazeColor, EyeRect);      
            c = UpdateStats(c,s);
            DrawFormattedText(c.window, c.TextString, c.TextRect(1), c.TextRect(2), c.TextColor);
    end
    %============= Present stimulus
    StimOffTime = Screen('Flip', c.window);                               	% Remove visual stimulus now
    if StimOn == 1                                                          % If stimulus was previously on the screen...
        c.StimOffTime = StimOffTime;                                      	% Record stimulus onset timestamp
        StimOn = 0;                                                         % Change stimulus on flag
        fprintf('Stim off\n\n');
    end
    CheckPress(PDS, c, s);                                                  % Check experimenter's input
    
end
                                                          


%================= Read continuously sampled Eye data
if c.UseDataPixx == 1
    Datapixx('RegWrRd');                                                            % Update registers for GetAdcStatus
    status = Datapixx('GetAdcStatus');                                              
    nReadSpls = status.newBufferFrames;                                             % How many samples can we read?
    [NewData, NewDataTs]= Datapixx('ReadAdcBuffer', nReadSpls, c.adcBuffBaseAddr); 	% Read all available samples from ADCs
	Datapixx('StopAdcSchedule'); 
    PDS.EyeXYP{s.TrialNumber, s.StimNumber}     = NewData(1:6,:);
    PDS.AnalogIn{s.TrialNumber, s.StimNumber}	= NewData(7:8,:);           
    PDS.Ts{s.TrialNumber, s.StimNumber}         = NewDataTs;
    save(c.Matfilename, '-append', 'PDS','c','s');
    
    [s, c] = SCNI_PlotEyeDataNIF(NewData(4:5,:), s, c);
    %[s, c] = PlotEyeData(NewData(1:6,:), s, c);
end

%================ Reward animal?
if c.Reward_MustFix == 1                    %========== If fixation is required for reward
	Valid = FindFixBreak(PDS.EyeXYP{s.TrialNumber, s.StimNumber}, c);       % Check whether fixation criteria were met for this trial
    if Valid == 1
        c.RewardEarned = 1;
    else
        c.RewardEarned = 0;
    end
end

if c.Reward_MustFix == 0 || c.RewardEarned == 1                                 % If fixation is not required OR fixation requirement has been met...
%     if GetSecs >= s.LastReward + c.NextRewardInt                                % If the time since the last automated reward exceeds the reward interval
%         SCNI_DigitalOutJuice(c.Reward_TTLDur);                                  % Deliver reward
%         disp('SCNI digital juice out')
%         s.RewardCount   = s.RewardCount + 1;
%         s.LastReward    = GetSecs;                                              % Record time of last automated reward delivery
%         c.NextRewardInt = c.Reward_MeanDur+rand(1)*c.Reward_RandDur;            % Generate random interval for next automated rward delivery
%         c.RewardEarned  = 0;
%     end
end





end
 

%% ==================== SCNIBLOCK SUBFUNCTIONS =============================

function [s, c] = PlotEyeData(NewData, s, c)
    if ~isfield(s, 'fh') || ~ishandle(s.fh)
        s.fh = figure('name','Eye data');
        FirstPlot = 1;
    else
        FirstPlot = 0;
        figure(s.fh);
        delete(s.ph);
    end
    s.ph(1) = plot(NewData(1,:),NewData(2,:), '-g');
    hold on
    s.ph(2) = plot(NewData(4,:),NewData(5,:), '-r');
    if FirstPlot == 1
        set(gca, 'color', [0.5,0.5,0.5], 'xlim', [-5 5], 'ylim', [-5 5], 'xtick', -5:1:5);
        grid on;
        xlabel('X voltage (V)')
        ylabel('Y voltage (V)')
        legend('Left eye', 'Right eye');
        hold on;
    end

end

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

%================= Check subject's gaze is within specified window
function [In, Dist] = CheckFixation(s, c)
    Dist = sqrt(s.EyeXc^2 + s.EyeYc^2);                   % Gaze distance from center of screen (pixels)
    if Dist <= c.Fix_WinRadius*c.Display.PixPerDeg          % Is gaze within specified radius?
        In = 1;
    else
        In = 0;
    end
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
    MaxBreakSamples = c.Eye_BlinkDuration*c.adcRate;                        % Calculate maximum acceptable number of samples gaze can leave fixation window without being penalized
    if any(FixAbsentSmpls > MaxBreakSamples)                                % If any fixation breaks exceeded permitted duration...
        ValidTrial = 0;                                                     % Invalid trial!
    else
        ValidTrial = 1;                                                     % Valid trial!
    end
end

%================= Update statistics for experimenter display =============
function c = UpdateStats(c, s)

    %========= Update clock
    c.Run.CurrentTime   = GetSecs-c.Run.StartTime;                                % Calulate time
    c.Run.CurrentMins   = floor(c.Run.CurrentTime/60);
    c.Run.CurrentSecs   = rem(c.Run.CurrentTime, 60);
    c.Run.CurrentTrial  = s.TrialNumber*c.TrialsPerRun + s.StimNumber;
    c.Run.CurrentPercent= c.Run.CurrentTrial/c.TrialsPerRun*c.StimPerTrial*100;
    c.TextFormat        = ['Stim      %d /%d\n\n',...
                           'Trial     %d /%d\n\n',...
                           'Run time  %02d:%02.0f\n\n',...
                           'Condition %d\n\n'];
    c.TextContent   = [s.StimNumber, c.StimPerTrial, s.TrialNumber, c.TrialsPerRun, c.Run.CurrentMins, c.Run.CurrentSecs, s.CondNo];
    c.TextString    = sprintf(c.TextFormat, c.TextContent);

    %========= Update stats
    currentbuffer = Screen('SelectStereoDrawBuffer', c.window, c.ExperimenterBuffer);
%     Screen('DrawTexture', c.window, c.BlockImgTex, [], c.BlockImgRect);
%     Screen('FrameRect', c.window, [0,0,0], c.BlockImgRect, 3);
%     c.BlockProgLen = c.BlockImgLen*(c.Run.CurrentPercent/100);
%     c.BlockProgRect = [c.BlockImgRect([1,2]), c.BlockProgLen+c.BlockImgRect(1), c.BlockImgRect(4)];
%     Screen('DrawTexture', c.window, c.BlockProgTex, [], c.BlockProgRect);
%     Screen('FrameRect', c.window, [0,0,0], c.BlockProgRect, 3);
end

%================= 
function out = checkJoy(pass,joy,th,pos)
% checkJoy is a boolean that is true if joy is less(pos=0; press) or greater(pos=1; greater) than th
% If PASS is on, it always returns TRUE.
    if pass == 0
        if pos == 0
            out = joy > th;
        else
            out = joy < th;
        end
    else
        out = 1;
    end
end

%
function joy = getjoy()
    Datapixx RegWrRd
    V       = Datapixx('GetAdcVoltages');       % 
    joy     = V(7);                             % joystick is on the 7th analog channel
    if joy<0
        joy=0;
    end
end

%================ Get current eye position in pixels from bottom left corner of screen
function [EyeX,EyeY,V] = GetEyePix(c)
	if c.SimulateEyes == 0
        TestWithFunctionGen = 1;
        if TestWithFunctionGen == 1
            EyeChannels = [8,7];
        else
            EyeChannels = [1,2];
        end
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

    Datapixx('RegWrRd');                                                % Update registers for GetAdcStatus
    status = Datapixx('GetAdcStatus');
    Datapixx('RegWrRd');                                                % Write local register cache to hardware
    Datapixx('RegWrRd');                                                % Give time for ADCs to convert, then read back data to local cache

    ScannerThresh   = 2.5;
    ScannerChannel  = find(~cellfun(@isempty, strfind(c.ADCchannelLabels, 'Scanner')));    % Find which ADC channel the scanner is connected to
    TTLcount        = 0;
    ScannerOn       = 0;
    NoSamples       = 5; 

    while TTLcount < NoTTLs
        if NoTTLs > 1                                                   % Print update to experimenter's screen only if waiting for more than 1 TTL pulse
            currentbuffer = Screen('SelectStereoDrawBuffer', c.window, c.ExperimenterBuffer);
            DrawFormattedText(c.window, sprintf('Waiting for TTL pulse %d/ %d from scanner...', TTLcount+1, NoTTLs), 'center','center', c.TextColor);
            Screen('Flip', c.window);  
        end
        while ScannerOn == 0
            status = Datapixx('GetAdcStatus');
            Datapixx('RegWrRd')
            V 	= Datapixx('GetAdcVoltages');
            if V(ScannerChannel) < ScannerThresh
                ScannerOn = 1;
            end
            CheckPress(PDS, c, s);                                      % Allow experimenter to abort if necessary
        end
        TTLcount = TTLcount+1;
        if TTLcount < NoTTLs                                            % If waiting for more TTL pulses...
            while ScannerOn == 1                                        % Wait for pulse to end
                status = Datapixx('GetAdcStatus');                      
                Datapixx('RegWrRd')
                V 	= Datapixx('GetAdcVoltages');
                if V(ScannerChannel) > ScannerThresh            
                    ScannerOn = 0;
                end
                CheckPress(PDS, c, s);                                  % Allow experimenter to abort if necessary
            end
        end
    end
    Datapixx('RegWrRd');
    
end



% %% ============== Omniplex/ TDT communication functions (UNUSED)
% % Starts saving data on Omniplex
% function startrecording
% 
% Datapixx('SetDoutValues',2^17,hex2dec('020000'))     % set RSTART to 1
% Datapixx('RegWrRd');
% end
% 
% % Stops saving data on Omniplex
% function stoprecording
% 
% Datapixx('SetDoutValues',0,hex2dec('020000'))       % set RSTART to 0
% Datapixx('RegWrRd');
% end

% % The function sends Omniplex stimuls tag info followed by its value.
% function sendOmniPlexStimInfo(c,s,state)
% % trial,block and set info
% sendStimTag(11001)
% sendStimValue(c.connectPLX)
% 
% sendStimTag(11002)
% sendStimValue(c.j)
% 
% sendStimTag(11003)
% sendStimValue(ceil(c.blockno))
% 
% sendStimTag(11004)
% sendStimValue(c.trinblk)
% 
% %trial type info
% sendStimTag(11010)
% sendStimValue(c.trialcode)
% 
% %trial result
% sendStimTag(11008)
% sendStimValue(state*10)
% 
% sendStimTag(16001)
% sendStimValue(floor(c.loc1deg*10))
% 
% sendStimTag(16002) %;%loc1 ecc
% sendStimValue(c.RFlocecc*10)
% 
% sendStimTag(16003)
% sendStimValue(floor(c.loc2deg*10))
% 
% sendStimTag(16004) ;%loc2 ecc same as loc 1
% sendStimValue(c.RFlocecc*10)
% 
% sendStimTag(16012)
% sendStimValue(c.loc1dir)
% 
% sendStimTag(16013)
% sendStimValue(c.loc2dir)
% 
% sendStimTag(16010)
% sendStimValue(c.loc1del)
% 
% sendStimTag(16011)
% sendStimValue(c.loc2del)
% 
% sendStimTag(18000)
% sendStimValue(floor(100*c.reward_size))
% 
% sendStimTag(11099)
% sendStimValue(3)
% 
% end

%========= Tag of a stimulus attribute
function sendStimTag(tag)
    % if isinteger(tag)
    strobe(tag)
    % else
    %     fprintf('tag not an integer.\n');
    % end
end

%========= Value of a stimulus attribute
function sendStimValue(value)
    %   if isinteger(value)
    strobe(value)
    %   else
    %     fprintf('stimulus value not an integer.\n');
    %   end
end

% %========= Strobe an integer
% function strobe(word)
% 
%     Datapixx('SetDoutValues',word,hex2dec('007fff'))    % set word in first 15 bits
%     Datapixx('RegWr');
%     Datapixx('SetDoutValues',2^16,hex2dec('010000'))   % set STRB to 1 (true)
%     Datapixx('RegWr');
%     Datapixx('SetDoutValues',0,hex2dec('017fff'))      % reset strobe and all 15 bits to 0.
%     Datapixx('RegWr');
% end
