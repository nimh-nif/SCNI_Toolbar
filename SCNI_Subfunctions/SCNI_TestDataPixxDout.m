

Datapixx('Open');
Datapixx('StopAllSchedules');
Datapixx('RegWrRd');

% Upload some arbitrary digital output waveforms for the first 5 button
% inputs.  Note that the digital output waveforms must be stored at 4kB
% increments from the DOUT buffer base address.
% Also note that the last value in the digital output waveform will be
% almost immediately replaced with the original contents of the digital
% output port when the schedule terminates.

doutBufferBaseAddr  = 0;                                                % D out buffer base address
doutSampleRate      = 1000;                                             % Sample rate for digital out
doutNoChannels      = 8;                                                % Number of channels to output to
PulseDuration       = 50;                                               % Pulse duration (ms)
PulseSamples        = round(PulseDuration*(doutSampleRate/1000));       % Number of samples in pulse
doutWaveform        = [zeros(1,10), ones(1,PulseSamples), zeros(1,10)]; % Create TTL waveform

Datapixx('WriteDoutBuffer', doutWaveform, doutBufferBaseAddr);          % 
Datapixx('SetDoutSchedule', 0, doutSampleRate, numel(doutWaveform)+1, doutBufferBaseAddr);
Datapixx('SetDinDataDirection', 0);
Datapixx('EnableDinDebounce');              % Filter out button bounce
Datapixx('EnableDoutButtonSchedules');      % This starts the schedules
Datapixx('RegWrRd');                        % Synchronize DATAPixx registers to local register cache
Datapixx('Close');
