%=========================== SCNI_RewardSettings.m ===========================
% This function provides a graphical user interface for setting parameters 
% related to liquid reward delivery. Parameters can be saved and loaded, 
% and the updated parameters are returned in the structure 'Params'.
%
% INPUTS:
%   DefaultInputs: 	optional string containing full path of .mat
%                 	file containing previously saved parameters.
% OUTPUT:
%   Params.Reward.: Structure containing reward settings
%
%==========================================================================

function ParamsOut = SCNI_RewardSettings(ParamsFile, OpenGUI)

persistent Params Fig;

%============ Initialize GUI
GUItag      = 'SCNI_RewardSettings';            % String to use as GUI window tag
Fieldname   = 'Reward';                         % Params structure fieldname for Reward info
if ~exist('OpenGUI','var')
    OpenGUI = 1;
end
if ~exist('ParamsFile','var')
    ParamsFile = [];
elseif exist('ParamsFile','var')
    if ischar(ParamsFile) && exist(ParamsFile, 'file')
        Params      = loead(ParamsFile);
    elseif isstruct(ParamsFile)
        Params      = ParamsFile;
        ParamsFile  = Params.File;
    end
end
[Params, Success, Fig]   = SCNI_InitGUI(GUItag, Fieldname, ParamsFile, OpenGUI);

%=========== Load default parameters
if Success < 1                                                      % If the parameters could not be loaded...
    Params.Reward.TaskTypes         = {'Fixation','Saccade to target','Lever press'};
    Params.Reward.TaskType          = 1;
    Params.Reward.Contingencies     = {'Time-based','Trial-based'};
    Params.Reward.Contingency       = 1;
    
    Params.Reward.Proportion        = 0.7;                          % Set proportion of reward interval that fixation must be maintained for (0-1)
    Params.Reward.MeanIRI           = 4;                            % Set mean interval between reward delivery (seconds)
    Params.Reward.RandIRI           = 2;                            % Set random jitter between reward delivery intervals (seconds)
    Params.Reward.LastRewardTime    = GetSecs;                      % Initialize last reward delivery time (seconds)
    Params.Reward.NextRewardInt     = Params.Reward.MeanIRI + rand(1)*Params.Reward.RandIRI;           	% Generate random interval before first reward delivery (seconds)
    Params.Reward.TTLDur            = 0.05;                         % Set TTL pulse duration (seconds)
    Params.Reward.TTLnumber         = 1;                            % Set how many TTL pulses to send per reward
    Params.Reward.RunCount          = 0;                            % Count how many reward delvieries in this run
    
%     Params.Audio.Penalty.Type       = 'noise';
%     Params.Audio.Penalty.Duration   = 0.5;
%     Params.Audio.Penalty.Volume     = 1;
%     Params.Audio.Penalty.WavFile    = '/projects/murphya/MacaqueFace3D/Macaque_video/OriginalWAVs/BE_Scream_mov64.wav';
    
end

if isfield(Params,'DPx')
    Params.Reward.OutputChannel     = find(Params.DPx.DigitalOutAssign==1);
end

ParamsOut = Params;