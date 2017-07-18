function [s,c] = SCNI_PlotEyeData(EyePos, s, c)

%========================= SCNI_PlotEyeTrace.m ============================
% Plots eye data for a single trial of calibration and allows the user to
% manually adjust the offset and gain parameters.
%
% INPUTS:   EyePos: a 4xN matrix containing N samples of eye voltages, with 
%                   rows corresponding to the following:
%                   1) Left eye X voltage
%                   2) Left eye Y voltage (V)
%                   3) Right eye X voltage (V)
%                   4) Right eye Y voltage (V)
%
%==========================================================================


% if IsLinux == 1
%     s.Fig.GazeWinPos = [66, 544, 910, 430];
% elseif IsOSX
%     s.Fig.GazeWinPos = [3840, 535, 900, 450];
% end


% global s
% global c


%========= Check whether eye data figure window is already open
if nargin == 0 || ~isfield(s, 'Fig') || ~ishandle(s.Fig.Handle)
    s.Fig.Background    = [0.9,0.9,0.9];
    s.Fig.Fontsize      = 14;
    s.Fig.GazeWinPos    = [1, 400, 1100, 600];
    s.Fig.Handle        = figure('name','SCNI_PlotEyeData','position',s.Fig.GazeWinPos,'color',s.Fig.Background);
    FirstPlot           = 1;
    
 	%========= Set default analysis parameters based on assumptions about reaction time
    s.CurrentEye        = 1;                                % 1 = Left; 2 = Right; 3 = Version
    s.Fig.EyeStrings    = {'Left eye','Right eye','Version (L+R)'};
    s.VoltageRange      = [-5, 5];                          % Range of ADC voltages (V)
    s.InitWinTimes      = [0, 0.1];                         % Time window of initial eye position (seconds from target onset)
    s.SacWinTimes       = [0.2, 0.3];                       % Time window of likely saccade to target (seconds from target onset)
    s.FixWinTimes       = [0.3, 0.5];                       % Time window of likely fixation on target (seconds from target onset)
    s.EpochColors       = [1, 0 0; 1 1 0; 0 1 0];           
    s.EpochNames        = {'Pre', 'Saccade', 'Fix'};
    s.Fig.ChangeInc     = 0.05;                             % Increment size when adjusting voltages with arrow keys (V)
    s.Fig.EpochInc  	= 10;                               % Increment size when adjusting time windows with arrow keys (ms)
    if nargin == 0
        c.adcRate           = 1000;                              % Default ADC smapling rate (Hz)
        c.Display.Rect      = [1920, 1080];
        c.Display.PixPerDeg	= [35, 35];
    end
    
    
    %========= Parse input EyePos
    if nargin > 0
        NoEyeChannels      	= min(size(EyePos));
    else
        NoEyeChannels      	= 2;
    end
    if NoEyeChannels<4                                      % If eye data matrix only contains less than 4 channels...
        s.Fig.EyeStrings    = {'Left eye'};                 % Only use left eye    
        s.Fig.EyeIndx{1}   	= [1,2];                        % Channel indices for left eye (X and Y)
        s.Fig.EyeIndx{2}   	= [];
        s.Fig.PupilIndx    	= [];
    end
    if NoEyeChannels == 4
        s.Fig.EyeIndx{1} 	= [1,2];                        % Channel indices for left eye (X and Y)
        s.Fig.EyeIndx{2}   	= [3,4];                        % Channel indices for right eye (X and Y)
        s.Fig.PupilIndx    	= [];
    elseif NoEyeChannels == 6
        s.Fig.EyeIndx{1}  	= [1,2];
        s.Fig.EyeIndx{2}  	= [4,5];
        s.Fig.PupilIndx   	= [3,6];
    end
       
    
else
    c.EyePos = EyePos;
    FirstPlot = 0;                  % This is not the first trial to be plotted
    figure(s.Fig.Handle);           % Make figure window active
    delete(s.ph);                   % Delete plotted data from previous trial
end

c.Display.RectDeg   = c.Display.Rect./c.Display.PixPerDeg;
EpochWinSamples{1}  = (s.InitWinTimes(1)*c.adcRate)+1:(s.InitWinTimes(2)*c.adcRate);
EpochWinSamples{2} 	= (s.SacWinTimes(1)*c.adcRate):(s.SacWinTimes(2)*c.adcRate);
EpochWinSamples{3}  = (s.FixWinTimes(1)*c.adcRate):(s.FixWinTimes(2)*c.adcRate);


%============== Generate simulated eye position data
if nargin == 0  
    TargetLoc       = [0, 0];           % Ideal central fixation voltage
    GazeWinradius   = 2;                % Initial central fixation voltage window
    EyeOffset       = 0.8;
    InitialOffset   = 2.5;      
    FinalOffset     = -2.5;
    Variance        = 0.2;
    SaccadeDur      = 30;
    TargetDuration  = 0.3;              % How long did the target appear for
    
    EyePos = nan(2,1000);
    EyePos(:,1:200) = (randn(2,200)*Variance)+repmat(InitialOffset, [2,200]);
    EyePos(:,201:200+SaccadeDur) = repmat(linspace(InitialOffset, 0, SaccadeDur),[2,1]);
    EyePos(:,(200+SaccadeDur+1):600) = (randn(2,400-SaccadeDur)*Variance);
    EyePos(:,601:(600+SaccadeDur)) = repmat(linspace(0, FinalOffset, SaccadeDur),[2,1]);
    EyePos(:,600+SaccadeDur+1:end) = (randn(2,(1000-600-SaccadeDur))*Variance)+repmat(FinalOffset, [2,(1000-600-SaccadeDur)]);
    EyePos      = EyePos+EyeOffset;
    c.EyeGain   = [6.2, 6.4];
    c.EyeOffset = [-0.5,0.8]; 
    c.EyePos    = EyePos;
else
    TargetDuration  = c.StimDuration;
    
end

s.Fig.CalibFilename = 'Test_calib.mat';

%=================== PLOT NEW DATA
if FirstPlot == 1
    s.Fig.Axh(1) = axes('units','normalized','position',[0.05, 0.05, 0.26, 0.8],'tickdir','out');
else
    axes(s.Fig.Axh(1));
end

s.ph(1) = plot(EyePos(1,:), EyePos(2,:),'-k','color', [0.5, 0.5, 0.5]);
hold on;
for n = 1:3
    s.ph(n+1) = plot(EyePos(1,EpochWinSamples{n}), EyePos(2,EpochWinSamples{n}),'-k','color', [s.EpochColors(n,:),0.5]);
end
MedianFix = [median(EyePos(1,EpochWinSamples{n})), median(EyePos(2,EpochWinSamples{n}))];
s.ph(n+2) = DrawCircle(MedianFix, 0.5, [0 1 0], 0.3, 1);

if FirstPlot == 1
    legend(s.ph(2:4), s.EpochNames, 'location', 'northwest','fontsize', s.Fig.Fontsize);
    grid on
    axis equal
    set(s.Fig.Axh(1), 'xlim', s.VoltageRange, 'ylim', s.VoltageRange, 'xtick', s.VoltageRange(1):1:s.VoltageRange(2),'color', [0.75,0.75,0.75]);
    xlabel(s.Fig.Axh(1),'X voltage (V)','fontsize', s.Fig.Fontsize);
    ylabel(s.Fig.Axh(1),'Y voltage (V)','fontsize', s.Fig.Fontsize);
    s.Fig.Vcenter(1) = plot(s.VoltageRange, [0 0], '--k');
    s.Fig.Vcenter(2) = plot([0 0], s.VoltageRange, '--k');
    
    %========== Plot in DVA
    s.Fig.Axh(2) = axes('Position',get(s.Fig.Axh(1),'position'),'XAxisLocation','top','YAxisLocation','right','Color','none','tickdir','out');
    s.Fig.Axh(2).XColor = 'r';                                      % Set DVA axis color
    s.Fig.Axh(2).YColor = 'r';                                      % Set DVA axis color
  	axis tight                                                      
    DVA_Xrange = (s.VoltageRange-c.EyeOffset(1))*c.EyeGain(1);      % Calculate range of possible DVA values from voltage range
    DVA_Yrange = (s.VoltageRange-c.EyeOffset(2))*c.EyeGain(2);      % Calculate range of possible DVA values from voltage range
    set(s.Fig.Axh(2), 'xlim', DVA_Xrange, 'ylim', DVA_Yrange);      % Set axis limits based on calculated range
  	xlabel(s.Fig.Axh(2),'X position (degrees)','fontsize', s.Fig.Fontsize);
    ylabel(s.Fig.Axh(2),'Y position (degrees)','fontsize', s.Fig.Fontsize);
    grid on                                                         
    s.Fig.DisplayFrame = rectangle('position', [0,0,c.Display.RectDeg]-[c.Display.RectDeg,0,0]/2,'edgecolor',[1 0 0],'linewidth',2);
    hold on
    s.Fig.DVAcenter(1) = plot(DVA_Xrange, [0 0], '--r');            % Draw cross-hairs to mark center of display (DVA)
    s.Fig.DVAcenter(2) = plot([0 0], DVA_Yrange, '--r');            % Draw cross-hairs to mark center of display (DVA)
    h = DrawCircle([0,0], 1, [0 0 0], 1, 0);                        % Draw circle to mark center of screen (0 DVA)
    daspect([1, diff(DVA_Yrange)/diff(DVA_Xrange), 1]);             % Set aspect ratio of plot in DVA
    
end


%=================== EYE POSITION TIME COURSE
if FirstPlot == 1
    s.Fig.Axh(3) = subplot(2,3,2);
else
    axes(s.Fig.Axh(3));
end
s.Fig.TimeStamps = (1:size(EyePos,2))*c.adcRate/1000;

s.ph(5) = plot(s.Fig.TimeStamps, EyePos(1,:),'-r','color',[1,0.5,0.5]);
hold on;
s.ph(6) = plot(s.Fig.TimeStamps, EyePos(2,:),'-b','color',[0.5,0.5,1]);
s.ph(7) = plot(s.FixWinTimes*c.adcRate, repmat(mean(EyePos(1,EpochWinSamples{3})),[1,2]),'-r','linewidth',2);
s.ph(8) = plot(s.FixWinTimes*c.adcRate, repmat(mean(EyePos(2,EpochWinSamples{3})),[1,2]),'-b','linewidth',2);
if FirstPlot == 1
    xlabel('Time (ms)','fontsize', s.Fig.Fontsize);
    ylabel('Voltage (V)','fontsize', s.Fig.Fontsize);
    grid on;
    legend(s.ph(7:8),{'X','Y'},'fontsize', s.Fig.Fontsize);
    Ylims = s.VoltageRange;
    s.Fig.EpochH(1) = patch(s.InitWinTimes([1,1,2,2])*c.adcRate, Ylims([1,2,2,1]), zeros(1,4),'facecolor',s.EpochColors(1,:),'facealpha', 0.3,'edgecolor', 'none');
    s.Fig.EpochH(2) = patch(s.SacWinTimes([1,1,2,2])*c.adcRate, Ylims([1,2,2,1]), zeros(1,4),'facecolor',s.EpochColors(2,:),'facealpha', 0.3,'edgecolor', 'none');
    s.Fig.EpochH(3) = patch(s.FixWinTimes([1,1,2,2])*c.adcRate, Ylims([1,2,2,1]), zeros(1,4),'facecolor',s.EpochColors(3,:),'facealpha', 0.3,'edgecolor', 'none');
    plot([0, TargetDuration*c.adcRate], [0 0], '-k', 'linewidth', 4);
    uistack(s.Fig.EpochH, 'bottom')
end


%=================== BOX AND WHISKER PLOTS
if FirstPlot == 1
	s.Fig.Axh(4) = subplot(2,3,5);
else
    axes(s.Fig.Axh(4));
end
EyePosDist   = sqrt(c.EyePos(1,:).^2 + c.EyePos(2,:).^2);                      % Combine X and Y vectors into single position vector
for n = 1:3
    s.Fig.bph{n} = boxplot(EyePosDist(:,EpochWinSamples{n}),'Notch','on','boxstyle','filled','colors',s.EpochColors(n,:));
    hold on
    for ch = 1:numel(s.Fig.bph{n})
        set(s.Fig.bph{n}(ch), 'Xdata', get(s.Fig.bph{n}(ch), 'Xdata')+n-1);
    end
	set(s.Fig.bph{n}(5), 'color', [0,0,0]);
	set(s.Fig.bph{n}(6), 'color', [0,0,0], 'linewidth', 2);
end
if FirstPlot == 1
    grid on;
    ylabel('Distance from target (V)','fontsize', s.Fig.Fontsize)
    set(gca, 'xlim',[0.5, 3.5], 'xtick',1:3, 'xticklabel', s.EpochNames,'ylim',[0, s.VoltageRange(2)],'fontsize', s.Fig.Fontsize);
end



%% ========================= ADD GUI CONTROLS =============================
if FirstPlot == 1
    s.Fig.PannelPos     = [0.66,0.42,0.33,0.55];
    s.Fig.ArrowColor    = [0.7,0.9,1];
    s.Fig.Labels        = {'Offset (V)','Gain (deg/V)', 'Range (V)'};
    s.Fig.EpochLabels   = {'Onset', 'Saccade', 'Fixation'};
    s.Fig.EpochValues   = {s.InitWinTimes, s.SacWinTimes, s.FixWinTimes};
    s.Fig.Values        = {c.EyeOffset, c.EyeGain, s.VoltageRange};
    s.Fig.PanelHandle   = uipanel('Title','Eye tracker calibration',...
                        'FontSize', s.Fig.Fontsize+2,...
                        'BackgroundColor',s.Fig.Background,...
                        'Units','normalized',...
                        'Position',s.Fig.PannelPos,...
                        'Parent', s.Fig.Handle); 

    uicontrol('Style', 'text','String', 'Method', 'Position', [20, 255, 80, 20], 'HorizontalAlignment', 'left', 'Parent', s.Fig.PanelHandle,'FontSize', s.Fig.Fontsize,'backgroundcolor', s.Fig.Background);
    uicontrol('Style', 'Popup','String', {'Manual','Automated (time)','Automated (position)'}, 'Position', [110, 255, 160, 20], 'HorizontalAlignment', 'left', 'Parent', s.Fig.PanelHandle,'FontSize', s.Fig.Fontsize,'Callback',{@ChangeMethod});
    uicontrol('Style', 'text','String', 'Select eye', 'Position', [20, 230, 80, 20], 'HorizontalAlignment', 'left', 'Parent', s.Fig.PanelHandle,'FontSize', s.Fig.Fontsize,'backgroundcolor', s.Fig.Background);
    s.Fig.EyeSelectH = uicontrol('Style', 'Popup','String', s.Fig.EyeStrings, 'Position', [110, 230, 160, 20], 'HorizontalAlignment', 'left', 'Parent', s.Fig.PanelHandle,'FontSize', s.Fig.Fontsize,'Callback',{@ChangeEye},'value', s.CurrentEye);
    uicontrol('Style', 'text','String', 'X', 'Position', [120, 200, 80, 20], 'HorizontalAlignment', 'left', 'Parent', s.Fig.PanelHandle,'FontSize', s.Fig.Fontsize, 'backgroundcolor', s.Fig.Background);
    uicontrol('Style', 'text','String', 'Y', 'Position', [220, 200, 80, 20], 'HorizontalAlignment', 'left', 'Parent', s.Fig.PanelHandle,'FontSize', s.Fig.Fontsize, 'backgroundcolor', s.Fig.Background);

    Ypos = 180;
    for n = 1:numel(s.Fig.Labels)
        uicontrol('Style', 'text','String',s.Fig.Labels{n},'Position', [20, Ypos, 100, 20],'Parent',s.Fig.PanelHandle, 'HorizontalAlignment', 'left', 'FontSize', s.Fig.Fontsize, 'backgroundcolor', s.Fig.Background);
        Xpos = 120;
        for xy = 1:2
            s.Fig.Edit(n, xy)     = uicontrol('Style', 'Edit','String', sprintf('%.2f', s.Fig.Values{n}(xy)), 'Position', [Xpos,Ypos,50,20],'Parent',s.Fig.PanelHandle,'HorizontalAlignment', 'left','FontSize', s.Fig.Fontsize,'Callback',{@CalibUpdate,1,n,xy});
            s.Fig.Arrow(n, xy, 1) = uicontrol('Style', 'PushButton', 'String', '<','Position', [Xpos+50,Ypos,20,20],'Parent',s.Fig.PanelHandle,'HorizontalAlignment', 'left','FontSize', s.Fig.Fontsize,'Callback',{@CalibUpdate,2,n,xy}, 'backgroundcolor', s.Fig.ArrowColor);
            s.Fig.Arrow(n, xy, 2) = uicontrol('Style', 'PushButton', 'String', '>','Position', [Xpos+70,Ypos,20,20],'Parent',s.Fig.PanelHandle,'HorizontalAlignment', 'left','FontSize', s.Fig.Fontsize,'Callback',{@CalibUpdate,3,n,xy}, 'backgroundcolor', s.Fig.ArrowColor);
            Xpos = Xpos + 100;
        end
        Ypos = Ypos-25;
    end

    Ypos = Ypos - 15;
    uicontrol('Style', 'text','String', 'Start (ms)', 'Position', [120, Ypos, 80, 20], 'HorizontalAlignment', 'left', 'Parent', s.Fig.PanelHandle,'FontSize', s.Fig.Fontsize, 'backgroundcolor', s.Fig.Background);
    uicontrol('Style', 'text','String', 'End (ms)', 'Position', [220, Ypos, 80, 20], 'HorizontalAlignment', 'left', 'Parent', s.Fig.PanelHandle,'FontSize', s.Fig.Fontsize, 'backgroundcolor', s.Fig.Background);
    Ypos = Ypos - 25;
    for n = 1:numel(s.Fig.EpochLabels)
        uicontrol('Style', 'text','String',s.Fig.EpochLabels{n},'Position', [20, Ypos, 100, 20],'Parent',s.Fig.PanelHandle, 'HorizontalAlignment', 'left', 'FontSize', s.Fig.Fontsize, 'backgroundcolor', s.Fig.Background);
        Xpos = 120;
        for r = 1:2
            s.Fig.TimeRange(n, r) = uicontrol('Style', 'Edit','String', sprintf('%.0f', s.Fig.EpochValues{n}(r)*10^3), 'Position', [Xpos,Ypos,50,20],'Parent',s.Fig.PanelHandle,'HorizontalAlignment', 'left','FontSize', s.Fig.Fontsize,'Callback',{@EpochUpdate,1,n,r});
            s.Fig.Arrow(n, xy, 1) = uicontrol('Style', 'PushButton', 'String', '<','Position', [Xpos+50,Ypos,20,20],'Parent',s.Fig.PanelHandle,'HorizontalAlignment', 'left','FontSize', s.Fig.Fontsize,'Callback',{@EpochUpdate,2,n,r}, 'backgroundcolor', s.Fig.ArrowColor);
            s.Fig.Arrow(n, xy, 2) = uicontrol('Style', 'PushButton', 'String', '>','Position', [Xpos+70,Ypos,20,20],'Parent',s.Fig.PanelHandle,'HorizontalAlignment', 'left','FontSize', s.Fig.Fontsize,'Callback',{@EpochUpdate,3,n,r}, 'backgroundcolor', s.Fig.ArrowColor);
            Xpos = Xpos + 100;
        end
        Ypos = Ypos - 25;
    end
    
    
    %============= STATUS PANNEL
    s.Fig.PannelPos2    = [0.66,0.18,0.33,0.22];
    s.Fig.PanelHandle2	= uipanel('Title','Calibration status',...
                        'FontSize', s.Fig.Fontsize+2,...
                        'BackgroundColor',s.Fig.Background,...
                        'Units','normalized',...
                        'Position',s.Fig.PannelPos2,...
                        'Parent', s.Fig.Handle); 
    s.Fig.Labels2     	= {'Eye detected','Criteria met','Fix. deviation','X:Y ratio'};
    s.Fig.Values2       = {10, 'Yes', 1.5, 0.5};
    s.Fig.StringFormat  = {'%.0f%%','%s','%.2f (dva)','%.3f'};
  	Ypos = 80;
    for n = 1:numel(s.Fig.Labels2)
        uicontrol('Style', 'text','String',s.Fig.Labels2{n},'Position', [20, Ypos, 100, 20],'Parent',s.Fig.PanelHandle2, 'HorizontalAlignment', 'left', 'FontSize', s.Fig.Fontsize, 'backgroundcolor', s.Fig.Background);
        s.Fig.StatusString(n) = uicontrol('Style', 'text','String',sprintf(s.Fig.StringFormat{n}, s.Fig.Values2{n}),'Position', [150, Ypos, 100, 20],'Parent',s.Fig.PanelHandle2, 'HorizontalAlignment', 'left', 'FontSize', s.Fig.Fontsize, 'backgroundcolor', s.Fig.Background);
        Ypos = Ypos - 25;
    end
    
    %============= OUTPUT PANNEL
    s.Fig.PannelPos3    = [0.66,0.02,0.33,0.15];
    s.Fig.PanelHandle3	= uipanel('Title','Output',...
                        'FontSize', s.Fig.Fontsize+2,...
                        'BackgroundColor',s.Fig.Background,...
                        'Units','normalized',...
                        'Position',s.Fig.PannelPos3,...
                        'Parent', s.Fig.Handle); 
    Ypos = 40;
    uicontrol('Style', 'text','String','Filename','Position', [20, Ypos, 100, 20],'Parent',s.Fig.PanelHandle3, 'HorizontalAlignment', 'left', 'FontSize', s.Fig.Fontsize, 'backgroundcolor', s.Fig.Background);
    s.Fig.MatfileH = uicontrol('Style', 'edit','String',s.Fig.CalibFilename,'Position', [140, Ypos, 200, 20],'Parent',s.Fig.PanelHandle3, 'HorizontalAlignment', 'left', 'FontSize', s.Fig.Fontsize);
    uicontrol('Style', 'pushbutton','String','...','Position', [320, Ypos, 20, 20],'Parent',s.Fig.PanelHandle3, 'HorizontalAlignment', 'left', 'FontSize', s.Fig.Fontsize, 'callback', {@CalibOutput, 1},'tooltip','Select previous calibration');
    Ypos = Ypos - 25;
    uicontrol('Style', 'pushbutton','String','Load','Position', [20, Ypos, 100, 20],'Parent',s.Fig.PanelHandle3, 'HorizontalAlignment', 'left', 'FontSize', s.Fig.Fontsize, 'backgroundcolor', s.Fig.Background, 'callback', {@CalibOutput, 1});
    uicontrol('Style', 'pushbutton','String','Save','Position', [140, Ypos, 100, 20],'Parent',s.Fig.PanelHandle3, 'HorizontalAlignment', 'left', 'FontSize', s.Fig.Fontsize, 'backgroundcolor', s.Fig.Background, 'callback', {@CalibOutput, 2});
end




%% ========================== SUBFUNCTIONS ================================

    %================ Draw a filled circle
    function h = DrawCircle(xy, rad, rgb, alpha, filled)
        h = rectangle('Position',[-rad,-rad,rad*2,rad*2]+[xy,xy],'Curvature',1);
        if filled == 0
            set(h, 'edgecolor', [rgb, alpha]);
        elseif filled == 1
            set(h, 'facecolor', [rgb, alpha],'edgecolor','none');
        end
    end

    %================ CHANGE METHOD
    function ChangeMethod(hObj, Event, Indx)
        Indx = get(hObj, 'value');
        switch Indx
            case 1
                set(s.Fig.Edit, 'enable', 'on');
                set(s.Fig.Arrow, 'enable', 'on');
                set(s.Fig.TimeRange, 'enable', 'off');
            case 2
                set(s.Fig.TimeRange, 'enable', 'on');
                set(s.Fig.Edit, 'enable', 'off');
                set(s.Fig.Arrow, 'enable', 'off');
            case 3

        end

    end

    %================ CHANGE EYE
    function ChangeEye(hObj, Event, Indx)
        s.CurrentEye = get(hObj, 'value');
        switch s.Fig.EyeStrings{s.CurrentEye}
            case 'Left eye'
                EyeData = EyePos(1:2,:);
            case 'Right eye'
                EyeData = EyePos(3:4,:);
            case 'Version (L+R)'
                EyeData = EyePos(1:2,:) + EyePos(3:4,:);
        end
        %======= Update GUI values for selected eye
        for n = 1:numel(s.Fig.Labels)
            for xy = 1:2
                set(s.Fig.Edit(n, xy), 'String', sprintf('%.2f', s.Fig.Values{n}(xy)));
            end
        end

    end

    %================ UPDATE CALIBRATION VALUES
    function CalibUpdate(hObj, Event, Indx1, Indx2, Indx3)
        switch Indx1
             case 1     %============= New edit value was entered
                String = get(hObj, 'String');
    %             if Indx3 == 1 && str2num(String)< s.Fig.Values{Indx2}(2)
    %                 s.Fig.Values{Indx2}(Indx3) = str2num(String);
    %             elseif Indx3 == 2 && str2num(String)> s.Fig.Values{Indx2}(1)
                    s.Fig.Values{Indx2}(Indx3) = str2num(String);
    %             else
    %                 
    %             end

             case 2     %============= Down arrow button was pressed
                s.Fig.Values{Indx2}(Indx3) = s.Fig.Values{Indx2}(Indx3)-s.Fig.ChangeInc;
                set(s.Fig.Edit(Indx2, Indx3), 'string', sprintf('%.2f', s.Fig.Values{Indx2}(Indx3)));

             case 3     %============= Up arrow button was pressed
                s.Fig.Values{Indx2}(Indx3) = s.Fig.Values{Indx2}(Indx3)+s.Fig.ChangeInc;
                set(s.Fig.Edit(Indx2, Indx3), 'string', sprintf('%.2f', s.Fig.Values{Indx2}(Indx3)));
         end
         c.EyeOffset    = s.Fig.Values{1};
         c.EyeGain      = s.Fig.Values{2};
         s.VoltageRange = s.Fig.Values{3};
         UpdatePlots;
    end

    %================ UPDATE CALIBRATION PLOTS
    function UpdatePlots

        %========= Update axes 1 range
        if diff(s.VoltageRange) <= 10
            VoltageTicks = round(s.VoltageRange(1)):1:s.VoltageRange(2);
        else
           VoltageTicks = round(s.VoltageRange(1)):2:s.VoltageRange(2);
        end
        set(s.Fig.Axh(1), 'xlim', s.VoltageRange, 'ylim', s.VoltageRange, 'xtick', VoltageTicks, 'ytick', VoltageTicks);
        set(s.Fig.Axh(3), 'ylim', s.VoltageRange, 'ytick', VoltageTicks);
        set(s.Fig.Vcenter(1), 'xdata', s.VoltageRange);
        set(s.Fig.Vcenter(2), 'ydata', s.VoltageRange);
        DVA_Xrange = (s.VoltageRange-c.EyeOffset(1))*c.EyeGain(1);
        DVA_Yrange = (s.VoltageRange-c.EyeOffset(2))*c.EyeGain(2);
        set(s.Fig.Axh(2), 'xlim', DVA_Xrange, 'ylim', DVA_Yrange);
        set(s.Fig.EpochH, 'Ydata', s.VoltageRange([1,2,2,1]));
        set(s.Fig.Axh(2), 'position', get(s.Fig.Axh(1),'position'));
        set(s.Fig.DVAcenter(1),'Xdata',DVA_Xrange);
        set(s.Fig.DVAcenter(2),'Ydata',DVA_Yrange);
        axes(s.Fig.Axh(2));
        daspect([1, diff(DVA_Yrange)/diff(DVA_Xrange), 1]);     % Set aspect ratio of plot in DVA

        %========= Update box plots
        UpdateBoxPlot(1);
        UpdateBoxPlot(2);
        UpdateBoxPlot(3);
    end

    %================ UPDATE PARAMETERS FOR AUTOMATED CALIBRATION
    function EpochUpdate(hObj, Event, Indx1, Indx2, Indx3)

        switch Indx1
            case 1     %============= New edit value was entered
                if str2num(get(hObj,'string'))/10^3 >= 0 && str2num(get(hObj,'string'))/10^3 < s.Fig.TimeStamps(end)/10^3
                    s.Fig.EpochValues{Indx2}(Indx3) = str2num(get(hObj,'string'))/10^3;
                end

            case 2     %============= Down arrow button was pressed
                if s.Fig.EpochValues{Indx2}(Indx3) >= (s.Fig.EpochInc/10^3)
                    s.Fig.EpochValues{Indx2}(Indx3) = s.Fig.EpochValues{Indx2}(Indx3)-(s.Fig.EpochInc/10^3);
                    set(s.Fig.TimeRange(Indx2, Indx3), 'string', sprintf('%.0f', s.Fig.EpochValues{Indx2}(Indx3)*10^3));
                end

            case 3     %============= Up arrow button was pressed
                if s.Fig.EpochValues{Indx2}(Indx3) < s.Fig.TimeStamps(end)/10^3
                    s.Fig.EpochValues{Indx2}(Indx3) = s.Fig.EpochValues{Indx2}(Indx3)+(s.Fig.EpochInc/10^3);
                    set(s.Fig.TimeRange(Indx2, Indx3), 'string', sprintf('%.0f', s.Fig.EpochValues{Indx2}(Indx3)*10^3));
                end

        end
        set(s.Fig.EpochH(Indx2), 'xdata', s.Fig.EpochValues{Indx2}([1,1,2,2])*c.adcRate);     % Update epoch patch location

        %========== Update epoch stats
        s.InitWinTimes  = s.Fig.EpochValues{1};
        s.SacWinTimes   = s.Fig.EpochValues{2};
        s.FixWinTimes   = s.Fig.EpochValues{3};
        for n = 1:3
            EpochWinSamples{n}  = round(s.Fig.EpochValues{n}(1)*c.adcRate)+1:round(s.Fig.EpochValues{n}(2)*c.adcRate);
        end

        if Indx2 == 3   % For fixation epoch update...
            if s.CurrentEye <= 2
                set(s.ph(7), 'Xdata', s.FixWinTimes*c.adcRate, 'Ydata', repmat(mean(c.EyePos(s.Fig.EyeIndx{s.CurrentEye}(1),EpochWinSamples{3})),[1,2]));
                set(s.ph(8), 'Xdata', s.FixWinTimes*c.adcRate, 'Ydata', repmat(mean(c.EyePos(s.Fig.EyeIndx{s.CurrentEye}(2),EpochWinSamples{3})),[1,2]));
            elseif s.CurrentEye == 3


            end
        end
        UpdateBoxPlot(Indx2);

    end

    %=============== UPDATE BOX PLOTS
    function UpdateBoxPlot(Indx)
        delete(s.Fig.bph{Indx});
        s.Fig.bph{Indx} = boxplot(EyePosDist(:,EpochWinSamples{Indx}),'Notch','on','boxstyle','filled','colors',s.EpochColors(Indx,:));
        for ch = 1:numel(s.Fig.bph{Indx})
            set(s.Fig.bph{Indx}(ch), 'Xdata', get(s.Fig.bph{Indx}(ch), 'Xdata')+Indx-1);
        end

    end


    %=============== LOAD OR SAVE CALIBRATION PARAMETERS
    function CalibOutput(hObj, Event, Indx)
        CalibFilename = get(s.Fig.MatfileH, 'string');
        switch Indx
            case 1  %============= Load a previous calibration
                [file, path] = uigetfile('*.mat','Load previous calibration', CalibFilename);
                if file ~= 0
                    CalibFilename = fullfile(path, file);
                    LoadCalibration(CalibFilename);
                end

            case 2  %============= Save calibration
                [file, path] = uiputfile('*.mat','Save calibration', CalibFilename);
                if file ~= 0
                    CalibFilename = fullfile(path, file);
                    SaveCalibration(CalibFilename);
                end
        end

    end

    %=============== SAVE
    function SaveCalibration(Filename)

        save(Filename, 's','c');
    end

    %=============== LOAD
    function LoadCalibration(Filename)
        set(s.Fig.MatfileH, 'string', Filename);
        New = load(Filename);

        s.CurrentEye        = New.s.CurrentEye;
        set(s.Fig.EyeSelectH, 'value', s.CurrentEye);    
        for n = 1:3
            for xy = 1:2
                s.Fig.Values{n}(xy) = New.s.Fig.Values{n}(xy);
                set(s.Fig.Edit(n, xy), 'String', sprintf('%.2f', s.Fig.Values{n}(xy)));
            end
        end
        UpdatePlots;

    end

end
