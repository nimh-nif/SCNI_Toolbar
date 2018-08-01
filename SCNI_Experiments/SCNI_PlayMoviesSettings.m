%======================= SCNI_PlayMoviesSettings.m
%========================Play
% This function provides a graphical user interface for setting parameters 
% related to the presentation of movie stimuli. Parameters can be saved and 
% loaded, and the updated parameters are returned in the structure 'Params'.
%
% INPUTS:
%   DefaultInputs: 	optional string containing full path of .mat
%                 	file containing previously saved parameters.
% OUTPUT:
%   Params.Movie.: Structure containing movie settings
%
%==========================================================================

function ParamsOut = SCNI_PlayMoviesSettings(ParamsFile, OpenGUI)

persistent Params Fig;

%============ Initialize GUI
GUItag      = 'SCNI_MovieSettings';            % String to use as GUI window tag
Fieldname   = 'Movie';                         % Params structure fieldname for Movie info
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
if Success < 1                                          	% If the parameters could not be loaded...
    Params.Movie.Dir            = '/projects/murphya/Stimuli/Movies/MonkeyThieves1080p/Season 1/';
    Params.Movie.AllFiles       = wildcardsearch(Params.Movie.Dir, '*.mp4');
    Params.Movie.CurrentFile    = Params.Movie.AllFiles{randi(numel(Params.Movie.AllFiles))};
    [~,Params.Movie.Filename]   = fileparts(Params.Movie.CurrentFile);
    Params.Movie.Duration       = 300;                      % Duration of each movie file to play (seconds). Whole movie plays if empty.
    Params.Movie.PlayMultiple   = 1;                        % Play multiple different movie files consecutively?
    Params.Movie.ISI            = 0;                        % Delay between consecutive movies (seconds)
    Params.Movie.SBS            = 0;                        % Are movies in side-by-side stereoscopic 3D format?
    Params.Movie.Fullscreen     = 0;                        % Scale the movie to fill the display screen?
    Params.Movie.AudioOn        = 1;                        % Play accompanying audio with movie?
    Params.Movie.AudioVol       = 1;                        % Set proportion of volume to use
    Params.Movie.VolInc         = 0.1;                      % Volume change increments (proportion) when set by experimenter
    Params.Movie.Loop           = 0;                        % Loop playback of same movie if it reaches the end before the set playback duration?
    Params.Movie.Background     = [0,0,0];                  % Color (RGB) of background for non-fullscreen movies
    Params.Movie.Rate           = 1;                        % Rate of movie playback as proportion of original fps (range -1:1)
    Params.Movie.StartTime      = 1;                        % Movie playback starts at time (seconds)
    Params.Movie.Scale          = 0.8;                      % Proportion of original size to present movie at
    Params.Movie.Paused         = 0;
    
    %============== Keyboard shortcuts
    KbName('UnifyKeyNames');
    KeyNames                    = {'Space','X','uparrow','downarrow'};         
    KeyFunctions                = {'Pause','Stop','VolUp','VolDown'};
    Params.Movie.KeysList       = zeros(1,256); 
    for k = 1:numel(KeyNames)
        eval(sprintf('Params.Movie.Keys.%s = KbName(''%s'');', KeyFunctions{k}, KeyNames{k}));
        eval(sprintf('Params.Movie.KeysList(Params.Movie.Keys.%s) = 1;', KeyFunctions{k}));
        fprintf('Press ''%s'' for %s\n', KeyNames{k}, KeyFunctions{k});
    end
    
    %============== Behavioural parameters
    Params.Movie.GazeRectBorder = 2;                        % Distance of gaze window border from edge of movie frame (degrees)
    Params.Movie.FixOn          = 0;                        % Present a fixtion marker during movie playback?
    Params.Movie.PreCalib       = 0;                        % Run a quick 9-point calibration routine prior to movie onset?
    Params.Movie.Reward         = 1;                        % Give reward during movie?
    Params.Movie.FixRequired    = 1;                        % Require fixation criterion to be met for reward?
    
end

