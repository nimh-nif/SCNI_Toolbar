
%============================= SCNI_Toolbar.m =============================
% This function opens the SCNI toolbar window, which allows users to execute
% various functions either during or between experimental runs using the 
% Psychtoolbox + DataPixx setup.
%
% 2017-06-27 - Written by murphyap@nih.gov
%==========================================================================

function [p] = SCNI_Toolbar(p)

%global Params
persistent FigTB Icon                                                         % Declare global variables

%============ Initialize GUI
GUItag      = 'SCNI_Toolbar';                                               % String to use as GUI window tag
Fieldname   = [];                             
OpenGUI     = 1;
if ~exist('SCNI_InitGUI.m','file')
    [SCNItoolbarDir, file] = fileparts(mfilename('fullpath'));
    addpath(genpath(SCNItoolbarDir));
end
[Params, Success, FigTB]  = SCNI_InitGUI(GUItag, Fieldname, [], OpenGUI);
FigTB.Background          = [0.6, 0.6, 0.6];                                      
FigTB.ButtonSize          = [0,0,50,50]*FigTB.DisplayScale;

%========== Load default params file and experiment directory
Params 	= load(Params.File);
Params  = UpdateToolbarField(Params);


%========================== Open toolbar window ===========================
FigTB.ToolbarRect  	= [0,0,1920,180]*FigTB.DisplayScale;            % Set toolbar dimensions (pixels)
Icon             	= LoadButtons();                                % Load toolbar icons
FigTB             	= AssignButtons(FigTB);                         % Assign functions to buttons

FigTB.Handle = figure('Name','SCNI Toolbar',...                 	% Open a figure window with specified title
                    'Color',FigTB.Background,...                	% Set the figure window background color
                    'Renderer','OpenGL',...                         % Use OpenGL renderer
                    'Position', FigTB.ToolbarRect,...               % position figure window
                    'NumberTitle','off',...                         % Remove the figure number from the title
                    'Resize','off',...                              % Turn off resizing of figure
                    'Menu','none','Toolbar','none');                % Turn off toolbars and menu
setappdata(0, GUItag, FigTB.Handle);                                % Make GUI handle accessible from other m-files

%============== Initialize panel settings
FigTB.Panel.Titles   	= {'Actions', 'Modes', 'Settings','User','Session'};  
FigTB.Panel.ButtonNo	= [6, 5, 10, 7, 7];
FigTB.Panel.Colors   	= {[1,0.5,0.5],[0.5,1,0.5],[0.5,0.5,1],[0.5,1,1],[1,1,0.5]};
FigTB.Panel.Widths   	= (FigTB.ButtonSize(3)+10*FigTB.DisplayScale)*FigTB.Panel.ButtonNo+10*FigTB.DisplayScale;
FigTB.Panel.Heights     = [FigTB.ButtonSize(4)+30*FigTB.DisplayScale, FigTB.ButtonSize(4)+30*FigTB.DisplayScale, FigTB.ButtonSize(4)+30*FigTB.DisplayScale, FigTB.ToolbarRect(4)-15*FigTB.DisplayScale, FigTB.ToolbarRect(4)-15*FigTB.DisplayScale];
FigTB.Panel.Xpos        = [10*FigTB.DisplayScale, 20*FigTB.DisplayScale+FigTB.Panel.Widths(1), 10*FigTB.DisplayScale, 30*FigTB.DisplayScale+sum(FigTB.Panel.Widths([1,2])), 40*FigTB.DisplayScale+sum(FigTB.Panel.Widths([1,2,4]))];
FigTB.Panel.Ypos        = [95, 95, 10, 10, 10]*FigTB.DisplayScale;

%============== User panel
FigTB.OptStrings{1}     = {'Settings file','Experiment directory','Data directory'};
FigTB.OptType{1}        = {'edit','edit','edit'};
FigTB.OptDefaults{1}    = {[Params.Toolbar.ParamsFile,'.mat'], Params.Toolbar.ExpDir, Params.Toolbar.SaveDir}; 
FigTB.OptValues{1}      = {[],[],[]};
FigTB.OptXsize          = round([140, 200, 16]*FigTB.DisplayScale);
FigTB.OptXPos           = round([20, 40, 60]*FigTB.DisplayScale)+[0, cumsum(FigTB.OptXsize(1:end-1))];
FigTB.OptYpos           = round([(FigTB.Panel.Heights(4)-100):(-20*FigTB.DisplayScale):(10*FigTB.DisplayScale)]);
FigTB.OptTips{1}        = {'Select settings file', 'Select directory containing experiment code','Select user directory to save data to'};
FigTB.OptsEnabled{1}    = [1, 1, 1];
FigTB.OptsHighlight{1}  = [0, exist(Params.Toolbar.ExpDir,'dir'), isempty(Params.Toolbar.SaveDir)];
FigTB.OptsButton{1}     = [1,1,1];

%============== Session panel
FigTB.OptStrings{2}     = {'Subject ID','Session date','Current experiment','Current run #','Experiment file','Calibration'};
FigTB.OptType{2}        = {'popup','edit','popup','edit','edit','edit'};
FigTB.OptDefaults{2}    = {Params.Toolbar.AllSubjects, Params.Toolbar.Session.DateStr, Params.Toolbar.AllExpFiles, Params.Toolbar.CurrentRun, Params.Toolbar.Session.File, []}; 
FigTB.OptValues{2}      = {Params.Toolbar.SelectedSubject,[],1,[],[],[]};
FigTB.OptTips{2}        = {'Enter a subject ID','Today''s date','Select current experiment', 'Current run number for this experiment','Data filename',''};
FigTB.OptsEnabled{2}    = [1, 0, 1, 1, 1, 0];
FigTB.OptsHighlight{2}  = [isempty(FigTB.OptDefaults{2}{1}), 0, 0, 0, isempty(FigTB.OptDefaults{2}{1}), 0];
FigTB.OptsButton{2}     = [0,0,0,0,1,1];

FigTB.OffOn             = {'Off','On'};        
FigTB.BIndx             = 1;                   
FigTB.MissingColor      = [1,0,0];             % Color to set fields/ buttons that must be updated
FigTB.ValidColor        = [1,1,1];

%============== Populate toolbar
for p = 1:numel(FigTB.Panel.Titles)
    if p == 1
        Xpos = 10*FigTB.DisplayScale;
    else
        Xpos = 10*FigTB.DisplayScale*p + sum(FigTB.Panel.Pos(1:(p-1),3));
    end
    FigTB.Panel.Pos(p,:) 	= [FigTB.Panel.Xpos(p), FigTB.Panel.Ypos(p), FigTB.Panel.Widths(p), FigTB.Panel.Heights(p)];
    FigTB.Panel.Handle(p) = uipanel('Title',FigTB.Panel.Titles{p},...
                                    'FontSize',FigTB.TitleFontSize,...
                                    'BackgroundColor',FigTB.Background,...
                                    'Units','pixels',...
                                    'Position',FigTB.Panel.Pos(p,:),...
                                    'Parent',FigTB.Handle);
    if p < 4                            
        for b = 1:FigTB.Panel.ButtonNo(p)
            FigTB.bh(FigTB.BIndx) = uicontrol('style',FigTB.Button(FigTB.BIndx).Type,...
                                'units','pixels',...
                                'position',[FigTB.Button(FigTB.BIndx).XPos, 10, 0, 0]+FigTB.ButtonSize,...
                                'cdata', eval(sprintf('Icon.%s{1}', FigTB.Button(FigTB.BIndx).IconName)),...
                                'callback', {@RunFunction, FigTB.BIndx},...
                                'TooltipString', FigTB.Button(FigTB.BIndx).Tip,...
                                'Enable', FigTB.OffOn{FigTB.Button(FigTB.BIndx).Enabled+1},...
                                'Parent', FigTB.Panel.Handle(FigTB.Button(FigTB.BIndx).Panel));
            FigTB.BIndx = FigTB.BIndx+1;
        end
    elseif p >= 4
        for n = 1:numel(FigTB.OptStrings{p-3})
            uicontrol('style','text',...
                'units','pixels',...
                'position',[FigTB.OptXPos(1), FigTB.OptYpos(n), FigTB.OptXsize(1), 20*FigTB.DisplayScale],...
                'string', FigTB.OptStrings{p-3}{n},...
                'callback', {@OptionsSet, n},...
                'BackgroundColor',FigTB.Background,...
                'HorizontalAlignment', 'left',...
                'fontsize', 18, ...
                'Parent',FigTB.Panel.Handle(p));
        	FigTB.OptH(p-3, n) = uicontrol('style',FigTB.OptType{p-3}{n},...
                                'units','pixels',...
                                'position',[FigTB.OptXPos(2), FigTB.OptYpos(n), FigTB.OptXsize(2), 18*FigTB.DisplayScale],...
                                'string', FigTB.OptDefaults{p-3}{n},...
                                'value', FigTB.OptValues{p-3}{n},...
                                'HorizontalAlignment', 'left',...
                                'TooltipString', FigTB.OptTips{p-3}{n},...
                                'fontsize', 18, ...
                                'enable', FigTB.OffOn{FigTB.OptsEnabled{p-3}(n)+1},...
                                'callback', {@OptionsSet, p-3, n},...
                                'Parent',FigTB.Panel.Handle(p));
            if FigTB.OptsButton{p-3}(n) == 1
                FigTB.OptBH(p-3,n) = uicontrol('style','pushbutton',...
                        'units','pixels',...
                        'position',[FigTB.OptXPos(3), FigTB.OptYpos(n), FigTB.OptXsize(3), 16*FigTB.DisplayScale],...
                        'string','...',...
                        'fontsize', 18, ...
                        'TooltipString', FigTB.OptTips{p-3}{n},...
                        'callback', {@OptionsSet, p-3, n},...
                        'Parent',FigTB.Panel.Handle(p));        
            end
        end
    end
    
end      

%========== Set stereo mode
StereoIndx    = find(strcmp({FigTB.Button.IconName}, 'Stereoscopic'));
set(FigTB.bh(StereoIndx),'value',Params.Display.UseSBS3D, 'cdata', eval(sprintf('Icon.%s{Params.Display.UseSBS3D+1}', FigTB.Button(StereoIndx).IconName)));

%================= Highlight fields requiring completion
for Opt = 1:numel(FigTB.OptsHighlight)
    for n = 1:numel(FigTB.OptsHighlight{Opt})
        if FigTB.OptsHighlight{Opt}(n) == 1
            set(FigTB.OptH(Opt, n), 'backgroundcolor', FigTB.MissingColor);
        end
    end
end

Params = AppendToolbarHandles(Params);

%================== Add logo button for link to Wiki
[im, cm, alph] = imread('Logo_SCNI_Toolbar.png');
im = imresize(im, [60*FigTB.DisplayScale, NaN]);
FigTB.HelpH = uicontrol('style','pushbutton',...
                'units','pixels',...
                'position',[FigTB.ToolbarRect(3)-120-size(im,2), 10*FigTB.DisplayScale, size(im,2), FigTB.ToolbarRect(4)-20*FigTB.DisplayScale],...
                'cdata', im,...
                'callback', {@OpenWiki},...
                'Parent',FigTB.Handle);


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
                            Params.File = fullfile(path, file);                               	% Add params filename
                            set(FigTB.OptH(indx1, 1), 'string', file);                          % Update params file string in SCNI_Toolbar GUI

                            if isfield(Params.Toolbar, 'ExpDir') && exist(Params.Toolbar.ExpDir, 'dir')
                                set(FigTB.OptH(1, 2), 'string', Params.Toolbar.ExpDir);
                                AllFullFiles = wildcardsearch(Params.Toolbar.ExpDir, '*.m');
                                for f = 1:numel(AllFullFiles)
                                    [~,AllFiles{f},AllExt{f}] = fileparts(AllFullFiles{f});
                                end
                                AllFiles(~cellfun(@isempty, strfind(AllExt, '~'))) = [];
                                AllFiles(~cellfun(@isempty, strfind(AllFiles, 'Settings'))) = [];
                                set(FigTB.OptH(2, 3), 'string', AllFiles);
                                Params.Toolbar.AllExpFiles = AllFiles;
                            end

                            if isfield(Params.Toolbar,'SaveDir') && exist(Params.Toolbar.SaveDir, 'dir')
                                set(FigTB.OptH(indx1, 3), 'string', Params.Toolbar.SaveDir, 'backgroundcolor', FigTB.ValidColor);
                            else
                                set(FigTB.OptH(indx1, 3), 'string', Params.Toolbar.SaveDir, 'backgroundcolor', FigTB.MissingColor);
                            end
                        end
                        Params = AppendToolbarHandles(Params);
                        Params = UpdateToolbarField(Params);

                    case 2   %================= Select experiment directory
                        Home = fileparts(mfilename('fullpath'));
                        path = uigetdir(fullfile(Home, 'SCNI_Experiments'), 'Select experiment directory');
                        if path ~= 0
                            Params.Toolbar.ExpDir = path;
                            set(FigTB.OptH(indx1, 2), 'string', path);
                            AllFullFiles = wildcardsearch(path, '*.m');
                            for f = 1:numel(AllFullFiles)
                                [~,AllFiles{f},AllExt{f}] = fileparts(AllFullFiles{f});
                            end
                            AllFiles(~cellfun(@isempty, strfind(AllExt, '~'))) = [];
                            set(FigTB.OptH(2, 3), 'string', AllFiles);
                            Params.Toolbar.AllExpFiles = AllFiles;
                        end

                    case 3   %================= Select current experiment
                      	path = uigetdir('/rawdata/', 'Select directory to save data to');
                        if path ~= 0
                            Params.Toolbar.SaveDir = path;
                            set(FigTB.OptH(indx1, indx2), 'string', Params.Toolbar.SaveDir, 'backgroundcolor', FigTB.ValidColor);
                        end
                        Params = GetSubjects(Params);
                end

            case 2 %=============== SESSION SETTINGS
                switch indx2
                    case 1  %================= Set subject ID
                        SubjectNo   = get(hObj, 'Value');
                        if strcmp(Params.Toolbar.AllSubjects{SubjectNo}, 'Add subject')
                            ans = inputdlg('Enter new subject name', 'New subject');
                            if ~isempty(ans)
                                mkdir(fullfile(Params.Toolbar.SaveDir, ans{1}));
                             	Params.Toolbar.AllSubjects{end}     = ans{1};
                                Params.Toolbar.AllSubjects{end+1}   = 'Add subject';
                                set(hObj, 'string', Params.Toolbar.AllSubjects, 'value', numel(Params.Toolbar.AllSubjects)-1);
                            else
                                return;
                            end
                        end
                        Params = UpdateToolbarField(Params);
                        CheckReady;
                        CheckData(Params);
                        Params = GetRunFiles(Params);
                        
                    case 3   %================= Select current experiment
                        CurrentExpIndx  = get(hObj, 'value');
                        Params.Toolbar.CurrentExp 	=  Params.Toolbar.AllExpFiles{CurrentExpIndx};
                        CheckReady;
                        CheckData(Params);    
                        
                    case 4  %================= Set current run number
                        CurrentRunNo  = str2num(get(hObj, 'string'));
                        Params.Toolbar.CurrentRun = CurrentRunNo;
                        CheckReady;
                        CheckData(Params);
                        
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
                          	set(FigTB.OptH(2, 5), 'string', Params.Toolbar.Session.File, 'backgroundcolor', FigTB.ValidColor);
                            CheckReady;
                        end
                        
                    case 6  %================= Calibration data
                        
                        
                end
        end
    end

    %============== Toggle stereoscopic 3D mode
    function Params = SCNI_3Dmode(Params)
        Params.Display.UseSBS3D = ~Params.Display.UseSBS3D;
        if Params.Toolbar.DebugMode == 1
            msgbox(sprintf('Stereoscopic 3D mode has been turned %s - don''t forget to switch the 3D mode of your display device to match!', FigTB.OffOn{Params.Display.UseSBS3D+1}), 'Toggle stereo mode');
        end
    end

  	%============== Toggle debug mode
    function Params = SCNI_DebugMode(Params)
      	Params.Toolbar.DebugMode = ~Params.Toolbar.DebugMode;
        if Params.Toolbar.DebugMode == 1
            msgbox('In debug mode you will receive additional popup messages and data output to the command line. This may be useful for debugging new code or learning to use existing code, but may slow experiments down.', 'Debug mode activated!');
        end
    end

    %============== Toggle scanner mode
    function Params = SCNI_ScannerMode(Params)
        Params.Toolbar.ScannerMode = ~Params.Toolbar.ScannerMode;
      	if Params.Toolbar.DebugMode == 1
            ExtraText = {'', 'A loop of EPI sequence audio will begin playback when you start any experiment.'};
            DPxText     = {'Audio will play via'};
            msgbox(sprintf('Scanner training mode has been turned %s. %s', FigTB.OffOn{Params.Toolbar.ScannerMode+1}, ExtraText{Params.Toolbar.ScannerMode+1}), 'Toggle scanner mode');
        end
    end

    %============== Toggle rest mode
    function Params = SCNI_RestMode(Params)
        Params.Toolbar.RestMode = ~Params.Toolbar.RestMode;
        Params                  = SCNI_OpenWindow(Params);
        if Params.Toolbar.RestMode == 0
            GreyLevels  = 0:1:(Params.Display.Exp.BackgroundColor(1)*255);
            for g = 1:numel(GreyLevels)
                Screen('FillRect', Params.Display.win, repmat(GreyLevels(g), [1,3]));
                Screen('Flip', Params.Display.win);
            end
            
        elseif Params.Toolbar.RestMode == 1
            GreyLevels  = (Params.Display.Exp.BackgroundColor(1)*255):-1:0;
           	for g = 1:numel(GreyLevels)
                Screen('FillRect', Params.Display.win, repmat(GreyLevels(g), [1,3]));
                Screen('Flip', Params.Display.win);
            end
            
        end
    end

  	%============ Get subject directories
    function Params = GetSubjects(Params)
        if ~isfield(Params.Toolbar, 'SelectedSubject')
            Params.Toolbar.SelectedSubject = 1;
        else
            if isfield(FigTB,'OptH')
                Params.Toolbar.SelectedSubject = get(FigTB.OptH(2, 1),'value');
            end
        end
        AllSubjects                     = dir(Params.Toolbar.SaveDir);
        AllSubjects                     = {AllSubjects.name};
        Params.Toolbar.AllSubjects      = AllSubjects(cellfun(@isempty, strfind(AllSubjects,'.')));
        Params.Toolbar.Session.Subject  = Params.Toolbar.AllSubjects{Params.Toolbar.SelectedSubject};
        if any(cellfun(@isempty, strfind(Params.Toolbar.AllSubjects, 'Add subject')))
            Params.Toolbar.AllSubjects{end+1} = 'Add subject';
        end
        if isfield(FigTB, 'OptH')
            set(FigTB.OptH(2, 1), 'string', Params.Toolbar.AllSubjects);
        end
    end

    %============ Get experiment .m files
    function Params = GetExperiments(Params)
        AllFullFiles                = wildcardsearch(Params.Toolbar.ExpDir, '*.m');
        for f = 1:numel(AllFullFiles)
            [~,AllFiles{f},AllExt{f}] = fileparts(AllFullFiles{f});
        end
        AllFiles(~cellfun(@isempty, strfind(AllExt, '~'))) = [];
        AllFiles(~cellfun(@isempty, strfind(AllFiles, 'Settings'))) = [];
        Params.Toolbar.AllExpFiles      = AllFiles;
        Params.Toolbar.CurrentExp       = Params.Toolbar.AllExpFiles{1};
        Params.Toolbar.Session.DateNum  = datetime('now');
        Params.Toolbar.Session.DateStr  = datestr(Params.Toolbar.Session.DateNum, 'yyyymmdd');
        if isfield(FigTB, 'OptH')
            set(FigTB.OptH(2, 3), 'string', Params.Toolbar.AllExpFiles);
        else
            Params.Toolbar.Session.File = [];
            
        end
    end

    %============== Update 'Toolbar' field of Params struct
    function Params = UpdateToolbarField(Params)
     	[~,ParamFilename]           = fileparts(Params.File);
       	Home                        = fileparts(mfilename('fullpath'));
        Params.Toolbar.ParamsFile   = ParamFilename;
        if ~isfield(Params,'Toolbar')
            Params.Toolbar.ExpDir       = fullfile(Home, 'SCNI_Experiments');
            Params.Toolbar.SaveDir      = '/rawdata/';

        end
        	Params.Toolbar.DebugMode    = 0;
            Params.Toolbar.ScannerMode  = 0;
            Params.Toolbar.RestMode     = 0;

        Params = GetSubjects(Params);
        Params = GetExperiments(Params);
        Params = GetRunFiles(Params);
    end

    %============== Check run number for this experiment
    function Params = GetRunFiles(Params)
        Params.Toolbar.Session.DataDir  = fullfile(Params.Toolbar.SaveDir, Params.Toolbar.Session.Subject, Params.Toolbar.Session.DateStr);
        SearchTerm      = sprintf('%s_%s_%s_*.mat', Params.Toolbar.Session.Subject, Params.Toolbar.Session.DateStr, Params.Toolbar.CurrentExp);
        PreviousRuns    = wildcardsearch(Params.Toolbar.Session.DataDir, SearchTerm);
        if isempty(PreviousRuns)
            Params.Toolbar.CurrentRun = 1;
        else
            Params.Toolbar.CurrentRun = numel(PreviousRuns)+1;
        end
        if isfield(FigTB, 'OptH')
            set(FigTB.OptH(2, 4), 'string', num2str(Params.Toolbar.CurrentRun));
        end
        Params = CheckData(Params);
    end

    %============== Check whether .mat file has been created & read
    function Params = CheckData(Params)
        Params.Toolbar.Session.Subject  = Params.Toolbar.AllSubjects{Params.Toolbar.SelectedSubject};
        Params.Toolbar.Session.File     = sprintf('%s_%s_%s_run%d.mat', Params.Toolbar.Session.Subject, Params.Toolbar.Session.DateStr, Params.Toolbar.CurrentExp, Params.Toolbar.CurrentRun);
        Params.Toolbar.Session.DataDir  = fullfile(Params.Toolbar.SaveDir, Params.Toolbar.Session.Subject, Params.Toolbar.Session.DateStr);
        Params.Toolbar.Session.Fullfile = fullfile(Params.Toolbar.Session.DataDir, Params.Toolbar.Session.File);
        
        %=========== Create new directory for this session?
        if ~exist(Params.Toolbar.Session.DataDir, 'dir')
            ans = questdlg(sprintf('Folder ''%s'' does not currently exist. Would you like to create it?', Params.Toolbar.Session.DataDir), 'Create data folder?', 'Yes','No','Yes');
            if strcmpi(ans,'Yes')
                mkdir(Params.Toolbar.Session.DataDir);
            end
        end
        
        %=========== Update Toolbar
      	if isfield(FigTB,'OptH')
            if ~exist(Params.Toolbar.Session.Fullfile)
                StatusColor = FigTB.ValidColor;
            else
                StatusColor = FigTB.MissingColor;
            end
            set(FigTB.OptH(2, 1), 'backgroundcolor', FigTB.ValidColor);
            set(FigTB.OptH(2, 5), 'string', Params.Toolbar.Session.File, 'backgroundcolor', StatusColor);
        end
        
    end
    
    %============== Check whether ready to run experiment
    function CheckReady
        Params.Toolbar.CurrentExpSettingsFile	= [Params.Toolbar.CurrentExp, 'Settings'];
        SettingsIndx    = find(strcmp({FigTB.Button.IconName}, 'Settings'));
        SettingsIndx    = SettingsIndx(FigTB.Button(SettingsIndx).Panel == 1);
        if exist(Params.Toolbar.CurrentExpSettingsFile,'file')
            set(FigTB.bh(SettingsIndx), 'enable', 'on');
        else
            set(FigTB.bh(SettingsIndx), 'enable', 'off');
        end
    end

    %============== Icon button pressed
    function RunFunction(hObj, event, indx)

        %======= Toggle button icon
%         ClickType = get(hObj, 'SelectionType')
%         if strmcp(ClickType, 'Alt')==1
%             
%         end
        
        if strcmpi(get(FigTB.bh(indx), 'style'), 'togglebutton')
            if get(hObj, 'value')==0
                set(FigTB.bh(indx), 'cdata', eval(sprintf('Icon.%s{1}',FigTB.Button(indx).IconName)));
            elseif get(hObj, 'value')==1
                set(FigTB.bh(indx), 'cdata', eval(sprintf('Icon.%s{2}',FigTB.Button(indx).IconName)));
            end
        end

        %======= Perform action
        eval(sprintf('Params = %s(Params);', FigTB.Button(indx).Func));
        
    end

    %============== Open web browser to SCNI Toolbar wiki
    function OpenWiki(hObj, event, indx)
        web('https://github.com/MonkeyGone2Heaven/SCNI_Toolbar/wiki');
    end

    %=========== Stop current experiment
    function Params = Stop(Params)
        Params.Run.ExpQuit = 1;
        winPtr = Screen('Windows');
        if ~isempty(winPtr)
            fprintf('User closed onscreen window(s) and textures.');
            Screen('CloseAll');
        elseif isempty(winPtr)
            fprintf('User terminated SCNI_Toolbar session.');
            clear all;
            close all;
            return
        end
    end

    %=========== Run currently selected experiment
    function Params = RunCurrentExp(Params)
        if exist([Params.Toolbar.CurrentExp,'.m'],'file')
            if ~exist(Params.Toolbar.Session.Fullfile, 'file')          % If a .mat file doesn't yet exist for this run...
                Params.Toolbar = rmfield(Params.Toolbar, 'Button');     % Remove figure handles
                save(Params.Toolbar.Session.Fullfile, 'Params');        % Save Params structure to .mat file
                Params = AppendToolbarHandles(Params);                  % Add figure handles
            end
            eval(sprintf('Params = %s(Params);', Params.Toolbar.CurrentExp));
        else
            msgbox(sprintf('Error: selected experiment ''%s'' was not found on the Matlab path!', [Params.Toolbar.CurrentExp,'.m']));
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
        Params.Toolbar.Button.Start      = FigTB.bh(~cellfun(@isempty, strfind({FigTB.Button.Func}, 'Start')));
        Params.Toolbar.Button.Stop       = FigTB.bh(~cellfun(@isempty, strfind({FigTB.Button.Func}, 'Stop')));
        Params.Toolbar.Button.Reward     = FigTB.bh(~cellfun(@isempty, strfind({FigTB.Button.Func}, 'SCNI_GiveReward')));
        Params.Toolbar.Button.Audio      = FigTB.bh(~cellfun(@isempty, strfind({FigTB.Button.Func}, 'SCNI_PlaySound')));
        Params.Toolbar.Button.Handles  	 = FigTB.bh;
        Params.Toolbar.Button.Names      = {FigTB.Button.Func};
        Params.Toolbar.Button.Desc       = {FigTB.Button.Tip};
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
        Button{1}       = imresize(imread(ButtonOnImg),FigTB.ButtonSize([3,4]));
        Button{2}       = imresize(imread(ButtonOffImg),FigTB.ButtonSize([3,4]));
        ButtonAlpha     = imresize(ButtonAlpha/max(ButtonAlpha(:)),FigTB.ButtonSize([3,4]));
        for b = 1:2
            for i = 1:numel(IconFiles)
                [im,c,Alpha] = imread(IconFiles{i});
                [~,filename] = fileparts(IconFiles{i});
                if numel(size(im))==2
                    im = repmat(im, [1,1,3]);
                end
                if ~isempty(Alpha)
                    im = Button{b};
                    overlay = imresize(Alpha/max(Alpha(:)), FigTB.ButtonSize([3,4]));
                    for ch = 1:3
                        iml = im(:,:,ch);
                        iml = iml.*(1-overlay);
                        iml(find(ButtonAlpha<0.5)) = FigTB.Background(ch)*255;
                        im(:,:,ch) = iml;
                    end
                end
                eval(sprintf('Icon.%s{b} = im;', filename));
            end
        end
    end

    %==================== ASSIGN FUNCTIONS TO BUTTONS
    function FigTB = AssignButtons(FigTB)
        
        FieldNames  = {'Type','IconName','Tip','Func','Shortcut','Panel','Enabled','XPos'};
        Type        = {'pushbutton','pushbutton','pushbutton','pushbutton','pushbutton','pushbutton','togglebutton','togglebutton','togglebutton','togglebutton','togglebutton','pushbutton','pushbutton','pushbutton','pushbutton','pushbutton','pushbutton','pushbutton','pushbutton','pushbutton','pushbutton'};
        IconName	= {'Play','Liquid','SpeakerOn','Eye','Exit','Settings','Penalty','GammaCorrect','Sleep','EPI','Stereoscopic','Display','Liquid','Eye','DataPixx','TDT','OpenEphys','Motive','Transfer','Github','Save'};
        Tip         = {'Run current experiment','Give reward','Play audio','Run eye calibration','Quit current experiment','Edit experiment settings','Debug mode','Apply gamma','Measure luminance','MRI training','Stereoscopic 3D','Display settings','Reward settings','Eye tracking settings','DataPixx settings','TDT settings','Open Ephys settings','OptiTrack settings','Transfer data','Manage GitHub repos','Save parameters'};
        Func        = {'RunCurrentExp','SCNI_GiveReward','SCNI_PlaySound','SCNI_EyeCalib','Stop','RunCurrentExpSettings',...
                    	'SCNI_DebugMode','SCNI_ApplyGamma','SCNI_RunLuminanceCal','SCNI_ScannerMode','SCNI_3Dmode',...
                        'SCNI_DisplaySettings','SCNI_RewardSettings','SCNI_EyeCalibSettings','SCNI_DatapixxSettings','SCNI_TDTSettings','SCNI_OpenEphysSettings','SCNI_OptiTrackSettings','SCNI_TransferSettings','SCNI_CodeSettings','SaveParams'};
        Shortcut    = {'g','r','a','c','q','s',[],[],[],[],[],[],[],[],[],[],[],[],[],[],[]};
        Panel       = [1,1,1,1,1,1,2,2,2,2,2,3,3,3,3,3,3,3,3,3,3];
        Enabled     = [1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0,1];
        AllXPos   	= (10*FigTB.DisplayScale):(FigTB.ButtonSize(3)+10*FigTB.DisplayScale):((FigTB.ButtonSize(3)+10*FigTB.DisplayScale)*numel(IconName)); 
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
                eval(sprintf('FigTB.Button(%d).%s = %s{%d};', n, FieldNames{f}, FieldNames{f}, n));
            end
        end
    end

end

