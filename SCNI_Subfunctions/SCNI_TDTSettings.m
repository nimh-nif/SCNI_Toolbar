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

%============ Initialize GUI
GUItag      = 'SCNI_TDTSettings';           % String to use as GUI window tag
Fieldname   = 'TDT';                        % Params structure fieldname for DataPixx info
if ~exist('OpenGUI','var')
    OpenGUI = 1;
end
if ~exist('ParamsFile','var')
    ParamsFile = [];
end
[Params, Success, Fig]   = SCNI_InitGUI(GUItag, Fieldname, ParamsFile, OpenGUI);

%=========== Load default parameters
if Success < 1                              % If the parameters could not be loaded...
    Params.TDT.UseSynapse           = 0;
    Params.TDT.UseOpenEX            = 1;
    Params.TDT.Host_IP              = '156.40.249.201';
    Params.TDT.RS4_IP               = '156.40.249.101';
    Params.TDT.Modes                = {'Idle','Standby','Preview','Record'};
  	Params.TDT.SubjectID            = 'Spice';
    Params.TDT.SpeciesIndx          = 3;
    Params.TDT.SpeciesList          = {'mouse', 'rat', 'monkey', 'marmoset', 'human', 'bat', 'owl', 'bird', 'ferret', 'gerbil','guinea-pig', 'rabbit', 'pig', 'cat', 'dog', 'fish', 'dolphin','snake', 'shark', 'duck', 'cow', 'goat', 'horse'};
    Params.TDT.TankPath             = 'C:\TDT\NEXTTANK';
    Params.TDT.StimRange            = [1, 7999];
    Params.TDT.Events               = SCNI_LoadEventCodes;
elseif Success > 1
    return;
end




%========================= OPEN GUI WINDOW ================================
Fig.Handle          = figure;                                           % Assign GUI arbitrary integer   
setappdata(0,GUItag,Fig.Handle);
Fig.Rect            = [0 200 700 800]*Fig.DisplayScale;              	% Specify figure window rectangle
Fig.PannelSize      = [170, 650]*Fig.DisplayScale;                                       
Fig.PannelElWidths  = [30, 120]*Fig.DisplayScale;
set(Fig.Handle,     'Name','SCNI: TDT settings',...                     % Open a figure window with specified title
                    'Tag','SCNI_TDTSettings',...                        % Set figure tag
                    'Renderer','OpenGL',...                             % Use OpenGL renderer
                    'OuterPosition', Fig.Rect,...                       % position figure window
                    'NumberTitle','off',...                             % Remove figure number from title
                    'Resize', 'off',...                                 % Prevent resizing of GUI window
                    'Menu','none',...                                   % Turn off memu
                    'Toolbar','none');                                  % Turn off toolbars to save space
Fig.Background  = get(Fig.Handle, 'Color');                           	% Get default figure background color
Fig.Margin      = 20*Fig.DisplayScale;                               	% Set margin between UI panels (pixels)                                 
Fig.Fields      = fieldnames(Params);                                 	% Get parameter field names
Fig.PannelNames	= {'', 'Synapse settings','Event codes'};
Fig.PannelPos  	= {[],[20,140,340,500],[380,140,280,500]};


%============= CREATE MAIN PANEL
Fig.TopPanelHandle  = uipanel('BackgroundColor',Fig.Background,...       
                    'Units','pixels',...
                    'Position',[Fig.Margin, Fig.Rect(4)-(120+20)*Fig.DisplayScale, Fig.Rect(3)-50*Fig.DisplayScale, 110*Fig.DisplayScale],...
                    'Parent',Fig.Handle); 
[Fig.Logo, cm, alphaMask] = imread('Logo_TDT.png');
Fig.LogoAx    	= axes('box','off','units','pixels','position', [20, 20, 156, 60]*Fig.DisplayScale,'color',Fig.Background, 'Parent', Fig.TopPanelHandle);
imh         	= image(Fig.Logo);
alpha(imh, double(alphaMask/max(alphaMask(:))));
axis off;

Fig.SynapseURL  = 'http://www.tdt.com/files/manuals/SynapseAPIManual.pdf';
Fig.OpenEXURL   = 'http://www.tdt.com/files/manuals/OpenDeveloper_Manual.pdf';
Params.TDT.ClientSoftware = CheckClientSoftware;


%============= Add uicontrols to main panel
Fig.Detectionlabels = {'Not detected!','Detected'};
Fig.Labels  = {'Host software','Host IP address','Client software','RS4 IP address'};
Fig.Options = {{'Synapse','OpenEX'},Params.TDT.Host_IP, Fig.Detectionlabels{Params.TDT.ClientSoftware+1},Params.TDT.RS4_IP};
Fig.Style   = {'PopupMenu','Edit','Text','Edit'};
Fig.Values  = {Params.TDT.UseOpenEX+1, [], [], []};
Fig.ModesColors = {[0.5,0.5,0.5],[1,0,0],[1,1,0],[0,1,0]};

Ypos = 80*Fig.DisplayScale;
for n = 1:numel(Fig.Labels)
    uicontrol('Style', 'text','String', Fig.Labels{n}, 'position', [200*Fig.DisplayScale, Ypos, 120*Fig.DisplayScale, 20*Fig.DisplayScale], 'HorizontalAlignment', 'left','backgroundcolor',Fig.Background, 'parent', Fig.TopPanelHandle, 'Fontsize', Fig.FontSize);
    Fig.P1.uih(n) = uicontrol('Style', Fig.Style{n},'String', Fig.Options{n}, 'value', Fig.Values{n}, 'position', [320*Fig.DisplayScale, Ypos, 160*Fig.DisplayScale, 20*Fig.DisplayScale], 'HorizontalAlignment', 'left','callback',{@SystemSetting, n}, 'parent', Fig.TopPanelHandle, 'Fontsize', Fig.FontSize);
    Ypos = Ypos-25*Fig.DisplayScale;
end


%============
Fig.P2.Handle   = uipanel( 'Title',Fig.PannelNames{2},...
                    'FontSize',Fig.TitleFontSize,...
                    'BackgroundColor',Fig.Background,...
                    'Units','pixels',...
                    'Position', Fig.PannelPos{2}*Fig.DisplayScale,...
                    'Parent',Fig.Handle); 
Fig.P2.Labels   = {'Subject ID','Species','Server tank path'};
Fig.P2.Strings  = {Params.TDT.SubjectID, Params.TDT.SpeciesList, Params.TDT.TankPath};
Fig.P2.Values   = {[],Params.TDT.SpeciesIndx,[]};
Fig.P2.Styles   = {'Edit','PopupMenu','Edit'};
Ypos = 400*Fig.DisplayScale;
for n = 1:numel(Fig.P2.Labels)
    uicontrol('Style', 'text','String', Fig.P2.Labels{n}, 'position', [20*Fig.DisplayScale, Ypos, 120*Fig.DisplayScale, 20*Fig.DisplayScale], 'HorizontalAlignment', 'left','backgroundcolor',Fig.Background, 'parent', Fig.P2.Handle, 'Fontsize', Fig.FontSize);
    Fig.P2.uih(n) = uicontrol('Style', Fig.P2.Styles{n},'String', Fig.P2.Strings{n}, 'value', Fig.P2.Values{n}, 'position', [160*Fig.DisplayScale, Ypos, 160*Fig.DisplayScale, 20*Fig.DisplayScale], 'HorizontalAlignment', 'left','callback',{@SynapseSetting, n}, 'parent', Fig.P2.Handle, 'Fontsize', Fig.FontSize);
    Ypos = Ypos-25*Fig.DisplayScale;
end


%============
Fig.P3.Handle   = uipanel( 'Title',Fig.PannelNames{3},...
                    'FontSize',Fig.TitleFontSize,...
                    'BackgroundColor',Fig.Background,...
                    'Units','pixels',...
                    'Position', Fig.PannelPos{3}*Fig.DisplayScale,...
                    'Parent',Fig.Handle); 
Fig.P3.Labels   = fieldnames(Params.TDT.Event);
Fig.P3.Strings  = strtrim(cellstr(num2str((Params.TDT.StimRange(2)+(1:numel(Fig.P3.Labels))).')));
Fig.P3.Values   = 1:numel(Fig.P3.Labels);
Fig.P3.Styles   = 'PopupMenu';
Ypos = 400*Fig.DisplayScale;
uicontrol('Style', 'text','String', 'Stimulus ID range', 'position', [20*Fig.DisplayScale, Ypos, 120*Fig.DisplayScale, 20*Fig.DisplayScale], 'HorizontalAlignment', 'left','backgroundcolor',Fig.Background, 'parent', Fig.P3.Handle, 'Fontsize', Fig.FontSize);
Fig.P3.uih(1) = uicontrol('Style', 'Edit','String', num2str(Params.TDT.StimRange(1)), 'position', [160*Fig.DisplayScale, Ypos, 50*Fig.DisplayScale, 20*Fig.DisplayScale], 'HorizontalAlignment', 'left','callback',{@SynapseSetting, n}, 'parent', Fig.P3.Handle, 'Fontsize', Fig.FontSize);
Fig.P3.uih(2) = uicontrol('Style', 'Edit','String', num2str(Params.TDT.StimRange(2)), 'position', [220*Fig.DisplayScale, Ypos, 50*Fig.DisplayScale, 20*Fig.DisplayScale], 'HorizontalAlignment', 'left','callback',{@SynapseSetting, n}, 'parent', Fig.P3.Handle, 'Fontsize', Fig.FontSize);
Ypos = Ypos -25*Fig.DisplayScale;
for n = 1:numel(Fig.P3.Labels)
    uicontrol('Style', 'text','String', Fig.P3.Labels{n}, 'position', [20*Fig.DisplayScale, Ypos, 120*Fig.DisplayScale, 20*Fig.DisplayScale], 'HorizontalAlignment', 'left','backgroundcolor',Fig.Background, 'parent', Fig.P3.Handle, 'Fontsize', Fig.FontSize);
    Fig.P3.uih(n) = uicontrol('Style', Fig.P3.Styles,'String', Fig.P3.Strings, 'value', Fig.P3.Values(n), 'position', [160*Fig.DisplayScale, Ypos, 100*Fig.DisplayScale, 20*Fig.DisplayScale], 'HorizontalAlignment', 'left','callback',{@EventCodes, n}, 'parent', Fig.P3.Handle, 'Fontsize', Fig.FontSize);
    Ypos = Ypos-25*Fig.DisplayScale;
end



%============= CREATE PANELS
% for p = 1:numel(Fig.PannelNames)
%     BoxXpos(p)      = Fig.Margin + (Fig.PannelSize(1)+Fig.Margin)*(p-1);
%     PannelPos{p}    = [BoxXpos(p), Fig.Rect(4)-Fig.PannelSize(2)-50, Fig.PannelSize]; 
% 
%     Fig.SystemHandle = uipanel( 'Title',Fig.PannelNames{p},...
%                     'FontSize',Fig.TitleFontSize,...
%                     'BackgroundColor',Fig.Background,...
%                     'Units','pixels',...
%                     'Position',PannelPos{p},...
%                     'Parent',Fig.Handle); 
%     
%     Ypos         	= PannelPos{p}(4)-Fig.Margin*2.5;
%     ChannelList     = eval(Fig.AllPannelChannels{p});               % Get channel numbers for this pannel
%     ChannelNames    = eval(Fig.AllPannelChannelnames{p});           % Get I/O names that can be assigned to this pannel
%     ChannelAssign   = eval(Fig.AllPannelChannelAssign{p});          % Get channel assignments
%     if numel(ChannelAssign) < numel(ChannelList)
%         NoneIndx = find(~cellfun(@isempty, strfind(ChannelNames, 'None')));
%         ChannelAssign(end+1:numel(ChannelList)) = NoneIndx;
%     end
%     
%     %============= CREATE FIELDS
%     for n = 1:numel(ChannelList)
%         Fig.ChH(p,n) = uicontrol('Style', 'text','String',ChannelList{n},'Position', [Fig.Margin,Ypos,Fig.PannelElWidths(1),20],'Parent',Fig.SystemHandle,'HorizontalAlignment', 'left');
%         Fig.h(p,n) = uicontrol('Style', 'popup','String',ChannelNames,'value', ChannelAssign(n), 'Position', [Fig.PannelElWidths(1)+10,Ypos,Fig.PannelElWidths(2),20],'Parent',Fig.SystemHandle,'HorizontalAlignment', 'left','Callback',{@ChannelUpdate,p,n});
%         if strfind(ChannelNames{ChannelAssign(n)}, 'None')
%             set(Fig.ChH(p,n), 'BackgroundColor', Fig.UnusedChanCol);
%         else
%             set(Fig.ChH(p,n), 'BackgroundColor', Fig.UsedChanCol);
%         end
%         Ypos = Ypos-25;
%     end
% %     set(h(1:numel(SystemLabels)), 'BackgroundColor', Fig.Background);
% 
% end




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
    function SystemSetting(hObj, Evnt, Indx)
        
        switch Indx
            case 1      %==================== Change TDT host software
                Params.TDT.UseOpenEX    = get(hObj, 'value')-1;
                Params.TDT.UseSynapse   = ~Params.TDT.UseOpenEX;
                Params.TDT.ClientSoftware  = CheckClientSoftware;
                set(Fig.P1.uih(3), 'string', Fig.Detectionlabels{Params.TDT.ClientSoftware+1});
                
            case 2
                Params.TDT.Host_IP = get(hObj, 'string');
            case 4
                Params.TDT.RS4_IP = get(hObj, 'string');
        end
    end

    %================ Check whether client has necessary software
    % installed for communication with server
    function ClientSoftware = CheckClientSoftware
        if ~exist('SynapseAPI','file')
            Params.TDT.SoftwareTools(1) = 0;
        else
            Params.TDT.SoftwareTools(1) = 1;
        end
        if ~exist('actxcontrol','file')
            Params.TDT.SoftwareTools(2) = 0;
            if ~IsWin && Params.TDT.UseOpenEX == 1
                WarningMsg = 'ActiveX server required for communication with TDT OpenEX is only available on Microsoft Windows!';
                msgbox(WarningMsg,'Communication with OpenEX unavailable!','non-modal');
            end
        else
            Params.TDT.SoftwareTools(2) = 1;
        end
        ClientSoftware = Params.TDT.SoftwareTools(Params.TDT.UseOpenEX+1);
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

    %===============
    function Synapse(Params)
        syn     = SynapseAPI(Params.TDT.Host_IP);                       % create Synapse API connection
        if syn.getMode() < 1,                                           % switch into a runtime mode (Preview in this case)
            syn.setMode(2);                                             % switch into a runtime mode (Preview in this case)
        end                       
        GIZMO       = 'TagTest1';
        PARAMETER   = 'MyArray';                          
        info        = syn.getParameterInfo(GIZMO, PARAMETER);               % get all info on the 'MyArray' parameter
        sz          = syn.getParameterSize(GIZMO, PARAMETER);            	% get the array size (should be 100)
        result      = syn.setParameterValues(GIZMO, PARAMETER, 1:50, 50); 	% write values 1 to 50 in first half of buffer

        syn.getParameterValues(GIZMO, PARAMETER, sz);                       % read all values from buffer

        PARAMETER   = 'Go';
        info        = syn.getParameterInfo(GIZMO, PARAMETER);           % get all info on the 'Go' parameter
        result      = syn.setParameterValue(GIZMO, PARAMETER, 1);       % flip the switch
        value       = syn.getParameterValue(GIZMO, PARAMETER);          % check the value
        fprintf('value = %d\n', value);

        dValue = getParameterValue(sGizmo, sParameter);
        
        gizmo_names = syn.getGizmoNames();
        if numel(gizmo_names) < 1
            error('no gizmos found')
        end
        
        % also verify visually that the switch slipped in the run
        % time interface. This state change will be logged just
        % like any other variable change and saved with the runtime
        % state.
        
        
        %============= Get info
        Params.TDT.currUser        = syn.getCurrentUser();
        Params.TDT.currExperiment  = syn.getCurrentExperiment();
        Params.TDT.currSubject     = syn.getCurrentSubject();
        Params.TDT.currTank        = syn.getCurrentTank();
        Params.TDT.currBlock       = syn.getCurrentBlock();

        result = syn.getKnownExperiments()
        if numel(result) < 1
            error('no experiments found')
        end
        
        result = syn.getKnownSubjects()
        if numel(result) < 1
            error('no subjects found')
        end
        
        result = syn.getKnownUsers()
        if numel(result) < 1
            error('no users found')
        end
        
        
        %=================

        
        syn.createSubject(nextSub, 'Control',Params.TDT.SpeciesList{Params.TDT.SpeciesIndx})
        syn.setCurrentSubject(Params.TDT.SubjectID)
        
        %================= Create tank
        syn.createTank(Params.TDT.TankPath);
        syn.setCurrentTank(Params.TDT.TankPath);
        
        %================= Create block
        NextBlock = 'MyBlockName';
        syn.setCurrentBlock(NextBlock)

        %================= Add memo notes
        currSubject = syn.currentSubject()
        syn.appendSubjectMemo(currSubject,'Subject memo from Matlab')
        currUser = syn.currentUser()
        syn.appendUserMemo(currUser, 'User memo from Matlab')
        currExperiment = syn.currentExperiment()
        syn.appendExperimentMemo(currExperiment,'Experiment memo from Matlab 1')
    end

end