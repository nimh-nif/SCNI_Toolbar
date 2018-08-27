function MaskTexture = SCNI_GenerateAlphaMask(Mask, Display, ReturnHandle)

%======================== SCNI_GenerateAlphaMask.m ========================
% Returns a PTB texture with varying alpha values that can be drawn over 
% stimuli to give the appearance of a central circular aperture.
%
% INPUTS:
%       Mask.Dim:       Dimensions [w, h] (pixels)
%       Mask.ApRadius:  radius of central aperture (pixels)
%       Mask.Color:     RGB 0-255
%       Mask.Edge:      0 = hard edge;      
%                       1 = gaussian edge;  
%                       2 = cosine edge;
%       Mask.s:         Standard deviation of Gaussian edge (if selcted) in degrees
%       Mask.Taper:     Spread of cosine edge as a proportion of aperture radius
%
% REVISIONS:
%   24/10/2012 - Created by Aidan Murphy (apm909@bham.ac.uk)
%   28/01/2014 - Updated for control over edge properties (APM)
%   02/08/2018 - Updated for SCNI Toolbar (murphyap@nih.gov)
%     ___  ______  __   __
%    /   ||  __  \|  \ |  \    APM SUBFUNCTIONS
%   / /| || |__/ /|   \|   \   Aidan P. Murphy - murphyap@nih.gov
%  / __  ||  ___/ | |\   |\ \  Section on Cognitive Neurophysiology and Imaging
% /_/  |_||_|     |_| \__| \_\ National Institute of Mental Health
%==========================================================================

%=================== Check inputs
if ~isfield(Display,'win') || nargin < 3
    ReturnHandle = 0;
end
Mask.ApRadius   = floor(Mask.ApRadius);
Mask.Dim        = ceil(Mask.Dim);
MaskTexture     = [];
if Mask.Edge == 1
    if ~isfield(Mask, 's')
        s = Mask.ApRadius/2;        
    else
        s = Mask.s;
    end
end
if Mask.Edge == 2 && ~isfield(Mask, 'Taper')
    Mask.Taper = 0.2;                                                   % Set aperture taper as fraction of radius
end
if Mask.ApRadius*2 > min(Mask.Dim)
    fprintf('ERROR: requested aperture radius is larger than smallest mask dimension!\n');
end
if find(mod(Mask.Dim,2))~=0                                              % All mask dimensions must be even number pixels
    Mask.Dim(find(mod(Mask.Dim,2))) = Mask.Dim(find(mod(Mask.Dim,2)))+1;	
end

mask    = ones(Mask.Dim(2), Mask.Dim(1), 2)*Mask.Color(1);          	% Create a 2 layer mask 
mask(:,:,2) = 255;                                                      % Mask begins fully opaque (alpha = 255)
circle  = ones(Mask.ApRadius*2, Mask.ApRadius*2, 2)*Mask.Color(1);    	% Create a 2 layer aperture
left    = (Mask.Dim(1)/2)-Mask.ApRadius;
right   = (Mask.Dim(1)/2)+Mask.ApRadius-1;
top     = (Mask.Dim(2)/2)-Mask.ApRadius;
bottom  = (Mask.Dim(2)/2)+Mask.ApRadius-1;

switch Mask.Edge
    case 0                  	%==================== HARD circular edged aperture
        for n = 1:numel(circle(:,1,1))
           for p = 1:numel(circle(1,:,1))
               if (n-Mask.ApRadius)^2 + (p-Mask.ApRadius)^2 > Mask.ApRadius^2
                   circle(n,p,2)= 255;
               else
                   circle(n,p,2)= 0;
               end
           end
        end
    case 1                   	%==================== GAUSSIAN edged aperture
        [x,y]= meshgrid(-Mask.ApRadius:Mask.ApRadius-1,-Mask.ApRadius:Mask.ApRadius-1);	% Get x and y coordinates for each pixel                
        circle(:,:,2) = 255*(1 - exp(-((x/s).^2)-((y/s).^2)));                          % Apply Gaussian to layer 2 of mask

        % METHOD 2: Gaussian blurring *requires Image Processing Toolbox*
    %     mask = ones(2*texsize+1, 2*texsize+1, 2)*Mask.Color(1);         % Create a m x n x [RGBA] matrix of background colour values
    %     [x y] = meshgrid(1:Stim.Height);
    %     C = sqrt((x-Stim.Width/2).^2+(y-Stim.Height/2).^2)<= Stim.Radius;
    %     Aperture = ones(Stim.Height, Stim.Width)*255;
    %     Aperture(C) = 0;
    %     MaskWindow(:,:,4) = Aperture;
    %     BlurRadius = Stim.Radius/6; 
    %     H = fspecial('disk',BlurRadius);
    %     MaskWindow(:,:,4) = imfilter(MaskWindow(:,:,4),H,'replicate');

    case 2                      %==================== COSINE edged aperture 
        x_range = -1:1/Mask.ApRadius:1;
        y_range = -1:1/Mask.ApRadius:1;
        [x,y]   = meshgrid(x_range,y_range);
        r       = sqrt(x.^2 + y.^2);
        r       = min(1, r);                                               	% Limit r to 1 in the corners
        r       = r - (1 - Mask.Taper);                                 	% Everything in centre is negative.
        r       = max(0, r);                                             	% Limit centre to zero
        r       = r * pi / Mask.Taper;                                    	% In window region, r is in range [0, pi] 
        image_window = (1 + cos(r)) /2;

        ImSize = max(size(image_window));                                   % Aperture is 1 pixel larger than requested, so...
        clear circle
        circle = ones(ImSize,ImSize, 2)*Mask.Color(1);
        circle(:,:,2) = (1-image_window)*255;
        circle(end,:,:) = [];
        circle(:,end,:) = [];
end 
mask(top:bottom,left:right,:) = circle;                                     % cut circular aperture in mask

if ReturnHandle == 1
    MaskTexture = Screen('MakeTexture', Display.win, mask);                 % Convert mask to texture
elseif ReturnHandle == 0
    MaskTexture = mask(:,:,2);
end