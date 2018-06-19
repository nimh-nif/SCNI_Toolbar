%======================== SCNI_ImageExpSettings.m =========================
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

function ParamsOut = SCNI_ImageExpSettings(ParamsFile, OpenGUI)

persistent Params Fig;

%============ Initialize GUI
GUItag      = 'SCNI_ImageExpSettings';                  % String to use as GUI window tag
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
    Params.ImageExp.ImageDir	= uigetdir('/projectsmurphya/Stimuli');     % Get full path of directory containing stimulus images
    Params.ImageExp.NoCond      = 1;                                        % How many conditions are there?
    Params.ImageExp.FileFormat  = '.png';                                   % What file format are the images?
    Params.ImageExp.Preload     = 1;                                        % Pre-load images to GPU before experiment?
    Params.ImageExp.UseAlpha    = 1;                                        % Use alpha transparency data (requires .png file type)
    Params.ImageExp.Greyscale   = 0;                                        % Convert images to greyscale?
    Params.ImageExp.Rotation    = 0;                                        % Rotate images?
    Params.ImageExp.Mask        = 1;                                        % Apply image mask?
    Params.ImageExp.MaskType    = {'None','Circular','Gaussian'};           
    Params.ImageExp.Fullscreen  = 0;                                        % Show images at fullscreen size
    Params.ImageExp.SBS3D       = 0;      
    Params.ImageExp.SizeDeg     = [10, 10];                                 
    Params.ImageExp.SizePix     = Params.ImageExp.SizeDeg.*Params.Display.PixPerDeg;
    Params.ImageExp.KeepAspect  = 1;                                        % Maintain aspect ratio of original images?
    Params.ImageExp.PositionDeg = [0, 0];
    Params.ImageExp.DurationMs  = 300;
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


%========================= OPEN GUI WINDOW ================================
Fig.Handle          = figure;                                       	% Open new figure window         
setappdata(0,GUItag,Fig.Handle);                                        % Assign tag
Fig.PanelYdim       = 130*Fig.DisplayScale;
Fig.Rect            = [0 200 500 900]*Fig.DisplayScale;              	% Specify figure window rectangle
set(Fig.Handle,     'Name','SCNI: Image Experiment settings',...    	% Open a figure window with specified title
                    'Tag','SCNI_ImageExpSettings',...                 	% Set figure tag
                    'Renderer','OpenGL',...                             % Use OpenGL renderer
                    'OuterPosition', Fig.Rect,...                       % position figure window
                    'NumberTitle','off',...                             % Remove figure number from title
                    'Resize', 'off',...                                 % Prevent resizing of GUI window
                    'Menu','none',...                                   % Turn off memu
                    'Toolbar','none');                                  % Turn off toolbars to save space
Fig.Background  = get(Fig.Handle, 'Color');                           	% Get default figure background color
Fig.Margin      = 20*Fig.DisplayScale;                               	% Set margin between UI panels (pixels)                                 
Fig.Fields      = fieldnames(Params);                                 	% Get parameter field names










%% ==================== SUBFUNCTIONS

    function LoadImages(win)
        LoadTextPos = Params.Display.Rect(3)/2;
        TextColor   = [1,1,1];
        wbh         = waitbar(0, '');                                                                                                       % Open a waitbar figure
        TotalStim   = 0;                                                                                                                    % Begin total stimulus tally
        for Cond = 1:Params.ImageExp.NoCond                                                                                                 % For each experimental condition...

            Params.ImageExp.StimFiles{Cond} = dir(fullfile(c.StimDir{Cond},['*', Params.ImageExp.FileFormat]));                             % Find all files of specified format in condition directory
            if Params.ImageExp.AddBckgrnd == 1 && ~isempty(Params.ImageExp.BckgrndDir{Cond})                                         
                Params.ImageExp.BackgroundFiles{Cond} = dir([Params.ImageExp.BckgrndDir{Cond},'/*', Params.ImageExp.FileFormat]);           % Find all corresponding background files
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

end
