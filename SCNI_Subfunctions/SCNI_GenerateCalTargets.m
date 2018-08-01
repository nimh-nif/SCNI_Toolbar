function Cal = SCNI_GenerateCalTargets(Cal)

%====================== SCNI_GenerateCalTargets.m =========================
% Generate screen coordinates for eye-tracker calibration targets.


Cal.TotalTrials       = Cal.TrialsPerRun*Cal.StimPerTrial;                                              % Total number of trials per run
Cal.NoLocations       = 9;                                                                              % Total number of possible fixation locations
Cal.RepsPerLoc        = ceil(Cal.TotalTrials/Cal.NoLocations);
Cal.LocationOrder     = randperm(Cal.NoLocations, Cal.NoLocations);  
for r = 1:Cal.RepsPerLoc
    Cal.LocationOrder	= [Cal.LocationOrder, randperm(Cal.NoLocations, Cal.NoLocations)];            	% Generate pseudo-random order of locations
end
Cal.FixmarkerRect     = [0, 0, Cal.Fix_MarkerSize*Cal.Display.PixPerDeg];                            	% Size of fixation marker (pixels)
Cal.GazeSourceRect    = [0, 0, Cal.Fix_WinRadius*2*Cal.Display.PixPerDeg];
Cal.FixLocDirections  = [0,0; 1,1; 1,0; 1,-1; 0,-1; -1,-1; -1,0; -1,1; 0,1];                            % Specify XY locations for 9-point grid
Cal.FixLocations      = Cal.FixLocDirections*Cal.FixEccentricity.*repmat(Cal.Display.PixPerDeg,[Cal.NoLocations,1]);	% Scale grid to specified eccentricity (pixels)
Cal.FixLocations      = Cal.FixLocations + repmat(Cal.Display.Rect([3,4])/2, [Cal.NoLocations,1]);    	% Add half a display width and height offsets to center locations
Cal.FixLocationsDeg   = Cal.FixLocDirections*Cal.FixEccentricity;                                         
if IsLinux == 1                                                                                         % If using dual displays on Linux...
    if Cal.Display.UseSBS3D == 0                                                          
        Cal.MonkFixLocations = Cal.FixLocations + repmat(Cal.Display.Rect([3,1]), [Cal.NoLocations,1]);	% Add an additional display width offset for subject's screen  
    elseif Cal.Display.UseSBS3D == 1
        Cal.MonkFixLocations{1} = Cal.FixLocations.*[0.5,1] + repmat(Cal.Display.Rect([3,1]), [Cal.NoLocations,1]);
        Cal.MonkFixLocations{2} = Cal.FixLocations.*[0.5,1] + repmat(Cal.Display.Rect([3,1])*1.5, [Cal.NoLocations,1]);	% Add an additional display width + half offset for subject's screen  
    end
else
    Cal.MonkFixLocations = Cal.FixLocations;
end
for n = 1:size(Cal.FixLocations,1)                                                                              % For each fixation coordinate...
    Cal.FixRects{n}(1,:) = CenterRectOnPoint(Cal.FixmarkerRect, Cal.FixLocations(n,1), Cal.FixLocations(n,2));  % Generate PTB rect argument
    Cal.GazeRect{n}(1,:) = CenterRectOnPoint(Cal.GazeSourceRect, Cal.FixLocations(n,1), Cal.FixLocations(n,2));	%
    if Cal.Display.UseSBS3D == 1  
    	Cal.MonkeyFixRect{n}(1,:)  = CenterRectOnPoint(Cal.FixmarkerRect./[1,1,2,1], Cal.MonkFixLocations{1}(n,1), Cal.MonkFixLocations{1}(n,2)); 	% Center a horizontally squashed fixation rectangle in a half screen rectangle
        Cal.MonkeyFixRect{n}(2,:)  = CenterRectOnPoint(Cal.FixmarkerRect./[1,1,2,1], Cal.MonkFixLocations{2}(n,1), Cal.MonkFixLocations{2}(n,2)); 
    else
        Cal.MonkeyFixRect{n}       = CenterRectOnPoint(Cal.FixmarkerRect, Cal.MonkFixLocations(n,1), Cal.MonkFixLocations(n,2)); 
    end
end