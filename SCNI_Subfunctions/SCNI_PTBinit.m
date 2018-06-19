function Params = SCNI_PTBinit(Params)

%============================= SCNI_PTBinit.m =============================
% Prepare and open a PsychToolbox window(s) suitable for the local
% operating system, and return the handle to the window(s). 
%

PsychImaging('PrepareConfiguration'); 
PsychImaging('AddTask', 'General', 'FloatingPoint32Bit');                                  	% Configure PsychToolbox imaging pipeline to use 32-bit floating point numbers                    
PsychImaging('AddTask', 'FinalFormatting', 'DisplayColorCorrection', 'SimpleGamma');     	% Apply inverse gamma for correction of display gamma
if IsOSX == 1                                                                               % If running on OSX...
    PsychImaging('AddTask', 'General', 'DualWindowStereo', Params.Display.ScreenID+1);      % Use dual windows
    Params.Display.Stereomode = 10;                                                         % Dual windows requires steromode 10 on OSX
elseif IsWin == 1                                                                           % If running on Windows...
    PsychImaging('AddTask', 'General', 'DualWindowStereo', Params.Display.ScreenID+1);      % Use dual windows
    Params.Display.Stereomode = 4;                                                          % Dual windows requires steromode 4 on Windows
elseif IsLinux == 1                                                                         % If running on Linux...
    Params.Display.Stereomode = 0;                                                          % Use a single PTB window spread across 2 displays
end

[Params.window, Params.screenRect] = PsychImaging('OpenWindow', Params.Display.ScreenID, Params.Display.Exp.BackgroundColor(1), [], [], [], Params.Display.Stereomode); 	% Open a PTB window
Screen('BlendFunction', Params.window, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);               % Enable alpha channel for transparency
%PsychColorCorrection('SetEncodingGamma', Params.window, 1/c.Display.gamma);                % Set gamma
Screen('TextSize', Params.window, 30);                                                      % Set default text size for window
Screen('TextFont', Params.window, 'Arial');                                                 % Set default font for window