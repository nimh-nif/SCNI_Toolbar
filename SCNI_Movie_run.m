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
    
    %================== Start ADC for recording analog signals
    Datapixx('RegWrRd');
    AdcStatus = Datapixx('GetAdcStatus');
    while AdcStatus.scheduleRunning == 1
        Datapixx('RegWrRd');
        AdcStatus = Datapixx('GetAdcStatus');
        WaitSecs(0.01);
    end
    Datapixx('SetAdcSchedule', 0, c.Params.DPx.AnalogInRate, c.Params.DPx.nAdcLocalBuffSpls, c.Params.DPx.AnalogInCh, c.Params.DPx.adcBuffBaseAddr, c.Params.DPx.nAdcLocalBuffSpls);
    Datapixx('StartAdcSchedule');
    Datapixx('RegWrRd');                                                % Make sure a DAC schedule is not running before setting a new schedule

    %================== Set DAC schedule for reward delivery
    if c.Params.DPx.AnalogReward == 1
        Dacstatus = Datapixx('GetDacStatus');                               % Check DAC status
        while Dacstatus.scheduleRunning == 1
            Datapixx('RegWrRd');
            Dacstatus = Datapixx('GetDacStatus');
        end
        Datapixx('RegWrRd');
        Datapixx('WriteDacBuffer', c.Params.DPx.reward_Voltages, c.Params.DPx.dacBuffAddr, c.Params.DPx.RewardChnl);
        nChannels = Datapixx('GetDacNumChannels');
        Datapixx('SetDacVoltages', [0:nChannels-1; zeros(1, nChannels)]);    	% Set all DAC channels to 0V
    end
    c.RestartDataPixx = 0;
end

% %============ Wait for dummy TTLs from MRI scanner
% if c.Blocks.Number == 1 && c.Blocks.TrialNumber == 1                        % If this is the first trial of a run...
%     c.ScanStartedTime = GetSecs;
%     if c.WaitForScanner == 1 && c.NumDummyTTLs > 0                          % If dummy TTLs were requested
%         ScannerOn   = getMRpulse(PDS, c, s, c.NumDummyTTLs);            	% Wait for N x TTL pulses from scanner indicating next MR acquisition
%         c.ScanStartedTime = GetSecs;
%     end
% end



%% ===================== DRAW NEXT FRAME TO SCREEN ========================
Screen('PlayMovie',c.mov,c.Movie.PlaybackRate,0,c.Movie.Volume);
Screen('SetmovieTimeIndex',c.mov, c.Movie.StartTime,0);  

if ~isfield(s,'framecount')
    s.framecount = 1;
    s.FrameOnTimes = zeros(1,1000);
end

    
%============ Check current eye position
if c.SimulateEyes ==0
    [s.EyeX,s.EyeY,V]       = GetEyePix(c);                                % Get instantaneous eye position
    s.EyeXc = s.EyeX - c.Display.Rect(3)/2;
    s.EyeYc = s.EyeY - c.Display.Rect(4)/2;

elseif c.SimulateEyes == 1
    [s.EyeX,s.EyeY,buttons]	= GetMouse(c.window);                       % Get mouse cursor position (relative to subject display)
    s.EyeXc = s.EyeX-c.Display.Rect(3)/2;                               % Find pixel location relative to center of experimenter display
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




%% =========== Draw to monkey's screen
if ~IsLinux
    currentbuffer = Screen('SelectStereoDrawBuffer', c.window, c.MonkeyBuffer);     % Draw to monkey's screen first
end
Screen('FillRect', c.window, c.Col_bckgrndRGB);                                     % Clear previous frame
% if c.Blocks.Order(c.Blocks.Number) ~= 0                                           % If the current block is not a fixation block...
    MovieTex = Screen('GetMovieImage', c.window, c.mov);                            % Get the next frame texture
    for Eye = 1:2                                                                   
        currentbuffer = Screen('SelectStereoDrawBuffer', c.window, Eye-1);        	
        Screen('DrawTexture', c.window, MovieTex, c.Movie.SourceRect{Eye}, c.Movie.MonkeyDestRect, c.Movie.Rotation, [], c.Movie.Contrast);
    end
% end
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
% if c.Blocks.Order(c.Blocks.Number) ~= 0
    if c.Display.UseSBS3D == 0 
        currentbuffer = Screen('SelectStereoDrawBuffer', c.window, 1);
        Screen('DrawTexture', c.window, MovieTex, [], c.Movie.ExpDestRect, c.Movie.Rotation, [], c.Movie.Contrast);
    elseif c.Display.UseSBS3D == 1
        currentbuffer = Screen('SelectStereoDrawBuffer', c.window, 1);
        Screen('DrawTexture', c.window, MovieTex, c.Movie.SourceRect{1}, c.Movie.ExpDestRect, c.Movie.Rotation, [], c.Movie.Contrast);
    end
%  end
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
Screen('FrameOval', c.window, GazeColor, c.GazeRect, c.GazeRectWidth);              % Draw border of gaze window that subject must fixate within
Screen('FillOval', c.window, GazeColor, EyeRect);
%         c = UpdateStats(c,s);
%         DrawFormattedText(c.window, c.TextString, c.TextRect(1), c.TextRect(2), c.TextColor);


%============= Present stimulus
s.FrameOnTimes(s.framecount) = Screen('Flip', c.window);                           	% Present visual stimulus now
Screen('Close', MovieTex);
c.Movie.FrameNumber = c.Movie.FrameNumber+1;    
s.framecount = s.framecount + 1;
% if MovieOn == 0                                                                   % If stimulus was not previously on the screen...
%     c.Movie.StartTime =  FrameOnTime;                                             % Record stimulus onset timestamp
%     SCNI_SendEventCode('Stim_On',c);
%     StimOn = 1;                                                               	% Change stimulus on flag
%     fprintf('Movie started\n\n');
% end
CheckPress(PDS, c, s);                                                  % Check experimenter's input


if s.framecount > 1000
    figure; hist(diff(FrameOnTime),100);
    s.framecount = 1;
end

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

function PlotEyeData(EyeData, fh)
    
    plot(NewData(1,:),NewData(2,:));
    


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
    MaxBreakSamples = c.Eye_BlinkDuration*c.Params.DPx.AnalogInRate;                        % Calculate maximum acceptable number of samples gaze can leave fixation window without being penalized
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
    c.Run.CurrentTrial  = (c.Blocks.Number-1)*size(c.Blocks.Stimorder, 2)+c.Blocks.TrialNumber;
    c.Run.CurrentPercent= c.Run.CurrentTrial/c.Run.TotalTrials*100;
    c.TextFormat        = ['Block     %d /%d\n\n',...
                           'Trial     %d /%d\n\n',...
                           'Run time  %02d:%02.0f\n\n',...
                           'Condition %d\n\n',...
                           'Stimulus  %d\n\n',...
                           'Rewards   %d'];
    if c.FixAfterEachBlock == 1;
        c.TextContent   = [c.Blocks.Number, c.Blocks.Total, c.Blocks.TrialNumber, size(c.Blocks.Stimorder, 2), c.Run.CurrentMins, c.Run.CurrentSecs, c.CondNo, c.ImageNo, s.RewardCount];
    else
        c.TextContent   = [c.Blocks.Number, c.Blocks.Total, c.Blocks.TrialNumber, size(c.Blocks.Stimorder, 2), c.Run.CurrentMins, c.Run.CurrentSecs, c.CondNo, c.ImageNo, s.RewardCount];
    end
    c.TextString    = sprintf(c.TextFormat, c.TextContent);

    %========= Update stats
    currentbuffer = Screen('SelectStereoDrawBuffer', c.window, c.ExperimenterBuffer);
    Screen('DrawTexture', c.window, c.BlockImgTex, [], c.BlockImgRect);
    Screen('FrameRect', c.window, [0,0,0], c.BlockImgRect, 3);
    c.BlockProgLen = c.BlockImgLen*(c.Run.CurrentPercent/100);
    c.BlockProgRect = [c.BlockImgRect([1,2]), c.BlockProgLen+c.BlockImgRect(1), c.BlockImgRect(4)];
    Screen('DrawTexture', c.window, c.BlockProgTex, [], c.BlockProgRect);
    Screen('FrameRect', c.window, [0,0,0], c.BlockProgRect, 3);
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
