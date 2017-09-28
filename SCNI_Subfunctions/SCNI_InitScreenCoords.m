function c = SCNI_InitScreenCoords(c)

%======================== SCNI_InitScreenCoords.m =========================
% Determine screen coordinates for subject and experimenter displays when
% using dual screen presentation methods. 
%
%
%==========================================================================

if ~isfield(c, 'Display')
    error('Input struct does contain a ''display'' field!\nDisplay settings must be initialized before calling %s\n',mfilename);
end

if isfield(c,'MonkeyFixRect') && iscell(c.MonkeyFixRect)                    % If MonkeyFixRect exists as a cell array...
    IsCalibration = 1;                                                      % This is a calibration
else
    IsCalibration = 0; 
end


%% ================= Calculate screen coordinates
c.Display.ExpRect   = c.Display.Rect;
c.Display.MonkRect  = c.Display.ExpRect([3,2,3,4]).*[1,1,2,1]; 
if ~isfield(c,'Stim_Fullscreen')
    c.Stim_Fullscreen   = 0;
end
if c.Stim_Fullscreen == 0
    c.ImgSize   = round(c.Stim_Diameter*c.Display.PixPerDeg);                                 	% Convert image size from degrees to pixels
elseif c.Stim_Fullscreen == 1                                                                   % If image is rendered at full screen aspect ratio...
    c.ImgSize   = c.Display.Rect([3,4]);                                                        % Stim rect is the same as display rect
end
c.FixRect   = CenterRect([0,0,c.Fix_MarkerSize*c.Display.PixPerDeg], c.Display.Rect);         	% Specify PTB rect to draw fixation marker to    
c.StimRect  = CenterRect([0,0,c.ImgSize], c.Display.Rect);                                     	% Specify PTB rect to draw stimuli to
if ~IsCalibration
    c.GazeRect  = CenterRect([0,0,c.Fix_WinRadius*2*c.Display.PixPerDeg], c.Display.Rect);  	% Specify PTB rect that fixation must remain inside
end

if IsLinux == 1                                                                                 % If using dual displays on Linux...
    c.MonkeyStimRect = c.StimRect + c.Display.Rect([3,1,3,1]);                                	% Specify subject's portion of the screen
    if ~IsCalibration
        c.MonkeyGazeRect = c.GazeRect + c.Display.Rect([3,1,3,1]);                              
    end
    if c.Display.UseSBS3D == 0 
        c.MonkeyFixRect(1,:)  = CenterRect(c.FixRect, c.MonkeyStimRect);  
    elseif c.Display.UseSBS3D == 1                                                                                              % For presenting side-by-side stereoscopic 3D images...
        c.MonkeyHalfRect      = c.MonkeyStimRect([1,2,1,4])+[0,0,diff(c.MonkeyStimRect([1,3]))/2,0];                            % Calculate screen coordinates of left half of subject's display
        if ~IsCalibration                                                                                                       % If this is not a calibration...
            c.MonkeyFixRect(1,:)  = CenterRect([0,0,c.Fix_MarkerSize*c.Display.PixPerDeg]./[1,1,2,1], c.MonkeyHalfRect);     	% Center a horizontally squashed fixation rectangle in a half screen rectangle
            c.MonkeyFixRect(2,:)  = CenterRect([0,0,c.Fix_MarkerSize*c.Display.PixPerDeg]./[1,1,2,1], [c.MonkeyHalfRect([3,2]), c.MonkeyStimRect([3,4])]);
        end
    end
elseif IsLinux == 0
	c.MonkeyStimRect = c.StimRect;   
    if ~IsCalibration
        c.MonkeyFixRect  = c.FixRect;     
        c.MonkeyGazeRect = c.GazeRect;   
    end
end
c.ExpStimRect = c.StimRect./[1,1,2,1];

