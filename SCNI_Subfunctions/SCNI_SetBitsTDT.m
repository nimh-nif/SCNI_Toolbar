function SCNI_SetBitsTDT(val)

%========================= SCNI_SetBitsTDT.m ==============================
% This function sets the appropriate bits on the digital output port of the
% DataPixx2 in order to send event codes to the TDT RZ2 digital input when
% the two are connected by a straight-through DB25 cable.
%
% INPUTS:
%   val:    an integer in the range 0 - (2^13)-1
%
% HISTORY:
%   06/22/2017 - Adapted from David McMahon's C code for QNX by Aidan Murphy
%==========================================================================

if ~strcmp(class(val),'double')  || val > (2^13)-1
    error('Input value ''val'' must be a double in the range 0-%d!', (2^13)-1);
end

if ~Datapixx('IsReady')                                         % If Datapixx is not ready...
   Datapixx('Open');                                            % Open connection
   Datapixx('RegWrRd');                                         
end

StrobeCh            = 10;                                       % Which channel/ bit TDT expects strobe on?
BinaryValue         = de2bi(val);                               % Convert input decimal to binary
bitValues           = [zeros(1,StrobeCh), BinaryValue, zeros(1, 13-length(BinaryValue))]; % Insert value in bit mask
DecValues           = bi2de(bitValues);                         % Convert binary back to decimal
status              = Datapixx('GetDoutStatus');              	% Get digital output status
Datapixx('SetDoutValues', DecValues);%, bitMask);             	% Set digital output
Datapixx('RegWrRd');        

bitValues(StrobeCh) = 1;                                        % Set strobe bit high                   
DecValues           = bi2de(bitValues);                         % Re-convert binary to decimal
Datapixx('SetDoutValues', DecValues);%, bitMask);             	% Set digital output
Datapixx('RegWrRd');

Datapixx('SetDoutValues', 0);%, bitMask);                       % Reset all digital outputs to zeros
Datapixx('RegWrRd');

end