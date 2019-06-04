% SCNI_MeasureStereoCrosstalk.m

Params = load('SCNI-Red-DataPixx.mat');
BackgroundRGB   = 0;
MaxVal          = 255;
NoLumVals   =   3;
LumVals     = linspace(0, MaxVal, NoLumVals);
FiltNames   = {'No', 'Left Eye', 'Right eye'};


%=================== Generate frames
ImSize      = Params.Display.XScreenRect([4,3]);
LeftIndx    = [1:(ImSize(2)/4),(ImSize(2)/2):(3*ImSize(2)/4)];
RightIndx   = [(ImSize(2)/4)+1:(ImSize(2)/2), (3*ImSize(2)/4)+1:ImSize(2)];
BlankFrame  = zeros([ImSize,3]);
for f = 1:4
    Frame{f}    = BlankFrame;
    if f == 2
        Frame{2}(:,LeftIndx,:) = MaxVal;
    elseif f == 3
        Frame{3}(:,RightIndx,:) = MaxVal;
    elseif f == 4
        Frame{4}(:) = MaxVal;
    end
end


%=================== Present to screen
Params = SCNI_OpenWindow(Params);
Screen('TextSize', Params.Display.win, 40)
for filt = 1:numel(FiltNames)
    
    
    for frame = 1:numel(Frame)
        TextString = sprintf('%s filter, Frame %d/ %d', FiltNames{filt}, frame, numel(Frame));
        FrameTex = Screen('MakeTexture',  Params.Display.win, Frame{frame});
        Screen('FillRect', Params.Display.win, BackgroundRGB);
        Screen('DrawTexture',  Params.Display.win, FrameTex);
        DrawFormattedText(Params.Display.win, TextString, 50, 50, [MaxVal,0,0], []);
        [VBL FrameOnset] = Screen('Flip', Params.Display.win);
        KbWait;
        Input = input('Input luminance measured for sample:');
        LumValues(frame, filt) = Input;
    end
    
end

sca;


figure;
axh(1) = subplot(1,4,1);
imagesc([0,0; 0,1; 1,0; 1,1])
axh(2) = subplot(1,4,2:4);
imagesc(LumValues);
colormap hot;
set(gca,'xticklabel', (FiltNames));
