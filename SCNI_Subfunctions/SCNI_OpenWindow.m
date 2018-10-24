function Params = SCNI_OpenWindow(Params)

%================= OPEN NEW PTB WINDOW 
HideCursor;                                                                 % Hide mouse cursor
winPtr = Screen('Windows');                                                 % Find all current PTB window pointers
if ~isfield(Params.Display, 'win') || isempty(winPtr)                       % If a PTB window is not already open...
    Screen('Preference', 'VisualDebugLevel', 0);                            % Set debug level
    [Params.Display.win]    = Screen('OpenWindow', Params.Display.ScreenID, Params.Display.Exp.BackgroundColor, Params.Display.XScreenRect,[],[], [], []);
    Screen('BlendFunction', Params.Display.win, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);  	% Enable alpha transparency channel
end