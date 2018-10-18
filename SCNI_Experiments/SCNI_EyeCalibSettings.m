function ParamsOut = SCNI_EyeCalibSettings(ParamsFile, OpenGUI)

%========================= SCNI_EyeCalibSettings.m ========================
% This function provides a graphical user interface for setting parameters 
% related to eye tracker calibration. Parameters can be saved and loaded, 
% and the updated parameters are returned in the structure 'Params'.
%
%==========================================================================

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

[Params, Success, Fig]   = SCNI_InitGUI(GUItag, Fieldname, Params, OpenGUI);

%=========== Load default parameters
if Success < 1 || ~isfield(Params, 'Eye')                                         	% If the parameters could not be loaded...
    
    Params.Eye.ChannelNames     =  {'Left eye X', 'Left eye Y', 'Left eye pupil', 'Right eye X', 'Right eye Y', 'Right eye pupil'};
    for ch = 1:numel(Params.Eye.ChannelNames)
        ChIndx = find(~cellfun(@isempty, strfind(Params.DPx.AnalogInLabels, Params.Eye.ChannelNames{ch})));
        if ~isempty(ChIndx)
            Params.Eye.DPxChannels(ch) = ChIndx;
        else
            Params.Eye.DPxChannels(ch) = NaN;
        end
    end
    Params.Eye.CalibFile        = '';
    Params.Eye.XYchannels     	= {Params.Eye.DPxChannels([1,2]), Params.Eye.DPxChannels([4,5])};
    Params.Eye.Pupilchannels 	= {Params.Eye.DPxChannels(3), Params.Eye.DPxChannels(6)};
    Params.Eye.Cal.Labels       = {'Left','Right','Version','Vergence'};
    Params.Eye.Cal.Offset       = {[0,0],[0,0],[0,0],[0,0]};
    Params.Eye.Cal.Gain         = {[6,6],[6,6],[6,6],[6,6]};
    Params.Eye.Cal.Sign         = {[1,1], [1,1], [1,1], [1,1]};
    Params.Eye.EyeToUse         = 1;
    Params.Eye.CalModes         = {'Mouse simulation','Manual calibration','Auto calibration','Fix. training - staircase'};
    Params.Eye.CalMode          = 1;
    Params.Eye.CenterOnly       = 1;
    Params.Eye.CalTypes         = {'Grid','Radial'};
    Params.Eye.CalType          = 1;
    Params.Eye.NoPointsList     = {(3:2:9).^2, 9:8:33};
    Params.Eye.NoPoint          = 1;
    Params.Eye.PointDist        = 10;                                                     	% linear or radial distance (degrees) between target points
    Params.Eye.MarkerTypes      = {'Dot', 'Image', 'Movie'};
    Params.Eye.MarkerType       = 1;
    Params.Eye.MarkerDir        = '/projects/murphya/Stimuli/2D_Images/MacaqueFaces/';
    Params.Eye.MarkerDiam       = 2;                        % Fixation marker diameter (degrees)
    Params.Eye.MarkerColor      = [1,1,1];                  
    Params.Eye.MarkerContrast   = 1;                        
    Params.Eye.Duration         = 1000;                     % Duration of each target presentation (ms)
    Params.Eye.TimeToFix        = 300;                      % Time from stimulus onset for subject to fixate target before abort (ms)
    Params.Eye.FixPercent     	= 80;                       % Percentage duration target must be fixated for a valid trial (default = until target disappears)
    Params.Eye.FixDist          = 4;                        % Maximum distance gaze can stray from center of target (degrees)
    Params.Eye.StimPerTrial     = 5;                      	% Number of stimulus presentations per trial
    Params.Eye.TrialsPerRun     = 100;                  	% Number of trials per run
    Params.Eye.ITIms            = 2000;                    	% Inter-trial interval (ms)
    Params.Eye.ISIms            = 300;                      % Inter-stimulus interval (ms)
    Params.Eye.UseSBS3D         = 0;                        % Use side-by-side stereoscopic 3D presentation?
    Params.Eye.DisparityRange   = [0, 0];                   % Range of binocular disparities to present targets at (min, max) (degrees)
    Params.Eye.XYselected      	= 1;                        % X position is selected by default
    Params.Eye.GainIncrement   	= 0.1;                      % Increment size for manual changes of gain (degrees per Volt)
elseif Success > 1
    ParamsOut = Params;
	return;
end
if OpenGUI == 0
    ParamsOut = Params;
    return;
end

%========================= OPEN GUI WINDOW ================================
Fig.Handle          = figure;                                       	% Open new figure window         
setappdata(0,GUItag,Fig.Handle);                                        % Assign tag
Fig.PanelYdim       = 130*Fig.DisplayScale;
Fig.Rect            = [0 200 500 800]*Fig.DisplayScale;              	% Specify figure window rectangle
set(Fig.Handle,     'Name','SCNI: Eye calibration settings',...         % Open a figure window with specified title
                    'Tag','SCNI_EyeCalibSettings',...                   % Set figure tag
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
Fig.PanelNames      = {'Eye tracker inputs','Calibration appearance','Calibration timing'};
Fig.PannelHeights   = [200, 220, 260];
BoxPos{1}           = [Fig.Margin, Fig.Rect(4)-Fig.PannelHeights(1)*Fig.DisplayScale-Fig.Margin*2, Fig.Rect(3)-Fig.Margin*2, Fig.PannelHeights(1)*Fig.DisplayScale];   
for i = 2:numel(Fig.PanelNames)
    BoxPos{i}           = [Fig.Margin, BoxPos{i-1}(2)-Fig.PannelHeights(i)*Fig.DisplayScale-Fig.Margin/2, Fig.Rect(3)-Fig.Margin*2, Fig.PannelHeights(i)*Fig.DisplayScale];
end

Fig.UIinputs.Labels         = {'Eye XY channels', 'Eye pupil channels','Eye to use','Offset XY (V)','Degrees per V','Inverted'};
Fig.UIinputs.Style          = {'Edit','Edit','popup','Edit','Edit','Checkbox'};
Fig.UIinputs.Defaults       = {num2str(Params.Eye.XYchannels{Params.Eye.EyeToUse}), num2str(Params.Eye.Pupilchannels{Params.Eye.EyeToUse}), Params.Eye.Cal.Labels, Params.Eye.Cal.Offset{Params.Eye.EyeToUse}, Params.Eye.Cal.Gain{Params.Eye.EyeToUse}, {[],[]}};
Fig.UIinputs.Values         = {[],[],Params.Eye.EyeToUse, Params.Eye.Cal.Offset{Params.Eye.EyeToUse}, Params.Eye.Cal.Gain{Params.Eye.EyeToUse}, Params.Eye.Cal.Sign{Params.Eye.EyeToUse}};
Fig.UIinputs.Enabled        = [0, 0, 1, 0, 0, 0];
Fig.UIinputs.Tips           = {'','','','','',''};
Fig.UIinputs.Ypos           = [(Fig.PannelHeights(1)-50):-20:10]*Fig.DisplayScale;
Fig.UIinputs.Xwidth         = [180, 200]*Fig.DisplayScale;

Fig.UIappearance.Labels    	= {'Calibration mode','Center only','Target layout', 'No. targets', 'Target spacing (deg)','Marker type','Marker directory','Marker diameter (deg)','Marker color'};
Fig.UIappearance.Style     	= {'popup', 'checkbox','popup','popup', 'edit','popup','edit', 'edit', 'pushbutton'};
Fig.UIappearance.Defaults 	= {Params.Eye.CalModes, [], Params.Eye.CalTypes, Params.Eye.NoPointsList{Params.Eye.CalType}, Params.Eye.PointDist, Params.Eye.MarkerTypes, Params.Eye.MarkerDir, Params.Eye.MarkerDiam, []};
Fig.UIappearance.Values   	= {Params.Eye.CalMode, Params.Eye.CenterOnly, Params.Eye.CalType, Params.Eye.NoPoint, [], Params.Eye.MarkerType, [], [], []};
Fig.UIappearance.Enabled   	= [1,1,1,1,1,1,Params.Eye.MarkerType>1,1,1];
Fig.UIappearance.Ypos      	= [(Fig.PannelHeights(2)-50):-20:10]*Fig.DisplayScale;
Fig.UIappearance.Xwidth   	= [180, 200]*Fig.DisplayScale;


Fig.UItiming.Labels         = {'Target duration (ms)','Fix duration (%)','Fixation radius (deg)', 'Stim per trial','Trials per run', 'Inter-trial interval (ms)', 'Inter-stimulus interval (ms)'};
Fig.UItiming.Style          = {'edit','edit','edit','edit','edit','edit','edit'};
Fig.UItiming.Defaults       = {Params.Eye.Duration, Params.Eye.FixPercent, Params.Eye.FixDist, Params.Eye.StimPerTrial, Params.Eye.TrialsPerRun, Params.Eye.ITIms, Params.Eye.ISIms};
Fig.UItiming.Values         = {[],[],[],[],[],[],[]};
Fig.UItiming.Enabled        = [1,1,1,1,1,1,1,1];
Fig.UItiming.Ypos           = [(Fig.PannelHeights(3)-50):-20:10]*Fig.DisplayScale;
Fig.UItiming.Xwidth         = [180, 200]*Fig.DisplayScale;
Fig.UItiming.Tips           = {'Duration of each target presentation (ms)',...
                                'Time from stimulus onset for subject to fixate target before abort (ms)',...
                                'Duration taregt must be fixated for valid trial (default = until target disappears)',...
                                'Maximum distance gaze can stray from center of target (degrees)',...
                                'Number of stimulus presentations per trial',...
                                'Number of trials per run',...
                                'Inter-trial interval (ms)',...
                                'Inter-stimulus interval (ms)',...
                                'Use side-by-side stereoscopic 3D presentation?',...
                                'Range of binocular disparities to present targets at (min, max) (degrees)'};


Fig.PanelVars(1).Fieldnames = {'XYchannels','Pupilchannels','EyeToUse','Cal.Offset','Cal.Gain','Cal.Sign'};
Fig.PanelVars(2).Fieldnames = {'CalMode','CenterOnly','CalType','NoPoint','PointDist','MarkerType','MarkerDir','MarkerDiam', 'MarkerColor'};
Fig.PanelVars(3).Fieldnames = {'Duration','FixPercent','FixDist','StimPerTrial','TrialsPerRun','ITIms','ISIms'};

Fig.OffOn           = {'Off','On'};
PanelStructs        = {Fig.UIinputs, Fig.UIappearance, Fig.UItiming};

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
        if p == 1 && n >= 4
            for xy = 1:2
            	Fig.UIhandle(p,n) = uicontrol(  'Style', PanelStructs{p}.Style{n},...
                        'String', PanelStructs{p}.Defaults{n}(xy),...
                        'Value', PanelStructs{p}.Values{n}(xy),...
                        'Enable', Fig.OffOn{PanelStructs{p}.Enabled(n)+1},...
                        'Position', [Fig.Margin + PanelStructs{p}.Xwidth(1)+((xy-1)*(PanelStructs{p}.Xwidth(2)/2+Fig.Margin)), PanelStructs{p}.Ypos(n), PanelStructs{p}.Xwidth(2)/2, 20*Fig.DisplayScale],...
                        'Parent', Fig.PannelHandl(p),...
                        'HorizontalAlignment', 'left',...
                        'FontSize', Fig.FontSize,...
                        'Callback', {@UpdateParams, p, n, xy});
            end
        else
            Fig.UIhandle(p,n) = uicontrol(  'Style', PanelStructs{p}.Style{n},...
                        'String', PanelStructs{p}.Defaults{n},...
                        'Value', PanelStructs{p}.Values{n},...
                        'Enable', Fig.OffOn{PanelStructs{p}.Enabled(n)+1},...
                        'Position', [Fig.Margin + PanelStructs{p}.Xwidth(1), PanelStructs{p}.Ypos(n), PanelStructs{p}.Xwidth(2), 20*Fig.DisplayScale],...
                        'Parent', Fig.PannelHandl(p),...
                        'HorizontalAlignment', 'left',...
                        'FontSize', Fig.FontSize,...
                        'Callback', {@UpdateParams, p, n});
        end
        if p == 2 && n == 7 
            uicontrol(  'Style', 'pushbutton',...
                        'string','...',...
                        'Parent', Fig.PannelHandl(p),...
                        'Position', [Fig.Margin + 20+ sum(PanelStructs{p}.Xwidth([1,2])), PanelStructs{p}.Ypos(n), 20*Fig.DisplayScale, 20*Fig.DisplayScale],...
                        'Callback', {@UpdateParams, p, n});
        end

    end
end
set(Fig.UIhandle(2,9), 'backgroundcolor', Params.Eye.MarkerColor);


%================= OPTIONS PANEL
uicontrol(  'Style', 'pushbutton',...
            'String','Load Params',...
            'parent', Fig.Handle,...
            'tag','Load calibration',...
            'units','pixels',...
            'Position', [Fig.Margin,20*Fig.DisplayScale,100*Fig.DisplayScale,30*Fig.DisplayScale],...
            'TooltipString', 'Load selected images to GPU',...
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
            'TooltipString', 'Continue to run SCNI_EyeCalib.m',...
            'FontSize', Fig.FontSize, ...
            'HorizontalAlignment', 'left',...
            'Callback', {@OptionSelect, 3});         

        
uiwait(Fig.Handle);     % Wait until GUI window is closed beofre returning Params
ParamsOut = Params;     % Output 'Params' struct
        
        
%% =========================== SUBFUNCTIONS ===============================

	%==================== User selected option
    function OptionSelect(hObj, Event, Indx)
        switch Indx
            case 1  %============ Load images to GPU
                Params = LoadEyeParams(Params);

            case 2  %============ Save parameters to file
                Eye = Params.Eye;
                save(Params.File, 'Eye', '-append');

            case 3  %============ Run experiment
                if Params.Eye.MarkerType == 2
                    if ~isfield(Params.Display,'win')
                        Params.Display.win = [];
                    end
                    Params = LoadImages(Params.Display.win, Params);
                end
                ParamsOut = Params;
                close(Fig.Handle);
                return;

        end
    end


    %=============== Update parameters
    function UpdateParams(hObj, Evnt, Indx1, Indx2)

        %============= Panel 1 controls for directory selection
        if Indx1 == 2 && Indx2 == 7         %===== Change stimulus directory
            ImageDir	= uigetdir('/projects/','Select stimulus directory');
            if ImageDir == 0
                return;
            end
            Params.Eye.MarkerDir = ImageDir;
            set(Fig.UIhandle(2,7),'string',Params.Eye.MarkerDir);
     
            
        elseif Indx1 == 1 & ismember([1,2,4,5,6], Indx2)             	%============= All other controls
            if ~isempty(Fig.PanelVars(Indx1).Fieldnames{Indx2})
                switch get(hObj,'style')
                    case 'edit'
                        NewValue = str2num(get(hObj, 'string'));
                    case 'checkbox'
                        NewValue = get(hObj, 'value');
                    case 'popupmenu'
                        NewValue = get(hObj, 'value');
                end
                eval(sprintf('Params.Eye.%s{%d} = %d;', Fig.PanelVars(Indx1).Fieldnames{Indx2}, Params.Eye.EyeToUse, NewValue));
            end
        	UpdateEye;
        else
            switch get(hObj,'style')
                case 'edit'
                    NewValue = str2num(get(hObj, 'string'));
                case 'checkbox'
                    NewValue = get(hObj, 'value');
                case 'popupmenu'
                    NewValue = get(hObj, 'value');
                case 'pushbutton'
                    Color = uisetcolor(Params.Eye.MarkerColor);
                    if numel(Color)>1
                        set(hObj, 'Background', Color);
                        NewValue = Color;
                    end
            end
            eval(sprintf('Params.Eye.%s = %d;', Fig.PanelVars(Indx1).Fieldnames{Indx2}, NewValue));
        end
        


    end

    %=============== Update which eye(s) to use
    function UpdateEye
        
        for n = [1,2,4,5,6]
            NewValue = eval(sprintf('Params.Eye.%s{%d};', Fig.PanelVars(1).Fieldnames{n}, Params.Eye.EyeToUse));
            if n < 6
                set(Fig.UIhandle(1,n), 'string', num2str(NewValue)); 
            else
                InvertValue = NewValue==-1;
                set(Fig.UIhandle(1,n), 'value', InvertValue); 
            end
        end
        
    end


    %==================== Pre-load selected images into GPU ===============
    function Params = LoadImages(win, Params)
        
        if nargin == 0 || isempty(win)
            Screen('Preference', 'VisualDebugLevel', 0);   
            Params.Display.ScreenID = max(Screen('Screens'));
            [Params.Display.win]    = Screen('OpenWindow', Params.Display.ScreenID, Params.Display.Exp.BackgroundColor, Params.Display.Rect,[],[], [], []);
            Screen('BlendFunction', Params.Display.win, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);                                              % Enable alpha channel
        end
        LoadTextPos = (Params.Display.Rect([3,4])./[4,2]);
        TextColor   = [1,1,1]*255;
        Screen(Params.Display.win,'TextSize',60); 
        wbh         = waitbar(0, '');                                                                                                       % Open a waitbar figure
        StimCount   = 1;
        
        Params.Eye.AllStim = wildcardsearch(Params.Eye.MarkerDir, '*.png');
        
        %============= Load stimuli
    	for Stim = 1:numel(Params.Eye.AllStim)                                                                                 % For each file...

            %============= Update experimenter display
            message = sprintf('Loading image %d of %d...\n',Stim, numel(Params.Eye.AllStim));
            Screen('FillRect', Params.Display.win, Params.Display.Exp.BackgroundColor);                                             	% Clear background
            DrawFormattedText(Params.Display.win, message, LoadTextPos(1), LoadTextPos(2), TextColor);
            Screen('Flip', Params.Display.win, [], 0);                                                                                	% Draw to experimenter display

            waitbar(StimCount/Params.ImageExp.TotalImages, wbh, message);                                                               % Update waitbar
            [keyIsDown, secs, keyCode, deltaSecs] = KbCheck();                                                                          % Check if escape key is pressed
            if keyIsDown && keyCode(KbName('Escape'))                                                                                   % If so...
                break;                                                                                                                  % Break out of loop
            end

            %============= Load next file
            img = imread(Params.Eye.AllStim{Stim});                                                                         % Load image file
            [~,~, imalpha] = imread(Params.Eye.AllStim{Stim});                                                          % Read alpha channel
            if ~isempty(imalpha)                                                                                                 	% If image file contains transparency data...
                img(:,:,4) = imalpha;                                                                                           	% Combine into a single RGBA image matrix
            else
                img(:,:,4) = ones(size(img,1),size(img,2))*255;
            end

            %============= Scale image
%             if size(img,2) == size(img,1)
%                 Params.ImageExp.SizePix     = Params.ImageExp.SizeDeg.*Params.Display.PixPerDeg;                                        % Convert requested image size from degrees to pixels
%             else
%                 Scale                       = [1, size(img,2)/size(img,1)];
%                 Params.ImageExp.SizePix     = Params.ImageExp.SizeDeg.*Params.Display.PixPerDeg.*Scale;
%             end

            Params.Eye.ImgTex(Stim)     = Screen('MakeTexture', Params.Display.win, img);                                                       % Create a PTB offscreen texture for the stimulus
        end
        delete(wbh);                                                                                                                      	% Close the waitbar figure window
        Screen('FillRect', Params.Display.win, Params.Display.Exp.BackgroundColor);                                                                        % Clear background
        DrawFormattedText(Params.Display.win, sprintf('All %d stimuli loaded!\n\nClick the ''Run'' button in the SCNI Toolbar to start the experiment.', Stim),  LoadTextPos(1), LoadTextPos(2), TextColor);
        Screen('Flip', Params.Display.win);
        
    end

end