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
    Params.ImageExp.SizePix     = Params.ImageExp.SizeDeg.*Params.Display.PixPerDeg;
    Params.ImageExp.KeepAspect  = 1;                                        % Maintain aspect ratio of original images?
    Params.ImageExp.PositionDeg = [0, 0];
    Params.ImageExp.FixOn       = 1;
    Params.ImageExp.FixTypes    = {'None','Dot','Square','Cross','Binocular'};
    Params.ImageExp.FixType     = 2;
    Params.ImageExp.StimPerTrial = 5;                                       % Number of stimulus presentations per trial
    Params.ImageExp.ITIms       = 2000;                                     % Inter-trial interval (ms)
    Params.ImageExp.DurationMs  = 300;
    Params.ImageExp.ISIMs       = 300;
    Params.ImageExp.ISIjitter   = 200;                                      % Maximum temporal jitter (+/- ms) to change each ISI by
    Params.ImageExp.PosJitter   = 2;                                        % Maximum spatial jitter (+/- deg) to move stimulus from center each trial
    Params.ImageExp.ScaleJitter = 0;                                        % Maximum scaling jitter (+/- % original) to scale stimulus by on each trial
    Params.ImageExp.AddBckgrnd  = 0;                                        % Add an image or noise background?
    Params.ImageExp.BckgrndDir  = {};
    
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
Fig.PannelHeights   = [200, 220, 200];
BoxPos{1}           = [Fig.Margin, Fig.Rect(4)-Fig.PannelHeights(1)*Fig.DisplayScale-Fig.Margin*2, Fig.Rect(3)-Fig.Margin*2, Fig.PannelHeights(1)*Fig.DisplayScale];   
for i = 2:numel(Fig.PanelNames)
    BoxPos{i}           = [Fig.Margin, BoxPos{i-1}(2)-Fig.PannelHeights(i)*Fig.DisplayScale-Fig.Margin/2, Fig.Rect(3)-Fig.Margin*2, Fig.PannelHeights(i)*Fig.DisplayScale];
end

Fig.UIimages.Labels         = {'Image directory', 'Background directory', 'Image format', 'Subdirectories', 'Conditions', 'Total images', 'SBS 3D?','Pre-load images?'};
Fig.UIimages.Style          = {'Edit','Edit','Popup','Popup','Popup','Edit','checkbox','checkbox'};
Fig.UIimages.Defaults       = {Params.ImageExp.ImageDir, Params.ImageExp.BckgrndDir, Params.ImageExp.FileFormats, Params.ImageExp.SubdirOpts, Params.ImageExp.ImageConds, num2str(Params.ImageExp.TotalImages), [], []};
Fig.UIimages.Values         = {isempty(Params.ImageExp.ImageDir), isempty(Params.ImageExp.BckgrndDir), Params.ImageExp.FileFormat, Params.ImageExp.SubdirOpt, 1, [], Params.ImageExp.SBS3D, Params.ImageExp.Preload};
Fig.UIimages.Enabled        = [0, 0, 1, 1, 1, 1, 1, 1];
Fig.UIimages.Ypos           = [(Fig.PannelHeights(1)-50):-20:10]*Fig.DisplayScale;
Fig.UIimages.Xwidth         = [180, 200]*Fig.DisplayScale;

Fig.UItransform.Labels      = {'Scale image','Present fullscreen','Retinal subtense (deg)','Use alpha channel?','Mask type','Present in greyscale','Image rotation (deg)','Image contrast (%)'};
Fig.UItransform.Style       = {'checkbox','checkbox','Edit','checkbox','Popup','checkbox','Edit','Edit'};
Fig.UItransform.Defaults    = {[], [], Params.ImageExp.SizeDeg(1), [], Params.ImageExp.MaskTypes, [], Params.ImageExp.Rotation, Params.ImageExp.Contrast};
Fig.UItransform.Values     	= {~Params.ImageExp.Fullscreen, Params.ImageExp.Fullscreen, [], Params.ImageExp.UseAlpha, Params.ImageExp.MaskType, Params.ImageExp.Greyscale, [], []};
Fig.UItransform.Enabled     = [1, 1, ~Params.ImageExp.Fullscreen, 1, 1, 1,1,1,1];
Fig.UItransform.Ypos      	= [(Fig.PannelHeights(2)-50):-20:10]*Fig.DisplayScale;
Fig.UItransform.Xwidth     	= [180, 200]*Fig.DisplayScale;

Fig.UIpresent.Labels        = {'Stim. per trial','Stimulus duration (ms)', 'Inter-stim interval (ms)', 'Temporal jitter (max ms)', 'Inter-trial interval (ms)','Fixation marker', 'Spatial jitter (max deg)', 'Scale jitter (max %)'};
Fig.UIpresent.Style        	= {'Edit','Edit','Edit','Edit','Edit','popup','Edit','Edit'};
Fig.UIpresent.Defaults     	= {Params.ImageExp.StimPerTrial, Params.ImageExp.DurationMs, Params.ImageExp.ISIMs, Params.ImageExp.ISIjitter, Params.ImageExp.ITIms, Params.ImageExp.FixTypes, Params.ImageExp.PosJitter, Params.ImageExp.ScaleJitter};
Fig.UIpresent.Values        = {[],[],[],[],[],Params.ImageExp.FixType,[],[]};
Fig.UIpresent.Enabled       = [1,1,1,1,1,1,1,1];
Fig.UIpresent.Ypos          = [(Fig.PannelHeights(3)-50):-20:10]*Fig.DisplayScale;
Fig.UIpresent.Xwidth        = [180, 200]*Fig.DisplayScale;

OfforOn         = {'Off','On'};
PanelStructs    = {Fig.UIimages, Fig.UItransform, Fig.UIpresent};

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
                    'Enable', OfforOn{PanelStructs{p}.Enabled(n)+1},...
                    'Position', [Fig.Margin + PanelStructs{p}.Xwidth(1), PanelStructs{p}.Ypos(n), PanelStructs{p}.Xwidth(2), 20*Fig.DisplayScale],...
                    'Parent', Fig.PannelHandl(p),...
                    'HorizontalAlignment', 'left',...
                    'FontSize', Fig.FontSize,...
                    'Callback', {@UpdateParams, p, n});
        if p == 1 && n < 3
            uicontrol(  'Style', 'pushbutton',...
                        'string','...',...
                        'Parent', Fig.PannelHandl(p),...
                        'Position', [Fig.Margin + 20+ sum(PanelStructs{p}.Xwidth([1,2])), PanelStructs{p}.Ypos(n), 20*Fig.DisplayScale, 20*Fig.DisplayScale],...
                        'Callback', {@UpdateParams, p, n});
        end


    end
end




%% =========================== SUBFUNCTIONS ===============================

    function LoadImages(win)
        LoadTextPos = Params.Display.Rect(3)/2;
        TextColor   = [1,1,1];
        wbh         = waitbar(0, '');                                                                                                       % Open a waitbar figure
        TotalStim   = 0;                                                                                                                    % Begin total stimulus tally
        for Cond = 1:Params.ImageExp.NoCond                                                                                                 % For each experimental condition...

            Params.ImageExp.StimFiles{Cond} = dir(fullfile(c.StimDir{Cond},['*', Params.ImageExp.FileFormats{Params.ImageExp.FileFormat}]));                  	% Find all files of specified format in condition directory
            if Params.ImageExp.AddBckgrnd == 1 && ~isempty(Params.ImageExp.BckgrndDir{Cond})                                         
                Params.ImageExp.BackgroundFiles{Cond} = dir([Params.ImageExp.BckgrndDir{Cond},'/*', Params.ImageExp.FileFormats{Params.ImageExp.FileFormat}]); 	% Find all corresponding background files
            end
            TotalStim = TotalStim+numel(Params.ImageExp.StimFiles{Cond});
            for Stim = 1:numel(Params.ImageExp.StimFiles{Cond})                                                                             % For each file...
                
                %============= Update experimenter display
                message = sprintf('Loading image %d of %d (Condition %d/ %d)...\n',Stim,numel(Params.ImageExp.StimFiles{Cond}),Cond,Params.ImageExp.NoCond);
%                 Screen('SelectStereoDrawBuffer', win, c.ExperimenterBuffer);
                Screen('FillRect', win, Params.Display.Exp.BackgroundColor);                                                                % Clear background
                DrawFormattedText(win, message,  LoadTextPos, 80, TextColor);
                Screen('Flip', win, [], 0);                                                                                                 % Draw to experimenter display
            
                waitbar(Stim/numel(Params.ImageExp.StimFiles{Cond}), wbh, message);                                                         % Update waitbar
                [keyIsDown, secs, keyCode, deltaSecs] = KbCheck();                                                                          % Check if escape key is pressed
                if keyIsDown && keyCode(KbName(c.Exit_Key))                                                                                 % If so...
                    break;                                                                                                                  % Break out of loop
                end

                %============= Load next file
                img = imread(fullfile(Params.ImageExp.StimDir{Cond}, Params.ImageExp.StimFiles{Cond}(Stim).name));                          % Load image file
                [~,~, imalpha] = imread(fullfile(Params.ImageExp.StimDir{Cond}, Params.ImageExp.StimFiles{Cond}(Stim).name));               % Read alpha channel
                if ~isempty(imalpha)                                                                                                        % If image file contains transparency data...
                    img(:,:,4) = imalpha;                                                                                                   % Combine into a single RGBA image matrix
                else
                    img(:,:,4) = ones(size(img,1),size(img,2))*255;
                end
                if [size(img,2), size(img,1)] ~= Params.ImageExp.SizePix                                                                    % If X and Y dimensions of image don't match requested...
                    img = imresize(img, Params.ImageExp.SizePix([2,1]));                                                                    % Resize image
                end
                if Params.ImageExp.Greyscale == 1                                                                                           % If greyscale was selected...
                    img(:,:,1:3) = repmat(rgb2gray(img(:,:,1:3)),[1,1,3]);                                                                  % Convert RGB(A) image to grayscale
                end
                if ~isempty(imalpha) && Params.ImageExp.AddBckgrnd == 1 && ~isempty(Params.ImageExp.BckgrndDir{Cond})                       % If image contains transparent pixels...         
                    Background = imread(fullfile(Params.ImageExp.BckgrndDir{Cond}, Params.ImageExp.BackgroundFiles{Cond}(Stim).name));      % Read in phase scrambled version of stimulus
                    Background = imresize(Background, Params.ImageExp.SizePix);                                                             % Resize background image
                    if Params.ImageExp.Greyscale == 1 
                        Background = repmat(rgb2gray(Background),[1,1,3]);
                    end
                    Background(:,:,4) = ones(size(Background(:,:,1)))*255;
                    Params.ImageExp.BlockBKGs{Cond}(Stim) = Screen('MakeTexture', win, Background);                                         % Create a PTB offscreen texture for the background
                else
                    Params.ImageExp.BlockBKGs{Cond}(Stim) = 0;
                end
                Params.ImageExp.ImgTex{Cond}(Stim) = Screen('MakeTexture', win, img);                                                       % Create a PTB offscreen texture for the stimulus
            end

        end
        delete(wbh);                                                                                                                      	% Close the waitbar figure window
        Screen('FillRect', win, Params.Display.Exp.BackgroundColor);                                                                        % Clear background
        DrawFormattedText(win, sprintf('All %d stimuli loaded!\n\nClick ''Run'' to start experiment.', TotalStim),  LoadTextPos, 80, TextColor);
        Screen('Flip', win);
        
    end


    %=============== Update parameters
    function UpdateParams(hObj, Evnt, Indx1, Indx2)

        switch Indx1    %============= Panel 1 controls
            case 1
                switch Indx2
                    case 1      %===== Change image directory
                        Params.ImageExp.ImageDir	= uigetdir('/projects/','Select stimulus directory');
                        set(Fig.UIhandle(1,1),'string',Params.ImageExp.ImageDir);
                        Params = RefreshImageList(Params);
                        
                    case 2      %===== Change background image directory
                        Params.ImageExp.BckgrndDir	= uigetdir('/projects/','Select background image directory');
                        set(Fig.UIhandle(1,2),'string',Params.ImageExp.BckgrndDir);
                        
                    case 3      %===== Change image file format
                        Params.ImageExp.FileFormat  = get(hObj, 'value');
                        Params = RefreshImageList(Params);
                        
                    case 4      %===== Change subdirectory use
                        Params.ImageExp.SubdirOpt = get(hObj, 'value');
                        Params = RefreshImageList(Params);
                        
                    case 5
                        
                    case 6
                        
                    case 7      %===== Change 3D format
                        Params.ImageExp.SBS3D = get(hObj, 'value');
                        
                    case 8      %===== Pre-load images?
                        
                end
                
            case 2      %============= Panel 2 controls
                switch Indx2
                    case 1      %===== Toggle image scaling

                        
                    case 2      %===== Toggle fullscreen
                        Params.ImageExp.Fullscreen = get(hObj, 'value');
                        
                    case 3
                        
                    case 4
                        
                    case 5
                        
                    case 6
                        
                    case 7
                        
                    case 8
                        
                end
                
            case 3      %============= Panel 3 controls
            	switch Indx2
                    case 1      %===== Toggle image scaling

                        
                    case 2      %===== Toggle fullscreen  
                        
                    case 3
                        
                    case 4
                        
                    case 5
                        
                    case 6
                        
                    case 7
                        
                    case 8
                end
        end

    end

    %====================== Refresh the list(s) of images =================
    function Params = RefreshImageList(Params)
        
        switch Params.ImageExp.SubdirOpts{Params.ImageExp.SubdirOpt}
            case 'Load'
                Params.ImageExp.AllImFiles 	= wildcardsearch(Params.ImageExp.ImageDir, ['*',Params.ImageExp.FileFormats{Params.ImageExp.FileFormat}]);
                Params.ImageExp.ImageConds  = {''};
                
            case 'Ignore'
                Params.ImageExp.AllImFiles 	= regexpdir(Params.ImageExp.ImageDir, Params.ImageExp.FileFormats{Params.ImageExp.FileFormat},0);
                Params.ImageExp.ImageConds  = {''};
                
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
        end
    end
end
