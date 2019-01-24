%=================== SCNI_TemporalContinuitySettings.m ====================
% This function provides a graphical user interface for setting parameters 
% related to the presentation of movie stimuli. Parameters can be saved and 
% loaded, and the updated parameters are returned in the structure 'Params'.
%
% INPUTS:
%   DefaultInputs: 	optional string containing full path of .mat
%                 	file containing previously saved parameters.
% OUTPUT:
%   Params.TC.: Structure containing TC experiment settings
%
%==========================================================================

function ParamsOut = SCNI_TemporalContinuitySettings(ParamsFile, OpenGUI)

persistent Params Fig;

%============ Initialize GUI
GUItag      = 'SCNI_TCSettings';                % String to use as GUI window tag
Fieldname   = 'TC';                             % Params structure fieldname for TemporalContinuity info
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
[Params, Success, Fig]   = SCNI_InitGUI(GUItag, Fieldname, Params, OpenGUI);

%=========== Load default parameters
if Success < 1 || ~isfield(Params, 'TC')                                         	% If the parameters could not be loaded...
    Params.TC.Dir            = '/projects/murphya/Stimuli/AvatarRenders_2018/';     % Parent directory for stimuli
    Params = GetExpDirs(Params);
    Params.TC.ExpDir         = 1;
    Params.TC.BackgroundDir  = '/projects/murphya/Stimuli/AvatarRenders_2018/';     % Background image directory
    Params.TC.Resolution     = [0, 0];
    Params.TC.FPS            = 30;
    Params.TC.SBS            = 0;                                                   % Are movies in side-by-side stereoscopic 3D format?
    Params.TC.Dome           = 0;                                                   % Are movies formatted for the dome, or require real-time warping?
    Params.TC.Fullscreen     = 0;                                                   % Scale the movie to fill the display screen?
    Params.TC.AudioOn        = 1;                                                   % Play accompanying audio with movie?
    Params.TC.AudioVol       = 1;                                                   % Set proportion of volume to use
    Params.TC.VolInc         = 0.1;                                                 % Volume change increments (proportion) when set by experimenter
    Params.TC.Loop           = 0;                                                   % Loop playback of same movie if it reaches the end before the set playback duration?
    Params.TC.Background     = [0,0,0];                                             % Color (RGB) of background for non-fullscreen movies
    Params.TC.Rate           = 1;                                                   % Rate of movie playback as proportion of original fps (range -1:1)

    Params.TC.BlockTypes     = {'1) Random static','2) Natural static','3) Movie clips shuffled','4) Movie clips intermittent','5) Natural movie'};
    Params.TC.Blocks         = 1;
    Params.TC.FileFormats    = {'.mp4','.mpg','.wmv','.mov','.avi'};                % What file format are the movies?
    Params.TC.FileFormat     = 1;
    Params.TC.SubdirOpts     = {'Ignore','Load','Conditions'};                      % How to treat subdirectories found in Params.TC.Dir?
    Params.TC.SubdirOpt      = 3;
    Params.TC.FixTypes       = {'None','Dot','Square','Cross','Binocular'};         
    Params.TC.FixType        = 1;
    Params.TC.FixPositions   = {'Central stationary','Peripheral stationary','At stimulus depth'};
    Params.TC.FixPosition    = 1;
    Params.TC.FixSize        = 1;
    Params.TC.FixColor       = [1,1,1];
    Params.TC.Rotation       = 0;
    Params.TC.Contrast       = 1;
    Params.TC.GreyScale      = 0;
    Params.TC.SizeDeg        = [15, 10];

    %============== Timing parameters
    Params.TC.ImageDur          = 300;                              % Duration to present each static image or movie snippet for (ms)
    Params.TC.ISI               = 300;                              % Duration of interval between images or movie snippets (ms)
    Params.TC.BlockDuration     = 20;                               % Duration of each block (seconds)
    Params.TC.IBI               = 2;                                % Duration of inter-block interval (seconds)
    Params.TC.BlocksPerRun      = 10;                               % Number of blocks per run
    
    %============== Behavioural parameters
    Params.TC.GazeRectBorder = 2;                                   % Distance of gaze window border from edge of movie frame (degrees)
    Params.TC.FixOn          = Params.TC.FixType>1;                 % Present a fixtion marker during movie playback?
    Params.TC.PreCalib       = 0;                                   % Run a quick 9-point calibration routine prior to movie onset?
    Params.TC.Reward         = 1;                                   % Give reward during movie?
    Params.TC.FixRequired    = 1;                                   % Require fixation criterion to be met for reward?
    
end
if OpenGUI == 0
    ParamsOut = Params;
    return;
end
Params = GetExpDirs(Params);
Params = LoadStimInfo(Params);
Params = GetMovieFiles(Params);
Params = RefreshGUI(Params);


%========================= OPEN GUI WINDOW ================================
Fig.Handle          = figure;                                       	% Open new figure window         
setappdata(0,GUItag,Fig.Handle);                                        % Assign tag
Fig.PanelYdim       = 130*Fig.DisplayScale;
Fig.Rect            = [0 200 500 900]*Fig.DisplayScale;              	% Specify figure window rectangle
set(Fig.Handle,     'Name','SCNI: Temporal Continuity Experiment settings',...    	% Open a figure window with specified title
                    'Tag','SCNI_TemporalContinuitySettings',...         % Set figure tag
                    'Renderer','OpenGL',...                             % Use OpenGL renderer
                    'OuterPosition', Fig.Rect,...                       % position figure window
                    'NumberTitle','off',...                             % Remove figure number from title
                    'Resize', 'off',...                                 % Prevent resizing of GUI window
                    'Menu','none',...                                   % Turn off memu
                    'Toolbar','none');                                  % Turn off toolbars to save space
Fig.Background  = get(Fig.Handle, 'Color');                           	% Get default figure background color
Fig.Margin      = 20*Fig.DisplayScale;                               	% Set margin between UI panels (pixels)                                 
Fig.Fields      = fieldnames(Params);                                 	% Get parameter field names
Fig.FontSize    = 16;
Fig.TitleFontSize = 18;

%============= Prepare GUI panels
Fig.PanelNames      = {'Stimulus selection','Stimulus transforms','Presentation'};
Fig.PannelHeights   = [220, 220, 280];
BoxPos{1}           = [Fig.Margin, Fig.Rect(4)-Fig.PannelHeights(1)*Fig.DisplayScale-Fig.Margin*2, Fig.Rect(3)-Fig.Margin*2, Fig.PannelHeights(1)*Fig.DisplayScale];   
for i = 2:numel(Fig.PanelNames)
    BoxPos{i}           = [Fig.Margin, BoxPos{i-1}(2)-Fig.PannelHeights(i)*Fig.DisplayScale-Fig.Margin/2, Fig.Rect(3)-Fig.Margin*2, Fig.PannelHeights(i)*Fig.DisplayScale];
end

Fig.UImovies.Labels         = {'Parent directory', 'Stimulus set','File format', 'Total movies','Conditions', 'Resolution (pixels)', 'Frame rate (fps)', 'SBS 3D?','Dome format?'};
Fig.UImovies.Style          = {'Edit','Popup','Popup','Edit','Popup','Edit','Edit','checkbox','checkbox'};
Fig.UImovies.Defaults       = {Params.TC.Dir, Params.TC.ExpDirs, Params.TC.FileFormats, num2str(Params.TC.TotalMovies), Params.TC.MovieFiles, sprintf('%d x %d', Params.TC.Resolution), Params.TC.FPS,  [],[]};
Fig.UImovies.Values         = {isempty(Params.TC.Dir), Params.TC.ExpDir,Params.TC.FileFormat, [], 1, [], [], Params.TC.SBS, Params.TC.Dome};
Fig.UImovies.Enabled        = [0, 1, 1, 1, 1, 0, 0, 1, 1];
Fig.UImovies.Ypos           = [(Fig.PannelHeights(1)-50):-20:10]*Fig.DisplayScale;
Fig.UImovies.Xwidth         = [180, 200]*Fig.DisplayScale;

Fig.UItransform.Labels      = {'Present fullscreen','Retinal subtense (deg)','Image rotation (deg)','Image contrast (%)','Grey scale?','Audio on?','Audio volume (%)','Playback rate (%)'};
Fig.UItransform.Style       = {'checkbox','Edit','Edit','Edit','Checkbox','Checkbox','Edit','Edit'};
Fig.UItransform.Defaults    = {[], Params.TC.SizeDeg(1), Params.TC.Rotation, Params.TC.Contrast*100, [], [], Params.TC.AudioVol*100, Params.TC.Rate*100};
Fig.UItransform.Values     	= {Params.TC.Fullscreen, [], [], [], Params.TC.GreyScale, Params.TC.AudioOn, [], []};
Fig.UItransform.Enabled     = [1, ~Params.TC.Fullscreen, 1, 1, 1, 1,1,1,1];
Fig.UItransform.Ypos      	= [(Fig.PannelHeights(2)-50):-20:10]*Fig.DisplayScale;
Fig.UItransform.Xwidth     	= [180, 200]*Fig.DisplayScale;

Fig.UIpresent.Labels        = {'Presentation mode', 'Image/ clip duration (ms)', 'ISI (ms)','Block duration (s)','Blocks per run', 'Fixation marker','Fixation size (deg)','Fixation color','Gaze contingent reward','Gaze rect border (deg)','Pre-calibrate'};
Fig.UIpresent.Style        	= {'Popup','Edit','Edit','Edit','Edit','Popupmenu','Edit','PushButton','Checkbox','Edit','Checkbox'};
Fig.UIpresent.Defaults     	= {Params.TC.BlockTypes, Params.TC.ImageDur, Params.TC.ISI, Params.TC.BlockDuration, Params.TC.BlocksPerRun, Params.TC.FixTypes,Params.TC.FixSize,[],[], Params.TC.GazeRectBorder, []};
Fig.UIpresent.Values        = {Params.TC.Blocks, [],[],[],[],Params.TC.FixType,[],[],Params.TC.FixRequired,[],Params.TC.PreCalib};
Fig.UIpresent.Enabled       = [1,1,1,1,1,1,0,0,1,Params.TC.FixRequired,1];
Fig.UIpresent.Ypos          = [(Fig.PannelHeights(3)-50):-20:10]*Fig.DisplayScale;
Fig.UIpresent.Xwidth        = [180, 200]*Fig.DisplayScale;

Fig.PanelVars(1).Fieldnames     = {'Dir','ExpDir','FileFormat','TotalMovies','MovieConds','Resolution','SBS','Dome'};
Fig.PanelVars(2).Fieldnames     = {'Fullscreen','SizeDeg','Rotation','Contrast','GreyScale','AudioOn','AudioVol','Rate'};
Fig.PanelVars(3).Fieldnames     = {'RunDuration','Duration','ISI','FixType','FixSize','','FixRequired','GazeRectBorder','PreCalib','FirstFrameDur'};

OfforOn         = {'Off','On'};
PanelStructs    = {Fig.UImovies, Fig.UItransform, Fig.UIpresent};

for p = 1:numel(Fig.PanelNames)
    Fig.PannelHandl(p) = uipanel( 'Title',Fig.PanelNames{p},...
                'FontSize',Fig.TitleFontSize,...
                'BackgroundColor',Fig.Background,...
                'Units','pixels',...
                'Position',BoxPos{p},...
                'Parent',Fig.Handle); 
            
    for n = 1:numel(PanelStructs{p}.Labels)
        uicontrol(  'Style', 'text',...
                    'String',PanelStructs{p}.Labels{n},...
                    'Position', [Fig.Margin, PanelStructs{p}.Ypos(n), PanelStructs{p}.Xwidth(1), 20*Fig.DisplayScale],...
                    'Parent', Fig.PannelHandl(p),...
                    'HorizontalAlignment', 'left',...
                    'FontSize', Fig.FontSize);
        Fig.UIhandle(p,n) = uicontrol(  'Style', PanelStructs{p}.Style{n},...
                    'String', PanelStructs{p}.Defaults{n},...
                    'Value', PanelStructs{p}.Values{n},...
                    'Enable', OfforOn{PanelStructs{p}.Enabled(n)+1},...
                    'Position', [Fig.Margin + PanelStructs{p}.Xwidth(1), PanelStructs{p}.Ypos(n), PanelStructs{p}.Xwidth(2), 20*Fig.DisplayScale],...
                    'Parent', Fig.PannelHandl(p),...
                    'HorizontalAlignment', 'left',...
                    'FontSize', Fig.FontSize,...
                    'Callback', {@UpdateParams, p, n});
        if p == 1 && n == 1
            uicontrol(  'Style', 'pushbutton',...
                        'string','...',...
                        'Parent', Fig.PannelHandl(p),...
                        'Position', [Fig.Margin + 20+ sum(PanelStructs{p}.Xwidth([1,2])), PanelStructs{p}.Ypos(n), 20*Fig.DisplayScale, 20*Fig.DisplayScale],...
                        'Callback', {@UpdateParams, p, n});
        end


    end
end

ColIndx = find(~cellfun(@isempty, strfind(Fig.UIpresent.Labels, 'Fixation color')));
set(Fig.UIhandle(3,ColIndx), 'BackgroundColor', Params.TC.FixColor, 'Callback',{@ChangeFixColor, p, n});

%================= OPTIONS PANEL
uicontrol(  'Style', 'pushbutton',...
            'String','Load Params',...
            'parent', Fig.Handle,...
            'tag','Load Params',...
            'units','pixels',...
            'Position', [Fig.Margin,20*Fig.DisplayScale,100*Fig.DisplayScale,30*Fig.DisplayScale],...
            'TooltipString', 'Load movie params',...
            'FontSize', Fig.FontSize, ...
            'HorizontalAlignment', 'left',...
            'Callback', {@OptionSelect, 1});   
uicontrol(  'Style', 'pushbutton',...
            'String','Save Params',...
            'parent', Fig.Handle,...
            'tag','Save Params',...
            'units','pixels',...
            'Position', [140,20,100,30]*Fig.DisplayScale,...
            'TooltipString', 'Save current parameters to file',...
            'FontSize', Fig.FontSize, ...
            'HorizontalAlignment', 'left',...
            'Callback', {@OptionSelect, 2});    
uicontrol(  'Style', 'pushbutton',...
            'String','Continue',...
            'parent', Fig.Handle,...
            'tag','Continue',...
            'units','pixels',...
            'Position', [260,20,100,30]*Fig.DisplayScale,...
            'TooltipString', 'Continue to run SCNI_PlayMovies.m',...
            'FontSize', Fig.FontSize, ...
            'HorizontalAlignment', 'left',...
            'Callback', {@OptionSelect, 3});  

uiwait(Fig.Handle);     % Wait until GUI window is closed beofre returning Params
ParamsOut = Params;     % Output 'Params' struct

%% ========================== SUBFUNCTIONS ================================

    %==================== User selected option
    function OptionSelect(hObj, Event, Indx)
        switch Indx
            case 1  %============ Load movies?

                
            case 2  %============ Save parameters to file
                TC   = Params.TC;
                save(Params.File, 'TC', '-append');
                
            case 3  %============ Exit settings
                
                %============= Generate design
                Params.Design.Type          = 1;
                Params.Design.NoCond      	= numel(Params.TC.MovieConds);
                Params.Design.TrialsPerRun	= ceil(Params.TC.RunDuration/(Params.TC.Duration+Params.TC.ISI));
                Params.Design.TotalStim    	= Params.TC.TotalMovies;             
                Params.Design.StimPerTrial 	= 1;                                % How many stimuli to present per 'trial' (or reward period)
                Params                      = SCNI_GenerateDesign(Params, 0);   
                
                ParamsOut = Params;
                close(Fig.Handle);
                return;
        end
    end

    %=============== Update parameters
    function UpdateParams(hObj, Evnt, Indx1, Indx2)

      	%============= Panel 1 controls for directory selection
        if Indx1 == 1 && Indx2 == 1         %===== Change image directory
            Params.TC.Dir	= uigetdir(Params.TC.Dir,'Select stimulus directory');
            set(Fig.UIhandle(1,1),'string',Params.TC.Dir);

        else                                %============= All other controls
            if ~isempty(Fig.PanelVars(Indx1).Fieldnames{Indx2})
                switch get(hObj,'style')
                    case 'edit'
                        NewValue = str2num(get(hObj, 'string'));
                    case 'checkbox'
                        NewValue = get(hObj, 'value');
                    case 'popupmenu'
                        NewValue = get(hObj, 'value');
                end
                if ~cellfun(@isempty, strfind({'Contrast','AudioVol','Rate'}, Fig.PanelVars(Indx1).Fieldnames{Indx2}))
                    NewValue = NewValue/100;            % Change percentage values to proportions
                end
                eval(sprintf('Params.TC.%s = %d;', Fig.PanelVars(Indx1).Fieldnames{Indx2}, NewValue));
            end
        end
        
     	if Indx1 == 1                                   % If first 4 controls were updated...
            switch Indx2
                case 1
                    Params = GetExpDirs(Params);
                case 2
                    Params = LoadStimInfo(Params);
                    Params = GetMovieFiles(Params);
                case 3
                    Params = GetMovieFiles(Params);
            end
            Params = RefreshGUI(Params);          % Refresh list of movies
        end
        
        %============= Update GUI controls affected by change
        FrameSizeIndx = find(~cellfun(@isempty, strfind(Fig.PanelVars(2).Fieldnames, 'SizeDeg')));
        if Params.TC.Fullscreen == 1
            set(Fig.UIhandle(2,FrameSizeIndx),'enable','off');
        elseif Params.TC.Fullscreen == 0
            set(Fig.UIhandle(2,FrameSizeIndx),'enable','on');
        end
        AudioVolIndx = find(~cellfun(@isempty, strfind(Fig.PanelVars(2).Fieldnames, 'AudioVol')));
     	if Params.TC.AudioOn == 1
            set(Fig.UIhandle(2,AudioVolIndx),'enable','on');
        elseif Params.TC.AudioOn == 0
            set(Fig.UIhandle(2,AudioVolIndx),'enable','off');
        end
        FixIndx = [1,2]+find(~cellfun(@isempty, strfind(Fig.PanelVars(3).Fieldnames, 'FixType')));
        if Params.TC.FixType == 1
            set(Fig.UIhandle(3,FixIndx),'enable','off');
            Params.TC.FixOn          = 0;
        elseif Params.TC.FixType > 1
            set(Fig.UIhandle(3,FixIndx),'enable','on');
            Params.TC.FixOn          = 1;
        end
        GazeRectIndx = find(~cellfun(@isempty, strfind(Fig.PanelVars(3).Fieldnames, 'GazeRectBorder')));
        if Params.TC.FixRequired == 1
            set(Fig.UIhandle(3,GazeRectIndx),'enable','on');
        elseif Params.TC.FixRequired == 0
            set(Fig.UIhandle(3,GazeRectIndx),'enable','off');
        end
        
    end


    %====================== Update fixation color
    function ChangeFixColor(hObj, Evnt, Indx1, Indx2)
        Color = uisetcolor;
        if numel(Color>1)
            set(hObj, 'Background', Color);
            Params.TC.FixColor = Color;
        end  
    end

    %====================== Get Experiment directories
    function Params = GetExpDirs(Params)
        Params.TC.ExpDir = 1;
      	ExpDirs = dir(Params.TC.Dir);
        ExpDirs = {ExpDirs.name};
        Params.TC.ExpDirs = ExpDirs(cellfun(@isempty, strfind(ExpDirs,'.')));
    end

    %====================== Get stimulus info
    function Params = LoadStimInfo(Params)
        StimDir         = fullfile(Params.TC.Dir, Params.TC.ExpDirs{Params.TC.ExpDir}, 'Movies');
        StimDir
        StimInfoFile    = wildcardsearch(StimDir, 'StimInfo.mat');
        if ~isempty(StimInfoFile)
            si  = load(StimInfoFile{1});
            Params.TC.StimInfo = si.StimInfo;
        else
            fprintf('No stimulus info ("StimInfo*.mat") file found for %s!\n', Params.TC.ExpDirs{Params.TC.ExpDir});
        end
    end

    %====================== Get movie files from selected directory
    function Params = GetMovieFiles(Params)
        if isfield(Params.TC, 'StimInfo') && ~isempty(Params.TC.StimInfo)
            StimDir                 = fullfile(Params.TC.Dir, Params.TC.ExpDirs{Params.TC.ExpDir},'Movies');
            Params.TC.MovieFiles	= wildcardsearch(StimDir, ['*',Params.TC.FileFormats{Params.TC.FileFormat}]);
            for m = 1:numel(Params.TC.MovieFiles)
                [~,Params.TC.MovieFiles{m}] = fileparts(Params.TC.MovieFiles{m});
            end
            Params.TC.TotalMovies 	= numel(Params.TC.MovieFiles);
        else
            Params.TC.MovieFiles	= {''};
            Params.TC.TotalMovies 	= 0;
        end
        
    end

    %====================== Refresh the list(s) of movies =================
    function Params = RefreshGUI(Params)
        if isfield(Fig, 'UImovies')
            ButtonIndx = find(~cellfun(@isempty, strfind(Fig.UImovies.Labels, 'Conditions')));

            if Params.TC.TotalMovies > 0
                set(Fig.UIhandle(1,ButtonIndx), 'string', Params.TC.MovieFiles, 'enable', 'on');
            else
                set(Fig.UIhandle(1,ButtonIndx), 'string', {''}, 'enable', 'off');
            end
            StrIndx = find(~cellfun(@isempty, strfind(Fig.UImovies.Labels, 'Total movies')));
            set(Fig.UIhandle(1,StrIndx), 'string', num2str(Params.TC.TotalMovies));
            
        end
    end

    %====================== 
    function Params = CheckMovieParams(Params)
        


    end

end

