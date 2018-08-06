function Movie = SCNI_PlayMovies(Params, movieFile)

%=========================== SCNI_PlayMovies.m ============================
% This function serves as a template for how to write an experiment using
% the SCNI toolbar subfunctions. As is, this particular function allows the
% experimenter to present one or more movie files in an order of their
% choosing (e.g. a block design for fMRI experiments, or pseudorandomly for
% neurophysiology). The numerous variables can be adjusted by running the
% accompanying SCNI_PlayMoviesSettings.m GUI and saving to your parameters
% file.
%
%
%==========================================================================

%================= SET DEFAULT PARAMETERS
if nargin < 2 || ~isfield(Params, 'Movie')
    
    Params  = SCNI_PlayMoviesSettings(Params, 0);
    Params  = SCNI_GenerateDesign(Params, 0);           
    
    %============== Keyboard shortcuts
    KbName('UnifyKeyNames');
    KeyNames                    = {'Space','X','uparrow','downarrow'};         
    KeyFunctions                = {'Pause','Stop','VolUp','VolDown'};
    Params.Movie.KeysList       = zeros(1,256); 
    for k = 1:numel(KeyNames)
        eval(sprintf('Params.Movie.Keys.%s = KbName(''%s'');', KeyFunctions{k}, KeyNames{k}));
        eval(sprintf('Params.Movie.KeysList(Params.Movie.Keys.%s) = 1;', KeyFunctions{k}));
        fprintf('Press ''%s'' for %s\n', KeyNames{k}, KeyFunctions{k});
    end

end

%================= PRE-ALLOCATE RUN AND REWARD FIELDS
Params.Run.ValidFixations       = nan(Params.Movie.Duration*Params.DPx.AnalogInRate, 2);
Params.Run.LastRewardTime       = GetSecs;
Params.Run.StartTime            = GetSecs;
Params.Run.LastPress            = GetSecs;
Params.Run.TextColor            = [1,1,1]*255;
Params.Run.TextRect             = [100, 100, [100, 100]+[200,300]];
Params.Run.Duration             = Params.Movie.RunDuration;
Params.Run.MaxTrialDur          = Params.Movie.Duration;
Params.Run.MovieCount           = 1;                            % Start movie count at 1
Params.Run.ExpQuit              = 0;
Params.Run.EndMovie             = 0;
% Params.Run.CurrentFile          = Params.Movie.ImByCond{Params.Design.Cond(1,1)}{Params.Design.Stim(1,1)};
Params.Run.CurrentFile          = Params.Movie.ImByCond{1}{1};

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

%================= LOAD FIRST MOVIE FILE
[mov, Movie.duration, Movie.fps, Movie.width, Movie.height, Movie.count, Movie.AR] = Screen('OpenMovie', Params.Display.win, Params.Run.CurrentFile); 
Params.Run.mov = mov;
if isempty(Params.Movie.Duration)
    Params.Movie.Duration = Movie.duration;
end

%================= CALCULATE SCREEN RECTANGLES
if Params.Movie.Fullscreen == 1
    Params.Movie.RectExp    = Params.Display.Rect;
    Params.Movie.RectMonk   = Params.Display.Rect + [Params.Display.Rect(3), 0, 0, 0];
    Params.Movie.GazeRect  	= Params.Movie.RectExp;
elseif Params.Movie.Fullscreen == 0
    Params.Movie.RectExp    = CenterRect([1, 1, Movie.width, Movie.height]*Params.Movie.Scale, Params.Display.Rect); 
    Params.Movie.RectMonk   = Params.Movie.RectExp + [Params.Display.Rect(3), 0, Params.Display.Rect(3), 0];
    Params.Movie.GazeRect 	= Params.Movie.RectExp + [-1,-1, 1, 1]*Params.Movie.GazeRectBorder*Params.Display.PixPerDeg(1);  	% Rectangle specifying gaze window on experimenter's display (overridden if fullscreen is selected)
end
if Params.Movie.SBS == 1
    NoEyes                      = 2;
    Params.Movie.SourceRect{1}  = [1, 1, Movie.width/2, Movie.height];
    Params.Movie.SourceRect{2}  = [(Movie.width/2)+1, 1, Movie.width, Movie.height];
elseif Params.Movie.SBS == 0
    NoEyes                      = 1;
    Params.Movie.SourceRect{1}  = [1, 1, Movie.width, Movie.height];
end
Params.Display.GazeRect = Params.Movie.GazeRect;


%================= BEGIN RUN
FrameOnset = GetSecs;
while Params.Run.EndMovie == 0 && (GetSecs-Params.Run.StartTime) < Params.Movie.RunDuration

    if Params.Run.MovieCount > 1
        Params.Run.MoiveIndx(Params.Run.MovieCount) = randi(numel(Params.Movie.AllFiles));                   % <<<< RANDOMIZE movie order
        SCNI_SendEventCode(Params.Run.MoiveIndx(Params.Run.MovieCount), Params);                             % Send event code to connected neurophys systems
        Params.Run.CurrentFile      = Params.Movie.AllFiles{Params.Run.MoiveIndx(Params.Run.MovieCount)};   
        [~,Params.Movie.Filename]   = fileparts(Params.Run.CurrentFile);  
        [mov, Movie.duration, Movie.fps, Movie.width, Movie.height, Movie.count, Movie.AR] = Screen('OpenMovie', Params.Display.win, Params.Run.CurrentFile); 
        Params.Run.mov = mov;
    end

    %================= Initialize DataPixx/ send event codes
    AdcStatus = SCNI_StartADC(Params);                                  % Start DataPixx ADC
    %ScannerOn = SCNI_WaitForTTL(Params, NoTTLs, 1, 1);                 % Wait for TTL pulses from MRI scanner
    SCNI_SendEventCode('Trial_Start', Params);                       	% Send event code to connected neurophys systems

   	%================= START PLAYBACK
    Screen('PlayMovie',mov, Params.Movie.Rate, Params.Movie.Loop, Params.Movie.AudioOn*Params.Movie.AudioVol);
    Screen('SetmovieTimeIndex',mov, Params.Movie.StartTime, 0);  
    
    %================= WAIT FOR ISI TO ELAPSE
    while (GetSecs - FrameOnset(end)) < Params.Movie.ISI
        for Eye = 1:NoEyes 
            Screen('FillRect', Params.Display.win, Params.Movie.Background*255);                                             	% Clear previous frame
            if Params.Display.PD.Position > 1
                Screen('FillOval', Params.Display.win, Params.Display.PD.Color{1}*255, Params.Display.PD.SubRect(Eye,:));
                Screen('FillOval', Params.Display.win, Params.Display.PD.Color{1}*255, Params.Display.PD.ExpRect);
            end
            if Params.Movie.FixOn == 1
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
            Screen('FrameRect', Params.Display.win, Params.Display.Exp.GazeWinColor(FixIn+1,:)*255, Params.Movie.GazeRect, 2); 	% Draw border of gaze window that subject must fixate within
        end
        Screen('FillOval', Params.Display.win, Params.Display.Exp.EyeColor(FixIn+1,:)*255, EyeRect);                            % Draw current gaze position
        Params       	= SCNI_UpdateStats(Params); 

        [~,ISIoffset]  	= Screen('Flip', Params.Display.win); 
        Params.Run.MovieStartTime = ISIoffset;
        if Params.Run.MovieCount == 1
            Params.Run.StartTime  = ISIoffset;
        end
        Params.Run.EndMovie = CheckKeys(Params);                                                   % Check for keyboard input
        if get(Params.Toolbar.StopButton,'value')==1                                    % Check for toolbar input
            Params.Run.EndMovie = 1;
        end
    end

    
    %================= BEGIN CURRENT MOVIE PLAYBACK
    MovieStarted = 0;
    while Params.Run.EndMovie == 0 && (FrameOnset(end)-Params.Run.MovieStartTime) < Params.Movie.Duration
        
        %=============== Get next frame and draw to displays
        if Params.Movie.Paused == 0
            MovieTex = Screen('GetMovieImage', Params.Display.win, mov);                                                    % Get texture handle for next frame
        end
        Screen('FillRect', Params.Display.win, Params.Movie.Background*255);                                             	% Clear previous frame
        for Eye = 1:NoEyes                                                                                              % For each individual eye view...
            currentbuffer = Screen('SelectStereoDrawBuffer', Params.Display.win, Eye-1);                                % Select the correct stereo buffer
            Screen('DrawTexture', Params.Display.win, MovieTex, Params.Movie.SourceRect{1}, Params.Movie.RectExp, Params.Movie.Rotation, [], Params.Movie.Contrast);      % Draw to the experimenter's display
            Screen('DrawTexture', Params.Display.win, MovieTex, Params.Movie.SourceRect{Eye}, Params.Movie.RectMonk, Params.Movie.Rotation, [], Params.Movie.Contrast);   % Draw to the subject's display
            if Params.Display.PD.Position > 1
                Screen('FillOval', Params.Display.win, Params.Display.PD.Color{~Params.Movie.Paused+1}*255, Params.Display.PD.SubRect(Eye,:));
                Screen('FillOval', Params.Display.win, Params.Display.PD.Color{~Params.Movie.Paused+1}*255, Params.Display.PD.ExpRect);
            end
            if Params.Movie.FixOn == 1
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
            Screen('FrameRect', Params.Display.win, Params.Display.Exp.GazeWinColor(FixIn+1,:)*255, Params.Movie.GazeRect, 2); 	% Draw border of gaze window that subject must fixate within
        end
        Screen('FillOval', Params.Display.win, Params.Display.Exp.EyeColor(FixIn+1,:)*255, EyeRect);                            % Draw current gaze position
        Params         = SCNI_UpdateStats(Params);                                      % Update statistics on experimenter's screen
        if MovieStarted == 0                                                            % If this is first frame of movie clip...
            SCNI_SendEventCode('Stim_On', Params);                                      % Send event code to connected neurophys systems
            MovieStarted = 1;                                                           % Change flag to show movie has started
        end
        [VBL FrameOnset(end+1)] = Screen('Flip', Params.Display.win);                   % Flip next frame
        Params.Run.EndMovie = CheckKeys(Params);                                                   % Check for keyboard input
        if get(Params.Toolbar.StopButton,'value') == 1
            Params.Run.EndMovie = 1;
        end
        if Params.Movie.Paused == 0 
            Screen('Close', MovieTex);                                                	% Close the last movie frame texture
        end
    end

    %================= END MOVIE PLAYBACK
    MovieEndTime = Screen('GetMovieTimeIndex', mov);
    Screen('CloseMovie',mov);
    Params.Run.MovieCount = Params.Run.MovieCount+1;
end

if CloseOnFinish == 1
    sca;
end

%================= PRINT PLAYBACK STATISTICS
if isfield(Params, 'Debug') && Params.Debug.On == 1
    Frametimes      = diff(FrameOnset);
    meanFrameRate   = mean(Frametimes(2:end))*1000;
    semFrameRate    = (std(Frametimes(2:end))*1000)/sqrt(numel(Frametimes(2:end)));
    fprintf('Frames shown............%.0f\n', numel(Frametimes));
    fprintf('Movie end time..........%.0f seconds\n', MovieEndTime);
    fprintf('Mean frame duration.....%.0f ms +/- %.0f ms\n', meanFrameRate, semFrameRate);
    fprintf('Max frame duration......%.0f ms\n', max(Frametimes)*1000);
end

end

%=============== CHECK FOR EXPERIMENTER INPUT
function EndMovie = CheckKeys(Params)
    EndMovie = Params.Run.EndMovie;
    [keyIsDown,secs,keyCode] = KbCheck([], Params.Movie.KeysList);                  % Check keyboard for relevant key presses 
    if keyIsDown && secs > Params.Run.LastPress+0.1                              	% If key is pressed and it's more than 100ms since last key press...
        Params.Run.LastPress   = secs;                                            	% Log time of current key press
        if keyCode(Params.Movie.Keys.Pause) == 1                                    % Experimenter pressed pause key
            Params.Movie.Paused      = ~Params.Movie.Paused;                        % Toggle pause status
            if Params.Movie.Paused == 1                                             % If paused...
                Params.Movie.PauseTime = Screen('GetMovieTimeIndex', Params.Run.mov);          % Get the time point of pause
                Screen('PlayMovie',Params.Run.mov, Params.Movie.Rate, Params.Movie.Loop, 0);
            elseif Params.Movie.Paused == 0                                         % If unpaused...
                Screen('SetMovieTimeIndex', Params.Run.mov, Params.Movie.PauseTime);        	% Set the movie time point to when paused
                Screen('PlayMovie',Params.Run.mov, Params.Movie.Rate, Params.Movie.Loop, Params.Movie.AudioOn*Params.Movie.AudioVol);
                Params.Run.StartTime = GetSecs-Params.Movie.PauseTime;              % Refresh start time
            end
        elseif keyCode(Params.Movie.Keys.VolUp) == 1
            Params.Movie.AudioVol = min([1, Params.Movie.AudioVol+Params.Movie.VolInc]);
            Screen('PlayMovie',Params.Run.mov, Params.Movie.Rate, Params.Movie.Loop, Params.Movie.AudioOn*Params.Movie.AudioVol);
        elseif keyCode(Params.Movie.Keys.VolDown) == 1
            Params.Movie.AudioVol = max([0, Params.Movie.AudioVol-Params.Movie.VolInc]);
            Screen('PlayMovie',Params.Run.mov, Params.Movie.Rate, Params.Movie.Loop, Params.Movie.AudioOn*Params.Movie.AudioVol);
        elseif keyCode(Params.Movie.Keys.Stop) == 1                     
            EndMovie = 1;
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
        if Params.Movie.PlayMultiple == 1 && Params.Movie.Duration < Params.Movie.RunDuration           % If multiple movies are presented per trial
            Params.Run.TextFormat = [Params.Run.TextFormat, '\n\n',...                                  % Add movie count field
                                    'Movie count    %d'];
        end
    end

	Params.Run.ValidFixPercent = nanmean(Params.Run.ValidFixations(:,2))*100;

    %========= Update clock
    if Params.Movie.Paused == 1   
         Params.Run.CurrentTime   = Params.Movie.PauseTime;
    elseif Params.Movie.Paused == 0 
        Params.Run.CurrentTime   = GetSecs-Params.Run.StartTime;                                            % Calulate time elapsed
    end
    Params.Run.CurrentMins      = floor(Params.Run.CurrentTime/60);                    
    Params.Run.TotalMins        = floor(Params.Run.Duration/60);
    Params.Run.CurrentSecs      = rem(Params.Run.CurrentTime, 60);
    Params.Run.CurrentPercent   = (Params.Run.CurrentTime/Params.Run.Duration)*100;
	Params.Run.TextContent      = {Params.Movie.Filename, [Params.Run.CurrentMins, Params.Run.CurrentSecs, Params.Run.TotalMins-Params.Run.CurrentMins-1, 60-Params.Run.CurrentSecs, Params.Reward.RunCount, Params.Run.ValidFixPercent]};
    if Params.Movie.PlayMultiple == 1 && Params.Movie.Duration < Params.Movie.RunDuration                   % If multiple movies are presented per trial
        Params.Run.TextContent{2} = [Params.Run.TextContent{2}, Params.Run.MovieCount];                     % Append movie count
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