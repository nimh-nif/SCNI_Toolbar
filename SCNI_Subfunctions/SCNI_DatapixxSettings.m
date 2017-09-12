%=========================== SCNI_DatapixxSettings.m ===========================
% This function provides a graphical user interface for setting parameters 
% related to the digital and analog I/O channels of DataPixx2. Parameters 
% can be saved and loaded, and the updated parameters are returned in the 
% structure 'Params'.
%
% INPUTS:
%   DefaultInputs: 	optional string containing full path of .mat
%                 	file containing previously saved parameters.
% OUTPUT:
%   Params.DPx.:    Structure containing channel assignments for all 
%                   DataPixx2 channels    
%
%==========================================================================

function ParamsOut = SCNI_DatapixxSettings(ParamsFile, OpenGUI)

persistent Params Fig;

%============ Initialize GUI
GUItag      = 'SCNI_DatapixxSettings';      % String to use as GUI window tag
Fieldname   = 'DPx';                        % Params structure fieldname for DataPixx info
if ~exist('OpenGUI','var')
    OpenGUI = 1;
end
if ~exist('ParamsFile','var')
    ParamsFile = [];
end
[Params, Success, Fig]   = SCNI_InitGUI(GUItag, Fieldname, ParamsFile, OpenGUI);

%=========== Load default parameters
if Success < 1                              % If the parameters could not be loaded...
    Params.DPx.TDTonDOUT        = 1;                                                            % Is DataPixx digital out DB25 connected to TDT digital in DB25?
    Params.DPx.UseVideo         = 0;                                                            % Is the video signal being sent through the DataPixx2 box?
    Params.DPx.UseAudio         = 0;                                                            % Is the audio signal being sent from the DataPixx2 box?
    Params.DPx.AnalogInRate     = 1000;                                                         % ADC sample rate (Hz)
    Params.DPx.AnalogInCh       = 0:15;
    Params.DPx.AnalogInNames    = {'Left eye X','Left eye Y','Left eye pupil','Right eye X','Right eye Y','Right eye pupil', 'Lever 1', 'Lever 2', 'Photodiode','Scanner TTL', 'None','Add new'};
    Params.DPx.AnalogInAssign   = [1,2,3,4,5,6,9,10,11,11,11,11,11,11,11,11];
    Params.DPx.AnalogInLabels   = Params.DPx.AnalogInNames(Params.DPx.AnalogInAssign); 
    Params.DPx.AnalogOutCh      = 0:3;
    Params.DPx.AnalogOutNames   = {'Reward','Audio','None','Add new'};
    Params.DPx.AnalogOutAssign  = [1,3,3,3];
    Params.DPx.AnalogOutLabels  = Params.DPx.AnalogOutNames(Params.DPx.AnalogOutAssign); 
    Params.DPx.AnalogOutRate    = 1000;
    Params.DPx.DigitalInCh      = 0:23;
    Params.DPx.DigitalInNames   = {'Photodiode','Scanner TTL','Spikes','None','Add new'};
    Params.DPx.DigitalInAssign  = [1,4,4,4];
    Params.DPx.DigitalInLabels  = Params.DPx.DigitalInNames(Params.DPx.DigitalInAssign); 
    Params.DPx.DigitalOutCh     = 0:23;
    Params.DPx.DigitalOutNames  = {'Reward','TDT port A','TDT port B','TDT port C','None','Add new'};
    Params.DPx.AnalogIn.Labels  = Params.DPx.AnalogInNames(Params.DPx.AnalogInAssign); 
    if Params.DPx.TDTonDOUT == 1
        Params.DPx.DigitalOutAssign = [1,5,5,5,5,5,5,5,5,3,3,3,3,3,3,3,3,4,4,4,4,4,4,4,4];
    end
    Params.DPx.DigitalOutLabels  = Params.DPx.DigitalOutNames(Params.DPx.DigitalOutAssign); 
elseif Success > 1
    ParamsOut = Params;
    return;
end
if OpenGUI == 0
    ParamsOut = Params;
    return;
end

%========================= OPEN GUI WINDOW ================================          
Fig.Handle          = figure;     
setappdata(0,GUItag,Fig.Handle);
Fig.Rect            = [0 200 600 860]*Fig.DisplayScale;              	% Specify figure window rectangle
Fig.PannelSize      = [170, 650]*Fig.DisplayScale;                                       
Fig.PannelElWidths  = [20, 120]*Fig.DisplayScale;
Fig.MaxADCrate      = 200*10^3;                                         % Maximum sample rate of DataPixx2 ADC channels
Fig.DataPixxURL   	= 'http://www.vpixx.com/manuals/psychtoolbox/html/intro.html';
set(Fig.Handle,     'Name','SCNI: Datapixx settings',...              	% Open a figure window with specified title
                    'Tag','SCNI_DatapixxSettings',...                 	% Set figure tag
                    'Renderer','OpenGL',...                             % Use OpenGL renderer
                    'OuterPosition', Fig.Rect,...                       % position figure window
                    'NumberTitle','off',...                             % Remove figure number from title
                    'Resize', 'off',...                                 % Prevent resizing of GUI window
                    'Menu','none',...                                   % Turn off memu
                    'Toolbar','none');                                  % Turn off toolbars to save space
Fig.Background      = get(Fig.Handle, 'Color');                      	% Get default figure background color
Fig.Margin          = 20*Fig.DisplayScale;                            	% Set margin between UI panels (pixels)                                 
Fig.Fields          = fieldnames(Params);                              	% Get parameter field names


%============= CREATE MAIN PANEL
Fig.TopPanelHandle  = uipanel('BackgroundColor',Fig.Background,...       
                    'Units','pixels',...
                    'Position',[20*Fig.DisplayScale, Fig.Rect(4)-(120+20)*Fig.DisplayScale, Fig.Rect(3)-50*Fig.DisplayScale, 110*Fig.DisplayScale],...
                    'Parent',Fig.Handle); 
Fig.Logo            = imread('Logo_VPixx.png');
Fig.LogoAx          = axes('box','off','units','pixels','position', [10, 10+30, 246, 60]*Fig.DisplayScale,'color',Fig.Background, 'Parent', Fig.TopPanelHandle,'ButtonDownFcn', @OpenWebpage);
image(Fig.Logo,'ButtonDownFcn', @OpenWebpage);
axis off;
if ~exist('Datapixx.m','file')
    Params.DPx.Installed = 0;
    Params.DPx.Connected = 0;
else
    Params.DPx.Installed = 1;
    try Datapixx('Open')
        Params.DPx.Connected = 1;
    catch
        Params.DPx.Connected = 0;
    end
end
Fig.MainStrings     = {'DataPixx tools installed?','DataPixx box connected?','TDT connected via DB25?','Enable video','Enable audio'};
Fig.MainResults     = {Params.DPx.Installed, Params.DPx.Connected, Params.DPx.TDTonDOUT, Params.DPx.UseVideo, Params.DPx.UseAudio};
Fig.DetectionColors = [1,0,0; 0,1,0];
for n = 1:numel(Fig.MainStrings)
    if n < 4
        Ypos = 110*Fig.DisplayScale-(20*n*Fig.DisplayScale)-10*Fig.DisplayScale;
        Fig.Mh(n) = uicontrol('Style', 'checkbox','String',Fig.MainStrings{n},'value', Fig.MainResults{n},'Position', [280*Fig.DisplayScale,Ypos, 200*Fig.DisplayScale,20*Fig.DisplayScale],'Parent',Fig.TopPanelHandle,'HorizontalAlignment', 'left','fontsize', Fig.FontSize);
        Fig.Mdh(n) = uicontrol('Style', 'text','String','','Position', [490*Fig.DisplayScale,Ypos+2*Fig.DisplayScale, 18*Fig.DisplayScale,18*Fig.DisplayScale],'Parent',Fig.TopPanelHandle,'HorizontalAlignment', 'left','backgroundcolor', Fig.DetectionColors(Fig.MainResults{n}+1,:));
    else
        Ypos = [105-(20*4)-15]*Fig.DisplayScale;
        Xpos = [10+(n-4)*130]*Fig.DisplayScale;
        Fig.Mh(n) = uicontrol('Style', 'ToggleButton','String',Fig.MainStrings{n},'value', Fig.MainResults{n},'Position', [Xpos,Ypos, 120*Fig.DisplayScale,20*Fig.DisplayScale],'Parent',Fig.TopPanelHandle,'HorizontalAlignment', 'left','fontsize', Fig.FontSize);
    end
end
set(Fig.Mh(1:2),'enable','off');
set(Fig.Mh(3), 'callback', {@ToggleTDTconnection, 1});
set(Fig.Mh(4), 'callback', {@ToggleTDTconnection, 2});
set(Fig.Mh(5), 'callback', {@ToggleTDTconnection, 3});

%======== Set group controls positions
Fig.UnusedChanCol           = [0.5,0.5,0.5];
Fig.UsedChanCol             = [0, 1, 0];
Fig.PannelNames             = {'Analog IN','Analog OUT','Digital IN','Digital OUT'};
Fig.AllPannelChannels       = {'Params.DPx.AnalogInCh','Params.DPx.AnalogOutCh','Params.DPx.DigitalInCh','Params.DPx.DigitalOutCh'};
Fig.AllPannelChannelnames   = {'Params.DPx.AnalogInNames', 'Params.DPx.AnalogOutNames','Params.DPx.DigitalInNames','Params.DPx.DigitalOutNames'};
Fig.AllPannelChannelAssign  = {'Params.DPx.AnalogInAssign','Params.DPx.AnalogOutAssign','Params.DPx.DigitalInAssign','Params.DPx.DigitalOutAssign'};


%============= CREATE PANELS
for p = 1:numel(Fig.PannelNames)
    if p == 1
        BoxXpos(p) 	= Fig.Margin + (Fig.PannelSize(1)+Fig.Margin)*(p-1);
        BoxYpos(p)  = Fig.Rect(4)-(470+150)*Fig.DisplayScale;
        PannelSize  = [Fig.PannelSize(1), 470*Fig.DisplayScale];
    elseif p == 2
        BoxXpos(p) 	= BoxXpos(1);
        BoxYpos(p)  = BoxYpos(1)-(160+20)*Fig.DisplayScale;
        PannelSize  = [Fig.PannelSize(1), 170*Fig.DisplayScale];
    else
      	BoxXpos(p) 	= Fig.Margin + (Fig.PannelSize(1)+Fig.Margin)*(p-2);
        BoxYpos(p)  = Fig.Rect(4)-Fig.PannelSize(2)-150*Fig.DisplayScale;
        PannelSize  = Fig.PannelSize;
    end
    PannelPos{p}    = [BoxXpos(p), BoxYpos(p), PannelSize]; 
    
    
    Fig.PanelHandle(p) = uipanel( 'Title',Fig.PannelNames{p},...
                    'FontSize',Fig.TitleFontSize,...
                    'BackgroundColor',Fig.Background,...
                    'Units','pixels',...
                    'Position',PannelPos{p},...
                    'Parent',Fig.Handle); 
    
    Ypos         	= PannelPos{p}(4)-Fig.Margin*2.8;
    ChannelList     = eval(Fig.AllPannelChannels{p});               % Get channel numbers for this pannel
    ChannelNames    = eval(Fig.AllPannelChannelnames{p});           % Get I/O names that can be assigned to this pannel
    ChannelAssign   = eval(Fig.AllPannelChannelAssign{p});          % Get channel assignments
    if numel(ChannelAssign) < numel(ChannelList)
        NoneIndx = find(~cellfun(@isempty, strfind(ChannelNames, 'None')));
        ChannelAssign(end+1:numel(ChannelList)) = NoneIndx;
        eval(sprintf('%s = ChannelAssign;', Fig.AllPannelChannelAssign{p}));
    end
     
    if p == 1
        uicontrol('Style', 'text','String','ADC rate (Hz)', 'Position', [Fig.Margin,Ypos,100*Fig.DisplayScale,20*Fig.DisplayScale],'Parent',Fig.PanelHandle(p),'HorizontalAlignment', 'left','fontsize', Fig.FontSize);
        uicontrol('Style', 'edit','String',num2str(Params.DPx.AnalogInRate),'Position', [Fig.Margin+90*Fig.DisplayScale,Ypos,50*Fig.DisplayScale,20*Fig.DisplayScale],'Parent',Fig.PanelHandle(p),'HorizontalAlignment', 'left','callback',@SetSampleRate,'Tooltip','Set ADC sample rate (samples per second)','fontsize', Fig.FontSize);
        Ypos = Ypos-25*Fig.DisplayScale;
 	elseif p == 2
        uicontrol('Style', 'text','String','DAC rate (Hz)', 'Position', [Fig.Margin,Ypos,100*Fig.DisplayScale,20*Fig.DisplayScale],'Parent',Fig.PanelHandle(p),'HorizontalAlignment', 'left','fontsize', Fig.FontSize);
        uicontrol('Style', 'edit','String',num2str(Params.DPx.AnalogOutRate),'Position', [Fig.Margin+90*Fig.DisplayScale,Ypos,50*Fig.DisplayScale,20*Fig.DisplayScale],'Parent',Fig.PanelHandle(p),'HorizontalAlignment', 'left','callback',@SetSampleRate,'Tooltip','Set DAC sample rate (samples per second)','fontsize', Fig.FontSize);
        Ypos = Ypos-25*Fig.DisplayScale;
    end
    
    %============= CREATE FIELDS
    for n = 1:numel(ChannelList)
        Fig.ChH(p,n) = uicontrol('Style', 'text','String',num2str(ChannelList(n)),'Position', [Fig.Margin,Ypos,Fig.PannelElWidths(1),20*Fig.DisplayScale],'Parent',Fig.PanelHandle(p),'HorizontalAlignment', 'left','fontsize', Fig.FontSize);
        Fig.h(p,n) = uicontrol('Style', 'popup','String',ChannelNames,'value', ChannelAssign(n), 'Position', [Fig.Margin+Fig.PannelElWidths(1),Ypos,Fig.PannelElWidths(2),20*Fig.DisplayScale],'Parent',Fig.PanelHandle(p),'HorizontalAlignment', 'left','Callback',{@ChannelUpdate,p,n},'fontsize', Fig.FontSize);
        if strfind(ChannelNames{ChannelAssign(n)}, 'None')
            set(Fig.ChH(p,n), 'BackgroundColor', Fig.UnusedChanCol);
        else
            set(Fig.ChH(p,n), 'BackgroundColor', Fig.UsedChanCol);
        end
        Ypos = Ypos-25*Fig.DisplayScale;
    end
end
if Params.DPx.TDTonDOUT == 1
    set(Fig.h(4,10:24), 'enable','off','TooltipString','Digital outs 9-23 in use for TDT communciation');    
end


%================= OPTIONS PANEL
Fig.OptionLabel     = {'Load','Save','Continue','Help'};
Fig.OptionPosition  = {[20,20,100,30], [140,20,100,30],[260,20,100,30],[380,20,100,30]};
Fig.OptionTip       = {'Load settings','Save settings','Exit','Open DataPixx help page'};
for n = 1:numel(Fig.OptionLabel)
    uicontrol(  'Style', 'pushbutton',...
                'String',Fig.OptionLabel{n},...
                'parent', Fig.Handle,...
                'tag','Load',...
                'units','pixels',...
                'Position', Fig.OptionPosition{n}*Fig.DisplayScale,...
                'TooltipString', Fig.OptionTip{n},...
                'FontSize', Fig.FontSize, ...
                'HorizontalAlignment', 'left',...
                'Callback', {@OptionSelect, n});   
end
 

hs = guihandles(Fig.Handle);                                % get UI handles
guidata(Fig.Handle, hs);                                    % store handles
set(Fig.Handle, 'HandleVisibility', 'callback');            % protect from command line
drawnow;
% uiwait(Fig.Handle);
ParamsOut = Params;




%% ========================= UICALLBACK FUNCTIONS =========================
    function ChannelUpdate(hObj, Evnt, Indx1, Indx2)
 
        %========== Update channel color code
        Selection = get(hObj, 'value');
        Channelnames = eval(Fig.AllPannelChannelnames{Indx1});
        if strcmp(Channelnames{Selection},'None')
            set(Fig.ChH(Indx1, Indx2), 'BackgroundColor', Fig.UnusedChanCol);
        else
            set(Fig.ChH(Indx1, Indx2), 'BackgroundColor', Fig.UsedChanCol);
        end
        
        %========== Add new option
%         if strcmpi(Fig.AllPannelChannelnames{Indx1}{Indx2},'Add new')
%             
%             
%             Fig.AllPannelChannelnames{Indx1}            = {Fig.AllPannelChannelnames{Indx1}(1:end-1), NewString, Fig.AllPannelChannelnames{Indx1}(end)};
%             Fig.AllPannelChannelAssign{Indx1}(Indx2)    = numel(Fig.AllPannelChannelnames{Indx1})-1;
%             set(Fig.h(Indx1, Indx2),'String',Fig.AllPannelChannelnames{Indx1},'value', Fig.AllPannelChannelAssign{Indx1}(Indx2));
%         end
        
        %========== Update params
        switch Indx1 
            case 1  %========= ANALOG IN
                Params.DPx.AnalogInAssign(Indx2) = Selection;
                Params.DPx.AnalogInLabels   = Params.DPx.AnalogInNames(Params.DPx.AnalogInAssign); 
                
            case 2  %========= ANALOG OUT
                Params.DPx.AnalogOutAssign(Indx2) = Selection;
                Params.DPx.AnalogOutLabels   = Params.DPx.AnalogOutNames(Params.DPx.AnalogOutAssign); 
                
            case 3  %========= DIGITAL IN
                Params.DPx.DigitalInAssign(Indx2) = Selection;
                Params.DPx.DigitalInLabels   = Params.DPx.DigitalInNames(Params.DPx.DigitalInAssign); 
                
            case 4  %========= DIGITAL OUT
                Params.DPx.DigitalOutAssign(Indx2) = Selection;
                Params.DPx.DigitalOutLabels   = Params.DPx.DigitalOutNames(Params.DPx.DigitalOutAssign); 
                
        end
       
    end

    %==================== Set ADC sample rate
    function SetSampleRate(Obj, Event, Indx)
        NewRate = str2num(get(Obj,'string'));
        if NewRate < Fig.MaxADCrate
            Params.DPx.AnalogRate = NewRate;
        else
            set(Obj,'string',Fig.MaxADCrate);
            Params.DPx.AnalogRate = Fig.MaxADCrate;
        end
    end

    function OpenWebpage(Obj, Event, Indx)
        web(Fig.DataPixxURL);
    end
        
    %==================== TDT connected to digital out
    function ToggleTDTconnection(Obj, Event, Indx)
        switch Indx
            case 1
                Params.DPx.TDTonDOUT = get(Obj, 'value');
                set(Fig.Mdh(3),'backgroundcolor', Fig.DetectionColors(Params.DPx.TDTonDOUT+1,:));
                if Params.DPx.TDTonDOUT == 1
                    Params.DPx.DigitalOutAssign(10:17) = find(~cellfun(@isempty, strfind(Params.DPx.DigitalOutNames, 'TDT port B')));
                    Params.DPx.DigitalOutAssign(18:24) = find(~cellfun(@isempty, strfind(Params.DPx.DigitalOutNames, 'TDT port C')));
                    set(Fig.ChH(4,10:24), 'BackgroundColor', Fig.UsedChanCol);
                    set(Fig.h(4,10:17), 'value', Params.DPx.DigitalOutAssign(10));
                    set(Fig.h(4,18:24), 'value', Params.DPx.DigitalOutAssign(18));
                    set(Fig.h(4,10:24), 'enable','off','TooltipString','Digital outs 9-23 in use for TDT communciation'); 
                else
                    set(Fig.h(4,10:24), 'enable','on','TooltipString','');
                end
                
            case 2
                Params.DPx.UseVideo = get(Obj, 'value');
                if Params.DPx.UseVideo == 1
                    set(Fig.Mh(4),'backgroundcolor',[0 1 0]);
                else
                    set(Fig.Mh(4),'backgroundcolor',Fig.Background);
                end
                
            case 3
                Params.DPx.UseAudio = get(Obj, 'value');
              	if Params.DPx.UseAudio == 1
                    set(Fig.Mh(5),'backgroundcolor',[0 1 0]);
                else
                    set(Fig.Mh(5),'backgroundcolor',Fig.Background);
                end
        end
    end

    %==================== OPTIONS
    function OptionSelect(Obj, Event, Indx)

        switch Indx
            case 1      %================ LOAD PARAMETERS FILE
                [Filename, Pathname, Indx] = uigetfile('*.mat','Load parameters file', Params.Dir);
                Params.File = fullfile(Pathname, Filename);
                SCNI_DatapixxSettings(Params.File);

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
                DPx     = Params.DPx;
                File    = Params.File;
                if exist(Params.File, 'file')
                    save(Params.File, 'DPx','File','-append');
                elseif ~exist(Params.File, 'file')
                    save(Params.File, 'DPx','File');
                end
                msgbox(sprintf('Parameters file saved to ''%s''!', Params.File),'Saved');

            case 3      %================ CLOSE PARAMETERS GUI
                ParamsOut = [];         % Clear params
                close(Fig.Handle);      % Close GUI figure
                return;
                
            case 4      %================ OPEN HELP PAGE
                web(Fig.DataPixxURL);
        end
    end

end