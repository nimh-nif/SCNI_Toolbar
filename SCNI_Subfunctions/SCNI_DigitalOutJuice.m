function SCNI_DigitalOutJuice(Duration)

%========================= SCNI_DigitalOutJuice.m ==============================
% This function sets the appropriate bits on the digital output port of the
% DataPixx2 in order to send event codes to the TDT RZ2 digital input when
% the two are connected by a straight-through DB25 cable.
%
% INPUTS:
%   Duration:    solenoid open time in seconds
%
% HISTORY:
%   06/22/2017 - Adapted from David McMahon's C code for QNX by Aidan Murphy
%==========================================================================


if ~Datapixx('IsReady')                                         % If Datapixx is not ready...
   Datapixx('Open');                                            % Open connection
   Datapixx('RegWrRd');                                         
end  

bitValues           = 1;
DecValues           = bi2de(bitValues);                         % Re-convert binary to decimal
Datapixx('SetDoutValues', DecValues);%, bitMask);             	% Set digital output
Datapixx('RegWrRd');
OpenTime = GetSecs;
bitValues           = 0;
DecValues           = bi2de(bitValues);                         % Re-convert binary to decimal
while GetSecs < OpenTime + Duration

end
Datapixx('SetDoutValues', DecValues);%, bitMask);             	% Set digital output
Datapixx('RegWrRd');

end