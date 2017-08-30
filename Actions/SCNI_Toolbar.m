
%============================= SCNI_Toolbar.m =============================
% This function opens the SCNI toolbar window, which allows users to execute
% various functions either during or between experimental runs using the 
% Psychtoolbox + DataPixx setup.
%
% 2017-06-27 - Written by murphyap@nih.gov
%==========================================================================

function [PDS, c, s] = SCNI_Toolbar(PDS, c, s)

persistent Fig Params Icon                                                      % Declare global variables

%============ Initialize GUI
GUItag      = 'SCNI_Toolbar';                                               % String to use as GUI window tag
Fieldname   = [];                             
OpenGUI     = 1;
[Params, Success]   = SCNI_InitGUI(GUItag, Fieldname, [], OpenGUI);
Fig.ScreenSize    	= get(0,'screensize');
Fig.DisplayScale    = Fig.ScreenSize(4)/1080;
Fig.Background      = [0.6, 0.6, 0.6];                                      
Fig.ButtonSize      = [0,0,60,60]*Fig.DisplayScale;


%================== Load toolbar icons
Fullmfilename   = mfilename('fullpath');
[Path,~]       	= fileparts(Fullmfilename);
IconDir         = fullfile(Path, '..','SCNI_Subfunctions','Icons');
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

%================== Open toolbar window
Fig.ToolbarRect     = [0,0,1920,100]*Fig.DisplayScale;
Fig.ButtonType      = {'togglebutton','pushbutton','pushbutton','pushbutton','togglebutton','togglebutton','togglebutton','togglebutton','pushbutton','pushbutton','pushbutton','pushbutton','pushbutton','pushbutton'};
Fig.IconList        = {'Play','Liquid','SpeakerOn','Exit','Penalty','GammaCorrect','Sleep','EPI','Display','Photodiode','Eye','DataPixx','TDT','OpenEphys'};
Fig.ButtonTips      = {'Run experiment','Give reward','Play audio','Quit','Debug mode','Apply gamma','Time out','MRI training','Display settings','Photodiode settings','Eye tracking settings','DataPixx settings','TDT settings','Open Ephys settings'};
Fig.ButtonFunc      = {'','SCNI_GiveReward','SCNI_PlaySound','','','','','','SCNI_DisplaySettings','','SCNI_EyelinkSettings','SCNI_DatapixxSettings','SCNI_TDTSettings','SCNI_OpenEphysSettings'};
Fig.ShortcutKeys    = {'g','r','a','q','d','p','k','g','e','t','s','o'};
Fig.ButtonXPos      = (10*Fig.DisplayScale):(Fig.ButtonSize(3)+10*Fig.DisplayScale):((Fig.ButtonSize(3)+10*Fig.DisplayScale)*numel(Fig.IconList));
Fig.Handle = figure('Name','SCNI Toolbar',...                 	% Open a figure window with specified title
                    'Color',Fig.Background,...                	% Set the figure window background color
                    'Renderer','OpenGL',...                     % Use OpenGL renderer
                    'Position', Fig.ToolbarRect,...             % position figure window
                    'NumberTitle','off',...                     % Remove the figure number from the title
                    'Resize','off',...                          % Turn off resizing of figure
                    'Menu','none','Toolbar','none');            % Turn off toolbars and menu
setappdata(0, GUItag, Fig.Handle);                              % Make GUI handle accessible from other m-files
Fig.PannelTitles    = {'Actions', 'Modes', 'Settings'};  
Fig.ButtonsPPannel  = [4, 4, 6];
if Fig.DisplayScale <= 1
    Fig.FontSize        = 16;
elseif Fig.DisplayScale > 1
    Fig.FontSize        = 24;
end
Fig.BIndx           = 1;

for p = 1:numel(Fig.PannelTitles)
    if p == 1
        Xpos = 10*Fig.DisplayScale;
    else
        Xpos = 10*Fig.DisplayScale*p + sum(Fig.PannelPos(1:(p-1),3));
    end
    Fig.PannelPos(p,:) 	= [Xpos, 10*Fig.DisplayScale, (Fig.ButtonSize(3)+10*Fig.DisplayScale)*Fig.ButtonsPPannel(p)+10*Fig.DisplayScale, Fig.ButtonSize(4)+30*Fig.DisplayScale];
    Fig.PannelHandle(p) = uipanel(  'Title',Fig.PannelTitles{p},...
                                    'FontSize',Fig.FontSize,...
                                    'BackgroundColor',Fig.Background,...
                                    'Units','pixels',...
                                    'Position',Fig.PannelPos(p,:),...
                                    'Parent',Fig.Handle);
                                
	for b = 1:Fig.ButtonsPPannel(p)
        Fig.bh(Fig.BIndx) = uicontrol('style',Fig.ButtonType{Fig.BIndx},...
                            'units','pixels',...
                            'position',[Fig.ButtonXPos(b), 10, 0, 0]+Fig.ButtonSize,...
                            'cdata', eval(sprintf('Icon.%s{1}',Fig.IconList{Fig.BIndx})),...
                            'callback', {@RunFunction,Fig.BIndx},...
                            'TooltipString', Fig.ButtonTips{Fig.BIndx},...
                            'Parent',Fig.PannelHandle(p));
        Fig.BIndx = Fig.BIndx+1;
    end
                                
end              


    %% ================== GUI BUTTON CALLBACK FUNCTIONS =======================
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
        eval(sprintf('%s(Params.File)', Fig.ButtonFunc{indx}));

    end

end