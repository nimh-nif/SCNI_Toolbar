function Params = SCNI_GazeFollowing(Params)

%========================== SCNI_GazeFollowing.m ==========================
% This function runs a gaze following experiment based on pre-rendered
% images and animations containing. 
% Experimental parameters can be adjusted by running the accompanying 
% SCNI_GazeFollowingSettings.m GUI and saving to your parameters file.
%
%
%==========================================================================

%================= SET DEFAULT PARAMETERS
if nargin == 0 || ~isfield(Params,'GF')
    Params = SCNI_GazeFollowingSettings(Params, 0);
end

%================= CHECK EXISTING DATA
% if exist(Params.Toolbar.Session.Fullfile, 'file')
%     load(Params.Toolbar.Session.Fullfile);
% end

%================= LOAD STIMULUS SET PARAMS
StimParamsFile      = wildcardsearch(Params.GF.StimDir, '*.mat');
Stim                = load(StimParamsFile{1});
Params.GF.Stim      = Stim.Stim;

Params.GF.TargetGazeRadius  = 1.5;
Params.GF.TrialStageDur     = [Params.GF.InitialFix, Params.GF.TargetDur, Params.GF.CueDur, Params.GF.RespFixDur, 500, 1000]/10^3;
Params.GF.StagesPerTrial    = 6;

%================= PRE-ALLOCATE RUN AND REWARD FIELDS
Params.Run.MaxDuration          = sum(Params.GF.TrialStageDur);
Params.Run.ValidFixations       = nan(Params.GF.TrialsPerRun, Params.Run.MaxDuration*Params.DPx.AnalogInRate, 3);
Params.Run.Correct              = nan(Params.GF.TrialsPerRun);
Params.Run.LastRewardTime       = GetSecs;
Params.Run.StartTime            = GetSecs;
Params.Run.LastPress            = GetSecs;
Params.Run.TextColor            = [1,1,1]*255;
Params.Run.TextRect             = [100, 100, [100, 100]+[200,300]];
Params.Run.MaxTrialDur          = 5;                            % Maximum trial duration (seconds)
Params.Run.TrialCount           = 1;                            % Start trial count at 1
Params.Run.EndRun              = 0;
if ~isfield(Params.Run, 'Number')                               % If run count field does not exist...
    Params.Run.Number          	= 1;                            % This is the first run of the session
else
    Params.Run.Number          	= Params.Run.Number + 1;        % Advance run count
end
    
if ~isfield(Params, 'Reward')
    Params.Reward.Proportion        = 0.7;                          % Set proportion of reward interval that fixation must be maintained for (0-1)
    Params.Reward.LastRewardTime    = GetSecs;                      % Initialize last reward delivery time (seconds)
    Params.Reward.TTLDur            = 0.05;                         % Set TTL pulse duration (seconds)
    Params.Reward.RunCount          = 0;                            % Count how many reward delvieries in this run
end
Params.DPx.UseDPx               = 1;                            % Use DataPixx?

if ~isfield(Params, 'Eye')
    Params = SCNI_EyeCalibSettings(Params);
end

Params = SCNI_OpenWindow(Params);

%================= GENERATE FIXATION TEXTURE
if Params.GF.FixType > 1
    Fix.Type        = Params.GF.FixType;                            % Fixation marker format
    Fix.Color       = Params.GF.FixColor;                           % Fixation marker color (RGB, 0-1)
    Fix.MarkerSize  = Params.GF.FixDiameter;                        % Fixation marker diameter (degrees)
    Fix.LineWidth   = 4;                                            % Fixation marker line width (pixels)
    Fix.Size        = Fix.MarkerSize*Params.Display.PixPerDeg;
    Params.GF.FixTex = SCNI_GenerateFixMarker(Fix, Params);     
end

%================= INITIALIZE SETTINGS
Params  = SCNI_AudioSettings(Params);                             	% Initialize audio
Params  = SCNI_DataPixxInit(Params);                                % Initialize DataPixx
Params 	= SCNI_InitializeGrid(Params);                              % Initialize experimenter's display grid
Params	= SCNI_GetPDrect(Params, Params.Display.UseSBS3D);          % Initialize photodiode location(s)
Params  = SCNI_InitKeyboard(Params);                                % Initialize keyboard shortcuts

%================= CALCULATE SCREEN RECTANGLES
Params.GF.RectExp   	= Params.Display.Rect;
Params.GF.RectMonk    	= Params.Display.Rect + [Params.Display.Rect(3), 0, Params.Display.Rect(3), 0];
Params.GF.GazeFixRect  	= CenterRect([1,1,Params.GF.FixWinDeg.*Params.Display.PixPerDeg], Params.Display.Rect);

%================= ADJUST FOR 3D FORMAT...
Params.GF.ImageRes = Params.Display.Rect([3,4]);
if Params.GF.Use3D == 1                 % If frames are rendered in SBS 3D...
    if Params.Display.UseSBS3D == 1     % If stereoscopic 3D presentation was requested...
        NoEyes                              = 2;
        Params.GF.SourceRectExp             = [1, 1, Params.GF.ImageRes(1)/2, Params.GF.ImageRes(2)];
        Params.GF.SourceRectMonk            = [1, 1, Params.GF.ImageRes];
        Params.Display.FixRectExp           = CenterRect([1, 1, Fix.Size], Params.Display.Rect);
        Params.Display.FixRectMonk(1,:)     = CenterRect([1, 1, Fix.Size./[2,1]], Params.Display.Rect./[1,1,2,1]) + [Params.Display.Rect(3),0,Params.Display.Rect(3),0]; 
        Params.Display.FixRectMonk(2,:)     = Params.Display.FixRectMonk(1,:) + Params.Display.Rect([3,1,3,1]).*[0.5,0,0.5,0];
    elseif Params.Display.UseSBS3D == 0     % If 2D presentation was requsted...
        NoEyes                              = 1;
        Params.GF.SourceRectExp             = [1, 1, Params.GF.ImageRes(1)/2, Params.GF.ImageRes(2)];
        Params.GF.SourceRectMonk            = [1, 1, Params.GF.ImageRes(1)/2, Params.GF.ImageRes(2)];
        Params.Display.FixRectExp           = CenterRect([1, 1, Fix.Size], Params.Display.Rect);
        Params.Display.FixRectMonk(1,:)     = CenterRect([1, 1, Fix.Size], Params.Display.Rect) + [Params.Display.Rect(3),0,Params.Display.Rect(3),0]; 
    end
    
elseif Params.GF.Use3D == 0
    NoEyes                              = 1;
	Params.GF.SourceRectExp             = [];
    Params.GF.SourceRectMonk            = [];
    Params.Display.FixRectExp           = CenterRect([1, 1, Fix.Size], Params.Display.Rect);
    Params.Display.FixRectMonk(1,:)     = CenterRect([1, 1, Fix.Size], Params.Display.Rect + [Params.Display.Rect(3), 0, Params.Display.Rect(3), 0]); 
    Params.Display.FixRectMonk(2,:)     = Params.Display.FixRectMonk(1,:);
end
Params.Eye.GazeRect     = Params.GF.GazeFixRect;
Params.GF.TargetRect    = [1, 1, 2*Params.GF.TargetGazeRadius.*Params.Display.PixPerDeg];

%================= LOAD FRAMES TO GPU
if isempty(winPtr) 
	Params = SCNI_LoadGFframes(Params);
end

%================= LOAD / GENERATE STIMULUS ORDER
Params = GenerateGFDesign(Params);


%% ============================ BEGIN RUN =================================
while Params.Run.TrialCount < Params.GF.TrialsPerRun && Params.Run.EndRun == 0
    AdcStatus = SCNI_StartADC(Params);                                          % Start DataPixx ADC
    
    %================== BEGIN NEXT TRIAL
    for TrialStage = 1:Params.GF.StagesPerTrial                              	% Loop through trial stages
        
        Params.Run.CurrentTrialStage    = TrialStage;
        Params.GF.StageTransTime        = GetSecs;
        NewStage                        = 1; 
        
        %================== BEGIN NEXT STAGE OF TRIAL
        switch TrialStage 
            case 1      %================== Initial fixation
                if Params.GF.UseAudioCue == 1
                    Params          = SCNI_PlaySound(Params, Params.Audio.Tones(1));
                end
                SCNI_SendEventCode('Trial_Start', Params);                   	% Send event code to connected neurophys systems
                TargetLocs      = Params.GF.Design(Params.Run.TrialCount,:);    
                CorrectTarget   = TargetLocs(1);
                TargetColorIndx = 1;
                frame           = 1;
                EndTrial        = 0;
                
                GazeCentroid            = Params.Display.Rect([3,4])/2; 
                CorrectTargetCenter     = Params.GF.TargetCenterPix(CorrectTarget, :);
                CorrectTargetRect       = CenterRectOnPoint(Params.GF.TargetRect, CorrectTargetCenter(1), CorrectTargetCenter(2));
                Params.Eye.GazeRect     = Params.GF.GazeFixRect;
                Params.GF.GazeRect      = Params.GF.GazeFixRect;
                
            case 2      %================== Targets appear
                
                
            case 3      %================== Cue appears
                ValidFixProp = nanmean(Params.Run.ValidFixations(Params.Run.TrialCount,:,3));   % Check whether adequate central fixation was maintained
                if ValidFixProp < Params.Eye.FixDur
                    EndTrial = 1;
                end
                
            case 4      %================== Response window begins
                ValidFixProp = nanmean(Params.Run.ValidFixations(Params.Run.TrialCount,:,3));   % Check whether adequate central fixation was maintained
                if ValidFixProp < Params.Eye.FixDur
                    EndTrial = 1;
                end
                Params.GF.GazeRect  = CorrectTargetRect;    
                Params.Eye.GazeRect = CorrectTargetRect;
                GazeCentroid        = CorrectTargetCenter;
                
            case 5      %================== Feedback given and avatar resets
                ValidFixProp = nanmean(Params.Run.ValidFixations(Params.Run.TrialCount,:,3));   % <<<< More accurate method needed?
                if ValidFixProp > Params.Eye.FixDur
                    TrialCorrect    = 1;
                else
                    TrialCorrect    = 0;
                end
                if TrialCorrect == 1
                    TargetColorIndx     = 2;
                elseif TrialCorrect == 0
                    TargetColorIndx     = 3;
                end
                
            case 6      %================== ITI and reward delivery

                
        end
        
        
        while (GetSecs - Params.GF.StageTransTime) < Params.GF.TrialStageDur(TrialStage) && EndTrial == 0 && Params.Run.EndRun == 0

            %=============== Draw stimulus components to both screens  
             
            %=============== Draw background image
            switch Params.GF.BckgrndType
                case 1
                    Screen('FillRect', Params.Display.win, Params.Display.Exp.BackgroundColor*255);                                             % Clear previous frame
                case 2
                    Screen('DrawTexture', Params.Display.win, Params.GF.BckgrndTex, Params.GF.SourceRectExp, Params.GF.RectExp);   
                    Screen('DrawTexture', Params.Display.win, Params.GF.BckgrndTex, Params.GF.SourceRectMonk, Params.GF.RectMonk);
                case 3

            end
            %============ Draw avatar
            if Params.GF.Mode > 1
                if ismember(TrialStage, [1,6])
                    Screen('DrawTexture', Params.Display.win, Params.GF.AvatarBlink(3), Params.GF.SourceRectExp, Params.GF.RectExp, [], [], Params.GF.Contrast);        % Draw to the experimenter's display
                    Screen('DrawTexture', Params.Display.win, Params.GF.AvatarBlink(3), Params.GF.SourceRectMonk, Params.GF.RectMonk, [], [], Params.GF.Contrast); 
                elseif ismember(TrialStage, [2,3,4,5])            
                    Screen('DrawTexture', Params.Display.win, Params.GF.AvatarTex(CorrectTarget,frame), Params.GF.SourceRectExp, Params.GF.RectExp, [], [], Params.GF.Contrast);        % Draw to the experimenter's display
                    Screen('DrawTexture', Params.Display.win, Params.GF.AvatarTex(CorrectTarget,frame), Params.GF.SourceRectMonk, Params.GF.RectMonk, [], [], Params.GF.Contrast);      % Draw to the subject's display
                end
                Screen('DrawTexture', Params.Display.win, Params.GF.ForegroundTex, Params.GF.SourceRectExp, Params.GF.RectExp, [], [], Params.GF.Contrast);        % Draw to the experimenter's display
              	Screen('DrawTexture', Params.Display.win, Params.GF.ForegroundTex, Params.GF.SourceRectMonk, Params.GF.RectMonk, [], [], Params.GF.Contrast);      % Draw to the subject's display
            end
            %============ Draw target objects
            if ismember(TrialStage, [2,3,4,5])
                for t = 1:numel(TargetLocs)
                    if t == 1
                    	T = TargetColorIndx;
                    else
                        T = 1;
                    end
                    Screen('DrawTexture', Params.Display.win, Params.GF.TargetTex(T, TargetLocs(t)), Params.GF.SourceRectExp, Params.GF.RectExp); 
                    Screen('DrawTexture', Params.Display.win, Params.GF.TargetTex(T, TargetLocs(t)), Params.GF.SourceRectMonk, Params.GF.RectMonk); 
                end
            end
            
           	for Eye = 1:NoEyes 
                %============ Draw photodiode markers
                if Params.Display.PD.Position > 1
                    if (NewStage == 1 && ismember(TrialStage, [1,2,5])) || TrialStage == 3
                        PDstatus = 2;
                    else
                        PDstatus = 1;
                    end
                    Screen('FillOval', Params.Display.win, Params.Display.PD.Color{PDstatus}*255, Params.Display.PD.SubRect(Eye,:));
                    Screen('FillOval', Params.Display.win, Params.Display.PD.Color{PDstatus}*255, Params.Display.PD.ExpRect);
                end
                %============ Draw fixation marker
                if ismember(TrialStage, [1,2,3]) && Params.GF.FixType > 1
                    Screen('DrawTexture', Params.Display.win, Params.GF.FixTex, [], Params.Display.FixRectMonk(Eye,:));         % Draw fixation marker
                end
            end


            %=============== Check current eye position
            Eye             = SCNI_GetEyePos(Params);                                                           % Get screen coordinates of current gaze position (pixels)
            EyeRect         = repmat(round(Eye(Params.Eye.EyeToUse).Pixels),[1,2])+[-10,-10,10,10];             % Get screen coordinates of current gaze position (pixels)
            [FixIn, FixDist]= SCNI_IsInFixWin(Eye(Params.Eye.EyeToUse).Pixels, GazeCentroid, [], Params);      	% Check if gaze position is inside fixation window

            %=============== Check whether to abort trial
            ValidFixNans 	= find(isnan(Params.Run.ValidFixations(Params.Run.TrialCount,:,1)), 1);             % Find first NaN elements in fix vector
            Params.Run.ValidFixations(Params.Run.TrialCount, ValidFixNans,:) = [GetSecs, FixDist, FixIn];       % Save current fixation result to matrix
         	%Params       	= SCNI_CheckReward(Params);                                                          

            %=============== Draw experimenter's overlay
            if Params.Display.Exp.GridOn == 1
                Screen('FrameOval', Params.Display.win, Params.Display.Exp.GridColor*255, Params.Display.Grid.Bullseye, Params.Display.Grid.BullsEyeWidth);                % Draw grid lines
                Screen('FrameOval', Params.Display.win, Params.Display.Exp.GridColor*255, Params.Display.Grid.Bullseye(:,2:2:end), Params.Display.Grid.BullsEyeWidth+2);   % Draw even lines thicker
                Screen('DrawLines', Params.Display.win, Params.Display.Grid.Meridians, 1, Params.Display.Exp.GridColor*255);                
            end

        	Screen('FrameOval', Params.Display.win, Params.Display.Exp.GazeWinColor(FixIn+1,:)*255, Params.GF.GazeRect, 3); 	% Draw border of gaze window that subject must fixate within
            if Eye(Params.Eye.EyeToUse).Pixels(1) < Params.Display.Rect(3)
                Screen('FillOval', Params.Display.win, Params.Display.Exp.EyeColor(FixIn+1,:)*255, EyeRect);        % Draw current gaze position
            end
            if ismember(TrialStage, [1,2,3]) && Params.GF.FixType > 1
                Screen('DrawTexture', Params.Display.win, Params.GF.FixTex, [], Params.Display.FixRectExp);         % Draw fixation marker
            end
            Params       	= SCNI_UpdateStats(Params); 
            
            %=============== Draw to screen and record time
            [~,FrameOnset]  	= Screen('Flip', Params.Display.win); 
            
            %=============== For first frame of this stage...
            if NewStage == 1
                switch TrialStage 
                    case 1
                        SCNI_SendEventCode('Fix_On', Params);
                        
                    case 2
                        SCNI_SendEventCode('Stim_On', Params);  
                        
                    case 3
                        SCNI_SendEventCode('Trial_Start', Params); 
                        
                    case 4
                        SCNI_SendEventCode('Fix_Off', Params); 
                        
                    case 5
                        SCNI_SendEventCode('Stim_Off', Params); 
                        
                    case 6  % ================= ANALYSE FIXATION FOR WHOLE TRIAL
                        %Params = SCNI_CheckTrialEyePos(Params);
                        
                      	if TrialCorrect == 1
                            SCNI_SendEventCode('Reward_Auto', Params); 
                            Params = SCNI_GiveReward(Params);
                            if Params.GF.UseAudioCue == 1
                                Params 	= SCNI_PlaySound(Params, Params.Audio.Tones(~TrialCorrect + 1));
                            end
                        else
                            if Params.GF.UseAudioCue == 1
                                Params 	= SCNI_PlaySound(Params, Params.Audio.Tones(~TrialCorrect + 1));
                            end
                        end
                        
                end
                NewStage = 0;
            end
            
            %=============== Check experimenter's input
            Params = SCNI_CheckKeys(Params);                                                            % Check for keyboard input
            if isfield(Params.Toolbar,'StopButton') && get(Params.Toolbar.StopButton,'value')==1     	% Check for toolbar input
                Params.Run.EndRun = 1;
            end
            
            %=============== Advance cue animation frame
            if isfield(Params.GF, 'AvatarTex')
                if TrialStage == 3 && frame < size(Params.GF.AvatarTex,2)
                    frame = frame+1;
                end
                if TrialStage == 5 && frame > 1
                    frame = frame-1;
                end
            end
        end

    end
    
    %=============== PENALIZE SUBJECT ABORTED TRIAL
    if EndTrial == 1
        
        
        
    end
    
    Params.Run.TrialCount = Params.Run.TrialCount+1;        % Count as one trial
    
end


%============== Run was aborted by experimenter
if Params.Run.EndRun == 1
    

end
    
SCNI_SendEventCode('Block_End', Params);   
SCNI_EndRun(Params);
 

end


%=============== END RUN
function SCNI_EndRun(Params)
    switch Params.GF.BckgrndType
        case 1
            Screen('FillRect', Params.Display.win, Params.Display.Exp.BackgroundColor*255);                                             % Clear previous frame
        case 2
            Screen('DrawTexture', Params.Display.win, Params.GF.BckgrndTex, Params.GF.SourceRectExp, Params.GF.RectExp);   
            Screen('DrawTexture', Params.Display.win, Params.GF.BckgrndTex, Params.GF.SourceRectMonk, Params.GF.RectMonk);
        case 3

    end
    Screen('Flip', Params.Display.win); 
    return;
end

%=============== RUN CALIBRATION
function Params = CalibrateGF(Params)

    
    



end

%=============== PREALLOCATE RANDOMIZED DESIGN
function Params = GenerateGFDesign(Params)

    switch Params.GF.Stim.TargetLayout
        case 'circular'
%             TotalLocations  = Params.GF.Stim.NoPolarAngles*Params.GF.Stim.NoEccentricities;
%             MinAngle        = 360/Params.GF.Stim.NoPolarAngles;
            % Calculate all pairwise distances in polar angle from avatar
%             for n = 1:TotalLocations
%                 for m = 1:TotalLocations
%                     if n==m
%                         DistMatrix(n,m) = NaN;
%                     else
%                         Pos1 = [sind((n-1)*MinAngle)*Stim.Eccentricities, cosd((n-1)*MinAngle)*Stim.Eccentricities, Params.GF.Stim.TargetDepth];
%                         Pos2 = [sind((m-1)*MinAngle)*Stim.Eccentricities, cosd((m-1)*MinAngle)*Stim.Eccentricities, Params.GF.Stim.TargetDepth];
%                         XYdist = abs(Pos1(1:2)-Pos2(1:2));
%                         DistMatrix(n,m) = sqrt(XYdist(1)^2 + XYdist(2)^2);
%                     end
%                 end
%             end
            
            
            if Params.GF.NoTargets == 1
                Params.GF.Design    = randi(Params.GF.Stim.NoTargets,[Params.GF.TrialsPerRun, 1]);
                
            elseif Params.GF.NoTargets == 2
                MinDistance         = 10;
                [X,Y]               = find(Params.GF.Stim.Distances>=MinDistance);
                AllPairs            = [X, Y];
                Params.GF.Design    = AllPairs(randi(numel(X),[Params.GF.TrialsPerRun, 1]), :);
            end

            
%             Params.GF.Design    = randi(numel(X), [Params.GF.NoTargets, Params.GF.TrialsPerRun]);
%             Duplicates          = find(Params.GF.Design(1,:)==Params.GF.Design(2,:));
%             while ~isempty(Duplicates)
%                 Params.GF.Design(2,Duplicates) = randi(TotalLocations, [1, numel(Duplicates)]);
%                 Duplicates          = find(Params.GF.Design(1,:)==Params.GF.Design(2,:));
%             end
                

        case 'linear'



    end

end

%=============== PREALLOCATE RANDOMIZATIONS
function Params	= AllocateRand(Params)
    NoStim = Params.GF.StagesPerTrial*Params.GF.TrialsPerRun;
    if Params.GF.ISIjitter ~= 0
        Params.Run.ISIjitter = ((rand([1,NoStim])*2)-1)*Params.GF.ISIjitter/10^3;
    end
    if Params.GF.PosJitter ~= 0
        Params.Run.PosJitter = ((rand([2,NoStim])*2)-1)'.*Params.GF.PosJitter.*Params.Display.PixPerDeg;
    end
    if Params.GF.ScaleJitter ~= 0
    	Params.Run.ScaleJitter = ((rand([1,NoStim])*2)-1)*Params.GF.ScaleJitter;
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
                                    'Stage #         %d / %d\n\n',...
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
    Params.Run.CurrentPercent   = (Params.Run.TrialCount/Params.GF.TrialsPerRun)*100;
	Params.Run.TextContent      = [Params.Run.Number, Params.Run.TrialCount, Params.GF.TrialsPerRun, Params.Run.CurrentTrialStage, Params.GF.StagesPerTrial, Params.Run.CurrentMins, Params.Run.CurrentSecs, Params.Reward.RunCount, Params.Run.ValidFixPercent];
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