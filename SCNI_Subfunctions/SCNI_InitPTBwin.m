function c = SCNI_InitPTBwin(c)

%========================= SCNI_InitPTBwin.m ==============================
% Initialize PsychToolbox window

PsychImaging('PrepareConfiguration'); 
PsychImaging('AddTask', 'General', 'FloatingPoint32Bit');                                       % Configure PsychToolbox imaging pipeline to use 32-bit floating point numbers                    
PsychImaging('AddTask', 'FinalFormatting', 'DisplayColorCorrection', 'SimpleGamma');            % Apply inverse gamma for correction of display gamma
if IsOSX == 1
    PsychImaging('AddTask', 'General', 'DualWindowStereo', c.Display.ScreenID+1);
    c.Display.Stereomode    = 10;
elseif IsWin == 1
    PsychImaging('AddTask', 'General', 'DualWindowStereo', c.Display.ScreenID+1);
    c.Display.Stereomode    = 4;
elseif IsLinux == 1
    c.Display.ScreenID      = 1;
    c.Display.Stereomode    = 0;
end
[c.window, c.screenRect] = PsychImaging('OpenWindow', c.Display.ScreenID, c.Col_bckgrndRGB(1), [], [], [], c.Display.Stereomode); 	% Open a PTB window
Screen('BlendFunction', c.window, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);                        % Enable alpha channel
% PsychColorCorrection('SetEncodingGamma', c.window, 1/c.Display.gamma);     
c.ExperimenterBuffer        = 0;
c.MonkeyBuffer              = 1;
Screen('TextSize', c.window, 30);
Screen('TextFont', c.window, 'Arial');