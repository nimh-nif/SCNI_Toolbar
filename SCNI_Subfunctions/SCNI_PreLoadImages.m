function [c] = SCNI_PreLoadImages(c)

%========================= SCNI_PreLoadImages.m ============================
% This function pre-loads image files from the specified directories into 
% PTB textures on the GPU, ready for visual presentation. The maximum
% number of stimuli that can be pre-loaded will depend on the size of the
% images and the amount of VRAM on your GPU. 
%
% USAGE:
% You should add code in your initialization file to avoid having to re-load
% the same images multiple times, as follows:
%
%   c.StimFiles = {'Icons'};
%   if ~isfield(c, 'StimHandle') || ~ishandle(c.StimHandle{1})
%       c = SCNI_PreLoadImages(c);
%   end
%
% INPUT FIELDS:
% (Required)
%   c.window:     handle to open PTB window that stimuli will be presented in
%   c.StimFiles:  cell array of directory name(s) to load stimuli from (one per condition)
%   c.ImgSize:    dimensions to resize loaded images to ([X,Y], pixels)
%
% (Optional)
%   c.Stim_AddBckgrnd:  flag
%   c.BckgrndDir:       cell array of directory name(s) to load stimulus backgrounds from (for .png files)
%   c.
%
% HISTORY:
%   2017 - Written by APM
%==========================================================================

if ~isfield(c,'window') || ~ishandle(c.window)
    error('Input structure ''c'', fieldname ''window'', must contain the handle to an open PTB window!');
end

PrintToDisplay  = 1;
wbh             = waitbar(0, '');                                                       % Open a waitbar figure
TotalStim       = 0;                                                                    % Begin total stimulus tally
for Cond = 1:numel(c.StimFiles)                                                               % For each experimental condition...

    if PrintToDisplay == 1
        currentbuffer = Screen('SelectStereoDrawBuffer', c.window, c.ExperimenterBuffer);
        Screen('FillRect', c.window, c.Col_bckgrndRGB);                             % Clear background
        DrawFormattedText(c.window, sprintf('Loading stimuli for condition %d/%d...', Cond, numel(c.StimFiles)), 'center', 80, c.TextColor);
        Screen('Flip', c.window, [], 0);                                            % Draw to experimenter display
    end
    c.StimFiles{Cond} = dir([c.StimDir{Cond},'/*', c.FileFormat]);              	% Find all files of specified format in condition directory
    if c.Stim_AddBckgrnd == 1 && ~isempty(c.BckgrndDir{Cond})                                         
        c.BackgroundFiles{Cond} = dir([c.BckgrndDir{Cond},'/*', c.FileFormat]);     % Find all corresponding background files
    end
    TotalStim = TotalStim+numel(c.StimFiles{Cond});
    for Stim = 1:numel(c.StimFiles{Cond})                                           % For each file...

        %============= Update experimenter display
        message = sprintf('Loading image %d of %d (Condition %d/ %d)...\n',Stim,numel(c.StimFiles{Cond}),Cond,numel(c.StimFiles));
        waitbar(Stim/numel(c.StimFiles{Cond}), wbh, message);                       % Update waitbar
        [keyIsDown, secs, keyCode, deltaSecs] = KbCheck();                          % Check if escape key is pressed
        if keyIsDown && keyCode(c.Key_Exit)                                         % If so...
            break;                                                                  % Break out of loop
        end

        %============= Load next image file
        img = imread(fullfile(c.StimDir{Cond}, c.StimFiles{Cond}(Stim).name));        	% Load image file
        img = imresize(img, c.ImgSize);                                                 % Resize image
        [a,b, imalpha] = imread(fullfile(c.StimDir{Cond}, c.StimFiles{Cond}(Stim).name));  % Read alpha channel
        if ~isempty(imalpha)                                                            % If image file contains transparency data...
            imalpha = imresize(imalpha, c.ImgSize);                                     % Resize alpha channel
            img(:,:,4) = imalpha;                                                       % Combine into a single RGBA image matrix
        else
            img(:,:,4) = ones(size(img,1),size(img,2))*255;
        end
        if c.Stim_Color == 0                                                         	% If color was set to zero...
            img(:,:,1:3) = repmat(rgb2gray(img(:,:,1:3)),[1,1,3]);                      % Convert RGB(A) image to grayscale
        end
        c.StimHandle{Cond}(Stim) = Screen('MakeTexture', c.window, img);               	% Create a PTB offscreen texture for the stimulus
        
        %================ Load background image?
        if ~isempty(imalpha) && c.Stim_AddBckgrnd == 1 && ~isempty(c.BckgrndDir{Cond})    	% If image contains transparent pixels...         
            Background = imread(fullfile(c.BckgrndDir{Cond}, c.BackgroundFiles{Cond}(Stim).name));   	% Read in phase scrambled version of stimulus
            Background = imresize(Background, c.ImgSize);                               % Resize background image
            if c.Stim_Color == 0
                Background = repmat(rgb2gray(Background),[1,1,3]);
            end
            Background(:,:,4) = ones(size(Background(:,:,1)))*255;                      
            c.StimBkgHandle{Cond}(Stim) = Screen('MakeTexture', c.window, Background); 	% Create a PTB offscreen texture for the background
        else
            c.StimBkgHandle{Cond}(Stim) = 0;
        end
        
    end

end
delete(wbh);                                                                            % Close the waitbar figure window

if PrintToDisplay == 1
    Screen('FillRect', c.window, c.Col_bckgrndRGB);                                  	% Clear background
    DrawFormattedText(c.window, sprintf('All %d stimuli loaded!\n\nClick ''Run'' to start experiment.', TotalStim), 'center', 80, c.TextColor);
    Screen('Flip', c.window);
end
