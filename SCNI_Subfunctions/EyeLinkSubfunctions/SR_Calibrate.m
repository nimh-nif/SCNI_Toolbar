
function SR_Calibrate(background)

% calibrate the SR eye tracker
%
% parameters
%
% background - specify background colour - this should be the same as for
% the experiment
%
    
% Eyetracker and Screen Setup
    
screenNumber=0
if max(Screen('screens')>1) % multiple screens - for now just use the first one
    screenNumber=1;
end
screenRect=Screen('rect',screenNumber);

eyeRect=[500 100 1180 1000]; % change this to correspond to the rectangle in which we want to calibrate the tracker


% open full screen window
screenWnd = Screen('OpenWindow',screenNumber,background,screenRect,[],2);

    
% with a window we can now do something with the the Eyetracker.
el=EyelinkInitDefaults(); % this does not initialise the window handle and more importantly does not tell the eyelink the size of the window in which to display targets


if ~EyelinkInit(0)
    fprintf('Error initialising eyelink');
    cleanup;  % cleanup function
    return;
end

% set the Eyelink to use the pixel coordinates in the visible rectangle -
% targets should only be shown within this region 
% region
if Eyelink('IsConnected') ~= el.notconnected
    Eyelink('Command', 'screen_pixel_coords = %d %d %d %d',eyeRect(1),eyeRect(2),eyeRect(3)-1,eyeRect(4)-1);
end

el.window=screenWnd; % tell eye tracker to draw into full screen window

el.backgroundcolour     = background;     
el.foregroundcolour = [255 255 255];   
el.msgfontcolour = [0 0 0];
el.imgtitlecolour = [0 0 0];
el.calibrationtargetcolour =  [	255 69 0 ];

% Calibrate the eye tracker
EyelinkDoTrackerSetup(el);

% do a final check of calibration using driftcorrection
status=EyelinkDoDriftCorrection(el);
if(status~=1)
    cleanup;
    return;
end
Screen('CloseAll');
    
end

% cleanup crew to aisle 3
function cleanup
    ShowCursor;
    sca;

    warning on;
end




