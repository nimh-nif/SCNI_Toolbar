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
if nargin == 0 || ~isfield(Params,'ImageExp') || ~isfield(Params.ImageExp,'ImgTex') || (Params.ImageExp.Preload == 1 && Params.ImageExp.ImagesLoaded == 0)
    Params = SCNI_ShowImagesSettings(Params, 0);
end

%================= PRE-ALLOCATE RUN AND REWARD FIELDS
Params.Run.ValidFixations       = nan(Params.ImageExp.TrialsPerRun, (Params.ImageExp.DurationMs+Params.ImageExp.ISIms)/10^3*Params.DPx.AnalogInRate, 3);
Params.Run.LastRewardTime       = GetSecs;
Params.Run.StartTime            = GetSecs;
Params.Run.LastPress            = GetSecs;
Params.Run.TextColor            = [1,1,1]*255;
Params.Run.TextRect             = [100, 100, [100, 100]+[200,300]];
Params.Run.MaxTrialDur          = (Params.ImageExp.StimPerTrial*(Params.ImageExp.DurationMs+Params.ImageExp.ISIms+Params.ImageExp.ISIjitter)*10^-3)+1;
Params.Run.TrialCount           = 1;                            % Start trial count at 1
Params.Run.StimCount            = 1;
Params.Run.EndRun               = 0;
Params.Run.StimIsOn             = 0;
Params.Run.FixIsOn              = 0;
Params.Run.StimCodeSent        	= 0;
Params.Reward.RunCount          = 0;                            % Count how many reward delvieries in this run


%================= INITIALIZE SETTINGS
Params  = SCNI_OpenWindow(Params);                              % Open an new PTB window (if not already open)
Params  = SCNI_DataPixxInit(Params);                            
Params	= SCNI_InitializeGrid(Params);
Params	= SCNI_GetPDrect(Params, Params.Display.UseSBS3D);
Params  = SCNI_InitKeyboard(Params);

%================= GENERATE FIXATION TEXTURE
if Params.ImageExp.FixType > 1
    Fix.Type        = Params.ImageExp.FixType-1;                % Fixation marker format
    Fix.Color       = [0,1,0];                                 	% Fixation marker color (RGB, 0-1)
    Fix.MarkerSize  = 1;                                        % Fixation marker diameter (degrees)
    Fix.LineWidth   = 4;                                        % Fixation marker line width (pixels)
    Fix.Size        = Fix.MarkerSize*Params.Display.PixPerDeg;
    Params.ImageExp.FixTex = SCNI_GenerateFixMarker(Fix, Params);
end

%================= CALCULATE SCREEN RECTANGLES
img = imread(Params.ImageExp.ImByCond{1}{1});
%Params.ImageExp.SizePix = [size(img,2), size(img,1)];

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
if Params.ImageExp.SBS3D == 1                       % If images are rendered as SBS stereo 3D...
    if Params.Display.UseSBS3D == 1               	% If SBS stereo 3D presentation was requested...
        NoEyes                              = 2;
        Params.ImageExp.SourceRectExp       = [1, 1, Params.ImageExp.SizePix(1)/2, Params.ImageExp.SizePix(2)];
        Params.ImageExp.SourceRectMonk      = [1, 1, Params.ImageExp.SizePix];
        Params.Display.FixRectExp           = CenterRect([1, 1, Fix.Size], Params.Display.Rect);
        Params.Display.FixRectMonk(1,:)     = CenterRect([1, 1, Fix.Size./[2,1]], Params.Display.Rect./[1,1,2,1]) + [Params.Display.Rect(3),0,Params.Display.Rect(3),0]; 
        Params.Display.FixRectMonk(2,:)     = Params.Display.FixRectMonk(1,:) + Params.Display.Rect([3,1,3,1]).*[0.5,0,0.5,0];
    elseif Params.Display.UseSBS3D == 0            	% If SBS stereo 3D presentation was NOT requested...
        NoEyes                              = 1;
        Params.ImageExp.SourceRectExp       = [1, 1, Params.ImageExp.SizePix(1)/2, Params.ImageExp.SizePix(2)];
        Params.ImageExp.SourceRectMonk      = [1, 1, Params.ImageExp.SizePix(1)/2, Params.ImageExp.SizePix(2)];
        Params.Display.FixRectExp           = CenterRect([1, 1, Fix.Size], Params.Display.Rect);
        Params.Display.FixRectMonk(1,:)     = CenterRect([1, 1, Fix.Size], Params.Display.Rect + [Params.Display.Rect(3), 0, Params.Display.Rect(3), 0]); 
        Params.Display.FixRectMonk(2,:)     = Params.Display.FixRectMonk(1,:);
    end
    
elseif Params.ImageExp.SBS3D == 0                   % If images are rendered as regular 2D...
    NoEyes                                  = 1;
	Params.ImageExp.SourceRectExp           = [];
    Params.ImageExp.SourceRectMonk          = [];
    Params.Display.FixRectExp               = CenterRect([1, 1, Fix.Size], Params.Display.Rect);
    Params.Display.FixRectMonk(1,:)         = CenterRect([1, 1, Fix.Size], Params.Display.Rect + [Params.Display.Rect(3), 0, Params.Display.Rect(3), 0]); 
    Params.Display.FixRectMonk(2,:)         = Params.Display.FixRectMonk(1,:);
end
Params.Eye.GazeRect = Params.ImageExp.GazeRect;


%================= LOAD / GENERATE STIMULUS ORDER
%if ~isfield(Params.ImageExp, 'Design') || Params.Toolbar.CurrentRun == 1
    fprintf('Generating new design matrix for SCNI_ShowImages.m...\n');
    Params.Design.Type          = Params.ImageExp.DesignType;
    Params.Design.TotalStim     = Params.ImageExp.TotalImages;
    Params.Design.StimPerTrial	= Params.ImageExp.StimPerTrial;
    Params.Design.TrialsPerRun  = Params.ImageExp.TrialsPerRun;
    Params                      = SCNI_GenerateDesign(Params, 0);
    Params                      = AllocateRand(Params);
%end

SCNI_SaveExperiment(Params);    % Save all parameters for current run to .mat file

Stages(1).Name       = 'ISI';
Stages(1).StimOn     = 0;
Stages(2).Name       = 'Stimulus On';
Stages(2).Duration   = Params.ImageExp.DurationMs/10^3;
Stages(2).StimOn     = 1;

%================= Attempt to communicate eye calibration values to TDT via
% 13 bits!
Params = SendEyeCalToTDT(Params); 


%% ============================ BEGIN RUN =================================
FrameOnset              = GetSecs;

while Params.Run.TrialCount < Params.ImageExp.TrialsPerRun && Params.Run.EndRun == 0

    Params.Run.AbortTrial   = 0;
    AdcStatus = SCNI_StartADC(Params);                                      % Start DataPixx ADC running
    
    %================= Wait for TTL sync?
    if Params.Run.StimCount == 1 && ~isempty(Params.DPx.ScannerChannel)   	% If this is the first trial...
    	ScannerOn               = SCNI_WaitForTTL(Params, NoTTLs, 1, 1);   	% Wait for TTL pulses from MRI scanner
        Params.Run.StartTime  	= GetSecs;                                 	% Reset start time to after TTLs
    end
    SCNI_SendEventCode('Trial_Start', Params);                              % Send event code to connected neurophys systems

    
    %================== LOOP THROUGH STIMULI
    Params.Run.FixOnset = GetSecs;
    for StimNo = 1:Params.ImageExp.StimPerTrial                             % Loop through stimuli for this trial
       
        Params.Run.CurrentStimNo = StimNo;
        
        %================== GET TRIAL STAGE DURATIONS 
        if StimNo == 1
            ISI           	= Params.ImageExp.InitialFixDur/10^3;
            PDstatus     	= 2;
            
        elseif StimNo > 1
            if Params.ImageExp.ISIjitter == 0
                ISI = Params.ImageExp.ISIms/10^3;
            elseif Params.ImageExp.ISIjitter ~= 0
                ISI = Params.ImageExp.ISIms/10^3 + Params.Run.ISIjitter(Params.Run.StimCount);
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

        %=============== Get handle to next stimulus texture                                                         	
        Cond        = Params.Design.CondMatrix(Params.Toolbar.CurrentRun, Params.Run.StimCount);                     	% Get condition number from design matrix
        Stim        = Params.Design.StimMatrix(Params.Toolbar.CurrentRun, Params.Run.StimCount);                      	% Get stimulus number from design matrix
        if Params.ImageExp.Preload == 0
        	ImageTex    = LoadImage(Params, Cond, Stim);
            Params.ImageExp.MaskTex = [];
        elseif Params.ImageExp.Preload == 1
            ImageTex    = Params.ImageExp.ImgTex{Cond}(Stim);                                                             	% Get texture handle for next stimulus
        end
        if isfield(Params.ImageExp, 'BckgrndTex') && ~isempty(Params.ImageExp.BckgrndTex)                               % If background textures were loaded...
            BackgroundTex = Params.ImageExp.BckgrndTex{Cond}(Stim);                                                     % Get texture handle for corresponding background texture
        else
            BackgroundTex = [];
        end
        Params.Run.StimCodeSent	= 0;

        %% ================= BEGIN NEXT IMAGE PRESENTATION ================
        for stage = 1:numel(Stages)
            Stages(1).Duration              = ISI;
            Params.Run.StageOnTime(stage)	= GetSecs;
            PDstatus                        = 2;
            
            while (GetSecs-Params.Run.StageOnTime(stage)) < Stages(stage).Duration && Params.Run.AbortTrial == 0 && Params.Run.EndRun == 0

                %=============== Begin drawing to displays
                Screen('FillRect', Params.Display.win, Params.Display.Exp.BackgroundColor*255);                                     % Clear previous frame                                                                          

                if Stages(stage).StimOn == 1
                    %============ Draw background texture
                    if ~isempty(BackgroundTex)          
                        Screen('DrawTexture', Params.Display.win, BackgroundTex, Params.ImageExp.SourceRectExp, RectExp);               % Draw to the experimenter's display
                        Screen('DrawTexture', Params.Display.win, BackgroundTex, Params.ImageExp.SourceRectMonk, RectMonk);             % Draw to the subject's display
                    end
                    %============ Draw image texture
                    Screen('DrawTexture', Params.Display.win, ImageTex, Params.ImageExp.SourceRectExp, RectExp, Params.ImageExp.Rotation, [], Params.ImageExp.Contrast);        % Draw to the experimenter's display
                    Screen('DrawTexture', Params.Display.win, ImageTex, Params.ImageExp.SourceRectMonk, RectMonk, Params.ImageExp.Rotation, [], Params.ImageExp.Contrast);     % Draw to the subject's display
                    %============ Draw mask texture
                    if isfield(Params.ImageExp,'MaskTex') & ~isempty(Params.ImageExp.MaskTex) & Params.ImageExp.MaskType > 1
                        Screen('DrawTexture', Params.Display.win, Params.ImageExp.MaskTex, Params.ImageExp.SourceRectExp, RectExp);
                        Screen('DrawTexture', Params.Display.win, Params.ImageExp.MaskTex, Params.ImageExp.SourceRectMonk, RectMonk);
                    end
                end

                for Eye = 1:NoEyes     
                    %============ Draw photodiode marker
                    if Params.Display.PD.Position > 1
                        Screen('FillOval', Params.Display.win, Params.Display.PD.Color{PDstatus}*255, Params.Display.PD.SubRect(Eye,:));
                        Screen('FillOval', Params.Display.win, Params.Display.PD.Color{PDstatus}*255, Params.Display.PD.ExpRect);
                    end
                    %============ Draw fixation marker
                    if Params.ImageExp.FixType > 1
                        Screen('DrawTexture', Params.Display.win, Params.ImageExp.FixTex, [], Params.Display.FixRectMonk(Eye,:));  	% Draw fixation marker
                    end
                end

                %=============== Check current eye position
                Eye             = SCNI_GetEyePos(Params);                                                        	% Get screen coordinates of current gaze position (pixels)
                EyeRect         = repmat(round(Eye(Params.Eye.EyeToUse).Pixels),[1,2])+[-10,-10,10,10];           	% Prepare rect to draw current gaze position                                   
                [FixIn, FixDist]= SCNI_IsInFixWin(Eye(Params.Eye.EyeToUse).Pixels, [], [], Params);               	% Check if gaze position is inside fixation window

                %=============== Check whether to deliver reward
                ValidFixNans 	= find(isnan(Params.Run.ValidFixations(Params.Run.TrialCount,:,:)), 1);            	% Find first NaN elements in fix matrix
                Params.Run.ValidFixations(Params.Run.TrialCount, ValidFixNans,:) = [GetSecs, FixDist, FixIn];    	% Save current fixation result to matrix
                Params      	= CheckFix(Params);                                                           

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
                if Eye(Params.Eye.EyeToUse).Pixels(1) < Params.Display.Rect(3)
                    Screen('FillOval', Params.Display.win, Params.Display.Exp.EyeColor(FixIn+1,:)*255, EyeRect);    % Draw current gaze position
                end
                Params         = SCNI_UpdateStats(Params);                                                      % Update statistics on experimenter's screen

                %=============== Draw to screen and record time
                [VBL FrameOnset(end+1)] = Screen('Flip', Params.Display.win);                                   % Flip next frame
                if Params.Run.FixIsOn == 0                                                                      % If this is the first fixation onset...
                    Params.Run.FixOnset = FrameOnset(end);                                                      % Record fixation onset time
                    Params.Run.FixIsOn  = 1;
                    SCNI_SendEventCode('Fix_On', Params);                                                       
                end
                if Params.Run.StimIsOn == 0 & stage == 2                                                        % If this is first frame of stimulus presentation...
                    SCNI_SendEventCode('Stim_On', Params);                                                      % Send event code to connected neurophys systems
                    Params.Run.StimIsOn     = 1;                                                              	% Change flag to show movie has started
                    Params.Run.StimOnTime   = FrameOnset(end);                                                  % Record stimulus onset time
                elseif Params.Run.StimIsOn == 1 & stage == 2 & Params.Run.StimCodeSent== 0                    	% If this is second frame of stimulus presentation...
                    SCNI_SendEventCode(Stim, Params);                                                        	% Send stimulus number to neurophys. system 
                    Params.Run.StimCodeSent = 1;
                elseif Params.Run.StimIsOn == 1 & stage == 1                                                    % If this is first frame of ISI...
                    SCNI_SendEventCode('Stim_Off', Params); 
                    Params.Run.StimIsOn     = 0;                                                              	% Change flag to show movie has started
                    StimCodeSent            = 0;
                    Params.Run.StimOffTime	= FrameOnset(end);                                                  % Record stimulus onset time
                end

                %=============== Check experimenter's input
                Params = SCNI_CheckKeys(Params);                                                                % Check for keyboard input
                if isfield(Params.Toolbar,'StopButton') && get(Params.Toolbar.StopButton,'value') == 1
                    Params.Run.EndRun = 1;
                end
                
                %============== Reset photodiode status for next frame
                PDstatus    = Stages(stage).StimOn +1;
            end
        end
        Params.Run.StimCount = Params.Run.StimCount+1;                                                      % Count as one stimulus presentation
        
    end
    
    %% ================= ANALYSE FIXATION
    if Params.Run.AbortTrial == 0
    	Params                  = SCNI_CheckTrialEyePos(Params);
        ITIduration             = Params.ImageExp.ITIms/10^3;           
        Params.Run.TrialCount   = Params.Run.TrialCount+1;              % Count as one completed trial
        RewardEarned            = 1;
         
    elseif Params.Run.AbortTrial == 1
        SCNI_SendEventCode('Fixation_Broken', Params); 
        Params.ImageExp.PenaltyTimeout = 2000;
        ITIduration             = Params.ImageExp.PenaltyTimeout/10^3; 
        Params.Run.FixIsOn      = 0;
        RewardEarned            = 0;
        Datapixx('StopAdcSchedule');   
    end

    %% ================= WAIT FOR ITI TO ELAPSE
    while (GetSecs - Params.Run.StimOffTime) < ITIduration && Params.Run.EndRun == 0
        for Eye = 1:NoEyes 
            Screen('FillRect', Params.Display.win, Params.Display.Exp.BackgroundColor*255);                                             	% Clear previous frame
            if Params.Display.PD.Position > 1
                Screen('FillOval', Params.Display.win, Params.Display.PD.Color{1}*255, Params.Display.PD.SubRect(Eye,:));
                Screen('FillOval', Params.Display.win, Params.Display.PD.Color{1}*255, Params.Display.PD.ExpRect);
            end
        end

        %=============== Check current eye position
        Eye         = SCNI_GetEyePos(Params);                                                           % Get screen coordinates of current gaze position (pixels)
        EyeRect   	= repmat(round(Eye(Params.Eye.EyeToUse).Pixels),[1,2]) +[-10,-10,10,10];            % Prepare rect to draw current gaze position                                                 

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
      	if Params.ImageExp.FixType > 1 && Params.Run.FixIsOn == 1
            Screen('DrawTexture', Params.Display.win, Params.ImageExp.FixTex, [], Params.Display.FixRectExp);
        end
        if Eye(Params.Eye.EyeToUse).Pixels(1) < Params.Display.Rect(3)
            Screen('FillOval', Params.Display.win, Params.Display.Exp.EyeColor(FixIn+1,:)*255, EyeRect);                            % Draw current gaze position
        end
        Params       	= SCNI_UpdateStats(Params);

        %=============== Draw to screen and record time
        [~,ITIoffset]  	= Screen('Flip', Params.Display.win); 
        if Params.Run.StimIsOn == 1
            Params.Run.StimIsOn     = 0;
            SCNI_SendEventCode('Stim_Off', Params);                                                         % Send event code to connected neurophys systems
            Params.Run.StimOffTime  = ITIoffset;
        end
        if Params.Run.FixIsOn == 1 && (GetSecs-Params.Run.StimOffTime)> Params.ImageExp.ISIms/10^3
            Params.Run.FixIsOn = 0;
            SCNI_SendEventCode('Fix_Off', Params);                                                          % Send event code to connected neurophys systems
        end
        
      	%=============== Check whether to deliver reward
        if RewardEarned  == 1 && (GetSecs - Params.Run.StimOffTime) > Params.ImageExp.ISIms/10^3
            Params = SCNI_GiveReward(Params);
            SCNI_SendEventCode('Reward_Auto', Params); 
            RewardEarned = 0;
        end
        
        %=============== Check experimenter's input
        Params = SCNI_CheckKeys(Params);                                                                % Check for keyboard input
        if isfield(Params.Toolbar,'StopButton') && get(Params.Toolbar.StopButton,'value')==1            % Check for toolbar input
            Params.Run.EndRun = 1;
        end
    end
    
    if Params.Run.AbortTrial == 0
        SCNI_SendEventCode('Trial_End', Params);
    end
    
end


%============== Run was aborted by experimenter
if Params.Run.EndRun == 1
    

end
    
SCNI_SendEventCode('Block_End', Params);   
SCNI_EndRun(Params);
 

end


%=============== END RUN
function SCNI_EndRun(Params)
	for Eye = 1:size(Params.Display.PD.SubRect,1)
        Screen('FillRect', Params.Display.win, Params.Display.Exp.BackgroundColor*255);                                             	% Clear previous frame
        if Params.Display.PD.Position > 1
            Screen('FillOval', Params.Display.win, Params.Display.PD.Color{1}*255, Params.Display.PD.SubRect(Eye,:));
            Screen('FillOval', Params.Display.win, Params.Display.PD.Color{1}*255, Params.Display.PD.ExpRect);
        end
    end
    Params       	= SCNI_UpdateStats(Params);
    Screen('Flip', Params.Display.win); 
    return;
end

%=============== LOAD IMAGE TO TEXTURE ON THE FLY
function ImageTex = LoadImage(Params, Cond, Stim)
    img = imread(Params.ImageExp.ImByCond{Cond}{Stim});                                     	% Load image file
    if isa(img, 'uint16')                                                                      	% If image is 16-bit color
        img = uint8(img)/256;                                                                  	% Reduce bit depth to 8-bit
        Bits16 = 0;
    else
        Bits16 = 0;
    end
    img = double(img);
    if Params.ImageExp.UseAlpha == 1
        [~,~, imalpha] = imread(Params.ImageExp.ImByCond{Cond}{Stim});                          % Read alpha channel
        if ~isempty(imalpha)                                                                 	% If image file contains transparency data...
            imalpha     = double(imalpha);
            img(:,:,4)  = imalpha;                                                          	% Combine into a single RGBA image matrix
        else
            img(:,:,4) = ones(size(img,1),size(img,2))*255;
        end
    end
  	ImageTex = Screen('MakeTexture', Params.Display.win, img, [], [], Bits16); 
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

%================= CHECK FIXATION DURING TRIAL
function Params = CheckFix(Params)
    ValidFixSamples = find(Params.Run.ValidFixations(Params.Run.TrialCount, :,1) > Params.Run.FixOnset+Params.Eye.TimeToFix/10^3);
    if ~isempty(ValidFixSamples)
        FixSoFar        = Params.Run.ValidFixations(Params.Run.TrialCount, ValidFixSamples,3);  	% Get all fixation validity data for current trial
        Proportion      = nanmean(FixSoFar);
        if Proportion < Params.Eye.FixDur/100                                                       % Calculate proportion of samples with valid fixations
            Params.Run.AbortTrial   = 1;       
            Params.Run.StimOffTime  = GetSecs;
        end
    end
end

%================= SEND EYE CALIBRATION VALUES TO TDT
function Params = SendEyeCalToTDT(Params)
    SCNI_SendEventCode('Sending_EyeOffsets',Params);
    for xy = 1:2
        OffsetValue(xy) = 4000 + round(Params.Eye.Cal.Offset{Params.Eye.EyeToUse}(xy)*1000);
        SCNI_SendEventCode(OffsetValue(xy), Params);
    end
    SCNI_SendEventCode('Sending_EyeGains',Params);
    for xy = 1:2
        GainValue(xy) = 4000 + round(Params.Eye.Cal.Gain{Params.Eye.EyeToUse}(xy)*100);
        SCNI_SendEventCode(GainValue(xy), Params);
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

	Params.Run.ValidFixPercent = nanmean(nanmean(Params.Run.ValidFixations(1:Params.Run.TrialCount,:,3)))*100;

    %========= Update clock
	Params.Run.CurrentTime      = GetSecs-Params.Run.StartTime;                                            % Calulate time elapsed
    Params.Run.CurrentMins      = floor(Params.Run.CurrentTime/60);                    
    Params.Run.CurrentSecs      = rem(Params.Run.CurrentTime, 60);
    Params.Run.CurrentPercent   = (Params.Run.TrialCount/Params.ImageExp.TrialsPerRun)*100;
	Params.Run.TextContent      = [Params.Toolbar.CurrentRun, Params.Run.TrialCount, Params.ImageExp.TrialsPerRun, Params.Run.CurrentStimNo, Params.ImageExp.StimPerTrial, Params.Run.CurrentMins, Params.Run.CurrentSecs, Params.Reward.RunCount, Params.Run.ValidFixPercent];
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