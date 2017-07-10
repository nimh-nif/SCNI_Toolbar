%=========================== SCNI_RigSettings.m ===========================
% This function provides a graphical user interface for setting parameters 
% related to the viewing configuration, geometry and preferences of specific
% neurophysiology and neuroimaging rigs. Parameters can be saved and loaded, 
% and the updated parameters are returned in the structure 'Params'.
%
% INPUTS:
%   DefaultInputs:          optional string containing full path of .mat
%                           file containing previously saved parameters.
% OUTPUT:
%   Params.Stereomode:      Method of stereoscopic presentation (1-10). For
%                           monocular rendering select 0.
%   Params.ViewingDist:     Viewing distance (eyes to screen) in centimetres.
%   Params.IPD:             Interpupillary distance in centimetres.
%   Params.ScreenDims:      2 element vector containing physical screen
%                           dimensions [width, height] in centimetres.
%   Params.ClippingPlanes:  2 element vector containing distance of frustum
%                           clipping planes along the z-axis relative to the
%                           plane of the screen [-near, far] in centimetres.
%   Params.Perspective:     0 = Orthographic, 1 = Perspective projection.
%   Params.ColorOn:      Polygon face Color on/ off
%   Params.Ambient:         4 element [RGBA] vector specifying ambient lighting
%   Params.Diffuse:         4 element [RGBA] vector specifying diffuse lighting
%   Params.Specular:        4 element [RGBA] vector specifying specular lighting
%   Params.Background:      4 element [RGBA] vector specifying background color
%   Params.
%
%==========================================================================

function ParamsOut = SCNI_RigSettings(ParamsFile)

persistent Params Fig;

Fullmfilename   = mfilename('fullpath');
[Path,~]       	= fileparts(Fullmfilename);
[Path,~]       	= fileparts(Path);
Params.Dir      = fullfile(Path, 'SCNI_Parameters');
if nargin == 0
    [~, CompName] = system('hostname');
	CompName(regexp(CompName, '\s')) = [];
    Params.File = fullfile(Params.Dir, sprintf('%s.mat', CompName));
else
    Params.File = ParamsFile;
end
if ~exist(Params.File,'file')
    WarningMsg = sprintf('The parameter file ''%s'' does not exist! Loading default parameters...', Params.File);
    msgbox(WarningMsg,'Parameters not detected!','non-modal')
    Params.Stereomode       = 6;
    Params.ViewingDist      = 50;
    Params.IPD              = 3.5;
    Params.ScreenDims       = [122.6, 71.8];                % SCNI 55" LG OLED 4K TV/ [25.2, 16.0] = NIF Epson porjectors
    Params.ClippingPlanes   = [-20, 20];
    Params.Perspective      = 1;
    Params.LightingOn       = 1;
    Params.Color.Grid     	= [0 1 1];
    Params.Color.Eye        = [1 0 0];
    Params.Color.GazeWin    = [0 1 0];
    Params.Color.Background = [0.5 0.5 0.5];
    Params.Exp.GridSpacing  = 5;
    Params.Exp.EyeSamples   = 1;
    Params.Exp.GazeWinAlpha	= 1;
    
elseif exist(Params.File,'file')
    load(Params.File, 'Params');
end



%========================= OPEN GUI WINDOW ================================
Fig.Handle = figure;%(typecast(uint8('ENav'),'uint32'));               	% Assign GUI arbitrary integer        
if strcmp('SCNI_RigSettings', get(Fig.Handle, 'Tag')), return; end   	% If figure already exists, return
Fig.FontSize        = 10;
Fig.TitleFontSize   = 14;
Fig.PanelYdim       = 130;
Fig.Rect            = [0 200 500 800];                               	% Specify figure window rectangle
set(Fig.Handle,     'Name','SCNI: Rig settings',...                     % Open a figure window with specified title
                    'Tag','SCNI_RigSettings',...                     	% Set figure tag
                    'Renderer','OpenGL',...                             % Use OpenGL renderer
                    'OuterPosition', Fig.Rect,...                       % position figure window
                    'NumberTitle','off',...                             % Remove figure number from title
                    'Resize', 'off',...                                 % Prevent resizing of GUI window
                    'Menu','none',...                                   % Turn off memu
                    'Toolbar','none');                                  % Turn off toolbars to save space
Fig.Background  = get(Fig.Handle, 'Color');                           	% Get default figure background color
Fig.Margin      = 20;                                                 	% Set margin between UI panels (pixels)                                 
Fig.Fields      = fieldnames(Params);                                 	% Get parameter field names

%======== Set group controls positions
BoxPos{1} = [Fig.Margin,Fig.Rect(4)-250-Fig.Margin*2,Fig.Rect(3)-Fig.Margin*2, 260];         	
BoxPos{2} = [Fig.Margin,BoxPos{1}(2)-160-Fig.Margin/2,Fig.Rect(3)-Fig.Margin*2, 160];
BoxPos{3} = [Fig.Margin*2+BoxPos{2}(3),BoxPos{2}(2),BoxPos{2}(3),BoxPos{2}(4)];
BoxPos{4} = [Fig.Margin,BoxPos{2}(2)-160-Fig.Margin/2,Fig.Rect(3)-Fig.Margin*2, 160];
BoxPos{5} = [Fig.Margin,BoxPos{4}(2)-80-Fig.Margin/2,Fig.Rect(3)-Fig.Margin*2, 200];

% Logo= imread(fullfile('Documentation','ElectroNav_5.png'),'BackgroundColor',Fig.Background);
% LogoAx = axes('box','off','units','pixels','position', [120, 520, 260, 42],'color',Fig.Background);
% image(Logo);
% axis off

%=========================== SYSTEM PANEL =================================
Fig.SystemHandle = uipanel( 'Title','System Profile',...
                'FontSize',Fig.FontSize+2,...
                'BackgroundColor',Fig.Background,...
                'Units','pixels',...
                'Position',BoxPos{1},...
                'Parent',Fig.Handle); 
[~, CompName]   = system('hostname');
OS              = computer;
MatlabVersion   = version;
OpenGL          = opengl('data');
if exist('PsychtoolboxVersion', 'file')==2
    PTBversion  = PsychtoolboxVersion;
    WhiteSpace  = strfind(PTBversion,' ');
    PTBversion  = PTBversion(1:WhiteSpace(1));
    NoXscreens 	= numel(Screen('screens'));
    Resolution  = Screen('rect',max(Screen('screens')));
else
    PTBversion  = 'Not detected!';
    NoXscreens  = 'Unknown!';
    Resolution  = get(0,'screensize');
end
if ~exist(Params.File,'file')
	ParamsFileName = 'No params file!';
else
    [~,ParamsFileName] = fileparts(Params.File);
end     
MissingDataColor    = [1,0,0];
Xwidth              = [180, 220];
Ypos                = BoxPos{1}(4)-Fig.Margin*2.5;
SystemValues = {CompName, OS, MatlabVersion,OpenGL.Renderer, OpenGL.Version, PTBversion, ParamsFileName, num2str(NoXscreens), sprintf('%d x %d', Resolution([3,4]))};
SystemLabels = {'Computer ID:','Operating system:','MATLAB version:','Graphics board:','OpenGL version:','PsychToolbox version:','Params file:','No. X Screens:','Total pixels:'};
for n = 1:numel(SystemLabels)
    h(n) = uicontrol('Style', 'text','String',SystemLabels{n},'Position', [Fig.Margin,Ypos,Xwidth(1),20],'Parent',Fig.SystemHandle,'HorizontalAlignment', 'left');
   	h(n+numel(SystemLabels)) = uicontrol('Style', 'text','String',SystemValues{n},'Position', [Xwidth(1),Ypos,Xwidth(2),20],'Parent',Fig.SystemHandle,'HorizontalAlignment', 'left');
    if strfind(SystemValues{n}, '!')
        set(h(n+numel(SystemLabels)), 'BackgroundColor', MissingDataColor);
    end
 	Ypos = Ypos-25;
end
set(h(1:numel(SystemLabels)), 'BackgroundColor', Fig.Background);




%% ======================== VIEWPORT GEOMETRY PANEL =======================
Fig.GeometryHandle = uipanel( 'Title','Viewing Geometry',...
                'FontSize',Fig.FontSize+2,...
                'BackgroundColor',Fig.Background,...
                'Units','pixels',...
                'Position',BoxPos{5},...
                'Parent',Fig.Handle);  
            
Ypos    = 150;           
Xwidth  = [150, 180];
%=================== STEREO MODE SELECTION
TipStr = 'Select a stereoscopic viewing method.';
RenderMethods = {'Monocular','Shutter glasses','Split-screen: top-bottom','Split-screen: bottom-top','Split-screen: free fusion','Split-screen: cross fusion',...
                 'Anaglyph: red-green','Anaglyph: green-red','Anaglyph: red-blue','Anaglyph: blue-red','Free fusion OSX',...
                 'PTB shutter glasses','Interleaved line','Interleaved column','Compressed HDMI'};
uicontrol(  'Style', 'text',...
            'String','Stereoscopic method:',...
            'Background',Fig.Background, ...
            'Position', [Fig.Margin,Ypos,Xwidth(1),20],...
            'parent',Fig.GeometryHandle,....
            'HorizontalAlignment', 'left');
uicontrol(  'Style', 'popup',...
            'Background', 'white',...
            'Tag', 'Method', ...
            'String', RenderMethods,...
            'Position', [198,Ypos,Xwidth(2),20],...
            'parent',Fig.GeometryHandle,...
            'TooltipString', TipStr,...
            'Callback', {@SetGeometry, 1});
Ypos = Ypos-25;
if strcmpi(PTBversion,'Not detected!')
    set(findobj('Tag','Method'), 'Value',1,'Enable','off');
else
    set(findobj('Tag','Method'), 'Value', Params.Stereomode+1);
end

ViewPortStrings = {'Viewing distance (cm):','Interpupillary distance (cm)','Screen dimensions (cm)','Pixels/degree (X, Y)','Photodiode position'};
TipStr = {  'Set the viewing distance in centimetres (distance from observer to screen).',...
            'Set the observer''s interpupillary distance (distance between the eyes) in centimetres.',...
            'Set the physical dimensions of the display screen in centimetres (width x height)'...
            'Screen resolution per degree of visual angle', ''};
Tags        = {'VD','IPD','ScreenDim','PixPerDeg','Photodiode'};
DefaultAns  = {Params.ViewingDist,Params.IPD,Params.ScreenDims,[30 30],1};


%================== 
Indx = 2;
Xpos = [200, 290];
for n = 1:numel(ViewPortStrings)
    LabelH(n) = uicontrol(  'Style', 'text','String',ViewPortStrings{n},'Position', [Fig.Margin,Ypos,160,20],...
                'TooltipString', TipStr{n},'Parent',Fig.GeometryHandle,'HorizontalAlignment', 'left');
    if ismember(n,[3,4])
        
        for i = 1:2
            uicontrol(  'Style', 'edit','Tag', Tags{n},'String', num2str(DefaultAns{n}(i)),'Position', [Xpos(i),Ypos,80,22],...
                        'TooltipString', TipStr{n},'Parent',Fig.GeometryHandle,'Callback', {@SetGeometry, Indx});
                    Indx = Indx+1;
        end
    else
        uicontrol(  'Style', 'edit','Tag', Tags{n},'String', num2str(DefaultAns{n}),'Position', [Xpos(1),Ypos,120,22],...
                    'TooltipString', TipStr{n},'Parent',Fig.GeometryHandle,'Callback', {@SetGeometry, Indx});
                    Indx = Indx+1;
    end
    Ypos = Ypos-25;
end
set(LabelH, 'BackgroundColor',Fig.Background);



%================= EXPERIMENTER PANEL
Fig.ColorHandle = uipanel( 'Title','Experimenter display',...
                'FontSize',Fig.FontSize+2,...
                'BackgroundColor',Fig.Background,...
                'Units','pixels',...
                'Position',BoxPos{2},...
                'Parent',Fig.Handle);  
Ypos            = BoxPos{2}(4)-Fig.Margin-10;           
ColorLabels     = {'Grid','Eye position','Gaze window','Background'};
ColorDefaults   = [Params.Color.Grid; Params.Color.Eye; Params.Color.GazeWin; Params.Color.Background];     
SettingsLabels  = {'Grid spacing (deg)', 'Samples (ms)', 'Alpha', ''};
SettingsVals    = {num2str(Params.Exp.GridSpacing), num2str(Params.Exp.EyeSamples), num2str(Params.Exp.GazeWinAlpha), ''};
Fig.TipStr      = {'Toggle grid','Toggle eye postion','Toggle fixation window',''};

Indx = 2;
for n = 1:numel(ColorLabels)
  	Ypos = Ypos-25;
    uicontrol(  'Style', 'radio',...
                'Background', Fig.Background,...
                'String', ColorLabels{n},...
                'Value', 1,...
                'Position', [15,Ypos,120,25],...
                'TooltipString', Fig.TipStr{n},...
                'Parent',Fig.ColorHandle,...
                'Callback', {@SetExpColor, Indx});
    uicontrol(  'Style', 'pushbutton',...
                'Background', ColorDefaults(n,1:3),...
                'Tag', ColorLabels{n}, ...
                'String', '',...
                'Position',[150,Ypos,20,20],...
                'Parent',Fig.ColorHandle,...
                'Callback', {@SetExpColor, Indx});
    uicontrol(  'Style', 'text',...
                'String', SettingsLabels{n},...
                'Position',[190,Ypos,100,20],...
                'HorizontalAlignment', 'left',...
                'Parent',Fig.ColorHandle);
    uicontrol(  'Style', 'edit',...
                'String', SettingsVals{n},...
                'Position',[300,Ypos,50,20],...
                'Parent',Fig.ColorHandle,...
                'Callback', {@SetExpVal, Indx});
    
	Indx = Indx+2;
end



% %================= MONKEY DISPLAY PANEL
% Fig.MaterialsHandle = uipanel( 'Title','Monkey display',...
%                 'FontSize',Fig.FontSize+2,...
%                 'BackgroundColor',Fig.Background,...
%                 'Units','pixels',...
%                 'Position',BoxPos{3},...
%                 'Parent',Fig.Handle);  
% Ypos = BoxPos{3}(4)-Fig.Margin*2-10;           
% TipStr = 'Select light reflectance component colors.';
% uicontrol(  'Style', 'togglebutton','Value',1,'String','Materials on/off','Position', [Fig.Margin,Ypos,120,20],'Background',Fig.Background,...
%             'TooltipString', TipStr,'Parent',Fig.MaterialsHandle,'HorizontalAlignment', 'left');
%         
%         
% MonkeyLabels = {'Ambient','Diffuse','Specular','Background'};
%         
% % ShadeHandle = uibuttongroup('visible','off','Position',[180,Ypos,120,25],'parent', Fig.GeometryHandle, 'SelectionChangeFcn', {@FileCheck, 1});
% for n = 1:numel(MonkeyLabels)
%   	Ypos = Ypos-25;
%     uicontrol(  'Style', 'radio',...
%                 'Background', Fig.Background,...
%                 'String', MaterialsLabels{n},...
%                 'Position', [15,Ypos,80,25],...
%                 'TooltipString', TipStr,...
%                 'Parent',Fig.MaterialsHandle);
%     uicontrol(  'Style', 'pushbutton',...
%                 'Background', [0.3 0.3 0.3],...
%                 'Tag', MaterialsLabels{n}, ...
%                 'String', '',...
%                 'Position',[110,Ypos,20,20],...
%                 'Parent',Fig.MaterialsHandle,...
%                 'Callback', {@SetColor, n});
% end
    

%================= OPTIONS PANEL
uicontrol(  'Style', 'pushbutton',...
            'String','Load',...
            'parent', Fig.Handle,...
            'tag','Load',...
            'units','pixels',...
            'Position', [Fig.Margin,20,100,30],...
            'TooltipString', 'Use current inputs',...
            'FontSize', Fig.FontSize, ...
            'HorizontalAlignment', 'left',...
            'Callback', {@OptionSelect, 1});   
uicontrol(  'Style', 'pushbutton',...
            'String','Save',...
            'parent', Fig.Handle,...
            'tag','Save',...
            'units','pixels',...
            'Position', [140,20,100,30],...
            'TooltipString', 'Save current inputs to file',...
            'FontSize', Fig.FontSize, ...
            'HorizontalAlignment', 'left',...
            'Callback', {@OptionSelect, 2});    
uicontrol(  'Style', 'pushbutton',...
            'String','Continue',...
            'parent', Fig.Handle,...
            'tag','Continue',...
            'units','pixels',...
            'Position', [260,20,100,30],...
            'TooltipString', 'Exit',...
            'FontSize', Fig.FontSize, ...
            'HorizontalAlignment', 'left',...
            'Callback', {@OptionSelect, 3});         

hs = guihandles(Fig.Handle);                                % get UI handles
guidata(Fig.Handle, hs);                                    % store handles
set(Fig.Handle, 'HandleVisibility', 'callback');            % protect from command line
drawnow;
% uiwait(Fig.Handle);
ParamsOut = Params;




%% ========================= UICALLBACK FUNCTIONS =========================
    function SetGeometry(hObj, Evnt, Indx)
        switch Indx
            case 1          %============== Stereomode
                Params.Stereomode = get(hObj,'Value')-1;
            case 2
                Params.ViewingDist = str2num(get(hObj,'String'));
            case 3
                Params.IPD = str2num(get(hObj,'String'));
            case 4
                Params.ScreenDims(1) = str2num(get(hObj,'String'));
            case 5
                Params.ScreenDims(2) = str2num(get(hObj,'String'));
            case 6
                Params.ClippingPlanes(1) = str2num(get(hObj,'String'));
                if Params.ClippingPlanes(1)>0
                    Params.ClippingPlanes(1) = -Params.ClippingPlanes(1);
                end
            case 7
                Params.ClippingPlanes(2) = str2num(get(hObj,'String'));
                if Params.ClippingPlanes(2)<0
                    Params.ClippingPlanes(2) = -Params.ClippingPlanes(2);
                end
            case 8
                Params.Perspective = 0;
            case 9
                Params.Perspective = 1;
        end
        Params

    end


    %==================== EXPERIMENTER DISPLAY SETTINGS
    function SetExpVal(hObj, Evnt, Indx)
        switch Indx
            case 1
                Params.Exp.GridSpacing = double(get(hObj,'String'));
            case 2
                Params.Exp.EyeSamples = double(get(hObj,'String'));
            case 3
                Params.Exp.GazeWinAlpha = double(get(hObj,'String'));
        end
        Params.Exp
    end

    %==================== EXPERIMENTER DISPLAY SETTINGS
    function SetExpColor(hObj, Evnt, Indx)
        switch Indx
            
            case 1
                Params.ColorOn = get(hObj,'Value');
                
            case {2,4,6,8}
                ColorIndx = find([3,5,7,9]==Indx);
                eval(sprintf('Params.Color.%s = get(hObj,''Value'');', Fields{ColorIndx}));
 
            case {3,5,7,9}
                ColorIndx = find([3,5,7,9]==Indx);
                Color = uisetcolor;
                set(hObj, 'Background', Color);
                Fields = fieldnames(Params.Color);
                eval(sprintf('Params.Color.%s = Color;', Fields{ColorIndx}));
                
        end
        Params.Color
    end


    %==================== OPTIONS
    function OptionSelect(Obj, Event, Indx)

        switch Indx
            case 1      %================ LOAD PARAMETERS FILE
                [Filename, Pathname, Indx] = uigetfile('*.mat','Load parameters file', Params.Dir);
                Params.File = fullfile(Pathname, Filename);
                SCNI_RigSettings(Params.File);

            case 2      %================ SAVE PARAMETERS TO FILE
                if exist(Params.File,'file')
                    ButtonName = questdlg(sprintf('A parameters file named ''%s'' already exists. Would you like to overwrite that file?', Params.File), ...
                         'File already exists!', ...
                         'Overwrite', 'Rename', 'Cancel', 'Overwrite');
                     if strcmp(ButtonName,'Cancel')
                         return;
                     end
                end
                [Filename, Pathname, Indx] = uiputfile('*.mat','Save parameters file', Params.File);
                if Filename == 0
                    return;
                end
                Params.File = fullfile(Pathname, Filename);
                save(Params.File, 'Params');
                msgbox(sprintf('Parameters file saved to ''%s''!', Params.File),'Saved');

            case 3      %================ CLOSE PARAMETERS GUI
                ParamsOut = [];         % Clear params
                close(Fig.Handle);      % Close GUI figure
                return;
        end
    end

end