function ParamsOut = SCNI_EyeCalibSettings(ParamsFile, OpenGUI)

%========================= SCNI_EyeCalibSettings.m ========================
%
%
%

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
if Success < 1 || ~isfield(Params, 'Eye')                                         	% If the parameters could not be loaded...
    
    Params.Eye.ChannelNames     =  {'Left eye X', 'Left eye Y', 'Left eye pupil', 'Right eye X', 'Right eye Y', 'Right eye pupil'};
    for ch = 1:numel(Params.Eye.ChannelNames)
        ChIndx = find(~cellfun(@isempty, strfind(Params.DPx.AnalogInLabels, Params.Eye.ChannelNames{ch})));
        if ~isempty(ChIndx)
            Params.Eye.DPxChannels(ch) = ChIndx;
        else
            Params.Eye.DPxChannels(ch) = 0;
        end
    end
    Params.Eye.Labels       = {'Left','Right','Version','Vergence'};
    Params.Eye.Offset       = {[0, 0], [0,0],[0,0],[0,0]};
    Params.Eye.Gain         = {[0, 0], [0,0],[0,0],[0,0]};
    Params.Eye.Sign         = {1, 1, 1, 1};


    Params.Eye.CalModes         = {'Manual calibration','Auto calibration','Fix. training - staircase'};
    Params.Eye.CalMode          = 1;
    Params.Eye.CalTypes         = {'Grid','Radial'};
    Params.Eye.CalType          = 1;
    Params.Eye.NoPoints         = {(3:2:9).^2, 9:8:33};
    Params.Eye.NoPoint          = 1;
    Params.Eye.MarkerTypes      = {'Dot', 'Image', 'Movie'};
    Params.Eye.MarkerType       = 1;
    Params.Eye.MarkerDir        = '/projects/murphya/Stimuli/2D_Images/MacaqueFaces/';
    Params.Eye.MarkerDiam       = 2;                                                        % Fixation marker diameter (degrees)
    Params.Eye.MarkerColor      = [1,1,1];              
    Params.Eye.MarkerContrast   = 1;
    Params.Eye.Duration         = 1000;                     % Duration of each target presentation (ms)
    Params.Eye.TimeToFix        = 300;                      % Time from stimulu sonset for subject to fixate target before abort (ms)
    Params.Eye.FixDur           = [];                       % Duration taregt must be fixated for valid trial (default = until target disappears)
    Params.Eye.FixDist          = 4;                        % Maximum distance gaze can stray from center of target (degrees)
    
    
end


ParamsOut = Params;
