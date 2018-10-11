function SCNI_SetBitsTDT(val, dc)

%========================= SCNI_SetBitsTDT.m ==============================
% This function sets the appropriate bits on the digital output port of the
% DataPixx2 in order to send event codes to the TDT RZ2 digital input when
% the two are directly connected by a straight-through DB25 cable.
%
% INPUTS:
%   val:    an integer in the range 0 - (2^13)-1
%   dc:     binary flag for direct connection between DataPixx and TDT RZ2
%
% HISTORY:
%   06/22/2017 - Adapted from David McMahon's C code for QNX by Aidan Murphy
%   03/22/2018 - Updated to allow for connection via SCNI DataPixx-TDT interface
%==========================================================================

% if nargin == 1 || dc == 0
%     MaxBits = 15;
% else
%     MaxBits = 13;
% end
if dc == 1
    StrobeCh    = 9;                    % Which channel/ bit TDT expects strobe on?
    MaxBits     = 15;
elseif dc == 0
  	StrobeCh    = 6; 
    MaxBits     = 16;
end
if ~strcmp(class(val),'double')  || val > (2^MaxBits)-1
    error('Input value ''val'' must be a double in the range 0-%d!', (2^MaxBits)-1);
end

if ~Datapixx('IsReady')                                         % If Datapixx is not ready...
   Datapixx('Open');                                            % Open connection
   Datapixx('RegWrRd');                                         
end


BinaryValue         = de2bi(val);                               % Convert input decimal to binary
bitValues           = [zeros(1,StrobeCh), BinaryValue, zeros(1, MaxBits-length(BinaryValue))]; % Insert value in bit mask
DecValues           = bi2de(bitValues);                         % Convert binary back to decimal
status              = Datapixx('GetDoutStatus');              	% Get digital output status
Datapixx('SetDoutValues', DecValues);%, bitMask);             	% Set digital output
Datapixx('RegWrRd');        

if dc == 1
    bitValues(StrobeCh) = 1;                                  	% Set strobe bit high     
end
DecValues           = bi2de(bitValues);                         % Re-convert binary to decimal
Datapixx('SetDoutValues', DecValues);%, bitMask);             	% Set digital output
Datapixx('RegWrRd');

Datapixx('SetDoutValues', 0);%, bitMask);                       % Reset all digital outputs to zeros
Datapixx('RegWrRd');

end