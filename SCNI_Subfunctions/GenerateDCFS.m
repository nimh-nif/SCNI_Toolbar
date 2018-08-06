function DCFStextures = GenerateDCFS(DCFS, Display, Test, PTB)

%============================== GenerateDCFS.m ============================
% Generate frames for dynamic continuous flash suppression stimulus mask and
% return a vector of PTB texture handles. Default settings are those used
% by Yuval-Greenberg & Heeger (2013).
%
% INPUTS:
%   DCFS.Duration:       loop duration (seconds)
%   DCFS.FrameRate:      frequency of texel repositioning (Hz) [default = 10Hz]
%   DCFS.TextureSize:    width x height of stimulus texture (degrees)
%   DCFS.TexelSize:      width x height of texture elements (degrees)
%   DCFS.Color:          0 = grayscale, 1 = color
%   DCFS.Background:     Background color [R,G,B]
%
% REFERENCES:
%   Maruya K, Watanabe H & Watanabe M (2008). Adaptation to invisible motion 
%       results in low-level but not high-level aftereffects. Journal of Vision
%       8(11):7, 1-11.
%   Yuval-Greenberg S & Heeger DJ (2013). Continuous Flash Suppression Modulates 
%       Cortical Activity in Early Visual Cortex. The Journal of Neuroscience, 
%       33(23):9635?9643.
%
% REVISIONS:
%   13/01/2014 - Written by APM
%     ___  ______  __   __
%    /   ||  __  \|  \ |  \    APM SUBFUNCTIONS
%   / /| || |__/ /|   \|   \   Aidan P. Murphy - murphyap@mail.nih.gov
%  / __  ||  ___/ | |\   |\ \  Section on Cognitive Neurophysiology and Imaging
% /_/  |_||_|     |_| \__| \_\ NIMH, National Institutes of Health
%==========================================================================
if nargin < 2
    DCFS.Duration = 5;
    DCFS.TextureSize = [12,12];
    DCFS.FrameRate = 10;
    DCFS.Background = [127 127 127];
    Test = 1;
end
if ~Test
    if ~isfield(Display,'win')
        PTB = 0;
    elseif isfield(Display,'win') && ~exist('PTB','var')
        PTB = 1;
    end
end

if Test == 1
    Background = [127 127 127];
    Display = DisplaySettings;
    [Display.win, Display.Rect] = Screen('OpenWindow',Display.ScreenID, Background, Display.Rect/1.5);
    PTB = 1;
end

TextureWindow = DCFS.TextureSize*Display.Pixels_per_deg(1);
TexelSize = [2, 2]*Display.Pixels_per_deg(1);
if ~isfield(DCFS,'TexelsPerFrame')
    DCFS.TexelsPerFrame = 200;                                   	% Number of texture elements
end
NoFrames = Display.RefreshRate*DCFS.Duration;         	% Number of animation frames                    

TexelBarWidth = 0.1*Display.Pixels_per_deg(1);
ArrangementFreq = DCFS.FrameRate;                     	% Frequency of pattern change (Hz)
ContrastReversalFreq = 30;                              % Frequency of sidebar contrast reversals (Hz)

Grating.AllCyclesPerDeg = [3,7,11,15];                 	% spatial frequency of sinusoids (cycles/deg)

Grating.Dim = round(TexelSize.*[2,1]);                               
Grating.ShiftPerFrame = 36;                             % sinusoid shift per frame (degrees phase angle)
TexelPixelsPerFrame = 2;                                % <<< BOTCH!
Grating.Alpha = 1;                                      % Set global contrast/ transparency
% Grating.PixelsPerFrame = Grating.CyclesPerDeg*Display.Pixels_per_deg(1)/(360/Grating.ShiftPerFrame);

for cpd = 1:numel(Grating.AllCyclesPerDeg)
    Grating.CyclesPerDeg = Grating.AllCyclesPerDeg(cpd);
    GratingTexture(cpd) = GenerateSineGrating(Grating, Display, PTB);
end

SideBar.Rect1 = [0, 0, Grating.Dim(1), TexelBarWidth];
SideBar.Rect2 = [0, Grating.Dim(2)-TexelBarWidth, Grating.Dim(1), Grating.Dim(2)];

BarContrasts = round(rand(1,DCFS.TexelsPerFrame));                 % Generate random contrasts for texel side bars

for f = 0:NoFrames-1
    DCFStextures(f+1) = Screen('MakeTexture',Display.win,ones(round(TextureWindow))*DCFS.Background(1));

    if rem(f, 360/Grating.ShiftPerFrame)==0                                                 
        TexelSourceRect = [0 0 TexelSize];                                                  % Reset texel source rect
    else
        TexelSourceRect = TexelSourceRect+[TexelPixelsPerFrame 0 TexelPixelsPerFrame 0];  	% Advance source window across grating
    end
    if rem(f, (60/ArrangementFreq))==0
        TexelPositions = rand(DCFS.TexelsPerFrame,2).*repmat(TextureWindow([2,1])-TexelSize,[DCFS.TexelsPerFrame,1]);   % Update texels positions to new random locations
        TexelRects = repmat(TexelPositions,[1,2])+[zeros(DCFS.TexelsPerFrame,2),repmat(TexelSize,[DCFS.TexelsPerFrame,1])];
        Grating.Orientations = rand(1,DCFS.TexelsPerFrame)*180;
        Grating.Colors = rand(DCFS.TexelsPerFrame,3)*255;
        Grating.SpatFreq = randi(numel(Grating.AllCyclesPerDeg),[1,DCFS.TexelsPerFrame]);
    end
    if rem(f, (Display.RefreshRate/ContrastReversalFreq))==0
        BarContrasts = ~BarContrasts;                                           % Reverse the contrast of texel side bars
    end
    
    for t = 1:DCFS.TexelsPerFrame
      	Screen('FillRect',GratingTexture(Grating.SpatFreq(t)),Grating.Colors(t,:)*BarContrasts(t),SideBar.Rect1);
        Screen('FillRect',GratingTexture(Grating.SpatFreq(t)),Grating.Colors(t,:)*BarContrasts(t),SideBar.Rect2);
        Screen('DrawTexture',DCFStextures(f+1),GratingTexture(Grating.SpatFreq(t)), TexelSourceRect, TexelRects(t,:), Grating.Orientations(t), [], Grating.Alpha, Grating.Colors(t,:));
    end
    if Test == 1
        Screen('DrawTexture', Display.win, DCFStextures(f+1));
        Screen('Flip',Display.win);
    end
end