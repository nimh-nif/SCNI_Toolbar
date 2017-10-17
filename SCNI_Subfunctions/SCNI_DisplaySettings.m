%======================== SCNI_DisplaySettings.m ==========================
% This function provides a graphical user interface for setting parameters 
% related to the viewing configuration, geometry and preferences of specific
% neurophysiology and neuroimaging rigs. Parameters can be saved and loaded, 
% and the updated parameters are returned in the structure 'Params'.
%
% INPUTS:
%   ParamsFile:   	optional string containing full path of a .mat file
%                	containing previously saved parameters. If no input is
%                	provided, the function will search for a .mat file with
%                	the name of the local computer. If no file is found,
%                	default parameters are loaded.
% OUTPUT:
%   Params:         a structure containing the parameters set in the GUI.
%
%==========================================================================

function ParamsOut = SCNI_DisplaySettings(ParamsFile, OpenGUI)

persistent Params Fig;

%============ Initialize GUI
GUItag      = 'SCNI_DisplaySettings';               % String to use as GUI window tag
Fieldname   = 'Display';                            % Params structure fieldname for DataPixx info
if ~exist('OpenGUI','var')
    OpenGUI = 1;
end
if ~exist('ParamsFile','var')
    ParamsFile = [];
end
[Params, Success, Fig]   = SCNI_InitGUI(GUItag, Fieldname, ParamsFile, OpenGUI);

%=========== Load default parameters
if Success < 1
    Params.Display.Stereomode           = 6;
    Params.Display.ViewingDist          = 50;
    Params.Display.IPD                  = 3.5;
    Params.Display.ScreenDims           = [122.6, 71.8];                % SCNI 55" LG OLED 4K TV/ [25.2, 16.0] = NIF Epson porjectors
    Params.Display.ClippingPlanes       = [-20, 20];
    Params.Display.Perspective          = 1;
    Params.Display.LightingOn           = 1;
    Params.Display.UseSBS3D             = 1;                           	% Use side-by-side stereoscopic 3D?
    Params.Display.SqueezedSBS          = 1;                            % If using SBS 3D, are images squeezed?
    Params.Display.Exp.GridOn           = 1;
    Params.Display.Exp.EyeOn            = 1;
    Params.Display.Exp.GazeWinOn        = 1;
    Params.Display.Exp.BackgroundOn   	= 1;
    Params.Display.Exp.GridColor        = [0 1 1];
    Params.Display.Exp.EyeColor         = [1 0 0];
    Params.Display.Exp.GazeWinColor     = [0 1 0];
    Params.Display.Exp.BackgroundColor  = [0.5 0.5 0.5];
    Params.Display.Exp.GridSpacing      = 5;
    Params.Display.Exp.EyeSamples       = 1;
    Params.Display.Exp.GazeWinAlpha     = 1;
    Params.Display.PD.Position          = 2;
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
Fig.Rect            = [0 200 500 900]*Fig.DisplayScale;              	% Specify figure window rectangle
set(Fig.Handle,     'Name','SCNI: Rig settings',...                     % Open a figure window with specified title
                    'Tag','SCNI_RigSettings',...                     	% Set figure tag
                    'Renderer','OpenGL',...                             % Use OpenGL renderer
                    'OuterPosition', Fig.Rect,...                       % position figure window
                    'NumberTitle','off',...                             % Remove figure number from title
                    'Resize', 'off',...                                 % Prevent resizing of GUI window
                    'Menu','none',...                                   % Turn off memu
                    'Toolbar','none');                                  % Turn off toolbars to save space
Fig.Background  = get(Fig.Handle, 'Color');                           	% Get default figure background color
Fig.Margin      = 20*Fig.DisplayScale;                               	% Set margin between UI panels (pixels)                                 
Fig.Fields      = fieldnames(Params);                                 	% Get parameter field names

%======== Set group controls positions
BoxPos{1} = [Fig.Margin,Fig.Rect(4)-230*Fig.DisplayScale-Fig.Margin*2,Fig.Rect(3)-Fig.Margin*2, 240*Fig.DisplayScale];         	
BoxPos{2} = [Fig.Margin,BoxPos{1}(2)-220*Fig.DisplayScale-Fig.Margin/2,Fig.Rect(3)-Fig.Margin*2, 220*Fig.DisplayScale];
BoxPos{3} = [Fig.Margin,BoxPos{2}(2)-140*Fig.DisplayScale-Fig.Margin/2,Fig.Rect(3)-Fig.Margin*2, 140*Fig.DisplayScale];
BoxPos{4} = [Fig.Margin,BoxPos{3}(2)-200*Fig.DisplayScale-Fig.Margin/2,Fig.Rect(3)-Fig.Margin*2, 200*Fig.DisplayScale];


%=========================== SYSTEM PANEL =================================
Fig.SystemHandle = uipanel( 'Title','System Profile',...
                'FontSize',Fig.TitleFontSize,...
                'BackgroundColor',Fig.Background,...
                'Units','pixels',...
                'Position',BoxPos{1},...
                'Parent',Fig.Handle); 
[~, CompName]   = system('hostname');
OS              = computer;
MatlabVersion   = version;
OpenGL          = opengl('data');
if exist('PsychtoolboxVersion', 'file')==2
    PTBversion  = deblank(PsychtoolboxVersion);
%     WhiteSpace  = strfind(PTBversion,' ');
%     PTBversion  = PTBversion(1:WhiteSpace(1));
    NoXscreens 	= numel(Screen('screens'));
    Resolution  = Screen('rect',max(Screen('screens')));
    RefreshRate = Screen('NominalFramerate', max(Screen('screens')));
else
    PTBversion  = 'Not detected!';
    NoXscreens  = 'Unknown!';
    Resolution  = get(0,'screensize');
    RefreshRate = 'Unknown!';
end
if ~isfield(Params, 'File') || ~exist(Params.File,'file')
	ParamsFileName = 'No params file!';
else
    [~,ParamsFileName] = fileparts(Params.File);
end     

MissingDataColor    = [1,0,0];
Xwidth              = [180, 260]*Fig.DisplayScale;
Ypos                = BoxPos{1}(4)-Fig.Margin*2.5;
SystemValues        = {CompName, OS, MatlabVersion,OpenGL.Renderer, OpenGL.Version, PTBversion, ParamsFileName, num2str(NoXscreens), sprintf('%d x %d', Resolution([3,4])), sprintf('%d Hz',RefreshRate)};
SystemLabels        = {'Computer ID:','Operating system:','MATLAB version:','Graphics board:','OpenGL version:','PsychToolbox version:','Params file:','No. X Screens:','Total pixels:','Refresh rate:'};
for n = 1:numel(SystemLabels)
    h(n) = uicontrol('Style', 'text','String',SystemLabels{n},'Position', [Fig.Margin,Ypos,Xwidth(1),20*Fig.DisplayScale],'Parent',Fig.SystemHandle,'HorizontalAlignment', 'left','FontSize', Fig.FontSize);
   	h(n+numel(SystemLabels)) = uicontrol('Style', 'text','String',SystemValues{n},'Position', [Xwidth(1),Ypos,Xwidth(2),20*Fig.DisplayScale],'Parent',Fig.SystemHandle,'HorizontalAlignment', 'left','FontSize', Fig.FontSize);
    if strfind(SystemValues{n}, '!')
        set(h(n+numel(SystemLabels)), 'BackgroundColor', MissingDataColor);
    end
 	Ypos = Ypos-20*Fig.DisplayScale;
end
set(h(1:numel(SystemLabels)), 'BackgroundColor', Fig.Background);



%% ======================== VIEWPORT GEOMETRY PANEL =======================
Fig.GeometryHandle = uipanel( 'Title','Viewing Geometry',...
                'FontSize',Fig.TitleFontSize,...
                'BackgroundColor',Fig.Background,...
                'Units','pixels',...
                'Position',BoxPos{2},...
                'Parent',Fig.Handle);  
            
Ypos    = 170*Fig.DisplayScale;           
Xwidth  = [170, 180]*Fig.DisplayScale;
%=================== STEREO MODE SELECTION
TipStr = 'Select a stereoscopic viewing method.';
RenderMethods = {'Monocular','Shutter glasses','Split-screen: top-bottom','Split-screen: bottom-top','Split-screen: free fusion','Split-screen: cross fusion',...
                 'Anaglyph: red-green','Anaglyph: green-red','Anaglyph: red-blue','Anaglyph: blue-red','Free fusion OSX',...
                 'PTB shutter glasses','Interleaved line','Interleaved column','Compressed HDMI'};
uicontrol(  'Style', 'text',...
            'String','Stereoscopic method:',...
            'Background',Fig.Background, ...
            'Position', [Fig.Margin,Ypos,Xwidth(1),Fig.Margin],...
            'parent',Fig.GeometryHandle,....
            'HorizontalAlignment', 'left',...
            'FontSize', Fig.FontSize);
uicontrol(  'Style', 'popup',...
            'Background', 'white',...
            'Tag', 'Method', ...
            'String', RenderMethods,...
            'Position', [218*Fig.DisplayScale,Ypos,Xwidth(2),Fig.Margin],...
            'parent',Fig.GeometryHandle,...
            'TooltipString', TipStr,...
            'Callback', {@SetGeometry, 1},...
            'FontSize', Fig.FontSize);
Ypos = Ypos-25*Fig.DisplayScale;
if strcmpi(PTBversion,'Not detected!')
    set(findobj('Tag','Method'), 'Value',1,'Enable','off');
else
    set(findobj('Tag','Method'), 'Value', Params.Display.Stereomode+1);
end

ViewPortStrings = {'Viewing distance (cm):','Interpupillary distance (cm)','Screen dimensions (cm)','Screen dimensions (pixels)','Pixels/degree (X, Y)','Photodiode position'};
TipStr = {  'Set the viewing distance in centimetres (distance from observer to screen).',...
            'Set the observer''s interpupillary distance (distance between the eyes) in centimetres.',...
            'Set the physical dimensions of the display screen in centimetres (width x height)'...
            'Set the resolution of the subject''s display in pixels (width x height)',...
            'Screen resolution per degree of visual angle', ...
            'Set the location to present a photodiode marker'};
Tags        = {'VD','IPD','ScreenDim','Pixels','PixPerDeg','Photodiode'};
if ~isfield(Params.Display, 'Rect')
    Params.Display.XScreenRect  = Resolution;
    Params.Display.Rect         = Resolution;
    Params.Display.PixPerCm   	= Params.Display.Rect([3,4])./Params.Display.ScreenDims;                         % Calculate number of pixels per centimetre
    Params.Display.PixPerDeg 	= (Params.Display.PixPerCm*Params.Display.ViewingDist*tand(0.5))*2;              % Calculate pixles per degree
end
PDpositions         = {'None','Bottom left','Top left','Top right','Bottom right'};
DefaultAns          = {Params.Display.ViewingDist,Params.Display.IPD,Params.Display.ScreenDims,Params.Display.Rect([3,4]), Params.Display.PixPerDeg,PDpositions};     

%================== OTHER GEOMERTY PARAMETER CONTROLS
Indx = 2;
Xpos = [220, 310]*Fig.DisplayScale;
for n = 1:numel(ViewPortStrings)
    LabelH(n) = uicontrol(  'Style', 'text','String',ViewPortStrings{n},'Position', [Fig.Margin,Ypos,180*Fig.DisplayScale,20*Fig.DisplayScale],...
                'TooltipString', TipStr{n},'Parent',Fig.GeometryHandle,'HorizontalAlignment', 'left', 'FontSize', Fig.FontSize);
    if ismember(n,[3,4,5])
        
        for i = 1:2
            Fig.GeomH{n}(i) = uicontrol(  'Style', 'edit','Tag', Tags{n},'String', num2str(DefaultAns{n}(i)),'Position', [Xpos(i),Ypos,80*Fig.DisplayScale,22*Fig.DisplayScale],...
                        'TooltipString', TipStr{n},'Parent',Fig.GeometryHandle,'Callback', {@SetGeometry, Indx}, 'FontSize', Fig.FontSize);
                    Indx = Indx+1;
        end
    elseif n == 6
        Fig.GeomH{n} = uicontrol(  'Style', 'popup','Tag', Tags{n},'String', DefaultAns{n},'value',Params.Display.PD.Position,'Position', [Xpos(1),Ypos,120*Fig.DisplayScale,22*Fig.DisplayScale],...
                    'TooltipString', TipStr{n},'Parent',Fig.GeometryHandle,'Callback', {@SetGeometry, Indx}, 'FontSize', Fig.FontSize);
                    Indx = Indx+1;
    else
        Fig.GeomH{n} = uicontrol(  'Style', 'edit','Tag', Tags{n},'String', num2str(DefaultAns{n}),'Position', [Xpos(1),Ypos,120,22*Fig.DisplayScale],...
                    'TooltipString', TipStr{n},'Parent',Fig.GeometryHandle,'Callback', {@SetGeometry, Indx}, 'FontSize', Fig.FontSize);
                    Indx = Indx+1;
    end
    Ypos = Ypos-25*Fig.DisplayScale;
end
set(LabelH, 'BackgroundColor',Fig.Background);
set(Fig.GeomH{5}, 'enable', 'off');


%================= EXPERIMENTER PANEL
Fig.ColorHandle = uipanel( 'Title','Experimenter display',...
                'FontSize',Fig.TitleFontSize,...
                'BackgroundColor',Fig.Background,...
                'Units','pixels',...
                'Position',BoxPos{3},...
                'Parent',Fig.Handle);  
Ypos            = BoxPos{3}(4)-Fig.Margin-10*Fig.DisplayScale;           
ColorLabels     = {'Grid','Eye position','Gaze window','Background'};
ColorValues     = {Params.Display.Exp.GridOn, Params.Display.Exp.EyeOn, Params.Display.Exp.GazeWinOn, 1};
ColorDefaults   = [Params.Display.Exp.GridColor; Params.Display.Exp.EyeColor; Params.Display.Exp.GazeWinColor; Params.Display.Exp.BackgroundColor];     
SettingsLabels  = {'Grid spacing (deg)', 'Samples (ms)', 'Alpha', ''};
SettingsVals    = {num2str(Params.Display.Exp.GridSpacing), num2str(Params.Display.Exp.EyeSamples), num2str(Params.Display.Exp.GazeWinAlpha), ''};
Fig.TipStr      = {'Toggle grid','Toggle eye postion','Toggle fixation window',''};

for n = 1:numel(ColorLabels)
  	Ypos = Ypos-25*Fig.DisplayScale;
    uicontrol(  'Style', 'radio',...
                'Background', Fig.Background,...
                'String', ColorLabels{n},...
                'Value', ColorValues{n},...
                'Position', [15*Fig.DisplayScale,Ypos,120*Fig.DisplayScale,25*Fig.DisplayScale],...
                'TooltipString', Fig.TipStr{n},...
                'Parent',Fig.ColorHandle,...
                'Callback', {@SetExpColor, 1, n},...
                'FontSize', Fig.FontSize);
    uicontrol(  'Style', 'pushbutton',...
                'Background', ColorDefaults(n,1:3),...
                'Tag', ColorLabels{n}, ...
                'String', '',...
                'Position',[150*Fig.DisplayScale,Ypos,20*Fig.DisplayScale,20*Fig.DisplayScale],...
                'Parent',Fig.ColorHandle,...
                'Callback', {@SetExpColor, 2, n},...
                'FontSize', Fig.FontSize);
    uicontrol(  'Style', 'text',...
                'String', SettingsLabels{n},...
                'Position',[190*Fig.DisplayScale,Ypos,120*Fig.DisplayScale,20*Fig.DisplayScale],...
                'HorizontalAlignment', 'left',...
                'Parent',Fig.ColorHandle,...
                'FontSize', Fig.FontSize);
    uicontrol(  'Style', 'edit',...
                'String', SettingsVals{n},...
                'Position',[320*Fig.DisplayScale,Ypos,50*Fig.DisplayScale,20*Fig.DisplayScale],...
                'Parent',Fig.ColorHandle,...
                'Callback', {@SetExpVal, n},...
                'FontSize', Fig.FontSize);
end


% %================= DISPLAY PREVIEW PANEL
% % Fig.PreviewHandle = uipanel( 'Title','Display Preview',...
% %                 'FontSize',Fig.FontSize+2,...
% %                 'BackgroundColor',Fig.Background,...
% %                 'Units','pixels',...
% %                 'Position',BoxPos{4},...
% %                 'Parent',Fig.Handle);  
% % Ypos = BoxPos{4}(4)-Fig.Margin*2-10;           
% 
% %Fig.Axh(1) = axes('Parent',Fig.PreviewHandle, 'position', [0.05, 0.1, 0.4, 0.7]);
% Fig.Axh(1) = axes('Parent',Fig.Handle, 'units','pixels','position',[50 50 300 150]);
% set(Fig.Axh(1), 'color', Params.Display.Color.Background, 'units','pixels');
% axis equal tight off
% xlabel('Experimenter display','fontsize', Fig.FontSize+2);
% Fig.Im      = image(1:Resolution(2), 1:Resolution(1), ones(Resolution(2),Resolution(1),3)*0.5, 'Parent', Fig.Axh(1));
% % alpha(Fig.Im, 0);
% 
% %============= Calculate experimenter grid positions
% if Params.Display.Exp.GridOn == 1 
%     
%     CircleSpacing   = Params.Display.Exp.GridSpacing*Params.Display.Display.PixPerDeg;         	% Increase in diameter with each concentric circle
%     NoCircles       = floor(Params.Display.Display.Rect(3)/CircleSpacing(1));         	% Calculate number of circles to fill screen width
%     Params.Display.Exp.GridLineWidth = 1;                                             	% Pen width for grid lines (pixels)
%     for circleno = 1:NoCircles
%         CircleDiameter(circleno,:)              = CircleSpacing*circleno;               
%         Params.Display.Exp.GridCircleRects(:,circleno) 	= CenterRect([0,0,CircleDiameter(circleno,:)], Params.Display.Display.Rect)'; 
%     end
%     Params.Display.Exp.Meridians     = [Params.Display.Display.ExpRect([3,3])/2, 0, Params.Display.Display.ExpRect(3); 0, Params.Display.Display.ExpRect(4), Params.Display.Display.ExpRect([4,4])/2];
%     
%     %=========== Draw grid to figure
%     axes(Fig.Axh(1));
%    	
%     ph(1) = plot([0 0], ylim, '-k', 'color', Params.Display.Exp.GridColor);
%     ph(2) = plot(xlim, [0 0], '-k', 'color', Params.Display.Exp.GridColor);
%     
%     
% end
% 
% 
% %Fig.Axh(2) = axes('Parent',Fig.PreviewHandle, 'position', [0.55, 0.1, 0.4, 0.7]);
% % xlabel('Subject display','fontsize', Fig.FontSize);
        
    

%================= OPTIONS PANEL
uicontrol(  'Style', 'pushbutton',...
            'String','Load',...
            'parent', Fig.Handle,...
            'tag','Load',...
            'units','pixels',...
            'Position', [Fig.Margin,20*Fig.DisplayScale,100*Fig.DisplayScale,30*Fig.DisplayScale],...
            'TooltipString', 'Use current inputs',...
            'FontSize', Fig.FontSize, ...
            'HorizontalAlignment', 'left',...
            'Callback', {@OptionSelect, 1});   
uicontrol(  'Style', 'pushbutton',...
            'String','Save',...
            'parent', Fig.Handle,...
            'tag','Save',...
            'units','pixels',...
            'Position', [140,20,100,30]*Fig.DisplayScale,...
            'TooltipString', 'Save current inputs to file',...
            'FontSize', Fig.FontSize, ...
            'HorizontalAlignment', 'left',...
            'Callback', {@OptionSelect, 2});    
uicontrol(  'Style', 'pushbutton',...
            'String','Continue',...
            'parent', Fig.Handle,...
            'tag','Continue',...
            'units','pixels',...
            'Position', [260,20,100,30]*Fig.DisplayScale,...
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
                Params.Display.Stereomode   = get(hObj,'Value')-1;
                
            case 2          %============== Viewing distance
                Params.Display.ViewingDist  = str2num(get(hObj,'String'));
             	Params.Display.PixPerCm   	= Params.Display.Rect([3,4])./Params.Display.ScreenDims;                     % Calculate number of pixels per centimetre
                Params.Display.PixPerDeg   	= (Params.Display.PixPerCm*Params.Display.ViewingDist*tand(0.5))*2;  
                set(Fig.GeomH{5}(1), 'string', num2str(Params.Display.PixPerDeg(1)));
                set(Fig.GeomH{5}(2), 'string', num2str(Params.Display.PixPerDeg(2)));
                
            case 3          %============== Inter pupillary distance of subject
                Params.Display.IPD = str2num(get(hObj,'String'));
                
            case {4,5}          %============== Screen width/ height (cm)
                i = Indx-3;
                Params.Display.ScreenDims(i)    = str2num(get(hObj,'String'));
                Params.Display.PixPerCm(i)   	= Params.Display.Rect(i+2)/Params.Display.ScreenDims(i);                  % Calculate number of pixels per centimetre
                Params.Display.PixPerDeg(i)   	= (Params.Display.PixPerCm(i)*Params.Display.ViewingDist*tand(0.5))*2;  
                set(Fig.GeomH{5}(i), 'string', num2str(Params.Display.PixPerDeg(i)));

            case {6,7}          %==============  Screen width/ height (pixels)
                i = Indx-5;
                Params.Display.Rect(i+2)        = str2num(get(hObj,'String'));
                Params.Display.PixPerCm(i)   	= Params.Display.Rect(i+2)/Params.Display.ScreenDims(i);                  % Calculate number of pixels per centimetre
                Params.Display.PixPerDeg(i)   	= (Params.Display.PixPerCm(i)*Params.Display.ViewingDist*tand(0.5))*2;  
                set(Fig.GeomH{5}(i), 'string', num2str(Params.Display.PixPerDeg(i)));
                
            case {8, 9}   	%============== Pixels per degree is DISABLED
    
            case 10          %============== Photodiode position
                Params.Display.PD.Position = get(hObj,'Value');

        end
        
        
        
    end


    %==================== EXPERIMENTER DISPLAY SETTINGS
    function SetExpVal(hObj, Evnt, Indx)
        switch Indx
            case 1
                Params.Display.Exp.GridSpacing = str2num(get(hObj,'String'));
            case 2
                Params.Display.Exp.EyeSamples = str2num(get(hObj,'String'));
            case 3
                Params.Display.Exp.GazeWinAlpha = str2num(get(hObj,'String'));
        end
        Params.Display.Exp
    end

    %==================== EXPERIMENTER DISPLAY SETTINGS
    function SetExpColor(hObj, Evnt, Indx1, Indx2)
        Fields = fieldnames(Params.Display.Exp);
        switch Indx1
            case 1 	%================ Toggle component visibility
                eval(sprintf('Params.Display.Exp.%s = get(hObj,''Value'');', Fields{Indx2}));
 
            case 2  %================ Update component color
                Color = uisetcolor;
                set(hObj, 'Background', Color);
                eval(sprintf('Params.Display.Exp.%s = Color;', Fields{(Indx1-1)*4+Indx2}));
                
        end
        Params.Display.Exp
    end


    %==================== OPTIONS
    function OptionSelect(Obj, Event, Indx)

        switch Indx
            case 1      %================ LOAD PARAMETERS FILE
                [Filename, Pathname, Indx] = uigetfile('*.mat','Load parameters file', Params.Display.Dir);
                Params.File = fullfile(Pathname, Filename);
                SCNI_DisplaySettings(Params.File);

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
                Display = Params.Display;
                if exist(Params.File, 'file')
                    save(Params.File, 'Display','-append');
                elseif ~exist(Params.File, 'file')
                    save(Params.File, 'Display');
                end
                msgbox(sprintf('Parameters file saved to ''%s''!', Params.File),'Saved');

            case 3      %================ CLOSE PARAMETERS GUI
                ParamsOut = [];         % Clear params
                close(Fig.Handle);      % Close GUI figure
                return;
        end
    end

end