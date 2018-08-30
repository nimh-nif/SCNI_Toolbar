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
if nargin == 0 || ~isfield(Params,'ImageExp') || ~isfield(Params.ImageExp,'ImgTex') || Params.ImageExp.ImagesLoaded == 0
    Params = SCNI_ShowImagesSettings(Params, 0);
end

%================= PRE-ALLOCATE RUN AND REWARD FIELDS
Params.Run.ValidFixations       = nan(Params.ImageExp.TrialsPerRun, (Params.ImageExp.DurationMs+Params.ImageExp.ISIMs)*10^-3*Params.DPx.AnalogInRate, 2);
Params.Run.LastRewardTime       = GetSecs;
Params.Run.StartTime            = GetSecs;
Params.Run.LastPress            = GetSecs;
Params.Run.TextColor            = [1,1,1]*255;
Params.Run.TextRect             = [100, 100, [100, 100]+[200,300]];
Params.Run.MaxTrialDur          = Params.ImageExp.StimPerTrial*(Params.ImageExp.DurationMs+Params.ImageExp.ISIMs+Params.ImageExp.ISIjitter)*10^-3;
Params.Run.TrialCount           = 1;                            % Start trial count at 1
Params.Run.StimCount            = 1;
Params.Run.ExpQuit              = 0;
Params.Run.Number               = 1; %<<<<< FUDGE - pretend it's the 1st run for now!
Params.Run.StimIsOn             = 0;

Params.Reward.Proportion        = 0.7;                          % Set proportion of reward interval that fixation must be maintained for (0-1)
Params.Reward.MeanIRI           = 4;                            % Set mean interval between reward delivery (seconds)
Params.Reward.RandIRI           = 2;                            % Set random jitter between reward delivery intervals (seconds)
Params.Reward.LastRewardTime    = GetSecs;                      % Initialize last reward delivery time (seconds)
Params.Reward.NextRewardInt     = Params.Reward.MeanIRI + rand(1)*Params.Reward.RandIRI;           	% Generate random interval before first reward delivery (seconds)
Params.Reward.TTLDur            = 0.05;                         % Set TTL pulse duration (seconds)
Params.Reward.RunCount          = 0;                            % Count how many reward delvieries in this run
Params.DPx.UseDPx               = 1;                            % Use DataPixx?

%================= OPEN NEW PTB WINDOW?
% if ~isfield(Params.Display, 'win')
    HideCursor;   
    Screen('Preference', 'VisualDebugLevel', 0);   
    Params.Display.ScreenID = max(Screen('Screens'));
    [Params.Display.win]    = Screen('OpenWindow', Params.Display.ScreenID, Params.Display.Exp.BackgroundColor, Params.Display.XScreenRect,[],[], [], []);
    Screen('BlendFunction', Params.Display.win, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);                        % Enable alpha channel
    Params.Display.ExpRect  = Params.Display.Rect;
    Params                  = SCNI_InitializeGrid(Params);
% end

%================= INITIALIZE DATAPIXX
if Params.DPx.UseDPx == 1
    Params = SCNI_DataPixxInit(Params);
end

%================= INITIALIZE KEYBOARD SHORTCUTS
KbName('UnifyKeyNames');
KeyNames                    = {'X','R','S'};         
KeyFunctions                = {'Stop','Reward','Sound'};
Params.ImageExp.KeysList       = zeros(1,256); 
for k = 1:numel(KeyNames)
    eval(sprintf('Params.ImageExp.Keys.%s = KbName(''%s'');', KeyFunctions{k}, KeyNames{k}));
    eval(sprintf('Params.ImageExp.KeysList(Params.ImageExp.Keys.%s) = 1;', KeyFunctions{k}));
end

%================= GENERATE FIXATION TEXTURE
if Params.ImageExp.FixType > 1
    Fix.Type        = Params.ImageExp.FixType-1;        % Fixation marker format
    Fix.Color       = [0,1,0];                          % Fixation marker color (RGB, 0-1)
    Fix.MarkerSize  = 1;                                % Fixation marker diameter (degrees)
    Fix.LineWidth   = 4;                                % Fixation marker line width (pixels)
    Fix.Size        = Fix.MarkerSize*Params.Display.PixPerDeg;
    Params.ImageExp.FixTex = SCNI_GenerateFixMarker(Fix, Params);
end

%================ PREPARE GRID FOR EXP. DISPLAY
Params = SCNI_InitializeGrid(Params);

%================= CALCULATE SCREEN RECTANGLES
if Params.ImageExp.Fullscreen == 1          %============ Fullscreen image
    Params.ImageExp.RectExp         = Params.Display.Rect;
    Params.ImageExp.RectMonk        = Params.Display.Rect + [Params.Display.Rect(3), 0, Params.Display.Rect(3), 0];
    if Params.ImageExp.FixType == 1                             % If fixation marker is OFF...
        Params.ImageExp.GazeRect 	= Params.ImageExp.RectExp;  % Anywhere on screen is valid eye position
    end
    
elseif Params.ImageExp.Fullscreen == 0      %============ Scaled image (degrees)
    Params.ImageExp.RectExp     = CenterRect([1, 1, Params.ImageExp.SizePix], Params.Display.Rect); 
    Params.ImageExp.RectMonk    = Params.ImageExp.RectExp + [Params.Display.Rect(3), 0, Params.Display.Rect(3), 0];
    if Params.ImageExp.FixType == 1                           	% If fixation marker is OFF...
        Params.ImageExp.GazeRect	= Params.ImageExp.RectExp + [-1,-1, 1, 1]*Params.ImageExp.GazeRectBorder*Params.Display.PixPerDeg(1);  	% Rectangle specifying gaze window on experimenter's display
    end
    
end
if Params.ImageExp.FixType > 1                                  % If fixation marker is ON...
    Params.ImageExp.GazeRect    = CenterRect([1,1,Params.ImageExp.FixWinDeg.*Params.Display.PixPerDeg], Params.Display.Rect);
end

%================= ADJUST FOR 3D FORMAT...
if Params.ImageExp.SBS3D == 1
    NoEyes                              = 2;
  	Params.ImageExp.SourceRectExp       = [1, 1, Params.ImageExp.SizePix(1)/2, Params.ImageExp.SizePix(2)];
    Params.ImageExp.SourceRectMonk      = [1, 1, Params.ImageExp.SizePix];
    Params.Display.FixRectExp           = CenterRect([1, 1, Fix.Size], Params.Display.Rect);
    Params.Display.FixRectMonk(1,:)     = CenterRect([1, 1, Fix.Size./[2,1]], Params.Display.Rect./[1,1,2,1]) + [Params.Display.Rect(3),0,Params.Display.Rect(3),0]; 
    Params.Display.FixRectMonk(2,:)     = Params.Display.FixRectMonk(1,:) + Params.Display.Rect([3,1,3,1]).*[0.5,0,0.5,0];
    
elseif Params.ImageExp.SBS3D == 0
    NoEyes                              = 1;
	Params.ImageExp.SourceRectExp       = [];
    Params.ImageExp.SourceRectMonk      = [];
    Params.Display.FixRectExp           = CenterRect([1, 1, Fix.Size], Params.Display.Rect);
    Params.Display.FixRectMonk(1,:)     = CenterRect([1, 1, Fix.Size], Params.Display.Rect + [Params.Display.Rect(3), 0, Params.Display.Rect(3), 0]); 
    Params.Display.FixRectMonk(2,:)     = Params.Display.FixRectMonk(1,:);
end
Params.Display.GazeRect = Params.ImageExp.GazeRect;



%================= LOAD / GENERATE STIMULUS ORDER
if ~isfield(Params.ImageExp, 'Design')
    Params.Design.Type          = Params.ImageExp.DesignType;
    Params.Design.TotalStim     = Params.ImageExp.TotalImages;
    Params.Design.StimPerTrial	= Params.ImageExp.StimPerTrial;
    Params.Design.TrialsPerRun  = Params.ImageExp.TrialsPerRun;
    Params                      = SCNI_GenerateDesign(Params, 0);
    Params                      = AllocateRand(Params);
end

%% ============================ BEGIN RUN =================================
FrameOnset              = GetSecs;

while Params.Run.TrialCount < Params.ImageExp.TrialsPerRun && Params.Run.ExpQuit == 0

    %================= Initialize DataPixx/ send event codes
    AdcStatus = SCNI_StartADC(Params);                                  % Start DataPixx ADC
    %ScannerOn = SCNI_WaitForTTL(Params, NoTTLs, 1, 1);                 % Wait for TTL pulses from MRI scanner
    SCNI_SendEventCode('Trial_Start', Params);                       	% Send event code to connected neurophys systems

    for StimNo = 1:Params.ImageExp.StimPerTrial                         % Loop through stimuli for this trial
        Params.Run.CurrentStimNo = StimNo;
        
        %% ================== WAIT FOR ISI TO ELAPSE ======================
        if StimNo == 1
            ISI = Params.ImageExp.InitialFixDur/10^3;
        elseif StimNo > 1
            if Params.ImageExp.ISIjitter == 0
                ISI = Params.ImageExp.ISIMs/10^3;
            elseif Params.ImageExp.ISIjitter ~= 0
                ISI = Params.ImageExp.ISIMs/10^3 + Params.Run.ISIjitter(Params.Run.StimCount);
            end
        end
        Params.Run.StimOffTime  = GetSecs;
        while (GetSecs - Params.Run.StimOffTime) < ISI && Params.Run.ExpQuit == 0
            
            Screen('FillRect', Params.Display.win, Params.Display.Exp.BackgroundColor*255);                                             % Clear previous frame
            for Eye = 1:NoEyes 
                if Params.Display.PD.Position > 1
                    Screen('FillOval', Params.Display.win, Params.Display.PD.Color{1}*255, Params.Display.PD.SubRect(Eye,:));
                    Screen('FillOval', Params.Display.win, Params.Display.PD.Color{1}*255, Params.Display.PD.ExpRect);
                end
                if Params.ImageExp.FixType > 1
                    Screen('DrawTexture', Params.Display.win, Params.ImageExp.FixTex, [], Params.Display.FixRectMonk(Eye,:));         % Draw fixation marker
                end
            end

            %=============== Check current eye position
            [EyeX,EyeY]     = SCNI_GetEyePos(Params);
            EyeRect         = repmat([round(EyeX), round(EyeY)],[1,2])+[-10,-10,10,10];               	% Get screen coordinates of current gaze position (pixels)
            FixIn           = IsInFixWin(EyeX, EyeY, Params);                                           % Check if gaze position is inside fixation window

            %=============== Check whether to deliver reward
            ValidFixNans 	= find(isnan(Params.Run.ValidFixations(Params.Run.TrialCount,:,:)), 1);  	% Find first NaN elements in fix vector
            Params.Run.ValidFixations(Params.Run.TrialCount, ValidFixNans,:) = [GetSecs, FixIn];     	% Save current fixation result to matrix
            Params       	= SCNI_CheckReward(Params);                                                          

            %=============== Draw experimenter's overlay
            if Params.Display.Exp.GridOn == 1
                Screen('FrameOval', Params.Display.win, Params.Display.Exp.GridColor*255, Params.Display.Grid.Bullseye, Params.Display.Grid.BullsEyeWidth);                % Draw grid lines
                Screen('FrameOval', Params.Display.win, Params.Display.Exp.GridColor*255, Params.Display.Grid.Bullseye(:,2:2:end), Params.Display.Grid.BullsEyeWidth+2);   % Draw even lines thicker
                Screen('DrawLines', Params.Display.win, Params.Display.Grid.Meridians, 1, Params.Display.Exp.GridColor*255);                
            end
            if Params.Display.Exp.GazeWinOn == 1
                if Params.ImageExp.FixType > 1
                    Screen('FrameOval', Params.Display.win, Params.Display.Exp.GazeWinColor(FixIn+1,:)*255, Params.ImageExp.GazeRect, 3); 	% Draw border of gaze window that subject must fixate within
                elseif Params.ImageExp.FixType == 1
                    Screen('FrameRect', Params.Display.win, Params.Display.Exp.GazeWinColor(FixIn+1,:)*255, Params.ImageExp.GazeRect, 3); 	% Draw border of gaze window that subject must fixate within
                end
            end
        	if Params.ImageExp.FixType > 1
                Screen('DrawTexture', Params.Display.win, Params.ImageExp.FixTex, [], Params.Display.FixRectExp);
            end
            Screen('FillOval', Params.Display.win, Params.Display.Exp.EyeColor(FixIn+1,:)*255, EyeRect);                            % Draw current gaze position
            Params       	= SCNI_UpdateStats(Params); 
            
            %=============== Draw to screen and record time
            [~,ISIoffset]  	= Screen('Flip', Params.Display.win); 
            if Params.Run.StimIsOn == 1                                                                 % If the stimulus was ON during the last frame...
                Params.Run.StimIsOn = 0;                                                                % Change state (stimulus is now off)
                SCNI_SendEventCode('Stim_Off', Params);                                                 % Send event code to connected neurophys systems
                Params.Run.StimOffTime = ISIoffset;                                                     % Record time stamp at which stimulus was removed
            elseif Params.Run.StimIsOn == 0
                if StimNo == 1                                                                          % If this is the first stimulus of the current trial...                                                          
                    SCNI_SendEventCode('Fix_On', Params);                                             	% Send event code to connected neurophys systems
                end
            end
            
            %=============== Check experimenter's input
            Params.Run.ExpQuit = CheckKeys(Params);                                                     % Check for keyboard input
            if isfield(Params.Toolbar,'StopButton') && get(Params.Toolbar.StopButton,'value')==1     	% Check for toolbar input
                Params.Run.ExpQuit = 1;
            end
        end

        %================= SET NEXT STIMULUS RECT
        RectExp     = Params.ImageExp.RectExp;
        RectMonk    = Params.ImageExp.RectMonk;
        if Params.ImageExp.ScaleJitter ~= 0
            RectExp     = Params.ImageExp.RectExp * Params.Run.ScaleJitter(Params.Run.StimCount);
            RectMonk    = Params.ImageExp.RectMonk * Params.Run.ScaleJitter(Params.Run.StimCount);
        end
        if Params.ImageExp.PosJitter ~= 0
            RectExp     = Params.ImageExp.RectExp + repmat(Params.Run.PosJitter(Params.Run.StimCount,:),[1,2]);
            RectMonk    = Params.ImageExp.RectMonk + repmat(Params.Run.PosJitter(Params.Run.StimCount,:),[1,2]);
        end

        %% ================= BEGIN NEXT IMAGE PRESENTATION ================
        Params.Run.StimOnTime = GetSecs;
        while (GetSecs-Params.Run.StimOnTime) < Params.ImageExp.DurationMs/10^3 && Params.Run.ExpQuit == 0

            %=============== Get next texture
            Cond = Params.Design.CondMatrix(Params.Run.Number, Params.Run.StimCount);                                       % Get condition number from design matrix
            Stim = Params.Design.StimMatrix(Params.Run.Number, Params.Run.StimCount);                                       % Get stimulus number from design matrix
            SCNI_SendEventCode(Stim, Params);                                                                               % Send stimulus number to neurophys. system 
            ImageTex = Params.ImageExp.ImgTex{Cond}(Stim);                                                                 	% Get texture handle for next stimulus
            if isfield(Params.ImageExp, 'BckgrndTex') && ~isempty(Params.ImageExp.BckgrndTex)                               % If background textures were loaded...
                BackgroundTex = Params.ImageExp.BckgrndTex{Cond}(Stim);                                                     % Get texture handle for corresponding background texture
            else
                BackgroundTex = [];
            end

            %=============== Begin drawing to displays
            Screen('FillRect', Params.Display.win, Params.Display.Exp.BackgroundColor*255);                                	% Clear previous frame                                                                          

            %============ Draw background texture
            if ~isempty(BackgroundTex)          
                Screen('DrawTexture', Params.Display.win, BackgroundTex, Params.ImageExp.SourceRectExp, RectExp);           % Draw to the experimenter's display
                Screen('DrawTexture', Params.Display.win, BackgroundTex, Params.ImageExp.SourceRectMonk, RectMonk);         % Draw to the subject's display
            end
            %============ Draw image texture
            Screen('DrawTexture', Params.Display.win, ImageTex, Params.ImageExp.SourceRectExp, RectExp, Params.ImageExp.Rotation, [], Params.ImageExp.Contrast);        % Draw to the experimenter's display
            Screen('DrawTexture', Params.Display.win, ImageTex, Params.ImageExp.SourceRectMonk, RectMonk, Params.ImageExp.Rotation, [], Params.ImageExp.Contrast);     % Draw to the subject's display
            %============ Draw mask texture
            if isfield(Params.ImageExp,'MaskTex') & ~isempty(Params.ImageExp.MaskTex)
                Screen('DrawTexture', Params.Display.win, Params.ImageExp.MaskTex, Params.ImageExp.SourceRectExp, RectExp);
                Screen('DrawTexture', Params.Display.win, Params.ImageExp.MaskTex, Params.ImageExp.SourceRectMonk, RectMonk);
            end
            
          	for Eye = 1:NoEyes     
                %============ Draw photodiode marker
                if Params.Display.PD.Position > 1
                    Screen('FillOval', Params.Display.win, Params.Display.PD.Color{2}*255, Params.Display.PD.SubRect(Eye,:));
                    Screen('FillOval', Params.Display.win, Params.Display.PD.Color{2}*255, Params.Display.PD.ExpRect);
                end
                %============ Draw fixation marker
                if Params.ImageExp.FixType > 1
                    Screen('DrawTexture', Params.Display.win, Params.ImageExp.FixTex, [], Params.Display.FixRectMonk(Eye,:));  	% Draw fixation marker
                end
            end

            %=============== Check current eye position
            [EyeX,EyeY]     = SCNI_GetEyePos(Params);
            EyeRect         = repmat([round(EyeX), round(EyeY)],[1,2])+[-10,-10,10,10];                                         % Get screen coordinates of current gaze position (pixels)
            FixIn           = IsInFixWin(EyeX, EyeY, Params);                                                                   % Check if gaze position is inside fixation window

            %=============== Check whether to deliver reward
            ValidFixNans 	= find(isnan(Params.Run.ValidFixations(Params.Run.TrialCount,:,:)), 1);                          	% Find first NaN elements in fix matrix
            Params.Run.ValidFixations(Params.Run.TrialCount, ValidFixNans,:) = [GetSecs, FixIn];                             	% Save current fixation result to matrix
            Params      	= SCNI_CheckReward(Params);                                                           

            %=============== Draw experimenter's overlay
            if Params.Display.Exp.GridOn == 1
                Screen('FrameOval', Params.Display.win, Params.Display.Exp.GridColor*255, Params.Display.Grid.Bullseye, Params.Display.Grid.BullsEyeWidth);                % Draw grid lines
                Screen('FrameOval', Params.Display.win, Params.Display.Exp.GridColor*255, Params.Display.Grid.Bullseye(:,2:2:end), Params.Display.Grid.BullsEyeWidth+2);   % Draw even lines thicker
                Screen('DrawLines', Params.Display.win, Params.Display.Grid.Meridians, 1, Params.Display.Exp.GridColor*255);                
            end
            if Params.Display.Exp.GazeWinOn == 1
                if Params.ImageExp.FixType > 1
                    Screen('FrameOval', Params.Display.win, Params.Display.Exp.GazeWinColor(FixIn+1,:)*255, Params.ImageExp.GazeRect, 3); 	% Draw border of gaze window that subject must fixate within
                elseif Params.ImageExp.FixType == 1
                    Screen('FrameRect', Params.Display.win, Params.Display.Exp.GazeWinColor(FixIn+1,:)*255, Params.ImageExp.GazeRect, 3); 	% Draw border of gaze window that subject must fixate within
                end
            end
         	if Params.ImageExp.FixType > 1
                Screen('DrawTexture', Params.Display.win, Params.ImageExp.FixTex, [], Params.Display.FixRectExp);
            end
            Screen('FillOval', Params.Display.win, Params.Display.Exp.EyeColor(FixIn+1,:)*255, EyeRect);    % Draw current gaze position
            Params         = SCNI_UpdateStats(Params);                                                      % Update statistics on experimenter's screen
            
            %=============== Draw to screen and record time
            [VBL FrameOnset(end+1)] = Screen('Flip', Params.Display.win);                                   % Flip next frame
            if Params.Run.StimIsOn == 0                                                                     % If this is first frame of stimulus presentation...
                SCNI_SendEventCode('Stim_On', Params);                                                      % Send event code to connected neurophys systems
                Params.Run.StimIsOn     = 1;                                                              	% Change flag to show movie has started
                Params.Run.StimOnTime   = FrameOnset(end);                                                  % Record stimulus onset time
            end
            
            %=============== Check experimenter's input
            Params.Run.ExpQuit = CheckKeys(Params);                                                         % Check for keyboard input
            if isfield(Params.Toolbar,'StopButton') && get(Params.Toolbar.StopButton,'value') == 1
                Params.Run.ExpQuit = 1;
            end

        end
        Params.Run.StimCount = Params.Run.StimCount+1;                                                      % Count as one stimulus presentation
    end
    

    %% ================= WAIT FOR ITI TO ELAPSE
    while (GetSecs - FrameOnset(end)) < Params.ImageExp.ITIms/10^3 && Params.Run.ExpQuit == 0
        for Eye = 1:NoEyes 
            Screen('FillRect', Params.Display.win, Params.Display.Exp.BackgroundColor*255);                                             	% Clear previous frame
            if Params.Display.PD.Position > 1
                Screen('FillOval', Params.Display.win, Params.Display.PD.Color{1}*255, Params.Display.PD.SubRect(Eye,:));
                Screen('FillOval', Params.Display.win, Params.Display.PD.Color{1}*255, Params.Display.PD.ExpRect);
            end
        end

        %=============== Check current eye position
        [EyeX,EyeY]     = SCNI_GetEyePos(Params);                                                  	% Get screen coordinates of current gaze position (pixels)
        EyeRect         = repmat([round(EyeX), round(EyeY)],[1,2])+[-10,-10,10,10];             	% Prepare rect to draw current gaze position
        
        %=============== Check whether to deliver reward
        Params       	= SCNI_CheckReward(Params);                                                          

        %=============== Draw experimenter's overlay
        if Params.Display.Exp.GridOn == 1
            Screen('FrameOval', Params.Display.win, Params.Display.Exp.GridColor*255, Params.Display.Grid.Bullseye, Params.Display.Grid.BullsEyeWidth);                % Draw grid lines
            Screen('FrameOval', Params.Display.win, Params.Display.Exp.GridColor*255, Params.Display.Grid.Bullseye(:,2:2:end), Params.Display.Grid.BullsEyeWidth+2);   % Draw even lines thicker
            Screen('DrawLines', Params.Display.win, Params.Display.Grid.Meridians, 1, Params.Display.Exp.GridColor*255);                
        end
        if Params.Display.Exp.GazeWinOn == 1
            if Params.ImageExp.FixType > 1
                Screen('FrameOval', Params.Display.win, Params.Display.Exp.GazeWinColor(FixIn+1,:)*255, Params.ImageExp.GazeRect, 3); 	% Draw border of gaze window that subject must fixate within
            elseif Params.ImageExp.FixType == 1
                Screen('FrameRect', Params.Display.win, Params.Display.Exp.GazeWinColor(FixIn+1,:)*255, Params.ImageExp.GazeRect, 3); 	% Draw border of gaze window that subject must fixate within
            end
        end
        Screen('FillOval', Params.Display.win, Params.Display.Exp.EyeColor(FixIn+1,:)*255, EyeRect);                            % Draw current gaze position
        Params       	= SCNI_UpdateStats(Params); 

        %=============== Draw to screen and record time
        [~,ISIoffset]  	= Screen('Flip', Params.Display.win); 
        if Params.Run.StimIsOn == 1
            Params.Run.StimIsOn     = 0;
            SCNI_SendEventCode('Stim_Off', Params);                                                         % Send event code to connected neurophys systems
            SCNI_SendEventCode('Fix_Off', Params);                                                          % Send event code to connected neurophys systems
            Params.Run.StimOffTime  = ISIoffset;
            Params.Run.StimOnTime   = ISIoffset;
        end
        
        %=============== Check experimenter's input
        Params.Run.ExpQuit = CheckKeys(Params);                                                     % Check for keyboard input
        if isfield(Params.Toolbar,'StopButton') && get(Params.Toolbar.StopButton,'value')==1    	% Check for toolbar input
            Params.Run.ExpQuit = 1;
        end
    end
    Params.Run.TrialCount = Params.Run.TrialCount+1;        % Count as one trial
    
end


%============== Run was aborted by experimenter
if Params.Run.ExpQuit == 1


end
    
SCNI_SendEventCode('Block_End', Params);   
SCNI_EndRun(Params);
 

end

%=============== CHECK FOR EXPERIMENTER INPUT
function EndRun = CheckKeys(Params)
    EndRun = 0;
    [keyIsDown,secs,keyCode] = KbCheck([], Params.ImageExp.KeysList);               % Check keyboard for relevant key presses 
    if keyIsDown && secs > Params.Run.LastPress+0.1                              	% If key is pressed and it's more than 100ms since last key press...
        Params.Run.LastPress   = secs;                                            	% Log time of current key press
        if keyCode(Params.ImageExp.Keys.Stop) == 1                                  % Experimenter pressed quit key
            SCNI_SendEventCode('ExpAborted', Params);                               % Inform neurophys. system
            SCNI_EndRun(Params);
            EndRun = 1;
        end
    end
end

%=============== END RUN
function SCNI_EndRun(Params)
    Screen('FillRect', Params.Display.win, Params.Display.Exp.BackgroundColor*255);     % Clear screens
    return;
end

%=============== PREALLOCATE RANDOMIZATIONS
function Params	= AllocateRand(Params)
    NoStim = Params.ImageExp.StimPerTrial*Params.ImageExp.TrialsPerRun;
    if Params.ImageExp.ISIjitter ~= 0
        Params.Run.ISIjitter = ((rand([1,NoStim])*2)-1)*Params.ImageExp.ISIjitter/10^3;
    end
    if Params.ImageExp.PosJitter ~= 0
        Params.Run.PosJitter = ((rand([2,NoStim])*2)-1)'.*Params.ImageExp.PosJitter.*Params.Display.PixPerDeg;
    end
    if Params.ImageExp.ScaleJitter ~= 0
    	Params.Run.ScaleJitter = ((rand([1,NoStim])*2)-1)*Params.ImageExp.ScaleJitter;
    end
end

%================= CHECK GAZE POSITION
function inside = IsInFixWin(x,y,Params)

    rect    = Params.ImageExp.GazeRect;
    shape   = Params.ImageExp.FixType>1;

    switch shape
        case 0  %========= Rectangular ROI
            if (x >= rect(RectLeft) && x <= rect(RectRight) && ...
                    y >= rect(RectTop) && y <= rect(RectBottom) )
                inside = 1;
            else
                inside = 0;
            end
            
        case 1  %========= Circular ROI
            x2 = x - Params.Display.Rect(3)/2;        % Calculate eye position relative to center of screen
            y2 = y - Params.Display.Rect(4)/2;
            if sqrt(x2^2 + y2^2) > diff(rect([RectLeft, RectRight]))/2
                inside = 0;
            elseif sqrt(x2^2 + y2^2) <= diff(rect([RectLeft, RectRight]))/2
                inside = 1;
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
        
        Params.Run.TextFormat    = ['Run             %d\n\n',...
                                    'Trial #         %d / %d\n\n',...
                                    'Stim #          %d / %d\n\n',...
                                    'Time elapsed    %02d:%02.0f\n\n',...
                                    'Reward count    %d\n\n',...
                                    'Valid fixation  %.0f %%'];
        if Params.Display.Rect(3) > 1920
           Screen('TextSize', Params.Display.win, 40);
           Screen('TextFont', Params.Display.win, 'Courier');
        end
    end

	Params.Run.ValidFixPercent = nanmean(nanmean(Params.Run.ValidFixations(1:Params.Run.TrialCount,:,2)))*100;

    %========= Update clock
	Params.Run.CurrentTime      = GetSecs-Params.Run.StartTime;                                            % Calulate time elapsed
    Params.Run.CurrentMins      = floor(Params.Run.CurrentTime/60);                    
    Params.Run.CurrentSecs      = rem(Params.Run.CurrentTime, 60);
    Params.Run.CurrentPercent   = (Params.Run.TrialCount/Params.ImageExp.TrialsPerRun)*100;
	Params.Run.TextContent      = [Params.Run.Number, Params.Run.TrialCount, Params.ImageExp.TrialsPerRun, Params.Run.CurrentStimNo, Params.ImageExp.StimPerTrial, Params.Run.CurrentMins, Params.Run.CurrentSecs, Params.Reward.RunCount, Params.Run.ValidFixPercent];
    Params.Run.TextString       = sprintf(Params.Run.TextFormat, Params.Run.TextContent);

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