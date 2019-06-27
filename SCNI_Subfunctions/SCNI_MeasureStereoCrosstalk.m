% SCNI_MeasureStereoCrosstalk.m

Params = load('SCNI-Red-DataPixx.mat');
BackgroundRGB   = 0;
MaxVal          = 255;
NoLumVals       = 3;
LumVals         = linspace(0, MaxVal, NoLumVals);
LumCombos       = numel(LumVals)^2;
FiltNames       = {'None', 'Left', 'Right'};


%=================== Generate frames
ImSize      = Params.Display.XScreenRect([4,3]);
LeftIndx    = [1:(ImSize(2)/4),(ImSize(2)/2):(3*ImSize(2)/4)];
RightIndx   = [(ImSize(2)/4)+1:(ImSize(2)/2), (3*ImSize(2)/4)+1:ImSize(2)];
BlankFrame  = zeros([ImSize,3]);
% for f = 1:4
%     Frame{f}    = BlankFrame;
%     if f == 2
%         Frame{2}(:,LeftIndx,:) = MaxVal;
%     elseif f == 3
%         Frame{3}(:,RightIndx,:) = MaxVal;
%     elseif f == 4
%         Frame{4}(:) = MaxVal;
%     end
% end
findx = 1;
for le = 1:numel(LumVals)
    for re = 1:numel(LumVals)
        Frame{findx}                = BlankFrame;
        Frame{findx}(:,LeftIndx,:)  = LumVals(le);
        Frame{findx}(:,RightIndx,:) = LumVals(re);
        LumMat(findx,:)             = [LumVals(le), LumVals(re)];
        findx = findx+1;
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

sca;0


figure;
axh(1) = subplot(1,4,1);
imagesc(LumMat)
box off;
set(axh(1), 'xticklabel', {'Left','Right'}, 'ytick', [], 'tickdir','out','fontsize', 14);
xlabel('Screen','fontsize',16)
ylabel('Stim pattern','fontsize',16)

axh(2) = subplot(1,4,2:4);
imagesc(LumValues);
axis equal tight
box off;
set(axh(2), 'xtick',1:3,'xticklabel', FiltNames, 'ytick', [], 'tickdir','out','fontsize', 14);
colormap hot;
xlabel('Filter','fontsize',14)
cbh = colorbar;
title('SCNI Red LG 55EF9500 luminance 06/13/19','fontsize', 18)

figure;
axh(3)  = subplot(1,2,1);
plot(LumVals,[LumValues(1,3),  LumValues(4,3), LumValues(7,3)], 'o--r','linewidth',2);
hold on;
plot(LumVals,[LumValues(1,3),  LumValues(2,3), LumValues(3,3)], 'o-r','linewidth',2);
plot(LumVals,[LumValues(1,2),  LumValues(2,2), LumValues(3,2)], 'o--b','linewidth',2);
plot(LumVals,[LumValues(1,2),  LumValues(4,2), LumValues(7,2)], 'o-b','linewidth',2);
box off
grid on
set(gca,'tickdir','out','fontsize', 14);
xlabel('Requested luminance','fontsize', 18);
ylabel('Measured luminance (cd/m^2)','fontsize', 18);

axh(4)  = subplot(1,2,2);

