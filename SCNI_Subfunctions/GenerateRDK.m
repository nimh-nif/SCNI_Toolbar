function [RDKframes] = GenerateRDK(Dot, Display)

%============================= GenerateRDK.m ==============================
% Creates a random dot kinetogram (RDK) of a plane of dots moving in 
% transparent motion. By rounding the requested dot velocity, an animation
% is created in which dots start and end in the same place and can
% therefore be looped smoothly.
%
% INPUTS:
%       Dot.Window:     w x h of textures (pixels)
%       Dot.Coherence:  (0-1)
%       Dot.Direction:  (degrees clockwise from 12 o'clock)
%       Dot.Velocity:   (pixels/second)
%       Dot.Num:        total number of dots
%       Dot.Size:       single value, range [min, max], or distribution [mean, sd, 1](pixels)
%       Dot.Contrast:   
%       Dot.Lifetime:   Dot lifetime (frames)
%       Dot.Type:       0 = squares; 1 = circles; 2 = anti-aliased circles
%       Dot.Colour:     RGB (or ommit for default black and white dots)
%
% REVISIONS:
%   23/10/2012 - Created by Aidan Murphy (apm909@bham.ac.uk)
%   16/07/2015 - Updated for variable coherence (APM)
%     ___  ______  __   __
%    /   ||  __  \|  \ |  \    APM SUBFUNCTIONS
%   / /| || |__/ /|   \|   \   Aidan P. Murphy - apm909@bham.ac.uk
%  / __  ||  ___/ | |\   |\ \  Binocular Vision Lab
% /_/  |_||_|     |_| \__| \_\ University of Birmingham
%==========================================================================

PixPerFrame = Dot.Velocity/Display.RefreshRate;      	% Requested dot speed (pixels per frame)
NrFrames = round(Dot.Window(1)/PixPerFrame);            % Number of frames for a dot to travel across the window
PixPerFrame = Dot.Window(1)/NrFrames;                   % Corrected dot speed (pixels per frame)

%======================== Set dot setting defaults ========================
if ~isfield(Dot,'Contrast'), Dot.Contrast = 1; end      % Full contrast
if ~isfield(Dot,'Coherence'), Dot.Coherence = 1; end    % Full coherence
if ~isfield(Dot,'Lifetime'), Dot.Lifetime = 30; end     % Dot lifetime (frames)
if ~isfield(Dot,'Type'), Dot.Type = 2; end              % Anti-aliased circles
if ~isfield(Dot,'Size'), Dot.Size = 4; end              % Dot sizes (pixels)
if ~isfield(Dot,'DrawAngle'), Dot.DrawAngle = 0; end    
switch numel(Dot.Size)
    case 3
        Dot.Sizes = abs(normrnd(Dot.Size(1)-1,Dot.Size(2),[1,Dot.Num]))+1;              % Normally distributed positive
    case 2
        Dot.Sizes = repmat(Dot.Size(1),[1,Dot.Num])+(rand(1,Dot.Num).*repmat(diff(Dot.Size),[1,Dot.Num]));
    case 1 
        Dot.Sizes = max([1 Dot.Size]);
end
Dot.Sizes(Dot.Sizes<1) = 1;
if ~isfield(Dot,'Colour')
    DotColour = (randi(2, [1, Dot.Num])-1)*255;                                      % Dot color defaults is black and white    
    Dot.Colour = [DotColour; DotColour; DotColour; ones(1, Dot.Num)*Dot.Contrast*255];
end
if isfield(Dot,'RandColour')
    if Dot.RandColour == 1
        DotColour = (randi(2, [1, Dot.Num])-1)*255;                                      % Apply random dot colors
        Dot.Colour = [DotColour(randperm(Dot.Num)); DotColour(randperm(Dot.Num)); DotColour(randperm(Dot.Num)); ones(1, Dot.Num)*Dot.Contrast*255];
    end
end
Screen('BlendFunction', Display.win, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);         % Enable alpha channel

%============= Generate dot lifetimes
if isfield(Dot, 'Lifetime')
	if Dot.Lifetime < inf
%         StartFrameCount = Dot.LifetimeMean + (randn([1, Dot.Num])*Dot.LifetimeStd);
        StartFrameCount = randi(Dot.Lifetime, [1, Dot.Num]);          % Assign start count of lifetime for each dot
        ReplacedPerFrame = round(Dot.Num/Dot.Lifetime);
    else
        StartFrameCount = [];
    end
else
    StartFrameCount = [];
end

%================= 
xpos = nan(NrFrames, Dot.Num);
ypos = nan(NrFrames, Dot.Num);
xpos(1,:) = randi(Dot.Window(1), [1, Dot.Num]);
ypos(1,:) = randi(Dot.Window(2), [1, Dot.Num]);
xposEnd = xpos(1,:)-(PixPerFrame*Dot.Lifetime);
xposEnd(xposEnd<0) = Dot.Window(1)-xposEnd(xposEnd<0);
yposEnd = ypos(1,:);
xposVis = nan(NrFrames, Dot.Num);
radius = Dot.Window(1)/2;
xposVis(1,:) = xpos(1,:);

%================= DOT COHERENCE PARAMETERS
DotDirections = zeros(1, Dot.Num);                                  % Diot direction defaults to zero
AllDotsOrder = randperm(Dot.Num);                                   % Randomly order all dots
RandomDots = AllDotsOrder(1:round(Dot.Num*(1-Dot.Coherence)));      % Assign random motion dots  
DotDirections(RandomDots) = rand(1, numel(RandomDots))*2*pi;     	% Assign random directions to random motion dots

%================ DRAW DOT/ GRATING TEXTURES
TextureBackground = ones([Dot.Window, 3])*Dot.Background(1);
TextureCentre = Dot.Window/2;

FrameCount = StartFrameCount;
for Frame = 1:NrFrames
  	RDKframes(Frame) = Screen('MakeTexture', Display.win, TextureBackground(:,:,1), Dot.DrawAngle);
    Screen('DrawDots', RDKframes(Frame), [xpos(Frame,:); ypos(Frame,:)], Dot.Sizes, Dot.Colour, [0 0], Dot.Type);
    
%     %================ Check dot lifetimes
%     if ~isempty(StartFrameCount)
%         FrameCount = FrameCount+1;                                                                                  % Keep frame count per dot
%         if Frame < NrFrames-Dot.Lifetime
%             xpos(FrameCount> Dot.Lifetime) = randi(Dot.Window(1), [1,numel(find(FrameCount> Dot.Lifetime))]);       % Assign new positions for expired dots
%             ypos(FrameCount> Dot.Lifetime) = randi(Dot.Window(2), [1,numel(find(FrameCount> Dot.Lifetime))]);
%         elseif Frame >= NrFrames-Dot.Lifetime                                                                     	% Prepare to return dots to starting positions
%             xpos(FrameCount> Dot.Lifetime) = xposEnd(FrameCount> Dot.Lifetime);
%             ypos(FrameCount> Dot.Lifetime) = yposEnd(FrameCount> Dot.Lifetime);
%         end
%         FrameCount(FrameCount> Dot.Lifetime) = 1;                                                                   % Reset frame count for expired dots
%     end      
    
    %============== Prepare dot positions for next frame
%     xpos(Frame+1, CoherentDots) = xpos(Frame,CoherentDots)+PixPerFrame;                                              % Advance coherent dot positions
%     xpos(Frame+1, xpos(Frame+1,CoherentDots)>Dot.Window(1)) = xpos(Frame+1, xpos(Frame+1,CoherentDots)>Dot.Window(1))-Dot.Window(1);    	% Reset positions of dots moving outside of the window
%     xposVis(Frame+1,CoherentDots) = xpos(Frame+1,CoherentDots);                   % 
    
    for i = 1:Dot.Num                                                                   % For each dot...
        xpos(Frame+1, i) = xpos(Frame, i) + sin(DotDirections(i))*PixPerFrame;          % Advance dot in x direction   
        ypos(Frame+1, i) = ypos(Frame, i) + cos(DotDirections(i))*PixPerFrame;          % Advance dot in y direction
        if xpos(Frame+1,i)> Dot.Window(2)                                            	% If dot falls outside of texture window...
            xpos(Frame+1, i) = 1;                                                       % Return dot to other side of texture
        elseif xpos(Frame+1, i) < 1                                                     
            xpos(Frame+1, i) = Dot.Window(2);                                         
        end
        if  ypos(Frame+1,i)> Dot.Window(1)
            ypos(Frame+1, i) = 1;
        elseif ypos(Frame+1, i) < 1
            ypos(Frame+1, i) = Dot.Window(1);
        end
    end
end