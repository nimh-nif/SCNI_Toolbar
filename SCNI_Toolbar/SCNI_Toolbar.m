
%============================= SCNI_Toolbar.m =============================
% This function opens the SCNI toolbar window, which allows users to execute
% various functions either during or between experimental runs using the 
% Psychtoolbox + DataPixx setup.
%
% 2017-06-27 - Written by murphyap@nih.gov
%==========================================================================

function [p] = SCNI_Toolbar(p)

persistent Fig Icon                                                      % Declare global variables

%============ Initialize GUI
GUItag      = 'SCNI_Toolbar';                                               % String to use as GUI window tag
Fieldname   = [];                             
OpenGUI     = 1;
[Params, Success, Fig]  = SCNI_InitGUI(GUItag, Fieldname, [], OpenGUI);
Fig.Background          = [0.6, 0.6, 0.6];                                      
Fig.ButtonSize          = [0,0,50,50]*Fig.DisplayScale;

[ParamFilename, path]	= uigetfile(Params.File, 'Select parameters file');
Params.File             = fullfile(path, ParamFilename);
Params                  = load(Params.File);

%================== Load toolbar icons
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

% %================== Save toolbar parameters
% Params.TB.ToolbarRect   = [0,0,1920,100]*Fig.DisplayScale;
% Params.TB.ParamsFile    = Params.File;
% Params.TB.ExpDir        = [];
% Params.TB.CurrentExp    = [];

%================== Open toolbar window
Fig.ToolbarRect     = [0,0,1920,100]*Fig.DisplayScale;
Fig.ButtonType      = {'togglebutton','pushbutton','pushbutton','togglebutton','pushbutton','pushbutton','togglebutton','togglebutton','togglebutton','togglebutton','togglebutton','pushbutton','pushbutton','pushbutton','pushbutton','pushbutton','pushbutton','pushbutton','pushbutton'};
Fig.IconList        = {'Play','Liquid','SpeakerOn','Movie','Eye','Exit','Penalty','GammaCorrect','Sleep','EPI','Stereoscopic','Display','Photodiode','Eye','DataPixx','TDT','OpenEphys','Transfer','Github'};
Fig.ButtonTips      = {'Run experiment','Give reward','Play audio','Play movie','Eye calibration','Quit','Debug mode','Apply gamma','Time out','MRI training','Stereoscopic 3D','Display settings','Photodiode settings','Eye tracking settings','DataPixx settings','TDT settings','Open Ephys settings','Transfer data','Manage GitHub repos'};
Fig.ButtonFunc      = {'RunCurrentExp','SCNI_GiveReward','SCNI_PlaySound','SCNI_PlayMovie','SCNI_Calibration','Quit',...
                        'SCNI_DebugMode','SCNI_ApplyGamma','SCNI_RestMode','SCNI_ScannerMode','SCNI_3Dmode',...
                        'SCNI_DisplaySettings','','SCNI_EyelinkSettings','SCNI_DatapixxSettings','SCNI_TDTSettings','SCNI_OpenEphysSettings','SCNI_TransferSettings','SCNI_CodeSettings'};
Fig.ShortcutKeys    = {'g','r','a','c','q','d','p','k','g','e','t','s','o','i',[]};
Fig.ButtonsEnabled  = [1,1,1,1,0,1,1,1,1,1,1,1,0,1,1,1,0,0,1];
Fig.ButtonXPos      = (10*Fig.DisplayScale):(Fig.ButtonSize(3)+10*Fig.DisplayScale):((Fig.ButtonSize(3)+10*Fig.DisplayScale)*numel(Fig.IconList));
Fig.Handle = figure('Name','SCNI Toolbar',...                 	% Open a figure window with specified title
                    'Color',Fig.Background,...                	% Set the figure window background color
                    'Renderer','OpenGL',...                     % Use OpenGL renderer
                    'Position', Fig.ToolbarRect,...             % position figure window
                    'NumberTitle','off',...                     % Remove the figure number from the title
                    'Resize','off',...                          % Turn off resizing of figure
                    'Menu','none','Toolbar','none');            % Turn off toolbars and menu
setappdata(0, GUItag, Fig.Handle);                              % Make GUI handle accessible from other m-files
Fig.PannelTitles    = {'Actions', 'Modes', 'Settings','Options'};  
Fig.ButtonsPPannel  = [6, 5, 8, 7];
Fig.BIndx           = 1;
Fig.OptStrings      = {'Settings file','Experiment directory', 'Current Experiment'};
Fig.OptType         = {'edit','edit','popup'};
Fig.OptDefaults     = {ParamFilename,'',{'None'}}; 
Fig.OptXsize        = round([140, 200, 16]*Fig.DisplayScale);
Fig.OptXPos         = round([20, 40, 60]*Fig.DisplayScale)+[0, cumsum(Fig.OptXsize(1:end-1))];
Fig.OptYpos         = round([39, 21, 3]*Fig.DisplayScale);
Fig.OptTips         = {'Select settings file', 'Select directory containing experiment code', 'Select current experiment'};


OffOn = {'Off','On'};
for p = 1:numel(Fig.PannelTitles)
    if p == 1
        Xpos = 10*Fig.DisplayScale;
    else
        Xpos = 10*Fig.DisplayScale*p + sum(Fig.PannelPos(1:(p-1),3));
    end
    Fig.PannelPos(p,:) 	= [Xpos, 10*Fig.DisplayScale, (Fig.ButtonSize(3)+10*Fig.DisplayScale)*Fig.ButtonsPPannel(p)+10*Fig.DisplayScale, Fig.ButtonSize(4)+30*Fig.DisplayScale];
    Fig.PannelHandle(p) = uipanel(  'Title',Fig.PannelTitles{p},...
                                    'FontSize',Fig.TitleFontSize,...
                                    'BackgroundColor',Fig.Background,...
                                    'Units','pixels',...
                                    'Position',Fig.PannelPos(p,:),...
                                    'Parent',Fig.Handle);
    if p < 4                            
        for b = 1:Fig.ButtonsPPannel(p)
            Fig.bh(Fig.BIndx) = uicontrol('style',Fig.ButtonType{Fig.BIndx},...
                                'units','pixels',...
                                'position',[Fig.ButtonXPos(b), 10, 0, 0]+Fig.ButtonSize,...
                                'cdata', eval(sprintf('Icon.%s{1}',Fig.IconList{Fig.BIndx})),...
                                'callback', {@RunFunction,Fig.BIndx},...
                                'TooltipString', Fig.ButtonTips{Fig.BIndx},...
                                'Enable', OffOn{Fig.ButtonsEnabled(Fig.BIndx)+1},...
                                'Parent',Fig.PannelHandle(p));
            Fig.BIndx = Fig.BIndx+1;
        end
    else
        for n = 1:numel(Fig.OptStrings)
            uicontrol('style','text',...
                'units','pixels',...
                'position',[Fig.OptXPos(1), Fig.OptYpos(n), Fig.OptXsize(1), 20*Fig.DisplayScale],...
                'string', Fig.OptStrings{n},...
                'callback', {@OptionsSet, n},...
                'BackgroundColor',Fig.Background,...
                'HorizontalAlignment', 'left',...
                'fontsize', 18, ...
                'Parent',Fig.PannelHandle(p));
        	Fig.OptH(n) = uicontrol('style',Fig.OptType{n},...
                                'units','pixels',...
                                'position',[Fig.OptXPos(2), Fig.OptYpos(n), Fig.OptXsize(2), 18*Fig.DisplayScale],...
                                'string', Fig.OptDefaults{n},...
                                'fontsize', 18, ...
                                'callback', {@OptionsSet, n},...
                                'Parent',Fig.PannelHandle(p));
            if n < 3
                Fig.OptBH(n) = uicontrol('style','pushbutton',...
                        'units','pixels',...
                        'position',[Fig.OptXPos(3), Fig.OptYpos(n), Fig.OptXsize(3), 16*Fig.DisplayScale],...
                        'string','...',...
                        'fontsize', 18, ...
                        'TooltipString', Fig.OptTips{n},...
                        'callback', {@OptionsSet, n},...
                        'Parent',Fig.PannelHandle(p));        
            end
        end
        set(Fig.OptH(3), 'callback', {@OptionsSet, 3});
    end
    
end      

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
    function OptionsSet(hObj, event, indx)
        switch indx
            case 1  %================= Select parameters file
                Home = fileparts(mfilename('fullpath'));
                DefaultSettingsFile = fullfile(Home, 'SCNI_Parameters');
                [file, path] = uigetfile(DefaultSettingsFile, 'Select paramaters file');
                if file ~= 0
                    Params = load(fullfile(path, file));
                    Params.File = file;
                    set(Fig.OptH(1), 'string', Params.File);
                end
                
            case 2   %================= Select experiment directory
              	Home = fileparts(mfilename('fullpath'));
                path = uigetdir(fullfile(Home, 'SCNI_Demos'), 'Select experiment directory');
                if path ~= 0
                    set(Fig.OptH(2), 'string', path);
                    AllFullFiles = wildcardsearch(path, '*.m');
                    for f = 1:numel(AllFullFiles)
                        [~,AllFiles{f}] = fileparts(AllFullFiles{f});
                    end
                    set(Fig.OptH(3), 'string', AllFiles);
                end
                
            case 3   %================= Select 
                CurrentExp  = get(hObj, 'value');
                
        end
    end

    %============== Icon button pressed
    function RunFunction(hObj, event, indx)

        %======= Toggle button icon
        if strcmpi(get(Fig.bh(indx), 'style'), 'togglebutton')
            if get(hObj, 'value')==0
                set(Fig.bh(indx), 'cdata', eval(sprintf('Icon.%s{1}',Fig.IconList{indx})));
            elseif get(hObj, 'value')==1
                set(Fig.bh(indx), 'cdata', eval(sprintf('Icon.%s{2}',Fig.IconList{indx})));
            end
        end

        %======= Perform action
        eval(sprintf('Params = %s(Params)', Fig.ButtonFunc{indx}));

    end

    %============== Open web browser to SCNI Toolbar wiki
    function OpenWiki(hObj, event, indx)
        web('https://github.com/MonkeyGone2Heaven/SCNI_Toolbar/wiki');
    end

end