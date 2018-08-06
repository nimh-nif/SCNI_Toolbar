function Params = SCNI_ShowImages(Params)

%=========================== SCNI_ShowImages.m ============================
% This function serves as a template for how to write an experiment using
% the SCNI toolbar subfunctions. As is, this particular function allows the
% experimenter to present a series of image files in an order of their
% choosing (e.g. a block design for fMRI experiments, or pseudorandomly for
% neurophysiology). The numerous variables can be adjusted by running the
% accompanying SCNI_ShowImagesSettings.m GUI and saving to your parameters
% file.
%
%==========================================================================

%================= SET DEFAULT PARAMETERS
if nargin == 0 || ~isfield(Params,'ImageExp')
    Params = SCNI_ShowImagesSettings(Params, 0);
end

%================= PRE-ALLOCATE RUN AND REWARD FIELDS
Params.Run.ValidFixations       = nan(Params.ImageExp.Duration*Params.DPx.AnalogInRate, 2);
Params.Run.LastRewardTime       = GetSecs;
Params.Run.StartTime            = GetSecs;
Params.Run.LastPress            = GetSecs;
Params.Run.TextColor            = [1,1,1]*255;
Params.Run.TextRect             = [100, 100, [100, 100]+[200,300]];
Params.Run.Duration             = Params.ImageExp.RunDuration;
Params.Run.MaxTrialDur          = Params.ImageExp.Duration;
Params.Run.TrialCount           = 1;                            % Start trial count at 1
Params.Run.ExpQuit              = 0;

Params.Reward.Proportion        = 0.7;                          % Set proportion of reward interval that fixation must be maintained for (0-1)
Params.Reward.MeanIRI           = 4;                            % Set mean interval between reward delivery (seconds)
Params.Reward.RandIRI           = 2;                            % Set random jitter between reward delivery intervals (seconds)
Params.Reward.LastRewardTime    = GetSecs;                      % Initialize last reward delivery time (seconds)
Params.Reward.NextRewardInt     = Params.Reward.MeanIRI + rand(1)*Params.Reward.RandIRI;           	% Generate random interval before first reward delivery (seconds)
Params.Reward.TTLDur            = 0.05;                         % Set TTL pulse duration (seconds)
Params.Reward.RunCount          = 0;                            % Count how many reward delvieries in this run
Params.DPx.UseDPx               = 1;                            % Use DataPixx?

%================= OPEN NEW PTB WINDOW?
if ~isfield(Params.Display, 'win')
    CloseOnFinish = 1;
    HideCursor;   
    KbName('UnifyKeyNames');
    Screen('Preference', 'VisualDebugLevel', 0);   
    Params.Display.ScreenID = max(Screen('Screens'));
    [Params.Display.win]    = Screen('OpenWindow', Params.Display.ScreenID, Params.Display.Exp.BackgroundColor, Params.Display.XScreenRect,[],[], [], []);
    Screen('BlendFunction', Params.Display.win, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);                        % Enable alpha channel
    Params.Display.ExpRect  = Params.Display.Rect;
    Params                  = SCNI_InitializeGrid(Params);
end

%================= INITIALIZE DATAPIXX
if Params.DPx.UseDPx == 1
    Params = SCNI_DataPixxInit(Params);
end

%================= CALCULATE SCREEN RECTANGLES
if Params.ImageExp.Fullscreen == 1
    Params.ImageExp.RectExp     = Params.Display.Rect;
    Params.ImageExp.RectMonk    = Params.Display.Rect + [Params.Display.Rect(3), 0, 0, 0];
    Params.ImageExp.GazeRect 	= Params.ImageExp.RectExp;
elseif Params.ImageExp.Fullscreen == 0
    Params.ImageExp.RectExp     = CenterRect([1, 1, Movie.width, Movie.height]*Params.ImageExp.Scale, Params.Display.Rect); 
    Params.ImageExp.RectMonk    = Params.ImageExp.RectExp + [Params.Display.Rect(3), 0, Params.Display.Rect(3), 0];
    Params.ImageExp.GazeRect 	= Params.ImageExp.RectExp + [-1,-1, 1, 1]*Params.ImageExp.GazeRectBorder*Params.Display.PixPerDeg(1);  	% Rectangle specifying gaze window on experimenter's display (overridden if fullscreen is selected)
end
if Params.ImageExp.SBS == 1
    NoEyes                      = 2;
    Params.ImageExp.SourceRect{1}  = [1, 1, Movie.width/2, Movie.height];
    Params.ImageExp.SourceRect{2}  = [(Movie.width/2)+1, 1, Movie.width, Movie.height];
elseif Params.ImageExp.SBS == 0
    NoEyes                      = 1;
    Params.ImageExp.SourceRect{1}  = [1, 1, Movie.width, Movie.height];
end
Params.Display.GazeRect = Params.ImageExp.GazeRect;


%================= BEGIN RUN
FrameOnset = GetSecs;
while EndRun == 0 && (GetSecs-Params.Run.StartTime) < Params.ImageExp.RunDuration

    if Params.Run.TrialCount > 1
        Params.Run.MoiveIndx(Params.Run.TrialCount) = randi(numel(Params.ImageExp.AllFiles));                   % <<<< RANDOMIZE movie order
        SCNI_SendEventCode(Params.Run.MoiveIndx(Params.Run.TrialCount), Params);                             % Send event code to connected neurophys systems
        Params.ImageExp.CurrentFile    = Params.ImageExp.AllFiles{Params.Run.MoiveIndx(Params.Run.TrialCount)};   
        [~,Params.ImageExp.Filename]   = fileparts(Params.ImageExp.CurrentFile);  
        [mov, Movie.duration, Movie.fps, Movie.width, Movie.height, Movie.count, Movie.AR] = Screen('OpenMovie', Params.Display.win, Params.ImageExp.CurrentFile); 
        Params.Run.mov = mov;
    end

    %================= Initialize DataPixx/ send event codes
    AdcStatus = SCNI_StartADC(Params);                                  % Start DataPixx ADC
    %ScannerOn = SCNI_WaitForTTL(Params, NoTTLs, 1, 1);                 % Wait for TTL pulses from MRI scanner
    SCNI_SendEventCode('Trial_Start', Params);                       	% Send event code to connected neurophys systems
    
    %================= WAIT FOR ISI TO ELAPSE
    while (GetSecs - FrameOnset(end)) < Params.ImageExp.ISIMs
        for Eye = 1:NoEyes 
            Screen('FillRect', Params.Display.win, Params.ImageExp.Background*255);                                             	% Clear previous frame
            if Params.Display.PD.Position > 1
                Screen('FillOval', Params.Display.win, Params.Display.PD.Color{1}*255, Params.Display.PD.SubRect(Eye,:));
                Screen('FillOval', Params.Display.win, Params.Display.PD.Color{1}*255, Params.Display.PD.ExpRect);
            end
            if Params.ImageExp.FixOn == 1
                Screen('DrawTexture', Params.Display.win, Params.Display.FixTexture, [], Params.Display.MonkeyFixRect(Eye,:));  	% Draw fixation marker
            end
        end

        %=============== Check current eye position
        [EyeX,EyeY]     = SCNI_GetEyePos(Params);
        EyeRect         = repmat([round(EyeX), round(EyeY)],[1,2])+[-10,-10,10,10];                 % Get screen coordinates of current gaze position (pixels)
        FixIn           = IsInRect(EyeX, EyeY, Params.Display.GazeRect);                            % Check if gaze position is inside fixation window

        %=============== Check whether to deliver reward
        ValidFixNans 	= find(isnan(Params.Run.ValidFixations), 1);                                % Find first NaN elements in fix vector
        Params.Run.ValidFixations(ValidFixNans,:) = [GetSecs, FixIn];                             	% Save current fixation result to matrix
        Params       	= SCNI_CheckReward(Params);                                                          

        %=============== Draw experimenter's overlay
        if Params.Display.Exp.GridOn == 1
            Screen('FrameOval', Params.Display.win, Params.Display.Exp.GridColor*255, Params.Display.Grid.Bullseye, Params.Display.Grid.BullsEyeWidth);                % Draw grid lines
            Screen('FrameOval', Params.Display.win, Params.Display.Exp.GridColor*255, Params.Display.Grid.Bullseye(:,2:2:end), Params.Display.Grid.BullsEyeWidth+2);   % Draw even lines thicker
            Screen('DrawLines', Params.Display.win, Params.Display.Grid.Meridians, 1, Params.Display.Exp.GridColor*255);                
        end
        if Params.Display.Exp.GazeWinOn == 1
            Screen('FrameRect', Params.Display.win, Params.Display.Exp.GazeWinColor(FixIn+1,:)*255, Params.ImageExp.GazeRect, 2); 	% Draw border of gaze window that subject must fixate within
        end
        Screen('FillOval', Params.Display.win, Params.Display.Exp.EyeColor(FixIn+1,:)*255, EyeRect);                            % Draw current gaze position
        Params       	= SCNI_UpdateStats(Params); 

        [~,ISIoffset]  	= Screen('Flip', Params.Display.win); 
        Params.Run.StimOnTime = ISIoffset;
        if Params.Run.TrialCount == 1
            Params.Run.StartTime  = ISIoffset;
        end
        EndRun = CheckKeys(Params);                                                   % Check for keyboard input
        if get(Params.Toolbar.StopButton,'value')==1                                    % Check for toolbar input
            EndRun = 1;
        end
    end

    
    %================= BEGIN CURRENT MOVIE PLAYBACK
    StimulusOn = 0;
    while EndRun == 0 && (FrameOnset(end)-Params.Run.StimOnTime) < Params.ImageExp.DurationMs
        
        %=============== Get next frame and draw to displays
      	ImageTex = Params.ImageExp.ImgTex{Cond}(Stim);                                                                      % Get texture handle for next stimulus
        if isfield(Params.ImageExp, 'BckgrndTex')
            BackgroundTex = Params.ImageExp.BckgrndTex{Cond}(Stim);
        end
        
        Screen('FillRect', Params.Display.win, Params.ImageExp.Background*255);                                             	% Clear previous frame
        for Eye = 1:NoEyes                                                                                                      % For each individual eye view...
            currentbuffer = Screen('SelectStereoDrawBuffer', Params.Display.win, Eye-1);                                        % Select the correct stereo buffer
            
            %============ Draw background texture
            if ~isempty(BackgroundTex)          
                Screen('DrawTexture', Params.Display.win, BackgroundTex, Params.ImageExp.SourceRect{1}, Params.ImageExp.RectExp);         % Draw to the experimenter's display
                Screen('DrawTexture', Params.Display.win, BackgroundTex, Params.ImageExp.SourceRect{Eye}, Params.ImageExp.RectMonk);      % Draw to the subject's display
            end
            %============ Draw image texture
            Screen('DrawTexture', Params.Display.win, ImageTex, Params.ImageExp.SourceRect{1}, Params.ImageExp.RectExp, Params.ImageExp.Rotation, [], Params.ImageExp.Contrast);        % Draw to the experimenter's display
            Screen('DrawTexture', Params.Display.win, ImageTex, Params.ImageExp.SourceRect{Eye}, Params.ImageExp.RectMonk, Params.ImageExp.Rotation, [], Params.ImageExp.Contrast);     % Draw to the subject's display
            %============ Draw mask texture
            if isfield(Params.ImageExp,'MaskTex')
                Screen('DrawTexture', Params.Display.win, Params.ImageExp,MaskTex, Params.ImageExp.SourceRect{1}, Params.ImageExp.RectExp);
                Screen('DrawTexture', Params.Display.win, Params.ImageExp,MaskTex, Params.ImageExp.SourceRect{Eye}, Params.ImageExp.RectMonk);
            end
            %============ Draw photodiode marker
            if Params.Display.PD.Position > 1
                Screen('FillOval', Params.Display.win, Params.Display.PD.Color{~Params.ImageExp.Paused+1}*255, Params.Display.PD.SubRect(Eye,:));
                Screen('FillOval', Params.Display.win, Params.Display.PD.Color{~Params.ImageExp.Paused+1}*255, Params.Display.PD.ExpRect);
            end
            %============ Draw fixation marker
            if Params.ImageExp.FixOn == 1
                Screen('DrawTexture', Params.Display.win, Params.Display.FixTexture, [], Params.Display.MonkeyFixRect(Eye,:));  	% Draw fixation marker
            end
        end

        %=============== Check current eye position
        [EyeX,EyeY]     = SCNI_GetEyePos(Params);
        EyeRect         = repmat([round(EyeX), round(EyeY)],[1,2])+[-10,-10,10,10];                 % Get screen coordinates of current gaze position (pixels)
        FixIn           = IsInRect(EyeX, EyeY, Params.Display.GazeRect);                            % Check if gaze position is inside fixation window

        %=============== Check whether to deliver reward
        ValidFixNans 	= find(isnan(Params.Run.ValidFixations), 1);                                % Find first NaN elements in fix vector
        Params.Run.ValidFixations(ValidFixNans,:) = [GetSecs, FixIn];                             	% Save current fixation result to matrix
        Params      	= SCNI_CheckReward(Params);                                                           

        %=============== Draw experimenter's overlay
        if Params.Display.Exp.GridOn == 1
            Screen('FrameOval', Params.Display.win, Params.Display.Exp.GridColor*255, Params.Display.Grid.Bullseye, Params.Display.Grid.BullsEyeWidth);                % Draw grid lines
            Screen('FrameOval', Params.Display.win, Params.Display.Exp.GridColor*255, Params.Display.Grid.Bullseye(:,2:2:end), Params.Display.Grid.BullsEyeWidth+2);   % Draw even lines thicker
            Screen('DrawLines', Params.Display.win, Params.Display.Grid.Meridians, 1, Params.Display.Exp.GridColor*255);                
        end
        if Params.Display.Exp.GazeWinOn == 1
            Screen('FrameRect', Params.Display.win, Params.Display.Exp.GazeWinColor(FixIn+1,:)*255, Params.ImageExp.GazeRect, 2); 	% Draw border of gaze window that subject must fixate within
        end
        Screen('FillOval', Params.Display.win, Params.Display.Exp.EyeColor(FixIn+1,:)*255, EyeRect);                            % Draw current gaze position
        Params         = SCNI_UpdateStats(Params);                                      % Update statistics on experimenter's screen
        if StimulusOn == 0                                                            % If this is first frame of stimulus presentation...
            SCNI_SendEventCode('Stim_On', Params);                                      % Send event code to connected neurophys systems
            StimulusOn = 1;                                                           % Change flag to show movie has started
        end
        [VBL FrameOnset(end+1)] = Screen('Flip', Params.Display.win);                   % Flip next frame
        EndRun = CheckKeys(Params);                                                     % Check for keyboard input
        if get(Params.Toolbar.StopButton,'value') == 1
            EndRun = 1;
        end

    end

    %================= END MOVIE PLAYBACK
  
    Params.Run.TrialCount = Params.Run.TrialCount+1;
end

if CloseOnFinish == 1
    sca;
end


end

%=============== CHECK FOR EXPERIMENTER INPUT
function EndRun = CheckKeys(Params)
    EndRun = 0;
    [keyIsDown,secs,keyCode] = KbCheck([], Params.ImageExp.KeysList);               % Check keyboard for relevant key presses 
    if keyIsDown && secs > Params.Run.LastPress+0.1                              	% If key is pressed and it's more than 100ms since last key press...
        Params.Run.LastPress   = secs;                                            	% Log time of current key press
        if keyCode(Params.ImageExp.Keys.Pause) == 1                              	% Experimenter pressed pause key
            Params.ImageExp.Paused      = ~Params.ImageExp.Paused;                 	% Toggle pause status
        elseif keyCode(Params.ImageExp.Keys.Stop) == 1                              % Experimenter pressed quit key
            EndRun = 1;
        end
    end
end

%================= UPDATE EXPERIMENTER'S DISPLAY STATS
function Params = SCNI_UpdateStats(Params)

    %=============== Initialize experimenter display
    if ~isfield(Params.Run, 'BlockImg')
    	Params.Run.Bar.Length   = 800;                                                                  % Specify length of progress bar (pixels)
        Params.Run.Bar.Labels   = {'Run %','Fix %'};
        Params.Run.Bar.Colors   = {[1,0,0], [0,1,0]};
        Params.Run.Bar.Img      = ones([50,Params.Run.Bar.Length]).*255;                             	% Create blank background image
        Params.Run.Bar.ImgTex 	= Screen('MakeTexture', Params.Display.win, Params.Run.Bar.Img);        % Generate texture handle for block design image
        for p = 10:10:90
            PercRect = [0, 0, p/100*Params.Run.Bar.Length, size(Params.Run.Bar.Img,1)]; 
        	Screen('FrameRect',Params.Run.Bar.ImgTex, [0.5,0.5,0.5]*255, PercRect, 2);
        end
        for B = 1:numel(Params.Run.Bar.Labels)
            Params.Run.Bar.TextRect{B}  = [20, Params.Display.Rect(4)-(B*100)];
            Params.Run.Bar.Rect{B}      = [200, Params.Display.Rect(4)-(B*100)-50, 200+Params.Run.Bar.Length, Params.Display.Rect(4)-(B*100)]; % Specify onscreen position to draw block design
            Params.Run.Bar.Overlay{B}   = zeros(size(Params.Run.Bar.Img));                              
            for ch = 1:3                                                                                
                Params.Run.Bar.Overlay{B}(:,:,ch) = Params.Run.Bar.Colors{B}(ch)*255;
            end
            Params.Run.Bar.Overlay{B}(:,:,4) = 0.5*255;                                               	% Set progress bar overlay opacity (0-255)
            Params.Run.Bar.ProgTex{B}  = Screen('MakeTexture', Params.Display.win, Params.Run.Bar.Overlay{B});            	% Create a texture handle for overlay
        end
        
        Params.Run.TextFormat    = ['Movie file      %s\n\n',...
                                    'Time elapsed    %02d:%02.0f\n\n',...
                                    'Time remaining  %02d:%02.0f\n\n',...
                                    'Reward count    %d\n\n',...
                                    'Valid fixation  %.0f %%'];
        if Params.Display.Rect(3) > 1920
           Screen('TextSize', Params.Display.win, 40);
           Screen('TextFont', Params.Display.win, 'Courier');
        end
        if Params.ImageExp.PlayMultiple == 1 && Params.ImageExp.Duration < Params.ImageExp.RunDuration           % If multiple movies are presented per trial
            Params.Run.TextFormat = [Params.Run.TextFormat, '\n\n',...                                  % Add movie count field
                                    'Movie count    %d'];
        end
    end

	Params.Run.ValidFixPercent = nanmean(Params.Run.ValidFixations(:,2))*100;

    %========= Update clock
    if Params.ImageExp.Paused == 1   
         Params.Run.CurrentTime   = Params.ImageExp.PauseTime;
    elseif Params.ImageExp.Paused == 0 
        Params.Run.CurrentTime   = GetSecs-Params.Run.StartTime;                                            % Calulate time elapsed
    end
    Params.Run.CurrentMins      = floor(Params.Run.CurrentTime/60);                    
    Params.Run.TotalMins        = floor(Params.Run.Duration/60);
    Params.Run.CurrentSecs      = rem(Params.Run.CurrentTime, 60);
    Params.Run.CurrentPercent   = (Params.Run.CurrentTime/Params.Run.Duration)*100;
	Params.Run.TextContent      = {Params.ImageExp.Filename, [Params.Run.CurrentMins, Params.Run.CurrentSecs, Params.Run.TotalMins-Params.Run.CurrentMins-1, 60-Params.Run.CurrentSecs, Params.Reward.RunCount, Params.Run.ValidFixPercent]};
    if Params.ImageExp.PlayMultiple == 1 && Params.ImageExp.Duration < Params.ImageExp.RunDuration                   % If multiple movies are presented per trial
        Params.Run.TextContent{2} = [Params.Run.TextContent{2}, Params.Run.TrialCount];                     % Append movie count
    end
    Params.Run.TextString       = sprintf(Params.Run.TextFormat, Params.Run.TextContent{1}, Params.Run.TextContent{2});

    %========= Update stats bars
    Params.Run.Bar.Prog = {Params.Run.CurrentPercent, Params.Run.ValidFixPercent};
    for B = 1:numel(Params.Run.Bar.Labels)
        Screen('DrawTexture', Params.Display.win, Params.Run.Bar.ImgTex, [], Params.Run.Bar.Rect{B});
        Screen('FrameRect', Params.Display.win, [0,0,0], Params.Run.Bar.Rect{B}, 3);
        if Params.Run.CurrentPercent > 0
            Params.Run.BlockProgLen      = Params.Run.Bar.Length*(Params.Run.Bar.Prog{B}/100);
            Params.Run.BlockProgRect     = [Params.Run.Bar.Rect{B}([1,2]), Params.Run.BlockProgLen+Params.Run.Bar.Rect{B}(1), Params.Run.Bar.Rect{B}(4)];
            Screen('DrawTexture',Params.Display.win, Params.Run.Bar.ProgTex{B}, [], Params.Run.BlockProgRect);
            Screen('FrameRect',Params.Display.win, [0,0,0], Params.Run.BlockProgRect, 3);
            DrawFormattedText(Params.Display.win, Params.Run.Bar.Labels{B}, Params.Run.Bar.TextRect{B}(1), Params.Run.Bar.TextRect{B}(2), Params.Run.TextColor);
        end
    end
    DrawFormattedText(Params.Display.win, Params.Run.TextString, Params.Run.TextRect(1), Params.Run.TextRect(2), Params.Run.TextColor);
end