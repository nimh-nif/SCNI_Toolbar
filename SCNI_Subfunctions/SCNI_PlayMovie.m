function Movie = SCNI_PlayMovie(Params, movieFile)


%================= SET DEFAULT PARAMETERS
if nargin < 2
    Params.Movie.Dir            = '/projects/murphya/Stimuli/Movies/MonkeyThieves1080p/Season 1/';
    Params.Movie.AllFiles       = wildcardsearch(Params.Movie.Dir, '*.mp4');
    Params.Movie.CurrentFile    = Params.Movie.AllFiles{randi(numel(Params.Movie.AllFiles))};
    [~,Params.Movie.Filename]   = fileparts(Params.Movie.CurrentFile);
    Params.Movie.Duration       = 300;                      % Duration of each movie file to play (seconds). Whole movie plays if empty.
    Params.Movie.PlayMultiple   = 1;                        % Play multiple different movie files consecutively?
    Params.Movie.SBS            = 0;                        % Are movies in side-by-side stereoscopic 3D format?
    Params.Movie.Fullscreen     = 0;                        % Scale the movie to fill the display screen?
    Params.Movie.AudioOn        = 1;                        % Play accompanying audio with movie?
    Params.Movie.AudioVol       = 1;                        % Set proportion of volume to use
    Params.Movie.VolInc         = 0.1;                      % Volume change increments (proportion) when set by experimenter
    Params.Movie.Loop           = 0;                        % Loop playback of same movie if it reaches the end before the set playback duration?
    Params.Movie.Background     = [0,0,0];                  % Color (RGB) of background for non-fullscreen movies
    Params.Movie.Rate           = 1;                        % Rate of movie playback as proportion of original fps (range -1:1)
    Params.Movie.StartTime      = 1;                        % Movie playback starts at time (seconds)
    Params.Movie.Scale          = 0.8;                        % Proportion of original size to present movie at
    Params.Movie.Paused         = 0;
    
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
    
    %============== Behavioural parameters
    Params.Movie.GazeRectBorder = 2;                        % Distance of gaze window border from edge of movie frame (degrees)
    Params.Movie.FixOn          = 0;                        % Present a fixtion marker during movie playback?
    Params.Movie.PreCalib       = 0;                        % Run a quick 9-point calibration routine prior to movie onset?
    Params.Movie.Reward         = 1;                        % Give reward during movie?
    Params.Movie.FixRequired    = 1;                        % Require fixation criterion to be met for reward?
    

end

%================= PRE-ALLOCATE RUN AND REWARD FIELDS
Params.Run.ValidFixations       = nan(Params.Movie.Duration*Params.DPx.AnalogInRate, 2);
Params.Run.LastRewardTime       = GetSecs;
Params.Run.TextColor            = [1,1,1]*255;
Params.Run.TextRect             = [100, 100, [100, 100]+[200,300]];
Params.Run.Duration             = Params.Movie.Duration;
Params.Run.MaxTrialDur          = Params.Run.Duration;
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
    [Params.Display.win]    = Screen('OpenWindow', Params.Display.ScreenID, Params.Display.Exp.BackgroundColor, Params.Display.Rect,[],[], [], []);
    Params.Display.ExpRect  = Params.Display.Rect;
    Params                  = SCNI_InitializeGrid(Params);
end

%================= INITIALIZE DATAPIXX
if Params.DPx.UseDPx == 1
    Params = SCNI_DataPixxInit(Params);
end

%================= LOAD MOVIE FILE
EndMovie        = 0;
LastPress       = GetSecs;
[mov, Movie.duration, Movie.fps, Movie.width, Movie.height, Movie.count, Movie.AR] = Screen('OpenMovie', Params.Display.win, Params.Movie.CurrentFile); 
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
    Params.Movie.RectMonk   = Params.Movie.RectExp + [Params.Display.Rect(3), 0, 0, 0];
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

%================= START PLAYBACK
Screen('PlayMovie',mov, Params.Movie.Rate, Params.Movie.Loop, Params.Movie.AudioOn*Params.Movie.AudioVol);
Screen('SetmovieTimeIndex',mov, Params.Movie.StartTime, 0);
Screen('FillRect',Params.Display.win, Params.Movie.Background);
[~,FrameOnset]          = Screen('Flip', Params.Display.win);
Params.Run.StartTime    = FrameOnset;

%================= BEGIN MOVIE PLAYBACK
while EndMovie == 0 && (GetSecs-Params.Run.StartTime) < Params.Movie.Duration
    
    %=============== Get next frame and draw to displays
    if Params.Movie.Paused == 0
        MovieTex = Screen('GetMovieImage', Params.Display.win, mov);                                                    % Get texture handle for next frame
    end
    Screen('FillRect', Params.Display.win, Params.Movie.Background*255);                                             	% Clear previous frame
    for Eye = 1:NoEyes                                                                                              % For each individual eye view...
        currentbuffer = Screen('SelectStereoDrawBuffer', Params.Display.win, Eye-1);                                % Select the correct stereo buffer
        Screen('DrawTexture', Params.Display.win, MovieTex, Params.Movie.SourceRect{1}, Params.Movie.RectExp);      % Draw to the experimenter's display
        %Screen('DrawTexture', Params.Display.win, MovieTex, Params.Movie.SourceRect{Eye}, Params.Movie.RectMonk);   % Draw to the subject's display
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
    ValidFixNans    	= find(isnan(Params.Run.ValidFixations), 1);                          	% Find first NaN elements in fix vector
    Params.Run.ValidFixations(ValidFixNans,:) = [GetSecs, FixIn];                             	% Save current fixation result to matrix
    Params = SCNI_CheckReward(Params);                                                          
    
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
	Params         = SCNI_UpdateStats(Params); 
    
    [VBL FrameOnset(end+1)] = Screen('Flip', Params.Display.win);               % Flip next frame

    
    %=============== Check for experimenter input
    [keyIsDown,secs,keyCode] = KbCheck([], Params.Movie.KeysList);                  % Check keyboard for relevant key presses 
    if keyIsDown && secs > LastPress+0.1                                            % If key is pressed and it's more than 100ms since last key press...
      	LastPress   = secs;                                                         % Log time of current key press
        if keyCode(Params.Movie.Keys.Pause) == 1                                    % Experimenter pressed pause key
            Params.Movie.Paused      = ~Params.Movie.Paused;                        % Toggle pause status
            if Params.Movie.Paused == 1                                             % If paused...
                Params.Movie.PauseTime = Screen('GetMovieTimeIndex', mov);          % Get the time point of pause
                Screen('PlayMovie',mov, Params.Movie.Rate, Params.Movie.Loop, 0);
            elseif Params.Movie.Paused == 0                                         % If unpaused...
                Screen('SetMovieTimeIndex', mov, Params.Movie.PauseTime);        	% Set the movie time point to when paused
                Screen('PlayMovie',mov, Params.Movie.Rate, Params.Movie.Loop, Params.Movie.AudioOn*Params.Movie.AudioVol);
                Params.Run.StartTime = GetSecs-Params.Movie.PauseTime;              % Refresh start time
            end
        elseif keyCode(Params.Movie.Keys.VolUp) == 1
            Params.Movie.AudioVol = min([1, Params.Movie.AudioVol+Params.Movie.VolInc]);
            Screen('PlayMovie',mov, Params.Movie.Rate, Params.Movie.Loop, Params.Movie.AudioOn*Params.Movie.AudioVol);
        elseif keyCode(Params.Movie.Keys.VolDown) == 1
            Params.Movie.AudioVol = max([0, Params.Movie.AudioVol-Params.Movie.VolInc]);
            Screen('PlayMovie',mov, Params.Movie.Rate, Params.Movie.Loop, Params.Movie.AudioOn*Params.Movie.AudioVol);
        elseif keyCode(Params.Movie.Keys.Stop) == 1                     
            EndMovie = 1;
        end
    end
    
	if Params.Movie.Paused == 0
        Screen('Close', MovieTex);                                                	% Close the last texture
    end
end

%================= END MOVIE PLAYBACK
MovieEndTime = Screen('GetMovieTimeIndex', mov);
Screen('CloseMovie',mov);
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

%================= UPDATE EXPERIMENTER'S DISPLAY STATS
function Params = SCNI_UpdateStats(Params)

    %=============== Initialize experimenter display
    if ~isfield(Params.Run, 'BlockImg')
        Params.Run.BlockImg      = ones([100,200]).*255;                                                % Create blank background
        Params.Run.BlockImgRect  = [100, Params.Display.Rect(4)-100, 600, Params.Display.Rect(4)-50]; 	% Specify onscreen position to draw block design
        Params.Run.BlockImgLen   = Params.Run.BlockImgRect(3)-Params.Run.BlockImgRect(1);            	% Calculate length of block design rect
        Params.Run.BlockImgTex   = Screen('MakeTexture', Params.Display.win, Params.Run.BlockImg);   	% Generate texture handle for block design image
        ProgOverlay              = zeros(size(Params.Run.BlockImg));                                  	% Generate a dark progress bar to overlay on block design
        ProgOverlay(:,:,1)       = 255;
        ProgOverlay(:,:,4)       = 127;                                                                 % Set progress bar overlay opacity (0-255)
        Params.Run.BlockProgTex  = Screen('MakeTexture', Params.Display.win, ProgOverlay);            	% Create a texture handle for overlay
        Params.Run.TextFormat    = ['Movie file      %s\n\n',...
                                    'Time elapsed    %02d:%02.0f\n\n',...
                                    'Time remaining  %02d:%02.0f\n\n',...
                                    'Reward count    %d\n\n',...
                                    'Valid fixation  %.0f %%'];
        if Params.Display.Rect(3) > 1920
           Screen('TextSize', Params.Display.win, 40);
           Screen('TextFont', Params.Display.win, 'Courier');
        end
    end

	Params.Run.ValidFixPercent = nanmean(Params.Run.ValidFixations(:,2))*100;

    %========= Update clock
    if Params.Movie.Paused == 1   
         Params.Run.CurrentTime   = Params.Movie.PauseTime;
    elseif Params.Movie.Paused == 0 
        Params.Run.CurrentTime   = GetSecs-Params.Run.StartTime;                                            % Calulate time elapsed
    end
    Params.Run.CurrentMins   = floor(Params.Run.CurrentTime/60);                    
    Params.Run.TotalMins     = floor(Params.Run.Duration/60);
    Params.Run.CurrentSecs   = rem(Params.Run.CurrentTime, 60);
    Params.Run.CurrentPercent = (Params.Run.CurrentTime/Params.Run.Duration)*100;
	Params.Run.TextContent   = {Params.Movie.Filename, [Params.Run.CurrentMins, Params.Run.CurrentSecs, Params.Run.TotalMins-Params.Run.CurrentMins-1, 60-Params.Run.CurrentSecs, Params.Reward.RunCount, Params.Run.ValidFixPercent]};
    Params.Run.TextString    = sprintf(Params.Run.TextFormat, Params.Run.TextContent{1}, Params.Run.TextContent{2});

    %========= Update stats bar
    Screen('DrawTexture', Params.Display.win, Params.Run.BlockImgTex, [], Params.Run.BlockImgRect);
    Screen('FrameRect', Params.Display.win, [0,0,0], Params.Run.BlockImgRect, 3);
    Params.Run.BlockProgLen      = Params.Run.BlockImgLen*(Params.Run.CurrentPercent/100);
    Params.Run.BlockProgRect     = [Params.Run.BlockImgRect([1,2]), Params.Run.BlockProgLen+Params.Run.BlockImgRect(1), Params.Run.BlockImgRect(4)];
    Screen('DrawTexture',Params.Display.win, Params.Run.BlockProgTex, [], Params.Run.BlockProgRect);
    Screen('FrameRect',Params.Display.win, [0,0,0], Params.Run.BlockProgRect, 3);
    
    DrawFormattedText(Params.Display.win, Params.Run.TextString, Params.Run.TextRect(1), Params.Run.TextRect(2), Params.Run.TextColor);
end