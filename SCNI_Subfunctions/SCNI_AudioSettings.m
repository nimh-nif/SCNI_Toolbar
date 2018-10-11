%======================= SCNI_AudioSettings.m =============================


function ParamsOut = SCNI_AudioSettings(ParamsFile, OpenGUI)

persistent Params Fig;

%============ Initialize GUI
GUItag      = 'SCNI_EyeCalibSettings';       	% String to use as GUI window tag
Fieldname   = 'Eye';                            % Params structure fieldname for Movie info
if ~exist('OpenGUI','var')
    OpenGUI = 1;
end
if ~exist('ParamsFile','var')
    ParamsFile = [];
elseif exist('ParamsFile','var')
    if ischar(ParamsFile) && exist(ParamsFile, 'file')
        Params      = load(ParamsFile);
    elseif isstruct(ParamsFile)
        Params      = ParamsFile;
        ParamsFile  = Params.File;
    end
end
[Params, Success, Fig]   = SCNI_InitGUI(GUItag, Fieldname, ParamsFile, OpenGUI);

%=========== Load default parameters
if Success < 1 || ~isfield(Params, 'Audio')                                         	% If the parameters could not be loaded...
    Params.Audio.OutputDPx      = Params.DPx.UseAudio;
    Params.Audio.WaveDir        = '/projects/murphya/MacaqueFace3D/Macaque_video/OriginalWAVs/';
    Params.Audio.AllWaveFiles   = wildcardsearch(Params.Audio.WaveDir, '*.wav');
    Params.Audio.NoChannels     = 2;
    Params.Audio.SampleRate     = 44100;
    Params.Audio.Volume         = 1;
    Params.Audio.Functions      = {'TrialStart','AbortTrial','CompleteRun','WakeUp'};
    Params.Audio.TrialStart    	= 1;        % List of possible audio files to play at trial onset
    Params.Audio.AbortTrial     = 2;        % List of possible audio files to play when trial is aborted by subject
    Params.Audio.CompleRun      = 3;        % List of possible audio files to play when run is completed
    Params.Audio.WakeUp         = 4;        % List of possible audio files to play when subject falls asleep



end





Params                      = InitAudio(Params);                  	% Initialize audio buffers



%============ Generate some tones
Params.Audio.Tones(1).Name      = 'FixOn';          % Tone name (e.g. use description)
Params.Audio.Tones(1).Freq      = 500;              % Tone frequency (Hz)
Params.Audio.Tones(1).Dur       = 0.3;              % Tone duration (seconds)
Params.Audio.Tones(1).Vol       = 0.2;              % Tone volume (relative to master volume)
Params.Audio.Tones(1).Type      = 'puretone';         

Params.Audio.Tones(2).Name      = 'Error';       	% Tone name (e.g. use description)
Params.Audio.Tones(2).Freq      = 200;              % Tone frequency (Hz)
Params.Audio.Tones(2).Dur       = 0.3;              % Tone duration (seconds)
Params.Audio.Tones(2).Vol       = 0.5;              % Tone volume (relative to master volume)
Params.Audio.Tones(2).Type      = 'puretone';     

Params.Audio.Tones(3).Name      = 'WakeUp';       	% Tone name (e.g. use description)
Params.Audio.Tones(3).Freq      = 500;              % Tone frequency (Hz)
Params.Audio.Tones(3).Dur       = 0.3;              % Tone duration (seconds)
Params.Audio.Tones(3).Vol       = 0.5;              % Tone volume (relative to master volume)
Params.Audio.Tones(3).Type      = 'white_noise';     

for t = 1:numel(Params.Audio.Tones)
    Params.Audio.Tones(t).Wave      = GenerateWave(Params.Audio.Tones(t), Params);
    Params.Audio.Tones(t).Nframes   = size(Params.Audio.Tones(t).Wave,2);  
    Params.Audio.Tones(t).Handle    = LoadAudio(Params.Audio.Tones(t).Wave, Params);
end



% PlayAudio(Params.Audio.Tones(2), Params)
% PlayAudio(Params.Audio.Wave(1), Params)

ParamsOut = Params;


end

%% =========================== SUBFUNCTIONS ===============================

%============ LOAD ALL .WAV FILES
function Params = LoadWavs(Params)
    for w = 1:numel(Params.Audio.WaveFiles)
        [~,Params.Audio.Wave(w).Name]   = fileparts(Params.Audio.WaveFiles{w});
        [waveData, freq]                = audioread(Params.Audio.WaveFiles{w}); 	% Load the .wav file
        Params.Audio.Wave(w).waveData	= waveData';                              	% Transpose so that each row has 1 channel
        Params.Audio.Wave(w).Freq       = freq;                                     % Check wave sampling frequency
        if Params.Audio.Wave(w).Freq ~= Params.Audio.SampleRate
            Ratio = Params.Audio.SampleRate/Params.Audio.Wave(w).Freq;                      
            Params.Audio.Wave(w).waveData = interp(Params.Audio.Wave(w).waveData, Ratio);   % Interpolate original waveform
        end
        Params.Audio.Wave(w).Handle     = LoadAudio(Params.Audio.Wave(w).waveData, Params);
    end
end

%============= INITIALIZE AUDIO
function Params = InitAudio(Params)

    if Params.DPx.UseAudio == 0         %================= Play wav file through PC audiocard
        InitializePsychSound;                               % Initialize PsychPortAudio at standard latency
        if IsWin
            sugLat = 0.015;                              	% Add 15 msecs latency on Windows, to protect against shoddy drivers
        else
            sugLat = [];                                                            
        end
        Params.Audio.pamaster = PsychPortAudio('Open', [], 1, 0, Params.Audio.SampleRate, Params.Audio.NoChannels, [], sugLat);    
        PsychPortAudio('Start', Params.Audio.pamaster, 0, 0, 1);                  	% Start the master immediately 
        
    elseif Params.DPx.UseAudio == 1   	%================= Play wav file through DataPixx2
        Datapixx('Open');                                   % Open Datapixx
        Datapixx('InitAudio');                              % Initialize audio
        Datapixx('SetAudioVolume', Params.Audio.Volume);  	% Set volume
    end
end

%============= GENERATE TONES OR NOISE WAVEFORMS
function waveData = GenerateWave(Tone, Params)
    switch Tone.Type
        case 'puretone'
            waveData 	= MakeBeep(Tone.Freq, Tone.Dur, Params.Audio.SampleRate);
        case 'white_noise'
        	waveData 	= ((rand([1, round(Tone.Freq*Tone.Dur)])*2)-1);
        case 'pink_noise'
            waveData 	= repmat(pinknoise(Tone.Dur*Params.Audio.SampleRate), [2,1]);
        case 'blue_noise'
            waveData 	= repmat(bluenoise(Tone.Dur*Params.Audio.SampleRate), [2,1]);
        case 'red_noise'
            waveData 	= repmat(rednoise(Tone.Dur*Params.Audio.SampleRate), [2,1]);
    end
    waveData = waveData*Tone.Vol;
end              

%============= LOAD AN AUDIO FILE
function WaveHandle = LoadAudio(waveData, Params)

    if Params.DPx.UseAudio == 0         %================= Play wav file through PC audiocard
        WaveHandle = PsychPortAudio('OpenSlave', Params.Audio.pamaster, 1);       	% Create slave channel
        PsychPortAudio('FillBuffer', WaveHandle, waveData);                       	% Add wave to buffer

    elseif Params.DPx.UseAudio == 1         %================= Play wav file through DataPixx2
        WaveHandle = numel(Params.Audio.Tones)+1;
        Params.Audio.Tones(WaveHandle).Nframes = size(waveData,2);       
        Datapixx('RegWrRd');                                % Synchronize Datapixx registers to local register cache
        Datapixx('WriteAudioBuffer', waveData, WaveHandle); % Download the entire waveform to address 'WaveHandle'.

    end
end

%============= PLAY AN AUDIO FILE
function PlayAudio(Tone, Params)

    if Params.DPx.UseAudio == 0         %================= Play wav file through PC audiocard
        PsychPortAudio('Start', Tone.Handle, 1);            % Play wave form

    elseif Params.DPx.UseAudio == 1         %================= Play wav file through DataPixx2
        if (Params.Audio.NoChannels == 1)                 	% If the .wav file has a single channel...
            lrMode = 0;                                     % play to both ears in mono mode,
        else
            lrMode = 3;                                     % Otherwise play in stereo mode.
        end
        Datapixx('SetAudioSchedule', Tone.Handle, Params.Audio.SampleRate, Tone.Nframes, lrMode, 0, Tone.Nframes);
        Datapixx('StartAudioSchedule');                     % Start the playback
        Datapixx('RegWrRd');                                % Synchronize Datapixx registers to local register cache
    end
end