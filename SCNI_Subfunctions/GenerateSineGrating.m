function [GratingTexture] = GenerateSineGrating(Grating, Display, PTB)

%========================== GenerateSineGrating.m ===========================
% Returns a PTB texture containing a sinusoidal luminance grating. This can
% optionally be converted to a Gabor patch when used in combination with
% GenerateAlphaMask.m.
%
% INPUTS:
%       Grating.Dim:            Dimensions [w, h] (pixels)
%       Grating.CyclesPerDeg:   Number of grating cycles per degree
%       Grating.Phase:              
%
% REVISIONS:
% 24/10/2012 - Created by Aidan Murphy (apm909@bham.ac.uk)
%     ___  ______  __   __
%    /   ||  __  \|  \ |  \    APM SUBFUNCTIONS
%   / /| || |__/ /|   \|   \   Aidan P. Murphy - apm909@bham.ac.uk
%  / __  ||  ___/ | |\   |\ \  Binocular Vision Lab
% /_/  |_||_|     |_| \__| \_\ University of Birmingham
%==========================================================================
if ~isfield(Display,'win') && ~exist('PTB','var')
   PTB = 0;
end
if ~isfield(Grating, 'CyclesPerDeg')
    Grating.CyclesPerDeg = 0.5;                                 % Default number of grating cycles per degree
end
f = 1/((1/Grating.CyclesPerDeg)*Display.Pixels_per_deg(1));     % Calculate grating cycles per pixel    
p = ceil(1/f);                                                  % Calculate pixels/cycle, rounded up
fr = f*2*pi;                                                    % Calculate frequency (radians)
Grating.Dim = round(Grating.Dim);
texsize = (Grating.Dim(1)/2)+2;                                     

%=========== Create single row texture
[x,y] = meshgrid(-texsize:texsize,1);% + p, 1);
grating = 128 + 127*cos(fr*x);
grating = repmat(grating(1:Grating.Dim(1)), Grating.Dim(2), 1);
if PTB == 1
    GratingTexture = Screen('MakeTexture', Display.win, grating);
elseif PTB == 0
    GratingTexture = grating;
end