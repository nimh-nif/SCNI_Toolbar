%======================= SCNI_PlayMoviesSettings.m ========================
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
        Params      = load(ParamsFile);
    elseif isstruct(ParamsFile)
        Params      = ParamsFile;
        ParamsFile  = Params.File;
    end
end
[Params, Success, Fig]   = SCNI_InitGUI(GUItag, Fieldname, ParamsFile, OpenGUI);

%=========== Load default parameters
if Success < 1 || ~isfield(Params, 'Movie')                                         	% If the parameters could not be loaded...
    Params.Movie.Dir            = '/projects/murphya/Stimuli/Movies/MonkeyThieves1080p/';
    Params.Movie.RunDuration    = 300;                      % Duration of each run of the experiment
    Params.Movie.Duration       = 10;                       % Duration of each movie file to play (seconds). Whole movie plays if empty.
    Params.Movie.PlayMultiple   = 1;                        % Play multiple different movie files consecutively?
    Params.Movie.ISI            = 0;                        % Delay between consecutive movies (seconds)
    Params.Movie.SBS            = 0;                        % Are movies in side-by-side stereoscopic 3D format?
    Params.Movie.Dome           = 0;                        % Are movies formatted for the dome, or require real-time warping?
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
    Params.Movie.FileFormats    = {'.mp4','.mpg','.wmv','.mov','.avi'};   	% What file format are the movies?
    Params.Movie.FileFormat     = 1;
    Params.Movie.SubdirOpts     = {'Ignore','Load','Conditions'};           % How to treat subdirectories found in Params.Movie.Dir?
    Params.Movie.SubdirOpt      = 3;
    Params.Movie.FixTypes       = {'None','Dot','Square','Cross','Binocular'};
    Params.Movie.FixType        = 1;
    Params.Movie.FixSize        = 1;
    Params.Movie.FixColor       = [1,1,1];
    Params.Movie.Rotation       = 0;
    Params.Movie.Contrast       = 1;
    Params.Movie.SizeDeg        = [15, 10];
    Params.Movie.FirstFrameDur  = [];                       % Duration to play static image of first frame for (ms)
    
    %============== Behavioural parameters
    Params.Movie.GazeRectBorder = 2;                        % Distance of gaze window border from edge of movie frame (degrees)
    Params.Movie.FixOn          = Params.Movie.FixType>1; 	% Present a fixtion marker during movie playback?
    Params.Movie.PreCalib       = 0;                        % Run a quick 9-point calibration routine prior to movie onset?
    Params.Movie.Reward         = 1;                        % Give reward during movie?
    Params.Movie.FixRequired    = 1;                        % Require fixation criterion to be met for reward?
    
end
Params = RefreshMovieList(Params);


%========================= OPEN GUI WINDOW ================================
Fig.Handle          = figure;                                       	% Open new figure window         
setappdata(0,GUItag,Fig.Handle);                                        % Assign tag
Fig.PanelYdim       = 130*Fig.DisplayScale;
Fig.Rect            = [0 200 500 900]*Fig.DisplayScale;              	% Specify figure window rectangle
set(Fig.Handle,     'Name','SCNI: Movie Experiment settings',...    	% Open a figure window with specified title
                    'Tag','SCNI_PlayMoviesSettings',...                 % Set figure tag
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
Fig.PanelNames      = {'Movie selection','Movie transforms','Presentation'};
Fig.PannelHeights   = [200, 220, 240];
BoxPos{1}           = [Fig.Margin, Fig.Rect(4)-Fig.PannelHeights(1)*Fig.DisplayScale-Fig.Margin*2, Fig.Rect(3)-Fig.Margin*2, Fig.PannelHeights(1)*Fig.DisplayScale];   
for i = 2:numel(Fig.PanelNames)
    BoxPos{i}           = [Fig.Margin, BoxPos{i-1}(2)-Fig.PannelHeights(i)*Fig.DisplayScale-Fig.Margin/2, Fig.Rect(3)-Fig.Margin*2, Fig.PannelHeights(i)*Fig.DisplayScale];
end

Fig.UImovies.Labels         = {'Movie directory', 'Movie format', 'Subdirectories', 'Conditions', 'Total movies', 'SBS 3D?','Dome format?'};
Fig.UImovies.Style          = {'Edit','Popup','Popup','Popup','Edit','checkbox','checkbox'};
Fig.UImovies.Defaults       = {Params.Movie.Dir, Params.Movie.FileFormats, Params.Movie.SubdirOpts, Params.Movie.MovieConds, num2str(Params.Movie.TotalMovies), [],[]};
Fig.UImovies.Values         = {isempty(Params.Movie.Dir), Params.Movie.FileFormat, Params.Movie.SubdirOpt, 1, [], Params.Movie.SBS, Params.Movie.Dome};
Fig.UImovies.Enabled        = [0, 1, 1, 1, 1, 1, 1];
Fig.UImovies.Ypos           = [(Fig.PannelHeights(1)-50):-20:10]*Fig.DisplayScale;
Fig.UImovies.Xwidth         = [180, 200]*Fig.DisplayScale;

Fig.UItransform.Labels      = {'Present fullscreen','Retinal subtense (deg)','Image rotation (deg)','Image contrast (%)','Audio on?','Audio volume (%)','Playback rate (%)'};
Fig.UItransform.Style       = {'checkbox','Edit','Edit','Edit','Checkbox','Edit','Edit'};
Fig.UItransform.Defaults    = {[], Params.Movie.SizeDeg(1), Params.Movie.Rotation, Params.Movie.Contrast*100, [], Params.Movie.AudioVol*100, Params.Movie.Rate*100};
Fig.UItransform.Values     	= {Params.Movie.Fullscreen, [], [], [], Params.Movie.AudioOn, [], []};
Fig.UItransform.Enabled     = [1, ~Params.Movie.Fullscreen, 1, 1, 1,1,1,1];
Fig.UItransform.Ypos      	= [(Fig.PannelHeights(2)-50):-20:10]*Fig.DisplayScale;
Fig.UItransform.Xwidth     	= [180, 200]*Fig.DisplayScale;

Fig.UIpresent.Labels        = {'Run duration (s)', 'Duration per movie (s)', 'Inter-stim interval (s)', 'Fixation marker','Fixation size (deg)','Fixation color','Gaze contingent reward','Gaze rect border (deg)','Pre-calibrate','First frame dur (ms)'};
Fig.UIpresent.Style        	= {'Edit','Edit','Edit','Popupmenu','Edit','PushButton','Checkbox','Edit','Checkbox','Edit'};
Fig.UIpresent.Defaults     	= {Params.Movie.RunDuration, Params.Movie.Duration, Params.Movie.ISI, Params.Movie.FixTypes,Params.Movie.FixSize,[],[], Params.Movie.GazeRectBorder, [],Params.Movie.FirstFrameDur};
Fig.UIpresent.Values        = {[],[],[],Params.Movie.FixType,[],[],Params.Movie.FixRequired,[],Params.Movie.PreCalib,[]};
Fig.UIpresent.Enabled       = [1,1,1,1,0,0,1,Params.Movie.FixRequired,1,1];
Fig.UIpresent.Ypos          = [(Fig.PannelHeights(3)-50):-20:10]*Fig.DisplayScale;
Fig.UIpresent.Xwidth        = [180, 200]*Fig.DisplayScale;

Fig.PanelVars(1).Fieldnames     = {'Dir','FileFormat','SubdirOpt','MovieConds','TotalMovies',[],[]};
Fig.PanelVars(2).Fieldnames     = {'Fullscreen','SizeDeg','Rotation','Contrast','AudioOn','AudioVol','Rate'};
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
set(Fig.UIhandle(3,ColIndx), 'BackgroundColor', Params.Movie.FixColor, 'Callback',{@ChangeFixColor, p, n});

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
                Movie   = Params.Movie;
                save(Params.File, 'Movie', '-append');
                
            case 3  %============ Exit settings
                
                %============= Generate design
                Params.Design.Type          = 1;
                Params.Design.NoCond      	= numel(Params.Movie.MovieConds);
                Params.Design.TrialsPerRun	= ceil(Params.Movie.RunDuration/(Params.Movie.Duration+Params.Movie.ISI));
                Params.Design.TotalStim    	= Params.Movie.TotalMovies;             
                Params.Design.StimPerTrial 	= 1;                         	% How many stimuli to present per 'trial' (or reward period)
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
            Params.Movie.Dir	= uigetdir(Params.Movie.Dir,'Select stimulus directory');
            set(Fig.UIhandle(1,1),'string',Params.Movie.Dir);

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
                eval(sprintf('Params.Movie.%s = %d;', Fig.PanelVars(Indx1).Fieldnames{Indx2}, NewValue));
            end
        end
        
     	if Indx1 == 1 && Indx2 <= 3                     % If first 4 controls were updated...
            Params = RefreshMovieList(Params);          % Refresh list of movies
        end
        
        %============= Update GUI controls affected by change
        FrameSizeIndx = find(~cellfun(@isempty, strfind(Fig.PanelVars(2).Fieldnames, 'SizeDeg')));
        if Params.Movie.Fullscreen == 1
            set(Fig.UIhandle(2,FrameSizeIndx),'enable','off');
        elseif Params.Movie.Fullscreen == 0
            set(Fig.UIhandle(2,FrameSizeIndx),'enable','on');
        end
        AudioVolIndx = find(~cellfun(@isempty, strfind(Fig.PanelVars(2).Fieldnames, 'AudioVol')));
     	if Params.Movie.AudioOn == 1
            set(Fig.UIhandle(2,AudioVolIndx),'enable','on');
        elseif Params.Movie.AudioOn == 0
            set(Fig.UIhandle(2,AudioVolIndx),'enable','off');
        end
        FixIndx = [1,2]+find(~cellfun(@isempty, strfind(Fig.PanelVars(3).Fieldnames, 'FixType')));
        if Params.Movie.FixType == 1
            set(Fig.UIhandle(3,FixIndx),'enable','off');
            Params.Movie.FixOn          = 0;
        elseif Params.Movie.FixType > 1
            set(Fig.UIhandle(3,FixIndx),'enable','on');
            Params.Movie.FixOn          = 1;
        end
        GazeRectIndx = find(~cellfun(@isempty, strfind(Fig.PanelVars(3).Fieldnames, 'GazeRectBorder')));
        if Params.Movie.FixRequired == 1
            set(Fig.UIhandle(3,GazeRectIndx),'enable','on');
        elseif Params.Movie.FixRequired == 0
            set(Fig.UIhandle(3,GazeRectIndx),'enable','off');
        end
        
    end


    %====================== Update fixation color
    function ChangeFixColor(hObj, Evnt, Indx1, Indx2)
        Color = uisetcolor;
        if numel(Color>1)
            set(hObj, 'Background', Color);
            Params.Movie.FixColor = Color;
        end  
    end

    %====================== Refresh the list(s) of movies =================
    function Params = RefreshMovieList(Params)
        
        switch Params.Movie.SubdirOpts{Params.Movie.SubdirOpt}
            case 'Load'
                Params.Movie.AllFiles 	= wildcardsearch(Params.Movie.Dir, ['*',Params.Movie.FileFormats{Params.Movie.FileFormat}]);
                Params.Movie.MovieConds  = {''};
                
            case 'Ignore'
                Params.Movie.AllFiles 	= regexpdir(Params.Movie.Dir, Params.Movie.FileFormats{Params.Movie.FileFormat},0);
                Params.Movie.MovieConds  = {''};
                
            case 'Conditions'
                SubDirs                     = dir(Params.Movie.Dir);
                Params.Movie.MovieConds  = {SubDirs([SubDirs.isdir]).name};
                Params.Movie.MovieConds(~cellfun(@isempty, strfind(Params.Movie.MovieConds, '.'))) = [];
                Params.Movie.AllFiles 	= [];
                for cond = 1:numel(Params.Movie.MovieConds)
                    Params.Movie.ImByCond{cond} 	= regexpdir(fullfile(Params.Movie.Dir, Params.Movie.MovieConds{cond}), Params.Movie.FileFormats{Params.Movie.FileFormat},0);
                    Params.Movie.ImByCond{cond}(cellfun(@isempty, Params.Movie.ImByCond{cond})) = [];
                    Params.Movie.AllFiles      = [Params.Movie.AllFiles; Params.Movie.ImByCond{cond}];
                end
        end
        Params.Movie.TotalMovies     = numel(Params.Movie.AllFiles);
        
        %========== Update GUI
        if isfield(Fig, 'UImovies')
            ButtonIndx = find(~cellfun(@isempty, strfind(Fig.UImovies.Labels, 'Conditions')));
            if ~isempty(Params.Movie.MovieConds)
                set(Fig.UIhandle(1,ButtonIndx), 'string', Params.Movie.MovieConds, 'enable', 'on');
            else
                set(Fig.UIhandle(1,ButtonIndx), 'string', {''}, 'enable', 'off');
            end
            StrIndx = find(~cellfun(@isempty, strfind(Fig.UImovies.Labels, 'Total movies')));
            set(Fig.UIhandle(1,StrIndx), 'string', num2str(Params.Movie.TotalMovies));
        end
    end





end

