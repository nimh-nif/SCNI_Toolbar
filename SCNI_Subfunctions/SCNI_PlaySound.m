function [Params] = SCNI_PlaySound(Params)

%============================ SCNI_PlaySound.m =============================
% Play a pre-loaded audio clip to the subject. This can be used to alert 
% the animal to the start of the next trial.


%================= Load audio file
repetitions     = 1;
wavFilename     = '/projects/murphya/MacaqueFace3D/Macaque_video/OriginalWAVs/BE_Coo_mov53.wav';
[waveData, freq] = audioread(wavFilename);       	% Load the .wav file
waveData        = waveData';                        % Transpose so that each row has 1 channel
nChannels       = size(waveData, 1);                
nTotalFrames    = size(waveData, 2);                


if Params.DPx.UseAudio == 0         %================= Play wav file through PC audiocard
    if ~isfield(Params,'Audio') || ~isfield(Params.Audio,'Penalty')
        InitializePsychSound;                                                       % Initialize PsychPortAudio at standard latency
        p.nrchannels = 1;                                                           % Set number of channels (1 channel = mono)
        p.sampRate = round(Snd('DefaultRate'));                                   	% Set sample rate
        if IsWin
            sugLat = 0.015;                                                      	% Add 15 msecs latency on Windows, to protect against shoddy drivers
        else
            sugLat = [];                                                            
        end
        pamaster = PsychPortAudio('Open', [], 1, 0, p.sampRate, p.nrchannels, [], sugLat);    
        PsychPortAudio('Start', pamaster, 0, 0, 1);                                 % Start the master immediately  
        Noise   = (rand([1, round(SampleRate*0.5)])*2)-1;                                         
        Params.Audio.Penalty = PsychPortAudio('OpenSlave', pamaster, 1);            % Create slave channel
        PsychPortAudio('FillBuffer', Params.Audio.Penalty, Noise);             		% Add noise to buffer
    end
    PsychPortAudio('Start', Params.Audio.Penalxty, 1);                               % Play noise

elseif Params.DPx.UseAudio == 1         %================= Play wav file through DataPixx2
    Datapixx('Open');                                   % Open Datapixx
    %Datapixx('StopAllSchedules');
    Datapixx('InitAudio');                              
    Datapixx('SetAudioVolume', 0.75);                	% Don't use full volume
    Datapixx('RegWrRd');                                % Synchronize Datapixx registers to local register cache
    Datapixx('WriteAudioBuffer', waveData, 0);          % Download the entire waveform to address 0.
    if (nChannels == 1)                                 % If the .wav file has a single channel...
        lrMode = 0;                                     % play to both ears in mono mode,
    else
        lrMode = 3;                                     % Otherwise play in stereo mode.
    end
    Datapixx('SetAudioSchedule', 0, freq, nTotalFrames*repetitions, lrMode, 0, nTotalFrames);
    Datapixx('StartAudioSchedule');                     % Start the playback
    Datapixx('RegWrRd');                                % Synchronize Datapixx registers to local register cache
    if (exist('OCTAVE_VERSION'))    
        fflush(stdout);
    end
end