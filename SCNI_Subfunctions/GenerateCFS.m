function CFSTexture = GenerateCFS(win, FrameSize, TexelsPerFrame, NoFrames, Background)

%============================= GenerateCFS.m ==============================
% Generates random 'Mondrian' texture frames which can be rapidly presented 
% to one eye in order to reliably suppress perception of the input to the 
% other eye through continuous flash suppression (Tsuchiya & Koch, 2005). 
% The recommended frame rate is 10 Hz.
% 
% INPUTS:   win:            PTB window pointer
%           FrameSize:      dimensions of each frame [Width, Height] in pixels
%           TexelsPerFrame: number of texture elements per frame
%           NoFrames:       number of frames to generate
%           Background:     background colour (RGB)
%
% REFERENCES:
% Tsuchiya N & Koch C (2005) Continuous flash suppression reduces negative
% afterimages.  Nature Neuroscience 8: 1096-1101.
%     ___  ______  __   __
%    /   ||  __  \|  \ |  \    APM SUBFUNCTIONS
%   / /| || |__/ /|   \|   \   Aidan P. Murphy - apm909@bham.ac.uk
%  / __  ||  ___/ | |\   |\ \  Binocular Vision Lab
% /_/  |_||_|     |_| \__| \_\ University of Birmingham
%
% HISTORY:
% 26/01/2011 - created by Aidan Murphy (apm909@bham.ac.uk)
%==========================================================================

if nargin < 3
    FrameSize = [500 500];
    TexelsPerFrame = 100;     
    NoFrames = 20;
end

MaskRect = ones(FrameSize(2), FrameSize(1))*Background(1);              % Create a matrix of the specified size and colour                
MeanRectSize = FrameSize(2)/4;
Rects = zeros(4, TexelsPerFrame, NoFrames);
RectColours = zeros(3, TexelsPerFrame, NoFrames);
for n = 1:NoFrames
    RectCorner = zeros(TexelsPerFrame, 2);                           	% Preallocate rectangle size and position matrices
    RectSize = zeros(TexelsPerFrame, 2);
    for i = 1:TexelsPerFrame                                              
        RectCorner(i,:) = [randi(FrameSize(1)), randi(FrameSize(2))];       	% Generate a random position for each rectangle
        RectSize(i,:) = [rand(1)*MeanRectSize, rand(1)*MeanRectSize];           % Generate a random size for each rectange
        if RectSize(i,1)> FrameSize(1)-RectCorner(i,1)                          % If the rectangle FrameSize(1) would exceed the texture boundary...
            RectSize(i,1) = rand(1)*FrameSize(1)-RectCorner(i,1);               % Generate a new rectangle FrameSize(1) than is a random proportion of the available FrameSize(1)
        end
        if RectSize(i,2)> FrameSize(2)-RectCorner(i,2)                          % If the rectangle FrameSize(2) would exceed the texture boundary...
            RectSize(i,2) = rand(1)*FrameSize(2)-RectCorner(i,2);               % Generate a new rectangle FrameSize(2) than is a random proportion of the available FrameSize(1)
        end
        Rects(:,i,n) = [RectCorner(i,:), RectCorner(i,:)+RectSize(i,:)]';  
        RectColours(:,i,n) = [(randi(3)-1)*128, (randi(3)-1)*128, (randi(3)-1)*128];
    end
    CFSTexture(n) = Screen('MakeTexture', win, MaskRect);
    Screen('FillRect', CFSTexture(n), RectColours(:,:,n), Rects(:,:,n));
end