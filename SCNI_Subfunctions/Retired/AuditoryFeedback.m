function [Beep, Noise] = AuditoryFeedback(Tone, PlaybackMode)

%========================== AuditoryFeedback.m ============================
% Initializes PTB's PsychSound audio and loads sine wave tones specified by
% the input structure 'Tone', into the audio buffer for use as auditory 
% feedback. If no input is provided, default settings produce 2 tones (e.g.
% correct = 1000Hz, incorrect = 400Hz). Handles to tones are returned in 
% the array Beep, and can be played by calling either: 
%           PsychPortAudio('Start', Beep(n), 1);
% or:
%           Snd('Play',Beep(n,:));
% PsychPortAudio should be closed down at the end of the experiment using:
%           PsychPortAudio('Close');
%
% INPUT:    Tone(n).Freq:      frequency of tone(s) to generate (Hz)
%           Tone(n).Duration:  duration of tone(s) to generate (seconds)
%           PlaybackMode:      0 = use 'Snd'; 1 = use 'PsychPortAudio'
%
% 01/03/2012 - Witten by Aidan Murphy (apm909@bham.ac.uk)
% 14/03/2013 - Lowpass filtered white noise output added.
% 16/07/2018 - Rhesus macaque vocalization added.
%     ___  ______  __   __
%    /   ||  __  \|  \ |  \    APM SUBFUNCTIONS
%   / /| || |__/ /|   \|   \   Aidan P. Murphy - apm909@bham.ac.uk
%  / __  ||  ___/ | |\   |\ \  Binocular Vision Lab
% /_/  |_||_|     |_| \__| \_\ University of Birmingham
%
%==========================================================================
persistent pamaster

if nargin == 0 || isempty(Tone)          % If no input was provided, use defaults:
    Tone(1).Freq = 1000;              	 % create a 1kHz tone for correct response
    Tone(2).Freq = 200;              	 % create a 400Hz tone for incorrect response
    Tone(1).Duration = 0.2;            	 % make each tone 200ms in duration
    Tone(2).Duration = 0.2;            	 % make each tone 200ms in duration
    Noise.Duration = 0.4;
end
if nargin < 2                            % If audio playback format was not specified,
   	if IsWin                             % if OS is Windows,
        PlaybackMode = 0;              	 % use high-latency 'Snd' playback
    else                                 % For any other OS,
        PlaybackMode = 1;             	 % use low-latency 'PsychPortAudio' playback
    end
    SampleRate = Snd('DefaultRate');     % Get default audio sample rate
end

if PlaybackMode == 1
    InitializePsychSound;                                                       % Initialize PsychPortAudio at standard latency
    p.nrchannels = 1;                                                           % Set number of channels (1 channel = mono)
    p.sampRate = round(Snd('DefaultRate'));                                       	% Set sample rate
    if IsWin
        sugLat = 0.015;                                                      	% Add 15 msecs latency on Windows, to protect against shoddy drivers
    else
        sugLat = [];                                                            
    end
    try
        pamaster = PsychPortAudio('Open', [], 1, 0, p.sampRate, p.nrchannels, [], sugLat);    
        PsychPortAudio('Start', pamaster, 0, 0, 1);                                 % Start the master immediately  
    catch
    end

    for n = 1:numel(Tone)
        Tone(n).Audio = MakeBeep(Tone(n).Freq, Tone(n).Duration, p.sampRate); 	% create tone
        Beep(n) = PsychPortAudio('OpenSlave', pamaster, 1);                   	% Create slave channel
        PsychPortAudio('FillBuffer', Beep(n), Tone(n).Audio);                 	% Add tone to buffer
    end
    
elseif PlaybackMode == 0
    for n = 1:numel(Tone)
        Beep(n,:) = MakeBeep(Tone(n).Freq, Tone(n).Duration);
    end
    Snd('Open');
    SampleRate = Snd('DefaultRate');     % Get default audio sample rate
    if exist('Noise','var')
        Noise = (rand([1, round(SampleRate*Noise.Duration)])*2)-1;
    end
%     h = fdesign.lowpass('N,Fc',2,0.5);
%     D = design(h,'butter');
%     Noise = filter(D, Noise);
end

