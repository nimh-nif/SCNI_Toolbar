%=========================== SCNI_TDTSettings.m ===========================
% This function provides a graphical user interface for setting parameters 
% related to sending event codes (via digital out) to the Tucker Davis
% Technologies neurophysiology recording system RZ2.
%
% INPUTS:
%   DefaultInputs: 	optional string containing full path of .mat
%                 	file containing previously saved parameters.
% OUTPUT:
%   Params.DPx.:    Structure containing channel assignments for all 
%                   DataPixx2 channels    
%
%==========================================================================

function ParamsOut = SCNI_TDTSettings(ParamsFile)

persistent Params Fig;

Params.Dir = '/projects/SCNI/SCNI_Datapixx/SCNI_Parameters';
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

    Params.TDT.StimRange            = [1, 7999];
    Params.TDT.Event.FixOn          = 8000;
   	Params.TDT.Event.FixOff         = 8001;
 	Params.TDT.Event.Abort          = 8002;
  	Params.TDT.Event.TrialEnd       = 8003;
    Params.TDT.Event.AutoReward     = 8004;
    Params.TDT.Event.ManualReward   = 8004;
    
elseif exist(Params.File,'file')
    Params = load(Params.File);
end



%========================= OPEN GUI WINDOW ================================
Fig.Handle = figure;%(typecast(uint8('ENav'),'uint32'));               	% Assign GUI arbitrary integer        
if strcmp('SCNI_TDTSettings', get(Fig.Handle, 'Tag')), return; end   	% If figure already exists, return
Fig.FontSize        = 14;
Fig.TitleFontSize   = 16;
Fig.Rect            = [0 200 800 800];                               	% Specify figure window rectangle
Fig.PannelSize      = [170, 650];                                       
Fig.PannelElWidths  = [30, 120];
set(Fig.Handle,     'Name','SCNI: TDT settings',...                     % Open a figure window with specified title
                    'Tag','SCNI_TDTSettings',...                        % Set figure tag
                    'Renderer','OpenGL',...                             % Use OpenGL renderer
                    'OuterPosition', Fig.Rect,...                       % position figure window
                    'NumberTitle','off',...                             % Remove figure number from title
                    'Resize', 'off',...                                 % Prevent resizing of GUI window
                    'Menu','none',...                                   % Turn off memu
                    'Toolbar','none');                                  % Turn off toolbars to save space
Fig.Background  = get(Fig.Handle, 'Color');                           	% Get default figure background color
Fig.Margin      = 20;                                                 	% Set margin between UI panels (pixels)                                 
Fig.Fields      = fieldnames(Params);                                 	% Get parameter field names

Logo= imread('TDT.png','BackgroundColor',Fig.Background);
LogoAx = axes('box','off','units','pixels','position', [120, 520, 260, 42],'color',Fig.Background);
image(Logo);
axis off



%======== Set group controls positions
Fig.UnusedChanCol           = [0.5,0.5,0.5];
Fig.UsedChanCol             = [0, 1, 0];
Fig.PannelNames             = {'Analog IN','Analog OUT','Digital IN','Digital OUT'};
Fig.AllPannelChannels       = {'Params.DPx.AnalogInCh','Params.DPx.AnalogOutCh','Params.DPx.DigitalInCh','Params.DPx.DigitalOutCh'};
Fig.AllPannelChannelnames   = {'Params.DPx.AnalogInNames', 'Params.DPx.AnalogOutNames','Params.DPx.DigitalInNames','Params.DPx.DigitalOutNames'};
Fig.AllPannelChannelAssign  = {'Params.DPx.AnalogInAssign','Params.DPx.AnalogOutAssign','Params.DPx.DigitalInAssign','Params.DPx.DigitalOutAssign'};


%============= CREATE PANELS
for p = 1:numel(Fig.PannelNames)
    BoxXpos(p)      = Fig.Margin + (Fig.PannelSize(1)+Fig.Margin)*(p-1);
    PannelPos{p}    = [BoxXpos(p), Fig.Rect(4)-Fig.PannelSize(2)-50, Fig.PannelSize]; 

    Fig.SystemHandle = uipanel( 'Title',Fig.PannelNames{p},...
                    'FontSize',Fig.TitleFontSize,...
                    'BackgroundColor',Fig.Background,...
                    'Units','pixels',...
                    'Position',PannelPos{p},...
                    'Parent',Fig.Handle); 
    
    Ypos         	= PannelPos{p}(4)-Fig.Margin*2.5;
    ChannelList     = eval(Fig.AllPannelChannels{p});               % Get channel numbers for this pannel
    ChannelNames    = eval(Fig.AllPannelChannelnames{p});           % Get I/O names that can be assigned to this pannel
    ChannelAssign   = eval(Fig.AllPannelChannelAssign{p});          % Get channel assignments
    if numel(ChannelAssign) < numel(ChannelList)
        NoneIndx = find(~cellfun(@isempty, strfind(ChannelNames, 'None')));
        ChannelAssign(end+1:numel(ChannelList)) = NoneIndx;
    end
    
    %============= CREATE FIELDS
    for n = 1:numel(ChannelList)
        Fig.ChH(p,n) = uicontrol('Style', 'text','String',ChannelList{n},'Position', [Fig.Margin,Ypos,Fig.PannelElWidths(1),20],'Parent',Fig.SystemHandle,'HorizontalAlignment', 'left');
        Fig.h(p,n) = uicontrol('Style', 'popup','String',ChannelNames,'value', ChannelAssign(n), 'Position', [Fig.PannelElWidths(1)+10,Ypos,Fig.PannelElWidths(2),20],'Parent',Fig.SystemHandle,'HorizontalAlignment', 'left','Callback',{@ChannelUpdate,p,n});
        if strfind(ChannelNames{ChannelAssign(n)}, 'None')
            set(Fig.ChH(p,n), 'BackgroundColor', Fig.UnusedChanCol);
        else
            set(Fig.ChH(p,n), 'BackgroundColor', Fig.UsedChanCol);
        end
        Ypos = Ypos-25;
    end
%     set(h(1:numel(SystemLabels)), 'BackgroundColor', Fig.Background);

end




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
    function ChannelUpdate(hObj, Evnt, Indx1, Indx2)
 
        %========== Update channel color code
        Selection = get(hObj, 'value');
        Channelnames = eval(Fig.AllPannelChannelnames{Indx1});
        if strcmp(Channelnames{Selection},'None')
            set(Fig.ChH(Indx1, Indx2), 'BackgroundColor', Fig.UnusedChanCol);
        else
            set(Fig.ChH(Indx1, Indx2), 'BackgroundColor', Fig.UsedChanCol);
        end
        
        %========== Update params
        switch Indx1 
            case 1  %========= ANALOG IN
                Params.DPx.AnalogInAssign(Indx2) = Selection;
                
            case 2  %========= ANALOG OUT
                Params.DPx.AnalogOutAssign(Indx2) = Selection;
                
            case 3  %========= DIGITAL IN
                Params.DPx.DigitalInAssign(Indx2) = Selection;
                
            case 4  %========= DIGITAL OUT
                Params.DPx.DigitalOutAssign(Indx2) = Selection;
                
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
                Dpx = Params.Dpx;
                save(Params.File, 'Dpx', '-append');
                msgbox(sprintf('Parameters file saved to ''%s''!', Params.File),'Saved');

            case 3      %================ CLOSE PARAMETERS GUI
                ParamsOut = [];         % Clear params
                close(Fig.Handle);      % Close GUI figure
                return;
        end
    end

end