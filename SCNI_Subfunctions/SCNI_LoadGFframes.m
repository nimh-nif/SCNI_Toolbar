function Params = SCNI_LoadGFframes(Params)

%======================= LoadGazeFollowingFrames.m ========================




%========= Load stimulus paramater information
StimParamsFile = wildcardsearch(Params.GF.StimDir, '*.mat');
if isempty(StimParamsFile)
    error('No stimulus parameters .mat file was found in %s!', Params.GF.StimDir);
else
    load(StimParamsFile{1});
end
    
%========= Load background image(s)
if Params.GF.BckgrndType == 2
    AllBckgrndTex   = wildcardsearch(Params.GF.BckgrndDir, '*.png');
    BckgrndIm       = imread(AllBckgrndTex{randi(numel(AllBckgrndTex))});
    Params.GF.BckgrndTex = Screen('MakeTexture', Params.Display.win, BckgrndIm);
end

%========= Load foreground image(s)
% if Params.GF.ForegroundType > 0
    ForegroundFile              = wildcardsearch(Params.GF.StimDir, 'Barrel*.png');
    [ForegroundIm, cmap, alph]  = imread(ForegroundFile{1});
    ForegroundIm(:,:,4)         = alph;
    Params.GF.ForegroundTex     = Screen('MakeTexture', Params.Display.win, ForegroundIm);
% end

%============= Update experimenter display
LoadTextPos     = (Params.Display.Rect([3,4]).*[0.4,0.5]);
TextColor       = [1,1,1]*255;
Screen(Params.Display.win,'TextSize',60); 
message = sprintf('Loading target frames (%d)...\n', Stim.NoTargets);
if Params.GF.BckgrndType == 1
    Screen('FillRect', Params.Display.win, Params.Display.Exp.BackgroundColor);                                             	% Clear background
elseif Params.GF.BckgrndType == 2
    Screen('DrawTexture', Params.Display.win, Params.GF.BckgrndTex, Params.GF.SourceRectExp, Params.GF.RectExp);   
    Screen('DrawTexture', Params.Display.win, Params.GF.BckgrndTex, Params.GF.SourceRectMonk, Params.GF.RectMonk);
end
DrawFormattedText(Params.Display.win, message, LoadTextPos(1), LoadTextPos(2), TextColor);
Screen('Flip', Params.Display.win, [], 0); 
        
%========= Load target frames
TargetsIndxFile         = fullfile(Stim.Dir, [Stim.Target.IndxFile, '.', Stim.FileFormat]);
IndxIm                 	= imread(TargetsIndxFile);
TargetsRGBFile          = fullfile(Stim.Dir, [Stim.Target.RGBFile, '.', Stim.FileFormat]);
[ColorIm, cmap, AlphaIm]= imread(TargetsRGBFile);
for t = 1:Stim.NoTargets
    MaskIm                  = IndxIm == t;
    NewMask                 = double(AlphaIm).*double(MaskIm);
    NewColorIm              = ColorIm;
    NewColorIm(:,:,4)       = NewMask;
  	Params.GF.TargetTex(1,t)= Screen('MakeTexture', Params.Display.win, NewColorIm);
    NewColorIm              = cat(3, NewMask*Params.GF.CorrectColor(1), NewMask*Params.GF.CorrectColor(2), NewMask*Params.GF.CorrectColor(3), NewMask);
    Params.GF.TargetTex(2,t)= Screen('MakeTexture', Params.Display.win, NewColorIm);
 	NewColorIm              = cat(3, NewMask*Params.GF.IncorrectColor(1), NewMask*Params.GF.IncorrectColor(2), NewMask*Params.GF.IncorrectColor(3), NewMask);
    Params.GF.TargetTex(3,t)= Screen('MakeTexture', Params.Display.win, NewColorIm);
    
  	% Find target centroid (screen pixel coordinates)
    ExpIm = imresize(MaskIm(:,1:size(MaskIm,2)/2), [size(MaskIm,1), size(MaskIm,2)]);  
    [Y,X] = find(ExpIm==1);
    Params.GF.TargetCenterPix(t,:) = [mean(X), mean(Y)];
end


%========= Load avatar animation frames
if Params.GF.Mode > 1
    wbh         = waitbar(0, '');                            
    FrameCount  = 1;
    C           = 1;
    SourceRect  = Params.Display.Rect./[1,1,2,1];
    
    %============= Load resting blink frames to PTB texture handles
    BlinkFrames = wildcardsearch(Params.GF.StimDir, 'Blink*');
    for f = 1:numel(BlinkFrames)
        [img, cmap, alpha]  = imread(BlinkFrames{f});
        img(:,:,4)          = alpha;
        Params.GF.AvatarBlink(f) = Screen('MakeTexture', Params.Display.win, img);
        ImageDim(f,:)       = [size(img,2), size(img,1)];
        if size(unique(ImageDim,'rows'),1) > 1
            error('Pixel resolution of frame %s does not match other frames!', BlinkFrames{f});
        end
    end
    
    %============= Load saccades/ head movements to targets
    for t = 1:Stim.NoTargets
        for f = 1:Stim.FramesPerTarget

            %============= Update experimenter display
            message = sprintf('Loading frame %d of %d \n\n(Condition %d/ %d: %s)...\n',FrameCount, Stim.FramesPerTarget*Stim.NoTargets, C, numel(Stim.Conditions), Stim.Conditions{C});
            if Params.GF.BckgrndType == 1
                Screen('FillRect', Params.Display.win, Params.Display.Exp.BackgroundColor);                                             	% Clear background
            elseif Params.GF.BckgrndType == 2
                Screen('DrawTexture', Params.Display.win, Params.GF.BckgrndTex, Params.GF.SourceRectExp, Params.GF.RectExp);   
                Screen('DrawTexture', Params.Display.win, Params.GF.BckgrndTex, Params.GF.SourceRectMonk, Params.GF.RectMonk);
            end
            DrawFormattedText(Params.Display.win, message, LoadTextPos(1), LoadTextPos(2), TextColor);
            for p = 1:t
                Screen('DrawTexture', Params.Display.win, Params.GF.TargetTex(1,p), SourceRect, Params.Display.Rect);
            end
            Screen('Flip', Params.Display.win, [], 0);                                                                                	% Draw to experimenter display

            waitbar(Stim.FramesPerTarget*Stim.NoTargets, wbh, message);                                                               % Update waitbar
            [keyIsDown, secs, keyCode, deltaSecs] = KbCheck();                                                                          % Check if escape key is pressed
            if keyIsDown && keyCode(KbName('Escape'))                                                                                   % If so...
                break;                                                                                                                  % Break out of loop
            end

            %============= Load next frame to PTB texture handle
            Filename            = fullfile(Params.GF.StimDir, sprintf('LookAtLocation_%s_Target%d_Frame%03d.%s', Stim.Conditions{C}, t, f, Stim.FileFormat));
            [img, cmap, alpha]  = imread(Filename);
            img(:,:,4)          = alpha;
            Params.GF.AvatarTex(t, f) = Screen('MakeTexture', Params.Display.win, img);
            ImageDim(FrameCount,:)    = [size(img,2), size(img,1)];
            if size(unique(ImageDim,'rows'),1) > 1
                error('Pixel resolution of frame %s does not match other frames!', Filename);
            end
            FrameCount = FrameCount+1;
        end
    end
    delete(wbh);
    Params.GF.ImageRes = ImageDim;
    
else
    Params.GF.ImageRes = Params.Display.Rect([3,4]);
end

