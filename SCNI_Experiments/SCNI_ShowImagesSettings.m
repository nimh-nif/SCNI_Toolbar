%======================== SCNI_ShowImagesSettings.m =======================
% This function provides a graphical user interface for setting parameters 
% related to simple static image presentation experiments. Parameters can 
% be saved and loaded, and the updated parameters are returned in the 
% structure 'Params'.
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

function ParamsOut = SCNI_ShowImagesSettings(ParamsFile, OpenGUI)

persistent Params Fig;

%============ Initialize GUI
GUItag      = 'SCNI_ShowImagesSettings';             	% String to use as GUI window tag
Fieldname   = 'ImageExp';                               % Params structure fieldname for DataPixx info
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
[Params, Success, Fig]   = SCNI_InitGUI(GUItag, Fieldname, ParamsFile, OpenGUI);

%=========== Load default parameters
if Success < 1
    Params.ImageExp.ImageDir	= uigetdir('/projects/murphya/Stimuli');    % Get full path of directory containing stimulus images
    Params.ImageExp.LoadRecurs  = 1;                                        % Load images recursively from all sub-directories?
    Params.ImageExp.FileFormats = {'.png','.jpg','.bmp'};                 	% What file format are the images?
    Params.ImageExp.FileFormat  = 1;
    Params.ImageExp.SubdirOpts  = {'Ignore','Load','Conditions'};           % How to treat subdirectories found in Params.ImageExp.ImageDir?    
    Params.ImageExp.SubdirOpt   = 1;                                        % Default is to ignore images in subdirectories
    Params.ImageExp.ImageConds  = {''};             
    Params.ImageExp.Preload     = 1;                                        % Pre-load images to GPU before experiment?
    Params.ImageExp.ImagesLoaded = 0;                                       % Images have not yet been loaded
    Params.ImageExp.UseAlpha    = 1;                                        % Use alpha transparency data (requires .png file type)
    Params.ImageExp.Greyscale   = 0;                                        % Convert images to greyscale?
    Params.ImageExp.Rotation    = 0;                                        % Rotate images?
    Params.ImageExp.Contrast    = 1;                                        % Contrast (proportion)
    Params.ImageExp.MaskTypes   = {'None','Circular','Cosine','Gaussian'};  %     
    Params.ImageExp.MaskType    = 1;
    Params.ImageExp.ColorTypes  = {'Original','Greyscale','Hue inverted'};  
    Params.ImageExp.ColorType   = 1;
    Params.ImageExp.Fullscreen  = 0;                                        % Show images at fullscreen size
    Params.ImageExp.SBS3D       = 0;      
    Params.ImageExp.SizeDeg     = [10, 10];                                 
    Params.ImageExp.KeepAspect  = 1;                                        % Maintain aspect ratio of original images?
    Params.ImageExp.PositionDeg = [0, 0];
    Params.ImageExp.FixOn       = 1;
    Params.ImageExp.FixTypes    = {'None','Dot','Square','Cross','Binocular'};
    Params.ImageExp.FixType     = 2;
    Params.ImageExp.DesignTypes = {'Neurophysiology (random)','fMRI (block design)','fMRI (event related)'};
    Params.ImageExp.DesignType  = 1;
    Params.ImageExp.StimPerTrial = 5;                                       % Number of stimulus presentations per trial
    Params.ImageExp.TrialsPerRun = 100;                                     % Number of trials per run
    Params.ImageExp.ITIms       = 2000;                                     % Inter-trial interval (ms)
    Params.ImageExp.DurationMs  = 300;
    Params.ImageExp.ISIms       = 300;
    Params.ImageExp.ISIjitter   = 200;                                      % Maximum temporal jitter (+/- ms) to change each ISI by
    Params.ImageExp.PosJitter   = 2;                                        % Maximum spatial jitter (+/- deg) to move stimulus from center each trial
    Params.ImageExp.ScaleJitter = 0;                                        % Maximum scaling jitter (+/- % original) to scale stimulus by on each trial
    Params.ImageExp.AddBckgrnd  = 0;                                        % Add an image or noise background?
    Params.ImageExp.BckgrndDir  = {};
    Params.ImageExp.FixWinDeg   = 2;                                        % Diameter of circular fixation window (degrees)
    Params.ImageExp.InitialFixDur = 500;                                    % Duration (ms) of fixation period before each trial
    
elseif Success > 1
    ParamsOut = Params;
	return;
end
if OpenGUI == 0
    ParamsOut = Params;
    return;
end
Params = RefreshImageList(Params);

%========================= OPEN GUI WINDOW ================================
Fig.Handle          = figure;                                       	% Open new figure window         
setappdata(0,GUItag,Fig.Handle);                                        % Assign tag
Fig.PanelYdim       = 130*Fig.DisplayScale;
Fig.Rect            = [0 200 500 900]*Fig.DisplayScale;              	% Specify figure window rectangle
set(Fig.Handle,     'Name','SCNI: Image Experiment settings',...    	% Open a figure window with specified title
                    'Tag','SCNI_ShowImagesSettings',...                 % Set figure tag
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
Fig.PanelNames      = {'Image selection','Image transforms','Image presentation'};
Fig.PannelHeights   = [220, 200, 260];
BoxPos{1}           = [Fig.Margin, Fig.Rect(4)-Fig.PannelHeights(1)*Fig.DisplayScale-Fig.Margin*2, Fig.Rect(3)-Fig.Margin*2, Fig.PannelHeights(1)*Fig.DisplayScale];   
for i = 2:numel(Fig.PanelNames)
    BoxPos{i}           = [Fig.Margin, BoxPos{i-1}(2)-Fig.PannelHeights(i)*Fig.DisplayScale-Fig.Margin/2, Fig.Rect(3)-Fig.Margin*2, Fig.PannelHeights(i)*Fig.DisplayScale];
end

Fig.UIimages.Labels         = {'Image directory', 'Background directory', 'Image format', 'Subdirectories', 'Conditions', 'Total images', 'Total memory (MB)', 'SBS 3D?','Pre-load images?'};
Fig.UIimages.Style          = {'Edit','Edit','Popup','Popup','Popup','Edit','Edit','checkbox','checkbox'};
Fig.UIimages.Defaults       = {Params.ImageExp.ImageDir, Params.ImageExp.BckgrndDir, Params.ImageExp.FileFormats, Params.ImageExp.SubdirOpts, Params.ImageExp.ImageConds, num2str(Params.ImageExp.TotalImages), num2str(Params.ImageExp.TotalMemory), [], []};
Fig.UIimages.Values         = {isempty(Params.ImageExp.ImageDir), isempty(Params.ImageExp.BckgrndDir), Params.ImageExp.FileFormat, Params.ImageExp.SubdirOpt, 1, [], [], Params.ImageExp.SBS3D, Params.ImageExp.Preload};
Fig.UIimages.Enabled        = [0, 0, 1, 1, 1, 0, 0, 1, 1];
Fig.UIimages.Tips           = {'Select directory to load images from','Select directory to load background images from','Select format of images to load',...
                                sprintf('Select how to treat subdirectories found within the image directory:\n1) IGNORE: load only images of selected format in image directory;\n2) LOAD: load images recursively from all subdirectories;\n3) CONDITIONS: treat each subdirectory as a condition name, and remember which directory each image came from.'),...
                                'Displays conditions (subdirectory names) found within the image directory (read-only)', 'Displays the total number of image files located of the selected type within the specified directories (read-only)', 'Dipslays the total memory required (MB) to load selected image files','Select whether images are in side-by-side stereoscopic 3D format', 'Pre-load images into GPU before starting experiment?'};
Fig.UIimages.Ypos           = [(Fig.PannelHeights(1)-50):-20:10]*Fig.DisplayScale;
Fig.UIimages.Xwidth         = [180, 200]*Fig.DisplayScale;

Fig.UItransform.Labels      = {'Present fullscreen','Retinal subtense (deg)','Use alpha channel?','Mask type','Present in greyscale','Image rotation (deg)','Image contrast (%)'};
Fig.UItransform.Style       = {'checkbox','Edit','checkbox','Popup','checkbox','Edit','Edit'};
Fig.UItransform.Defaults    = {[], Params.ImageExp.SizeDeg(1), [], Params.ImageExp.MaskTypes, [], Params.ImageExp.Rotation, Params.ImageExp.Contrast};
Fig.UItransform.Values     	= {Params.ImageExp.Fullscreen, [], Params.ImageExp.UseAlpha, Params.ImageExp.MaskType, Params.ImageExp.Greyscale, [], []};
Fig.UItransform.Enabled     = [1, ~Params.ImageExp.Fullscreen, 1, 1, 1,1,1,1];
Fig.UItransform.Ypos      	= [(Fig.PannelHeights(2)-50):-20:10]*Fig.DisplayScale;
Fig.UItransform.Xwidth     	= [180, 200]*Fig.DisplayScale;

Fig.UIpresent.Labels        = {'Experimental design','Trials per run','Stim. per trial','Stimulus duration (ms)', 'Inter-stim interval (ms)', 'Temporal jitter (max ms)', 'Inter-trial interval (ms)','Fixation marker', 'Spatial jitter (max deg)', 'Scale jitter (max %)','Fixation window (deg)'};
Fig.UIpresent.Style        	= {'Popup', 'Edit','Edit','Edit','Edit','Edit','Edit','popup','Edit','Edit','Edit'};
Fig.UIpresent.Defaults     	= {Params.ImageExp.DesignTypes, Params.ImageExp.TrialsPerRun, Params.ImageExp.StimPerTrial, Params.ImageExp.DurationMs, Params.ImageExp.ISIms, Params.ImageExp.ISIjitter, Params.ImageExp.ITIms, Params.ImageExp.FixTypes, Params.ImageExp.PosJitter, Params.ImageExp.ScaleJitter, Params.ImageExp.FixWinDeg};
Fig.UIpresent.Values        = {Params.ImageExp.DesignType,[],[],[],[],[],[],Params.ImageExp.FixType,[],[],[]};
Fig.UIpresent.Enabled       = [1,1,1,1,1,1,1,1,1,1,1];
Fig.UIpresent.Ypos          = [(Fig.PannelHeights(3)-50):-20:10]*Fig.DisplayScale;
Fig.UIpresent.Xwidth        = [180, 200]*Fig.DisplayScale;

Fig.PanelVars(1).Fieldnames = {'', '', 'FileFormat', 'SubdirOpt', '', '', '','SBS3D','Preload'};
Fig.PanelVars(2).Fieldnames = {'Fullscreen','SizeDeg','UseAlpha','MaskType','Greyscale','Rotation','Contrast'};
Fig.PanelVars(3).Fieldnames = {'DesignType','TrialsPerRun','StimPerTrial','DurationMs','ISIms','ISIjitter','ITIms','FixType','PosJitter','ScaleJitter','FixWinDeg'};

Fig.OffOn           = {'Off','On'};
PanelStructs        = {Fig.UIimages, Fig.UItransform, Fig.UIpresent};

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
            'TooltipString', 'Continue to run SCNI_ShowImages.m',...
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
                Params.ImageExp.ImagesLoaded = 1;
                
            case 2  %============ Save parameters to file
                ImageExp = Params.ImageExp;
                save(Params.File, 'ImageExp', '-append');
                
            case 3  %============ Run experiment
                if Params.ImageExp.Preload == 1 && Params.ImageExp.ImagesLoaded == 0
                    Params = LoadImages([], Params);
                    Params.ImageExp.ImagesLoaded = 1;
                end
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
        
     	%============= Generate alpha mask
        if Params.ImageExp.MaskType > 1
            Mask.Dim        = repmat(Params.ImageExp.SizeDeg,[1,2])*Params.Display.PixPerDeg(1);% Dimensions [w, h] (pixels)
            Mask.ApRadius   = (Params.ImageExp.SizeDeg-0.1)/2*Params.Display.PixPerDeg(1);      % radius of central aperture (pixels)
            Mask.Color      = Params.Display.Exp.BackgroundColor*255;                          	% RGB 0-255
            Mask.s          = 1;                                                                % Standard deviation of Gaussian edge (if selcted) in degrees
            Mask.Taper      = 0.2;                                                              % Spread of cosine edge as a proportion of aperture radius
            ReturnMaskTex   = 1;                                                                % 0 = return mask as an image; 1 = return mask as a PTB texture handle
            switch Params.ImageExp.MaskTypes{Params.ImageExp.MaskType}
                case 'Circular'
                    Mask.Edge = 0;          % 0 = hard edge;  
                case 'Gaussian'
                    Mask.Edge = 1;          % 1 = gaussian edge;  
                case 'Cosine'
                    Mask.Edge = 2;          % 2 = cosine edge;  
            end
            Params.ImageExp.MaskTex = SCNI_GenerateAlphaMask(Mask, Params.Display, ReturnMaskTex);
        end
        
        %============= Load stimuli
        for Cond = 1:numel(Params.ImageExp.ImageConds)                                                                                  	% For each experimental condition...

            for Stim = 1:numel(Params.ImageExp.ImByCond{Cond})                                                                             % For each file...
                
                %============= Update experimenter display
                message = sprintf('Loading image %d of %d (Condition %d/ %d: %s)...\n',Stim, numel(Params.ImageExp.ImByCond{Cond}), Cond, numel(Params.ImageExp.ImageConds), Params.ImageExp.ImageConds{Cond});
                Screen('FillRect', Params.Display.win, Params.Display.Exp.BackgroundColor);                                             	% Clear background
                DrawFormattedText(Params.Display.win, message, LoadTextPos(1), LoadTextPos(2), TextColor);
                Screen('Flip', Params.Display.win, [], 0);                                                                                	% Draw to experimenter display
            
                waitbar(StimCount/Params.ImageExp.TotalImages, wbh, message);                                                               % Update waitbar
                [keyIsDown, secs, keyCode, deltaSecs] = KbCheck();                                                                          % Check if escape key is pressed
                if keyIsDown && keyCode(KbName('Escape'))                                                                                   % If so...
                    break;                                                                                                                  % Break out of loop
                end

                %============= Load next file
                img = imread(Params.ImageExp.ImByCond{Cond}{Stim});                                                                         % Load image file
                if Params.ImageExp.UseAlpha == 1
                    [~,~, imalpha] = imread(Params.ImageExp.ImByCond{Cond}{Stim});                                                          % Read alpha channel
                    if ~isempty(imalpha)                                                                                                 	% If image file contains transparency data...
                        img(:,:,4) = imalpha;                                                                                           	% Combine into a single RGBA image matrix
                    else
                        img(:,:,4) = ones(size(img,1),size(img,2))*255;
                    end
                end
                
                %============= Scale image
                if Params.ImageExp.Fullscreen == 0
                    if size(img,2) == size(img,1)
                        Params.ImageExp.SizePix     = Params.ImageExp.SizeDeg.*Params.Display.PixPerDeg;                                        % Convert requested image size from degrees to pixels
                    else
                        Scale                       = [1, size(img,2)/size(img,1)];
                        Params.ImageExp.SizePix     = Params.ImageExp.SizeDeg.*Params.Display.PixPerDeg.*Scale;
                    end
                elseif Params.ImageExp.Fullscreen == 1
                    Params.ImageExp.SizePix     = [size(img,2), size(img,1)]; 
                end
                
                %============= Convert to greyscale
                if Params.ImageExp.Greyscale == 1                                                                                           % If greyscale was selected...
                    img(:,:,1:3) = repmat(rgb2gray(img(:,:,1:3)),[1,1,3]);                                                                  % Convert RGB(A) image to grayscale
                end
                
                %============= Add background image
                if Params.ImageExp.UseAlpha == 1 && ~isempty(imalpha) && ~isempty(Params.ImageExp.BckgrndDir)                                                                % If image contains transparent pixels...         
                    Background = imread(Params.ImageExp.BackgroundFiles{Cond}{Stim});                                                       % Read in background images (e.g. phase scrambled version of stimuli)
                    Background = imresize(Background, Params.ImageExp.SizePix);                                                             % Resize background image
                    if Params.ImageExp.Greyscale == 1 
                        Background = repmat(rgb2gray(Background),[1,1,3]);
                    end
                    Background(:,:,4) = ones(size(Background(:,:,1)))*255;
                    Params.ImageExp.BckgrndTex{Cond}(Stim) = Screen('MakeTexture', Params.Display.win, Background);                                    	% Create a PTB offscreen texture for the background
                else
                    Params.ImageExp.BckgrndTex = [];
                end
                
                Params.ImageExp.ImgTex{Cond}(Stim) = Screen('MakeTexture', Params.Display.win, img);                                                       % Create a PTB offscreen texture for the stimulus
                StimCount = StimCount+1;
            end

        end

        delete(wbh);                                                                                                                      	% Close the waitbar figure window
        Screen('FillRect', Params.Display.win, Params.Display.Exp.BackgroundColor);                                                                        % Clear background
        DrawFormattedText(Params.Display.win, sprintf('All %d stimuli loaded!\n\nClick the ''Run'' button in the SCNI Toolbar to start the experiment.', Params.ImageExp.TotalImages),  LoadTextPos(1), LoadTextPos(2), TextColor);
        Screen('Flip', Params.Display.win);
        
    end


    %=============== Update parameters
    function UpdateParams(hObj, Evnt, Indx1, Indx2)

        %============= Panel 1 controls for directory selection
        if Indx1 == 1 && Indx2 == 1         %===== Change image directory
                    ImageDir	= uigetdir('/projects/','Select stimulus directory');
                    if ImageDir == 0
                        return;
                    end
                    Params.ImageExp.ImageDir = ImageDir;
                    set(Fig.UIhandle(1,1),'string',Params.ImageExp.ImageDir);

        elseif Indx1 == 1 && Indx2 == 2      %===== Change background image directory
                    BckgrndDir	= uigetdir('/projects/','Select background image directory');
                    if BckgrndDir == 0
                        return;
                    end
                    Params.ImageExp.BckgrndDir = BckgrndDir;
                    set(Fig.UIhandle(1,2),'string',Params.ImageExp.BckgrndDir);
                    
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
                eval(sprintf('Params.ImageExp.%s = %d;', Fig.PanelVars(Indx1).Fieldnames{Indx2}, NewValue));
            end
        end
        if Indx1 == 1 && Indx2 <= 4                     % If first 4 controls were updated...
            Params = RefreshImageList(Params);          % Refresh list of images
        end
        if Indx1 == 2 && Indx2 == 1
            set(Fig.UIhandle(2,2), 'enable', Fig.OffOn{1 + ~NewValue});
        end


    end

    %====================== Refresh the list(s) of images =================
    function Params = RefreshImageList(Params)

        switch Params.ImageExp.SubdirOpts{Params.ImageExp.SubdirOpt}
            case 'Load'
                Params.ImageExp.AllImFiles 	= wildcardsearch(Params.ImageExp.ImageDir, ['*',Params.ImageExp.FileFormats{Params.ImageExp.FileFormat}]);
             	if numel(Params.ImageExp.AllImFiles) > 1 && isempty(Params.ImageExp.AllImFiles{1})
                    Params.ImageExp.AllImFiles = Params.ImageExp.AllImFiles(2:end);
                end
                Params.ImageExp.ImageConds  = {''};
                Params.ImageExp.ImByCond    = {Params.ImageExp.AllImFiles};
                
            case 'Ignore'
                Params.ImageExp.AllImFiles 	= regexpdir(Params.ImageExp.ImageDir, Params.ImageExp.FileFormats{Params.ImageExp.FileFormat},0);
             	if numel(Params.ImageExp.AllImFiles) > 1 && isempty(Params.ImageExp.AllImFiles{1})
                    Params.ImageExp.AllImFiles = Params.ImageExp.AllImFiles(2:end);
                end
                Params.ImageExp.ImageConds  = {''};
                Params.ImageExp.ImByCond    = {Params.ImageExp.AllImFiles};
                
            case 'Conditions'
                SubDirs                     = dir(Params.ImageExp.ImageDir);
                Params.ImageExp.ImageConds  = {SubDirs([SubDirs.isdir]).name};
                Params.ImageExp.ImageConds(~cellfun(@isempty, strfind(Params.ImageExp.ImageConds, '.'))) = [];
                Params.ImageExp.AllImFiles 	= [];
                for cond = 1:numel(Params.ImageExp.ImageConds)
                    Params.ImageExp.ImByCond{cond} 	= regexpdir(fullfile(Params.ImageExp.ImageDir, Params.ImageExp.ImageConds{cond}), Params.ImageExp.FileFormats{Params.ImageExp.FileFormat},0);
                    Params.ImageExp.ImByCond{cond}(cellfun(@isempty, Params.ImageExp.ImByCond{cond})) = [];
                    Params.ImageExp.AllImFiles      = [Params.ImageExp.AllImFiles; Params.ImageExp.ImByCond{cond}];
                end
        end
        Params.ImageExp.TotalImages     = numel(Params.ImageExp.AllImFiles);

        
        %========== Find background images
        if ~isempty(Params.ImageExp.BckgrndDir)   
            switch Params.ImageExp.SubdirOpts{Params.ImageExp.SubdirOpt}
                case 'Load'
                    Params.ImageExp.BckgrndFiles 	= wildcardsearch(Params.ImageExp.BckgrndDir, ['*',Params.ImageExp.FileFormats{Params.ImageExp.FileFormat}]);
                case 'Ignore'
                    Params.ImageExp.BckgrndFiles 	= regexpdir(Params.ImageExp.BckgrndDir, Params.ImageExp.FileFormats{Params.ImageExp.FileFormat},0);
                case 'Conditions'
                    for cond = 1:numel(Params.ImageExp.ImageConds)
                        Params.ImageExp.BckgrndFilesByCond{Cond} = regexpdir(fullfile(Params.ImageExp.BckgrndDir, Params.ImageExp.ImageConds{cond}), Params.ImageExp.FileFormats{Params.ImageExp.FileFormat},0);
                        
                    end
            end
        end
        
        %========== Calculate GPU memory required for pre-loading
        Params.ImageExp.AllImFiles = Params.ImageExp.AllImFiles(~cellfun(@isempty, Params.ImageExp.AllImFiles));
        if ~isempty(Params.ImageExp.AllImFiles)
            for n = 1:numel(Params.ImageExp.AllImFiles)
                temp            = dir(Params.ImageExp.AllImFiles{n});
                MemoryTally(n)  = temp.bytes/10^6;
            end
            Params.ImageExp.TotalMemory = sum(MemoryTally);
        else
            Params.ImageExp.TotalMemory = 0;
        end
        
        %========== Update GUI
        if isfield(Fig, 'UIimages')
            ButtonIndx = find(~cellfun(@isempty, strfind(Fig.UIimages.Labels, 'Conditions')));
            if ~isempty(Params.ImageExp.ImageConds)
                set(Fig.UIhandle(1,ButtonIndx), 'string', Params.ImageExp.ImageConds, 'enable', 'on');
            else
                set(Fig.UIhandle(1,ButtonIndx), 'string', {''}, 'enable', 'off');
            end
            StrIndx = find(~cellfun(@isempty, strfind(Fig.UIimages.Labels, 'Total images')));
            set(Fig.UIhandle(1,StrIndx), 'string', num2str(Params.ImageExp.TotalImages));
            StrIndx = find(~cellfun(@isempty, strfind(Fig.UIimages.Labels, 'Total memory (MB)')));
            set(Fig.UIhandle(1,StrIndx), 'string', sprintf('%.2f', Params.ImageExp.TotalMemory));
            
        end
    end
end
