%======================= SCNI_GazeFollowingSettings.m =====================
% This function provides a graphical user interface for setting parameters 
% related to the gaze following experiments. Parameters can be saved and 
% loaded, and the updated parameters are returned in the structure 'Params'.
%
% INPUTS:
%   ParamsFile:   	optional string containing full path of a .mat file
%                	containing previously saved parameters. If no input is
%                	provided, the function will search for a .mat file with
%                	the name of the local computer. If no file is found,
%                	default parameters are loaded.
% OUTPUT:
%   Params:         a structure containing the parameters set in the GUI.
%
%==========================================================================

function ParamsOut = SCNI_GazeFollowingSettings(ParamsFile, OpenGUI)

persistent Params Fig;

%============ Initialize GUI
GUItag      = 'SCNI_GazeFollowingSettings';             	% String to use as GUI window tag
Fieldname   = 'GF';                                         % Params structure fieldname for DataPixx info
if ~exist('OpenGUI','var')
    OpenGUI = 1;
end
if ~exist('ParamsFile','var')
    ParamsFile = [];
elseif exist('ParamsFile','var')
    if ischar(ParamsFile) && exist(ParamsFile, 'file')
        Params      = load(ParamsFile);
    elseif isstruct(ParamsFile)
        Params      = ParamsFile;
        ParamsFile  = Params.File;
    end
end
[Params, Success, Fig]   = SCNI_InitGUI(GUItag, Fieldname, Params, OpenGUI);

%=========== Load default parameters
if Success < 1
    
    %============= Spatial parameters
    Params.GF.StimDir           = uigetdir('/projects/murphya/Blender/Renders/CuedAttention/AnimationFrames/'); 	% Get full path of directory containing stimulus files
    Params.GF.TargetArrays      = {'Linear','Circular'};                    % Geometric arrangment of target array
    Params.GF.TargetArray       = 1;                                        
  	Params.GF.NoTargets         = 2;                                        % Number of targets on each trial
    Params.GF.ActorLocations	= {'Central only','Multiple'};              
    Params.GF.Modes             = {'Training','Easy','Intermediate','Difficult','Controls'};               
    Params.GF.Mode              = 1;                                        
    Params.GF.BckgrndTypes      = {'None','Image','Movie'};               	% Add a background?
    Params.GF.BckgrndType       = 1;
    Params.GF.BckgrndDir        = '/projects/murphya/Stimuli/';           	% Add an image or movie background?
    Params.GF.Greyscale         = 0;                                        % Convert images to greyscale?
    Params.GF.Contrast          = 1;                                        % Contrast (proportion)
    Params.GF.Use3D             = 1;      
    Params.GF.NoiseLevel        = 0;
    Params.GF.Contrast          = 1;
    
    %============= Fixation parameters
    Params.GF.FixWinDeg         = 2;                                        % Diameter of circular fixation window (degrees)
    Params.GF.FixTypes          = {'None','Dot','Square','Cross','Binocular'}; % Central fixation marker types
    Params.GF.FixType         	= 3;                                        
    Params.GF.FixDiameter      	= 1;                                        % Central fixation marker diameter (degrees)
    Params.GF.FixColor          = [0,1,0];                                  % Color of central fixation marker (RGB, 0-1)

    %============= Trial timing parameters
    Params.GF.TrialsPerRun      = 100;                                      % Number of trials per run
    Params.GF.InitialFix        = 500;                                      % Initial fixation duration (ms)
    Params.GF.TargetDur         = 500;                                      % Duration that targets appear for prior to the cue (ms)
    Params.GF.TargDurJitter     = 200;                                      % Maximum temporal jitter (+/- ms) between targets and cue
    Params.GF.CueDur            = 500;                                      % Cue duration (ms)
    Params.GF.CueDurJitter      = 200;
    Params.GF.RespDurMax        = 500;                                      % Maximum duration from fixation offset for subject to select a target
    Params.GF.RespFixDur        = 1000;                                     % Duration that subject must fixate selected target for (ms)
    Params.GF.PreRewardDur      = 500;                                      % Duration from target offset to reward delivery (ms)
    Params.GF.PreRewardJitter	= 200;                                    	
    
    Params.GF.CorrectColor      = [0,1,0];
    Params.GF.IncorrectColor    = [1,0,0];
    Params.GF.UseAudioCue       = 1;

    
elseif Success > 1
    ParamsOut = Params;
	return;
end
if OpenGUI == 0
    ParamsOut = Params;
    return;
end

%========================= OPEN GUI WINDOW ================================
Fig.Handle          = figure;                                       	% Open new figure window         
setappdata(0,GUItag,Fig.Handle);                                        % Assign tag
Fig.PanelYdim       = 130*Fig.DisplayScale;
Fig.Rect            = [0 200 500 900]*Fig.DisplayScale;              	% Specify figure window rectangle
set(Fig.Handle,     'Name','SCNI: Gaze Following Experiment settings',...    	% Open a figure window with specified title
                    'Tag','SCNI_GazeFollowingSettings',...            	% Set figure tag
                    'Renderer','OpenGL',...                             % Use OpenGL renderer
                    'OuterPosition', Fig.Rect,...                       % position figure window
                    'NumberTitle','off',...                             % Remove figure number from title
                    'Resize', 'off',...                                 % Prevent resizing of GUI window
                    'Menu','none',...                                   % Turn off memu
                    'Toolbar','none');                                  % Turn off toolbars to save space
Fig.Background  = get(Fig.Handle, 'Color');                           	% Get default figure background color
Fig.Margin      = 20*Fig.DisplayScale;                               	% Set margin between UI panels (pixels)                                 
Fig.Fields      = fieldnames(Params);                                 	% Get parameter field names
Fig.FontSize    = 16;
Fig.TitleFontSize = 18;

%============= Prepare GUI panels
Fig.PanelNames      = {'Stimulus configuration','Trial Timing','Fixation requirements'};
Fig.PannelHeights   = [220, 200, 260];
BoxPos{1}           = [Fig.Margin, Fig.Rect(4)-Fig.PannelHeights(1)*Fig.DisplayScale-Fig.Margin*2, Fig.Rect(3)-Fig.Margin*2, Fig.PannelHeights(1)*Fig.DisplayScale];   
for i = 2:numel(Fig.PanelNames)
    BoxPos{i}           = [Fig.Margin, BoxPos{i-1}(2)-Fig.PannelHeights(i)*Fig.DisplayScale-Fig.Margin/2, Fig.Rect(3)-Fig.Margin*2, Fig.PannelHeights(i)*Fig.DisplayScale];
end


Fig.UIstim.Labels         = {'Stimulus directory', 'Background directory', 'Background type','Target array','Targets per trial','Trial mode','Greyscale?','Stereoscopic 3D?','Noise (%)'};
Fig.UIstim.Style          = {'Edit','Edit','Popup','Popup','Edit','Popup','checkbox','checkbox','edit'};
Fig.UIstim.Defaults       = {Params.GF.StimDir, Params.GF.BckgrndDir, Params.GF.BckgrndTypes, Params.GF.TargetArrays, Params.GF.NoTargets, Params.GF.Modes, [], [], Params.GF.NoiseLevel};
Fig.UIstim.Values         = {isempty(Params.GF.StimDir), isempty(Params.GF.BckgrndDir), Params.GF.BckgrndType, Params.GF.TargetArray, [], Params.GF.Mode, Params.GF.Greyscale, Params.GF.Use3D, []};
Fig.UIstim.Enabled        = [0, 0, 1, 1, 1, 1, 1, 1, 1];
Fig.UIstim.Tips           = {'Select directory to load stimuli from','Select directory to load background images from','Select background type',...
                                'Select target array geometry','Select number of targets to present on each trial'...
                                 sprintf('Select trial mode:\n1) Training = Targets only, no cue and no avatar.\n2) Easy = Central avatar uses head and body to cue.\n3) Intermediate = \n4) Difficult = avatar changes position\n5) Controls = eyes only, eyes closed, silhouette, etc.'), ...
                                'Select whether stimuli are presented in black and white','Select whether stimuli are presented in stereoscopic 3D', 'Select level of visual noise to add'};
Fig.UIstim.Ypos           = [(Fig.PannelHeights(1)-50):-20:10]*Fig.DisplayScale;
Fig.UIstim.Xwidth         = [180, 200]*Fig.DisplayScale;


Fig.UItiming.Labels   	= {'Trials per run','Initial fixation (ms)','Target duration (ms)', 'Cue duration (ms)', 'Response window (ms)','Selection duration (ms)','Reward delay (ms)'};
Fig.UItiming.Style   	= {'Edit','Edit','Edit','Edit','Edit','Edit','Edit','Edit',};
Fig.UItiming.Defaults	= {Params.GF.TrialsPerRun, Params.GF.InitialFix, Params.GF.TargetDur, Params.GF.CueDur, Params.GF.RespDurMax, Params.GF.RespFixDur, Params.GF.PreRewardDur};
Fig.UItiming.Values   	= {[], [], [], [], [], [], []};
Fig.UItiming.Enabled  	= [1,1,1,1,1,1,1];
Fig.UItiming.Ypos    	= [(Fig.PannelHeights(2)-50):-20:10]*Fig.DisplayScale;
Fig.UItiming.Xwidth 	= [180, 200]*Fig.DisplayScale;

Fig.UIfixation.Labels    	= {'Central fix window (deg)','Central fix type','Central fix diameter (deg)','Central fix color','Audio cue?'};
Fig.UIfixation.Style    	= {'Edit','Popup', 'Edit','PushButton','Checkbox'};
Fig.UIfixation.Defaults   	= {Params.GF.FixWinDeg, Params.GF.FixTypes, Params.GF.FixDiameter,[],[]};
Fig.UIfixation.Values     	= {[],Params.GF.FixType,[],[],Params.GF.UseAudioCue};
Fig.UIfixation.Enabled    	= [1,1,1,1,1,1,1,1,1,1,1];
Fig.UIfixation.Ypos        	= [(Fig.PannelHeights(3)-50):-20:10]*Fig.DisplayScale;
Fig.UIfixation.Xwidth      	= [180, 200]*Fig.DisplayScale;

Fig.PanelVars(1).Fieldnames = {'', '', 'BckgrndType', 'TargetArray', 'NoTargets','Mode','Greyscale', 'Use3D', 'NoiseLevel'};
Fig.PanelVars(2).Fieldnames = {'TrialsPerRun', 'InitialFix', 'TargetDur', 'CueDur', 'RespDurMax', 'RespFixDur', 'PreRewardDur'};
Fig.PanelVars(3).Fieldnames = {'FixWinDeg','FixType','FixDiameter','UseAudioCue'};

Fig.OffOn           = {'Off','On'};
PanelStructs        = {Fig.UIstim, Fig.UItiming, Fig.UIfixation};

for p = 1:numel(Fig.PanelNames)
    Fig.PannelHandl(p) = uipanel( 'Title',Fig.PanelNames{p},...
                'FontSize',Fig.TitleFontSize,...
                'BackgroundColor',Fig.Background,...
                'Units','pixels',...
                'Position',BoxPos{p},...
                'Parent',Fig.Handle); 
            
    for n = 1:numel(PanelStructs{p}.Labels)
        uicontrol(  'Style', 'text',...
                    'String',PanelStructs{p}.Labels{n},...
                    'Position', [Fig.Margin, PanelStructs{p}.Ypos(n), PanelStructs{p}.Xwidth(1), 20*Fig.DisplayScale],...
                    'Parent', Fig.PannelHandl(p),...
                    'HorizontalAlignment', 'left',...
                    'FontSize', Fig.FontSize);

        Fig.UIhandle(p,n) = uicontrol(  'Style', PanelStructs{p}.Style{n},...
                    'String', PanelStructs{p}.Defaults{n},...
                    'Value', PanelStructs{p}.Values{n},...
                    'Enable', Fig.OffOn{PanelStructs{p}.Enabled(n)+1},...
                    'Position', [Fig.Margin + PanelStructs{p}.Xwidth(1), PanelStructs{p}.Ypos(n), PanelStructs{p}.Xwidth(2), 20*Fig.DisplayScale],...
                    'Parent', Fig.PannelHandl(p),...
                    'HorizontalAlignment', 'left',...
                    'FontSize', Fig.FontSize,...
                    'Callback', {@UpdateParams, p, n});
        if p == 1 
            set(Fig.UIhandle(p,n), 'TooltipString', PanelStructs{p}.Tips{n});
            if n < 3
                uicontrol(  'Style', 'pushbutton',...
                            'string','...',...
                            'Parent', Fig.PannelHandl(p),...
                            'Position', [Fig.Margin + 20+ sum(PanelStructs{p}.Xwidth([1,2])), PanelStructs{p}.Ypos(n), 20*Fig.DisplayScale, 20*Fig.DisplayScale],...
                            'Callback', {@UpdateParams, p, n});
            end
        end

    end
end
set(Fig.UIhandle(3,4), 'Background', Params.GF.FixColor);

%================= OPTIONS PANEL
uicontrol(  'Style', 'pushbutton',...
            'String','Load Images',...
            'parent', Fig.Handle,...
            'tag','Load Images',...
            'units','pixels',...
            'Position', [Fig.Margin,20*Fig.DisplayScale,100*Fig.DisplayScale,30*Fig.DisplayScale],...
            'TooltipString', 'Load selected images to GPU',...
            'FontSize', Fig.FontSize, ...
            'HorizontalAlignment', 'left',...
            'Callback', {@OptionSelect, 1});   
uicontrol(  'Style', 'pushbutton',...
            'String','Save Params',...
            'parent', Fig.Handle,...
            'tag','Save Params',...
            'units','pixels',...
            'Position', [140,20,100,30]*Fig.DisplayScale,...
            'TooltipString', 'Save current parameters to file',...
            'FontSize', Fig.FontSize, ...
            'HorizontalAlignment', 'left',...
            'Callback', {@OptionSelect, 2});    
uicontrol(  'Style', 'pushbutton',...
            'String','Continue',...
            'parent', Fig.Handle,...
            'tag','Continue',...
            'units','pixels',...
            'Position', [260,20,100,30]*Fig.DisplayScale,...
            'TooltipString', 'Continue to run SCNI_GazeFollowing.m',...
            'FontSize', Fig.FontSize, ...
            'HorizontalAlignment', 'left',...
            'Callback', {@OptionSelect, 3});         

        
uiwait(Fig.Handle);     % Wait until GUI window is closed beofre returning Params
ParamsOut = Params;     % Output 'Params' struct
        
        
%% =========================== SUBFUNCTIONS ===============================

    %==================== User selected option
    function OptionSelect(hObj, Event, Indx)
        switch Indx
            case 1  %============ Load images to GPU
                Params = LoadImages([], Params);
                Params.GF.ImagesLoaded = 1;
                
            case 2  %============ Save parameters to file
                GF = Params.GF;
                save(Params.File, 'GF', '-append');
                
            case 3  %============ Run experiment
%                 if Params.GF.ImagesLoaded == 0
%                     Params = SCNI_LoadGFframes(Params);
%                     Params.GF.ImagesLoaded = 1;
%                 end
                ParamsOut = Params;
                close(Fig.Handle);
                return;

        end
    end

    %==================== Pre-load selected images into GPU ===============
    function Params = LoadImages(win, Params)
        
        if nargin == 0 || isempty(win)
            Screen('Preference', 'VisualDebugLevel', 0);   
            Params.Display.ScreenID = max(Screen('Screens'));
            [Params.Display.win]    = Screen('OpenWindow', Params.Display.ScreenID, Params.Display.Exp.BackgroundColor, Params.Display.Rect,[],[], [], []);
            Screen('BlendFunction', Params.Display.win, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);                                              % Enable alpha channel
        end
        LoadTextPos = (Params.Display.Rect([3,4])./[4,2]);
        TextColor   = [1,1,1]*255;
        Screen(Params.Display.win,'TextSize',60); 
        wbh         = waitbar(0, '');                                                                                                       % Open a waitbar figure
        StimCount   = 1;
        
        %============= Load target stimuli
        TargetFiles             = wildcardsearch(fullfile(Params.GF.StimDir, 'Targets'), '*_Target_Neutral*.png');
        Params.GF.TotalTargets  = numel(TargetFiles);
        TargetTypes             = {'Neutral','Hit','Miss'};
        for Target = 1:Params.GF.TotalTargets                                                                                  	% For each experimental condition...
            for type = 1:numel(TargetTypes)
                Params.GF.TargetFiles{Target, type} = fullfile(Params.GF.StimDir, 'Targets', sprintf('GF1_Target_%s_%02d.png', TargetTypes{type}, Target));
                [im, cmap, alpha] = imread(Params.GF.TargetFiles{Target, type});
                ImageMat    = [im; alpha];
                Params.GF.TargetTex{Target, type} = Screen('MakeTexture', Params.Display.win, ImageMat);
            end
            
            for Frame = 1:numel(Params.GF.NoFrames{Target})                                                                             % For each file...
                
                %============= Update experimenter display
                message = sprintf('Loading image %d of %d (Condition %d/ %d: %s)...\n',Stim, numel(Params.GF.ImByCond{Target}), Target, numel(Params.GF.ImageConds), Params.GF.ImageConds{Target});
                Screen('FillRect', Params.Display.win, Params.Display.Exp.BackgroundColor);                                             	% Clear background
                DrawFormattedText(Params.Display.win, message, LoadTextPos(1), LoadTextPos(2), TextColor);
                Screen('Flip', Params.Display.win, [], 0);                                                                                	% Draw to experimenter display
            
                waitbar(StimCount/Params.GF.TotalImages, wbh, message);                                                               % Update waitbar
                [keyIsDown, secs, keyCode, deltaSecs] = KbCheck();                                                                          % Check if escape key is pressed
                if keyIsDown && keyCode(KbName('Escape'))                                                                                   % If so...
                    break;                                                                                                                  % Break out of loop
                end

                %============= Load next file
                img = imread(Params.GF.ImByCond{Target}{Stim});                                                                         % Load image file
                if Params.GF.UseAlpha == 1
                    [~,~, imalpha] = imread(Params.GF.ImByCond{Target}{Stim});                                                          % Read alpha channel
                    if ~isempty(imalpha)                                                                                                 	% If image file contains transparency data...
                        img(:,:,4) = imalpha;                                                                                           	% Combine into a single RGBA image matrix
                    else
                        img(:,:,4) = ones(size(img,1),size(img,2))*255;
                    end
                end
                
                %============= Convert to greyscale
                if Params.GF.Greyscale == 1                                                                                           % If greyscale was selected...
                    img(:,:,1:3) = repmat(rgb2gray(img(:,:,1:3)),[1,1,3]);                                                                  % Convert RGB(A) image to grayscale
                end
                
                %============= Create PTB texture
                Params.GF.ImgTex{Target}(Stim) = Screen('MakeTexture', Params.Display.win, img);                                                       % Create a PTB offscreen texture for the stimulus
                StimCount = StimCount+1;
            end

        end

        delete(wbh);                                                                                                                      	% Close the waitbar figure window
        Screen('FillRect', Params.Display.win, Params.Display.Exp.BackgroundColor);                                                                        % Clear background
        DrawFormattedText(Params.Display.win, sprintf('All %d stimuli loaded!\n\nClick the ''Run'' button in the SCNI Toolbar to start the experiment.', Params.GF.TotalImages),  LoadTextPos(1), LoadTextPos(2), TextColor);
        Screen('Flip', Params.Display.win);
        
    end


    %=============== Update parameters
    function UpdateParams(hObj, Evnt, Indx1, Indx2)

        %============= Panel 1 controls for directory selection
        if Indx1 == 1 && Indx2 == 1         %===== Change image directory
                    StimDir	= uigetdir('/projects/murphya/MacaqueFace3D/','Select stimulus directory');
                    if StimDir == 0
                        return;
                    end
                    Params.GF.StimDir = StimDir;
                    set(Fig.UIhandle(1,1),'string',Params.GF.StimDir);

        elseif Indx1 == 1 && Indx2 == 2      %===== Change background image directory
                    BckgrndDir	= uigetdir('/projects/murphya/','Select background image directory');
                    if BckgrndDir == 0
                        return;
                    end
                    Params.GF.BckgrndDir = BckgrndDir;
                    set(Fig.UIhandle(1,2),'string',Params.GF.BckgrndDir);
                    
        elseif Indx1 == 3 && Indx2 == 4
            Color = uisetcolor;
            if numel(Color>1)
                set(hObj, 'Background', Color);
                Params.GF.FixColor = Color;
            end
                    
        else                                %============= All other controls
            if ~isempty(Fig.PanelVars(Indx1).Fieldnames{Indx2})
                switch get(hObj,'style')
                    case 'edit'
                        NewValue = str2num(get(hObj, 'string'));
                    case 'checkbox'
                        NewValue = get(hObj, 'value');
                    case 'popupmenu'
                        NewValue = get(hObj, 'value');
                end
                eval(sprintf('Params.GF.%s = %d;', Fig.PanelVars(Indx1).Fieldnames{Indx2}, NewValue));
            end
        end
        if Indx1 == 1 && Indx2 <= 4                     % If first 4 controls were updated...
%             Params = RefreshImageList(Params);          % Refresh list of images
        end
        if Indx1 == 2 && Indx2 == 1
            set(Fig.UIhandle(2,2), 'enable', Fig.OffOn{1 + ~NewValue});
        end


    end

    %====================== Refresh the list(s) of images =================
    function Params = RefreshImageList(Params)

        SubDirs                     = dir(Params.GF.StimDir);
        Params.GF.ImageConds        = {SubDirs([SubDirs.isdir]).name};
        Params.GF.ImageConds(~cellfun(@isempty, strfind(Params.GF.ImageConds, '.'))) = [];
        Params.GF.AllImFiles        = [];
        for cond = 1:numel(Params.GF.ImageConds)
            Params.GF.ImByCond{cond} 	= regexpdir(fullfile(Params.GF.StimDir, Params.GF.ImageConds{cond}), Params.GF.FileFormats{Params.GF.FileFormat},0);
            Params.GF.ImByCond{cond}(cellfun(@isempty, Params.GF.ImByCond{cond})) = [];
            Params.GF.AllImFiles      = [Params.GF.AllImFiles; Params.GF.ImByCond{cond}];
        end
        Params.GF.TotalImages     = numel(Params.GF.AllImFiles);

        
        %========== Find background images
        if Params.GF.BckgrndType > 1 && ~isempty(Params.GF.BckgrndDir)   
            switch Params.GF.BckgrndType 
                case 2 
                    Params.GF.BckgrndFiles 	= wildcardsearch(Params.GF.BckgrndDir, '*.png');
                    Params.GF.BckgrndFile   = Params.GF.BckgrndFiles{randi(numel(Params.GF.BckgrndFiles))};
                    
                case 3
                	Params.GF.BckgrndFiles 	= wildcardsearch(Params.GF.BckgrndDir, '*.mp4');
                 	Params.GF.BckgrndFile   = Params.GF.BckgrndFiles{randi(numel(Params.GF.BckgrndFiles))};
            end
        end
        
        %========== Calculate GPU memory required for pre-loading
        Params.GF.AllImFiles = Params.GF.AllImFiles(~cellfun(@isempty, Params.GF.AllImFiles));
        if ~isempty(Params.GF.AllImFiles)
            for n = 1:numel(Params.GF.AllImFiles)
                temp            = dir(Params.GF.AllImFiles{n});
                MemoryTally(n)  = temp.bytes/10^6;
            end
            Params.GF.TotalMemory = sum(MemoryTally);
        else
            Params.GF.TotalMemory = 0;
        end
        
        %========== Update GUI
        if isfield(Fig, 'UIimages')
            ButtonIndx = find(~cellfun(@isempty, strfind(Fig.UIstim.Labels, 'Conditions')));
            if ~isempty(Params.GF.ImageConds)
                set(Fig.UIhandle(1,ButtonIndx), 'string', Params.GF.ImageConds, 'enable', 'on');
            else
                set(Fig.UIhandle(1,ButtonIndx), 'string', {''}, 'enable', 'off');
            end
            StrIndx = find(~cellfun(@isempty, strfind(Fig.UIstim.Labels, 'Total images')));
            set(Fig.UIhandle(1,StrIndx), 'string', num2str(Params.GF.TotalImages));
            StrIndx = find(~cellfun(@isempty, strfind(Fig.UIstim.Labels, 'Total memory (MB)')));
            set(Fig.UIhandle(1,StrIndx), 'string', sprintf('%.2f', Params.GF.TotalMemory));
            
        end
    end

end