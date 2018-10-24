
%============================= SCNI_Toolbar.m =============================
% This function opens the SCNI toolbar window, which allows users to execute
% various functions either during or between experimental runs using the 
% Psychtoolbox + DataPixx setup.
%
% 2017-06-27 - Written by murphyap@nih.gov
%==========================================================================

function [p] = SCNI_Toolbar(p)

global Params
persistent Fig Icon                                                         % Declare global variables

%============ Initialize GUI
GUItag      = 'SCNI_Toolbar';                                               % String to use as GUI window tag
Fieldname   = [];                             
OpenGUI     = 1;
[Params, Success, Fig]  = SCNI_InitGUI(GUItag, Fieldname, [], OpenGUI);
Fig.Background          = [0.6, 0.6, 0.6];                                      
Fig.ButtonSize          = [0,0,50,50]*Fig.DisplayScale;

%========== Load default params file and experiment directory
Params 	= load(Params.File);
Params  = UpdateToolbarField(Params);


%========================== Open toolbar window ===========================
Fig.ToolbarRect     = [0,0,1920,180]*Fig.DisplayScale;          % Set toolbar dimensions (pixels)
Icon                = LoadButtons();                            % Load toolbar icons
Fig                 = AssignButtons(Fig);                       % Assign functions to buttons

Fig.Handle = figure('Name','SCNI Toolbar',...                 	% Open a figure window with specified title
                    'Color',Fig.Background,...                	% Set the figure window background color
                    'Renderer','OpenGL',...                     % Use OpenGL renderer
                    'Position', Fig.ToolbarRect,...             % position figure window
                    'NumberTitle','off',...                     % Remove the figure number from the title
                    'Resize','off',...                          % Turn off resizing of figure
                    'Menu','none','Toolbar','none');            % Turn off toolbars and menu
setappdata(0, GUItag, Fig.Handle);                              % Make GUI handle accessible from other m-files

%============== Initialize panel settings
Fig.Panel.Titles     = {'Actions', 'Modes', 'Settings','User','Session'};  
Fig.Panel.ButtonNo   = [6, 5, 10, 7, 7];
Fig.Panel.Colors     = {[1,0.5,0.5],[0.5,1,0.5],[0.5,0.5,1],[0.5,1,1],[1,1,0.5]};
Fig.Panel.Widths     = (Fig.ButtonSize(3)+10*Fig.DisplayScale)*Fig.Panel.ButtonNo+10*Fig.DisplayScale;
Fig.Panel.Heights    = [Fig.ButtonSize(4)+30*Fig.DisplayScale, Fig.ButtonSize(4)+30*Fig.DisplayScale, Fig.ButtonSize(4)+30*Fig.DisplayScale, Fig.ToolbarRect(4)-15*Fig.DisplayScale, Fig.ToolbarRect(4)-15*Fig.DisplayScale];
Fig.Panel.Xpos       = [10*Fig.DisplayScale, 20*Fig.DisplayScale+Fig.Panel.Widths(1), 10*Fig.DisplayScale, 30*Fig.DisplayScale+sum(Fig.Panel.Widths([1,2])), 40*Fig.DisplayScale+sum(Fig.Panel.Widths([1,2,4]))];
Fig.Panel.Ypos       = [95, 95, 10, 10, 10]*Fig.DisplayScale;

%============== User panel
Fig.OptStrings{1}   = {'Settings file','Experiment directory','Data directory'};
Fig.OptType{1}      = {'edit','edit','edit'};
Fig.OptDefaults{1}  = {ParamFilename, Params.Toolbar.ExpDir, Params.Toolbar.SaveDir}; 
Fig.OptXsize        = round([140, 200, 16]*Fig.DisplayScale);
Fig.OptXPos         = round([20, 40, 60]*Fig.DisplayScale)+[0, cumsum(Fig.OptXsize(1:end-1))];
Fig.OptYpos         = round([(Fig.Panel.Heights(4)-100):(-20*Fig.DisplayScale):(10*Fig.DisplayScale)]);
Fig.OptTips{1}      = {'Select settings file', 'Select directory containing experiment code','Select user directory to save data to'};
Fig.OptsEnabled{1}  = [1, 1, 1];
Fig.OptsHighlight{1} = [0, exist(Params.Toolbar.ExpDir,'dir'), isempty(Params.Toolbar.SaveDir)];
Fig.OptsButton{1}   = [1,1,1];

%============== Session panel
Fig.OptStrings{2}   = {'Subject ID','Session date','Current experiment','Current run #','Experiment file','Calibration'};
Fig.OptType{2}      = {'edit','edit','popup','edit','edit','edit'};
Fig.OptDefaults{2}  = {Params.Toolbar.Session.Subject, Params.Toolbar.Session.DateStr, Params.Toolbar.AllExpFiles, 1, Params.Toolbar.Session.File, []}; 
Fig.OptTips{2}      = {'Enter a subject ID','Today''s date','Select current experiment', 'Current run number for this experiment','Data filename',''};
Fig.OptsEnabled{2}  = [1, 0, 1, 1, 1, 0];
Fig.OptsHighlight{2} = [isempty(Fig.OptDefaults{2}{1}), 0, 0, 0, isempty(Fig.OptDefaults{2}{1}), 0];
Fig.OptsButton{2}   = [0,0,0,0,1,1];

Fig.OffOn            = {'Off','On'};        
Fig.BIndx            = 1;                   
Fig.MissingColor     = [1,0,0];             % Color to set fields/ buttons that must be updated
Fig.ValidColor       = [1,1,1];

%============== Populate toolbar
for p = 1:numel(Fig.Panel.Titles)
    if p == 1
        Xpos = 10*Fig.DisplayScale;
    else
        Xpos = 10*Fig.DisplayScale*p + sum(Fig.Panel.Pos(1:(p-1),3));
    end
    Fig.Panel.Pos(p,:) 	= [Fig.Panel.Xpos(p), Fig.Panel.Ypos(p), Fig.Panel.Widths(p), Fig.Panel.Heights(p)];
    Fig.Panel.Handle(p) = uipanel(  'Title',Fig.Panel.Titles{p},...
                                    'FontSize',Fig.TitleFontSize,...
                                    'BackgroundColor',Fig.Background,...
                                    'Units','pixels',...
                                    'Position',Fig.Panel.Pos(p,:),...
                                    'Parent',Fig.Handle);
    if p < 4                            
        for b = 1:Fig.Panel.ButtonNo(p)
            Fig.bh(Fig.BIndx) = uicontrol('style',Fig.Button(Fig.BIndx).Type,...
                                'units','pixels',...
                                'position',[Fig.Button(Fig.BIndx).XPos, 10, 0, 0]+Fig.ButtonSize,...
                                'cdata', eval(sprintf('Icon.%s{1}', Fig.Button(Fig.BIndx).IconName)),...
                                'callback', {@RunFunction, Fig.BIndx},...
                                'TooltipString', Fig.Button(Fig.BIndx).Tip,...
                                'Enable', Fig.OffOn{Fig.Button(Fig.BIndx).Enabled+1},...
                                'Parent', Fig.Panel.Handle(Fig.Button(Fig.BIndx).Panel));
            Fig.BIndx = Fig.BIndx+1;
        end
    elseif p >= 4
        for n = 1:numel(Fig.OptStrings{p-3})
            uicontrol('style','text',...
                'units','pixels',...
                'position',[Fig.OptXPos(1), Fig.OptYpos(n), Fig.OptXsize(1), 20*Fig.DisplayScale],...
                'string', Fig.OptStrings{p-3}{n},...
                'callback', {@OptionsSet, n},...
                'BackgroundColor',Fig.Background,...
                'HorizontalAlignment', 'left',...
                'fontsize', 18, ...
                'Parent',Fig.Panel.Handle(p));
        	Fig.OptH(p-3, n) = uicontrol('style',Fig.OptType{p-3}{n},...
                                'units','pixels',...
                                'position',[Fig.OptXPos(2), Fig.OptYpos(n), Fig.OptXsize(2), 18*Fig.DisplayScale],...
                                'string', Fig.OptDefaults{p-3}{n},...
                                'HorizontalAlignment', 'left',...
                                'TooltipString', Fig.OptTips{p-3}{n},...
                                'fontsize', 18, ...
                                'enable', Fig.OffOn{Fig.OptsEnabled{p-3}(n)+1},...
                                'callback', {@OptionsSet, p-3, n},...
                                'Parent',Fig.Panel.Handle(p));
            if Fig.OptsButton{p-3}(n) == 1
                Fig.OptBH(p-3,n) = uicontrol('style','pushbutton',...
                        'units','pixels',...
                        'position',[Fig.OptXPos(3), Fig.OptYpos(n), Fig.OptXsize(3), 16*Fig.DisplayScale],...
                        'string','...',...
                        'fontsize', 18, ...
                        'TooltipString', Fig.OptTips{p-3}{n},...
                        'callback', {@OptionsSet, p-3, n},...
                        'Parent',Fig.Panel.Handle(p));        
            end
        end
    end
    
end      

%========== Set stereo mode
StereoIndx    = find(strcmp({Fig.Button.IconName}, 'Stereoscopic'));
set(Fig.bh(StereoIndx),'value',Params.Display.UseSBS3D, 'cdata', eval(sprintf('Icon.%s{2}', Fig.Button(StereoIndx).IconName)));

%================= Highlight fields requiring completion
for Opt = 1:numel(Fig.OptsHighlight)
    for n = 1:numel(Fig.OptsHighlight{Opt})
        if Fig.OptsHighlight{Opt}(n) == 1
            set(Fig.OptH(Opt, n), 'backgroundcolor', Fig.MissingColor);
        end
    end
end

Params = AppendToolbarHandles(Params);

%================== Add logo button for link to Wiki
[im, cm, alph] = imread('Logo_SCNI_Toolbar.png');
im = imresize(im, [60*Fig.DisplayScale, NaN]);
Fig.HelpH = uicontrol('style','pushbutton',...
                'units','pixels',...
                'position',[Fig.ToolbarRect(3)-120-size(im,2), 10*Fig.DisplayScale, size(im,2), Fig.ToolbarRect(4)-20*Fig.DisplayScale],...
                'cdata', im,...
                'callback', {@OpenWiki},...
                'Parent',Fig.Handle);


    %% ================== GUI BUTTON CALLBACK FUNCTIONS =======================
    
    
    %============== Option button pressed
    function OptionsSet(hObj, event, indx1, indx2)
        switch indx1 
            
            case 1 %=============== USER SETTINGS
                switch indx2
                    case 1  %================= Select parameters file
                        Home = fileparts(mfilename('fullpath'));
                        DefaultSettingsFile = fullfile(Home, 'SCNI_Parameters');
                        [file, path] = uigetfile(DefaultSettingsFile, 'Select paramaters file');
                        if file ~= 0
                            NewParams 	= load(fullfile(path, file));                           % Load params file
                            NewParams.Toolbar.Session       = Params.Toolbar.Session;         	% Transfer 'Toolbar' fields to new Params
                            NewParams.Toolbar.Button        = Params.Toolbar.Button; 
                            NewParams.Toolbar.AllExpFiles   = Params.Toolbar.AllExpFiles;
                            NewParams.Toolbar.CurrentExp    = Params.Toolbar.CurrentExp;
                            Params  = NewParams;                                                % Replace previously loaded params
                            Params.File = file;                                                 % Add params filename
                            set(Fig.OptH(indx1, 1), 'string', Params.File);                     % Update params file string in SCNI_Toolbar GUI

                            if isfield(Params.Toolbar, 'ExpDir') && exist(Params.Toolbar.ExpDir, 'dir')
                                set(Fig.OptH(1, 2), 'string', Params.Toolbar.ExpDir);
                                AllFullFiles = wildcardsearch(Params.Toolbar.ExpDir, '*.m');
                                for f = 1:numel(AllFullFiles)
                                    [~,AllFiles{f},AllExt{f}] = fileparts(AllFullFiles{f});
                                end
                                AllFiles(~cellfun(@isempty, strfind(AllExt, '~'))) = [];
                                AllFiles(~cellfun(@isempty, strfind(AllFiles, 'Settings'))) = [];
                                set(Fig.OptH(2, 3), 'string', AllFiles);
                                Params.Toolbar.AllExpFiles = AllFiles;
                            end

                            if isfield(Params.Toolbar,'SaveDir') && exist(Params.Toolbar.SaveDir, 'dir')
                                set(Fig.OptH(indx1, 3), 'string', Params.Toolbar.SaveDir, 'backgroundcolor', Fig.ValidColor);
                            else
                                set(Fig.OptH(indx1, 3), 'string', Params.Toolbar.SaveDir, 'backgroundcolor', Fig.MissingColor);
                            end
                        end
                        Params = AppendToolbarHandles(Params);
                        Params = UpdateToolbarField(Params);

                    case 2   %================= Select experiment directory
                        Home = fileparts(mfilename('fullpath'));
                        path = uigetdir(fullfile(Home, 'SCNI_Experiments'), 'Select experiment directory');
                        if path ~= 0
                            Params.Toolbar.ExpDir = path;
                            set(Fig.OptH(indx1, 2), 'string', path);
                            AllFullFiles = wildcardsearch(path, '*.m');
                            for f = 1:numel(AllFullFiles)
                                [~,AllFiles{f},AllExt{f}] = fileparts(AllFullFiles{f});
                            end
                            AllFiles(~cellfun(@isempty, strfind(AllExt, '~'))) = [];
                            set(Fig.OptH(2, 3), 'string', AllFiles);
                            Params.Toolbar.AllExpFiles = AllFiles;
                        end

                    case 3   %================= Select current experiment
                      	path = uigetdir('/rawdata/', 'Select directory to save data to');
                        if path ~= 0
                            Params.Toolbar.SaveDir = path;
                            set(Fig.OptH(indx1, indx2), 'string', Params.Toolbar.SaveDir, 'backgroundcolor', Fig.ValidColor);
                        end

                end

            case 2 %=============== SESSION SETTINGS
                switch indx2
                    case 1  %================= Set subject ID
                        Params.Toolbar.Session.Subject  = get(hObj, 'String');
                        CheckReady;
                        CheckData;
                        
                    case 3   %================= Select current experiment
                        CurrentExpIndx  = get(hObj, 'value');
                        Params.Toolbar.CurrentExp 	=  Params.Toolbar.AllExpFiles{CurrentExpIndx};
                        CheckReady;
                        CheckData;    
                        
                    case 4  %================= Set current run number
                        CurrentRunNo  = str2num(get(hObj, 'string'));
                        Params.Toolbar.CurrentRun = CurrentRunNo;
                        CheckReady;
                        CheckData;
                        
                    case 5  %================= Select experiment data file
                        if isfield(Params.Toolbar.Session, 'DataDir')
                            DefaultDataFile = Params.Toolbar.Session.DataDir;
                        else
                            DefaultDataFile = Params.Toolbar.SaveDir;
                        end
                        [file, path] = uigetfile(DefaultDataFile, 'Select .mat file to save session data to');
                        if file ~= 0
                            Params.Toolbar.Session.Fullfile  	= fullfile(path, file);
                            Params.Toolbar.Session.File         = file;
                          	set(Fig.OptH(2, 5), 'string', Params.Toolbar.Session.File, 'backgroundcolor', Fig.ValidColor);
                            CheckReady;
                        end
                        
                    case 6  %================= Calibration data
                        
                        
                end
        end
    end

    %============== Toggle stereoscopic 3D
    function Params = SCNI_3Dmode(Params)
        Params.Display.UseSBS3D = ~Params.Display.UseSBS3D;
    end

    %============== Update 'Toolbar' field of Params struct
    function Params = UpdateToolbarField(Params)
        [~,ParamFilename]   	= fileparts(Params.File);
        Home                    = fileparts(mfilename('fullpath'));
        if ~isfield(Params,'Toolbar')
            Params.Toolbar.ExpDir   = fullfile(Home, 'SCNI_Experiments');
            Params.Toolbar.SaveDir  = '/rawdata/';
        end
        AllFullFiles            = wildcardsearch(Params.Toolbar.ExpDir, '*.m');
        for f = 1:numel(AllFullFiles)
            [~,AllFiles{f},AllExt{f}] = fileparts(AllFullFiles{f});
        end
        AllFiles(~cellfun(@isempty, strfind(AllExt, '~'))) = [];
        AllFiles(~cellfun(@isempty, strfind(AllFiles, 'Settings'))) = [];
        Params.Toolbar.AllExpFiles      = AllFiles;
        Params.Toolbar.CurrentExp       = Params.Toolbar.AllExpFiles{1};
        Params.Toolbar.Session.DateNum  = datetime('now');
        Params.Toolbar.Session.DateStr  = datestr(Params.Toolbar.Session.DateNum, 'yyyymmdd');
        if isfield(Fig, 'OptH')
            set(Fig.OptH(2, 3), 'string', Params.Toolbar.AllExpFiles);
            Params.Toolbar.Session.Subject  = get(Fig.OptH(2, 1), 'string');
            Params.Toolbar.Session.File   	= get(Fig.OptH(2, 5), 'string');
        else
            Params.Toolbar.Session.Subject  = [];
            Params.Toolbar.Session.File   	= [];
        end
    end

    %============== Check whether mat file has been created & read
    function Run = CheckData
        Run = 0;
        if isempty(Params.Toolbar.Session.Subject)
            return;
        end
        if ~isfield(Params.Toolbar,'CurrentExp') || isempty(Params.Toolbar.CurrentExp)
            return;
        end
        Params.Toolbar.Session.File     = sprintf('%s_%s_%s.mat', Params.Toolbar.Session.Subject, Params.Toolbar.Session.DateStr, Params.Toolbar.CurrentExp);
        Params.Toolbar.Session.DataDir  = fullfile(Params.Toolbar.SaveDir, Params.Toolbar.Session.Subject, Params.Toolbar.Session.DateStr);
        Params.Toolbar.Session.Fullfile = fullfile(Params.Toolbar.Session.DataDir, Params.Toolbar.Session.File);
        
        %=========== Create new directory for thsi session?
        if ~exist(Params.Toolbar.Session.DataDir, 'dir')
            ans = questdlg(sprintf('Folder ''%s'' does not currently exist. Would you like to create it?', Params.Toolbar.Session.DataDir), 'Create data folder?', 'Yes','No','Yes');
            if strcmpi(ans,'Yes')
                mkdir(Params.Toolbar.Session.DataDir);
            end
        end
        set(Fig.OptH(2, 1), 'backgroundcolor', Fig.ValidColor);
        
        %=========== Does .mat file for this RUN already exist?
        if ~exist(Params.Toolbar.Session.Fullfile)
            StatusColor = Fig.ValidColor;
        else
            StatusColor = Fig.MissingColor;
        end
        set(Fig.OptH(2, 5), 'string', Params.Toolbar.Session.File, 'backgroundcolor', StatusColor);
        
        
    end
    
    %============== Check whether ready to run experiment
    function CheckReady
        if ~isempty(Params.Toolbar.Session.File) && ~isempty(Params.Toolbar.CurrentExp)
            set(Fig.bh(1), 'enable', 'on');
        end
        if ~isempty(Params.Toolbar.CurrentExp)
            Params.Toolbar.CurrentExpSettingsFile	= [Params.Toolbar.CurrentExp, 'Settings'];
            SettingsIndx    = find(strcmp({Fig.Button.IconName}, 'Settings'));
            SettingsIndx    = SettingsIndx(Fig.Button(SettingsIndx).Panel == 1);
            if exist(Params.Toolbar.CurrentExpSettingsFile,'file')
                set(Fig.bh(SettingsIndx), 'enable', 'on');
            else
                set(Fig.bh(SettingsIndx), 'enable', 'off');
            end
        end
    end

    %============== Icon button pressed
    function RunFunction(hObj, event, indx)

        %======= Toggle button icon
        if strcmpi(get(Fig.bh(indx), 'style'), 'togglebutton')
            if get(hObj, 'value')==0
                set(Fig.bh(indx), 'cdata', eval(sprintf('Icon.%s{1}',Fig.Button(indx).IconName)));
            elseif get(hObj, 'value')==1
                set(Fig.bh(indx), 'cdata', eval(sprintf('Icon.%s{2}',Fig.Button(indx).IconName)));
            end
        end

        %======= Perform action
        eval(sprintf('Params = %s(Params);', Fig.Button(indx).Func));
        
    end

    %============== Open web browser to SCNI Toolbar wiki
    function OpenWiki(hObj, event, indx)
        web('https://github.com/MonkeyGone2Heaven/SCNI_Toolbar/wiki');
    end

    %=========== Stop current experiment
    function Params = Stop(Params)
        Params.Run.ExpQuit = 1;
        sca;
    end

    %=========== Run currently selected experiment
    function Params = RunCurrentExp(Params)
        if isfield(Params.Toolbar, 'CurrentExp')
            if ~exist(Params.Toolbar.Session.Fullfile, 'file')
                Params.Toolbar = rmfield(Params.Toolbar, 'Button');     % Remove figure handles
                save(Params.Toolbar.Session.Fullfile, 'Params');        % Save Params structure
                Params = AppendToolbarHandles(Params);                  % Add figure handles
            end
            eval(sprintf('Params = %s(Params);', Params.Toolbar.CurrentExp));
        end
    end
        
    %=========== Run currently selected experiment's settings GUI
    function Params = RunCurrentExpSettings(Params)
        if isfield(Params.Toolbar, 'CurrentExp')
            SettingsFile    = [Params.Toolbar.CurrentExp, 'Settings'];
            if exist(SettingsFile,'file')
                eval(sprintf('Params = %s(Params);', SettingsFile));
            else
                warndlg(sprintf('No settings file named ''%s.m'' detected!', SettingsFile), 'Settings not found');
            end
        end
    end

    %=========== Save current parameters
    function Params = SaveParams(Params)
        [file, path] = uigetfile(Params.File, 'Select file to save to');
        if file ~= 0
            Filename        = fullfile(path, file);                   
            Params.Toolbar  = rmfield(Params.Toolbar, 'Button');                        % Remove GUI handles
            save(Filename, '-struct', 'Params');
            msgbox(sprintf('Parameters file saved to ''%s''!', Filename),'Saved');
            Params = AppendToolbarHandles(Params);
        end
    end

  	%================== Pass toolbar button handles to Params
    function Params = AppendToolbarHandles(Params)
        Params.Toolbar.Button.Start      = Fig.bh(~cellfun(@isempty, strfind({Fig.Button.Func}, 'Start')));
        Params.Toolbar.Button.Stop       = Fig.bh(~cellfun(@isempty, strfind({Fig.Button.Func}, 'Stop')));
        Params.Toolbar.Button.Reward     = Fig.bh(~cellfun(@isempty, strfind({Fig.Button.Func}, 'SCNI_GiveReward')));
        Params.Toolbar.Button.Audio      = Fig.bh(~cellfun(@isempty, strfind({Fig.Button.Func}, 'SCNI_PlaySound')));
        Params.Toolbar.Button.Handles  	 = Fig.bh;
        Params.Toolbar.Button.Names      = {Fig.Button.Func};
        Params.Toolbar.Button.Desc       = {Fig.Button.Tip};
    end

    %==================== LOAD SCNI_TOOLBAR BUTTONS
    function Icon = LoadButtons()
        Fullmfilename   = mfilename('fullpath');
        [Path,~]       	= fileparts(Fullmfilename);
        IconDir         = fullfile(Path, 'SCNI_Subfunctions','Icons');
        IconFiles       = wildcardsearch(IconDir, '*.png');
        ButtonOnImg     = fullfile(IconDir, 'ButtonOn.png');
        ButtonOffImg    = fullfile(IconDir, 'ButtonOff.png');
        [~,~,ButtonAlpha] = imread(ButtonOnImg);
        Button{1}       = imresize(imread(ButtonOnImg),Fig.ButtonSize([3,4]));
        Button{2}       = imresize(imread(ButtonOffImg),Fig.ButtonSize([3,4]));
        ButtonAlpha     = imresize(ButtonAlpha/max(ButtonAlpha(:)),Fig.ButtonSize([3,4]));
        for b = 1:2
            for i = 1:numel(IconFiles)
                [im,c,Alpha] = imread(IconFiles{i});
                [~,filename] = fileparts(IconFiles{i});
                if numel(size(im))==2
                    im = repmat(im, [1,1,3]);
                end
                if ~isempty(Alpha)
                    im = Button{b};
                    overlay = imresize(Alpha/max(Alpha(:)), Fig.ButtonSize([3,4]));
                    for ch = 1:3
                        iml = im(:,:,ch);
                        iml = iml.*(1-overlay);
                        iml(find(ButtonAlpha<0.5)) = Fig.Background(ch)*255;
                        im(:,:,ch) = iml;
                    end
                end
                eval(sprintf('Icon.%s{b} = im;', filename));
            end
        end
    end

    %==================== ASSIGN FUNCTIONS TO BUTTONS
    function Fig = AssignButtons(Fig)
        
        FieldNames  = {'Type','IconName','Tip','Func','Shortcut','Panel','Enabled','XPos'};
        Type        = {'togglebutton','pushbutton','pushbutton','pushbutton','pushbutton','pushbutton','togglebutton','togglebutton','togglebutton','togglebutton','togglebutton','pushbutton','pushbutton','pushbutton','pushbutton','pushbutton','pushbutton','pushbutton','pushbutton','pushbutton','pushbutton'};
        IconName	= {'Play','Liquid','SpeakerOn','Eye','Exit','Settings','Penalty','GammaCorrect','Sleep','EPI','Stereoscopic','Display','Liquid','Eye','DataPixx','TDT','OpenEphys','Motive','Transfer','Github','Save'};
        Tip         = {'Run current experiment','Give reward','Play audio','Run eye calibration','Quit current experiment','Edit experiment settings','Debug mode','Apply gamma','Time out','MRI training','Stereoscopic 3D','Display settings','Reward settings','Eye tracking settings','DataPixx settings','TDT settings','Open Ephys settings','OptiTrack settings','Transfer data','Manage GitHub repos','Save parameters'};
        Func        = {'RunCurrentExp','SCNI_GiveReward','SCNI_PlaySound','SCNI_EyeCalib','Stop','RunCurrentExpSettings',...
                    	'SCNI_DebugMode','SCNI_ApplyGamma','SCNI_RestMode','SCNI_ScannerMode','SCNI_3Dmode',...
                        'SCNI_DisplaySettings','SCNI_RewardSettings','SCNI_EyeCalibSettings','SCNI_DatapixxSettings','SCNI_TDTSettings','SCNI_OpenEphysSettings','SCNI_OptiTrackSettings','SCNI_TransferSettings','SCNI_CodeSettings','SaveParams'};
        Shortcut    = {'g','r','a','c','q','s',[],[],[],[],[],[],[],[],[],[],[],[],[],[],[]};
        Panel       = [1,1,1,1,1,1,2,2,2,2,2,3,3,3,3,3,3,3,3,3,3];
        Enabled     = [0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0,1];
        AllXPos   	= (10*Fig.DisplayScale):(Fig.ButtonSize(3)+10*Fig.DisplayScale):((Fig.ButtonSize(3)+10*Fig.DisplayScale)*numel(IconName)); 
        XPos        = [];
        for p = unique(Panel)
            Count(p)    = numel(find(Panel == p)); 
          	XPos        = [XPos, AllXPos(1:Count(p))];
        end

        %=========== Add data to 'Button' structure
        Class       = 0;
        NoButtons   = numel(Type);
        for f = 1:numel(FieldNames)
            eval(sprintf('Class = class(%s);', FieldNames{f}));
            if strcmp(Class,'double')==1
                eval(sprintf('%s = num2cell(%s, 1);', FieldNames{f}, FieldNames{f}));
            end
            for n = 1:NoButtons
                eval(sprintf('Fig.Button(%d).%s = %s{%d};', n, FieldNames{f}, FieldNames{f}, n));
            end
        end
    end

end

