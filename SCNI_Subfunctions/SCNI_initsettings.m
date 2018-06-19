function Display = NIF_initsettings(Stereo)

%============================== NIF_initsettings.m ========================
% Initializes display settings for visual experiments conducted in the SCNI
% and the NIF. 
%
% HISTORY:
%   2017-01-23 - Adapted from APMSubfunctions by murphyap@mail.nih.gov
%   2017-06-26 - Updated for SCNI displays
%     ____    ___ __  _______
%    /    |  /  //  //  ____/    Neuro Imaging Facility Core
%   /  /| | /  //  //  /___      Building 49 Convent Drive
%  /  / | |/  //  //  ____/      NATIONAL INSTITUTES OF HEALTH
% /__/  |____//__//__/          
%==========================================================================

if nargin == 0 
    Stereo = 0;
end

%% ======================= PERFORM SYESTEM CHECKS =========================
Settings.MATLAB     = version;                                         	% Check MATLAB version and release date
Settings.Bits       = computer('arch');                                	% Check 32 or 64-bit
Settings.PTB        = PsychtoolboxVersion;                             	% Check Psychtoolbox installation and get version
if ~isempty(strfind(Settings.PTB, ' '))
    Settings.PTB   	= Settings.PTB(1:strfind(Settings.PTB, ' '));       
end
if ~ IsOctave
  Settings.OpenGL = opengl('data');                                     % Check graphics card and adapters and check OpenGL version
else
  Settings.OpenGL = [];
end
Settings.Versions = ver;                                                % Check availability of MATLAB toolboxes
Settings.OS = computer;                                                 % Check operating system
[~, Settings.CompName] = system('hostname');                            % Get x-platform computer name
if usejava('jvm')==1
    Settings.CompName = char(getHostName(java.net.InetAddress.getLocalHost()));	% Get x-platform computer name (requires Java)
end
if IsWin && usejava('jvm')
    Settings.SID = get(com.sun.security.auth.module.NTSystem,'DomainSID');  % Check Windows Security Identifier to confirm PC identity
    Settings.CompName = getenv('computername');                             % Get Windows PC name
    address = java.net.InetAddress.getLocalHost;
    Settings.IPaddress = char(address.getHostAddress);
else 
    Settings.IPaddress = '?';
end
if ~isempty(Settings.OpenGL) && ~isempty(Settings.OpenGL.Version) && str2num(Settings.OpenGL.Version(1:3)) < 1.5    % Check what version of OpenGL is available
    fprintf(['DISPLAY: OpenGL version %s does not support vertex buffer objects (VBO)!\n',...
        'You must use display lists instead, but this will reduce performance.\n'], num2str(Settings.OpenGL.Version));
end
if any(double(Settings.CompName) <= 13)
  Settings.CompName(double(Settings.CompName) <= 13) = [];
end
Display.Settings = Settings;
AssertOpenGL;                                                               % Check that the script is running in OpenGL Psychtoolbox, otherwise abort

fprintf('\n============================================================\n');
fprintf('\n     ____    ___ __  _______');
fprintf('\n    /    |  /  //  //  ____/    Neuro Imaging Facility Core');
fprintf('\n   /  /| | /  //  //  /___      Building 49 Convent Drive');
fprintf('\n  /  / | |/  //  //  ____/      NATIONAL INSTITUTES OF HEALTH');
fprintf('\n /__/  |____//__//__/          \n ');

fprintf('\n============== SYSTEM CONFIGURATION SUMMARY ================\n\n');
fprintf('DISPLAY: Computer ID............. %s\n', char(Settings.CompName));
fprintf('DISPLAY: MATLAB version.......... %s\n', Settings.MATLAB);
fprintf('DISPLAY: MATLAB bits............. %s\n', Settings.Bits);
fprintf('DISPLAY: PsychToolbox version.... %s\n', Settings.PTB);
if ~isempty(Settings.OpenGL)
  fprintf('DISPLAY: Graphics hardware....... %s\n', Settings.OpenGL.Renderer);
  fprintf('DISPLAY: OpenGL version.......... %s\n', Settings.OpenGL.Version);
end
try
    [Settings.UserMem Settings.SystemMem] = memory;             % Check system memory if possible
    fprintf('DISPLAY: Available memory........ %.2f GB\n', Settings.UserMem.MemAvailableAllArrays/10^9);
end


%% ========================= SET VIEWING GEOMETRY =========================
% The Epson projectors will change the size of the projected image
% depending on the resolution of the input signal. The settings below are
% based on measurments taken outside of the bore using the same throw
% distance. They should be updated for changes in distance between screen
% and projector.

if IsOSX
    Display.ScreenID  	= min(Screen('Screens'));               % Get the screen ID for the monkey's display
else
	Display.ScreenID  	= max(Screen('Screens'));  
end
Display.Rect            = Screen('rect', Display.ScreenID);  	% Get the screen resolution of a single monitors (pixels)
if IsLinux                                                      % On Linux systems...
    Display.Rect = Display.Rect./[1,1,2,1];                     % Find resolution of one half of dual screen
end
if Display.Rect == [0 0 1280 1024];                             % For standard resolution...
    Display.Dimensions = [19.5, 16.0];                          % display width x height (cm)
elseif Display.Rect == [0 0 1920 1080]                          % For HD 1080p resolution...
	Display.Dimensions = [25.2, 14.5];                          % display width x height (cm)
elseif Display.Rect == [0 0 1920 1200];                     
    Display.Dimensions = [25.2, 16.0]; 
elseif Display.Rect == [0 0 1280 800];  
     Display.Dimensions = [25.2, 16.0]; 
end
if IsLinux                                                      %======= For Linux systems...
    if Screen('rect', Display.ScreenID) == [0 0 9600 2160]          % Ubuntu system with 1 x 1080p + 2 x 4K displays
        error('Display resolution (%d x %d) requires multiple X servers! Try using NVidia GUI to configure', Display.Rect([3,4]));
    elseif Display.Rect == [0 0 3840 2160] | Display.Rect == [0 0 1920 1080] % Correctly configured Ubuntu system with dual 4K/ 1080p displays
        if strfind(Display.Settings.CompName, 'vpixx-HP-Z240-Tower-Workstation')
            Display.Dimensions  = [122.6, 71.8];                % SCNI 55" LG OLED 4K TV
        else
            Display.Dimensions = [25.2, 16.0];                  % NIF Epson porjectors
        end
    end
end
if ~isfield(Display, 'Dimensions')
    error('The current display resolution (%d x %d) is not supported by %s!\n', Display.Rect([3,4]), mfilename);
end

Display.Center      = Display.Rect([3,4])/2;                % Get pixel coordinates of center of screen
Display.D           = 52;                                	% viewing distance from monkey to screen (cm)
Display.Stereomode  = 0;                                    % run in stereo mode?                        
Display.Mirror      = 0;                                 	% Set inversion (mirroring) to on?

if Stereo == 0                                                              % If stereo presentation was not requested...
     Display.Stereomode = 0;                                                % Select monocular presentation
%      Display.ScreenID = min(Screen('Screens'));                             % Only use one monitor
elseif Stereo == 2
     Display.Stereomode = 4;
%      Display.ScreenID = max(Screen('Screens'));                         
end
Display.RefreshRate = Screen('NominalFramerate', Display.ScreenID);         % Get the monitor refresh rate (Hz)
if str2double(Settings.PTB(1)) >= 3                                         % For more recent versions of PTB...
    if ismac                                                                % Check is running on OS X...
        if Display.RefreshRate == 0                                         % If running on OS X and refresh rate of 0Hz is reported...
            Display.RefreshRate = 60;                                   	% Assume refresh rate of 60Hz
        end
        if Display.Stereomode == 4                                          % If running on OS X and dual view stereomode is requested...
            Display.Stereomode = 10;
        end
    end
end

Display.MultiSample     = 0;                                                    % Set to higher values (2,4,6,8) for improved anti-aliasing        
Display.AspectRatio     = Display.Rect(3)/Display.Rect(4);                      % Calculate the screen's aspect ration at current resolution
Display.PixPerCm        = Display.Rect([3,4])./Display.Dimensions([1,2]);       % Calculate number of pixels per centimetre
Display.PixPerDeg       = (Display.PixPerCm*Display.D*tand(0.5))*2;             % Calculate pixles per degree
Display.CmPerDeg        = tand(1)*Display.D;                                    % Calculate the number of centimetres per degree of visual angle


fprintf('\n============== DISPLAY SETTINGS SUMMARY ====================\n\n');
fprintf('DISPLAY: PTB screen selected..... %d\n', Display.ScreenID);
fprintf('DISPLAY: Screen resolution....... %d x %d\n', Display.Rect(3),Display.Rect(4));
fprintf('DISPLAY: Screen refresh rate..... %d Hz\n', Display.RefreshRate);
switch Display.Stereomode
    case 0
    	fprintf('DISPLAY: Stereomode.............. 0 = monocular presentation.\n');
    case 4
        fprintf('DISPLAY: Stereomode.............. 4 = dual screen stereo presentation.\n');
    case 6
        fprintf('DISPLAY: Stereomode.............. 6 = red-green anaglyph presentation.\n');
    case 8
        fprintf('DISPLAY: Stereomode.............. 8 = red-blue anaglyph presentation.\n');
    case 10
        fprintf('DISPLAY: Stereomode.............. 10 = horizontal span stereo presentation (OSX/ Win7).\n');
end
switch Display.Mirror
    case 0
         fprintf('DISPLAY: Mirror mode............. OFF\n\n');
    case 1
         fprintf('DISPLAY: Mirror mode............. ON\n\n');
end