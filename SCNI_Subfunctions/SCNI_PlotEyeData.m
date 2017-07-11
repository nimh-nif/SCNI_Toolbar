function [s,c] = SCNI_PlotEyeData(EyePos, s, c)

%========================= SCNI_PlotEyeTrace.m ============================
% Plots eye data for a single trial.

%========= Check whether eye data figure window is already open
if nargin == 0 || ~isfield(s, 'fh') || ~ishandle(s.fh)
    s.fh = figure('name','SCNI_PlotEyeData','position',[66, 544, 910, 430]);
    FirstPlot = 1;
else
    FirstPlot = 0;
    figure(s.fh);
    delete(s.ph);
end

%========= Set analysis parameters based on assumptions about reaction time
InitWinTimes    = [0, 0.1];             % Time window of initial eye position (seconds from target onset)
SacWinTimes     = [0.2, 0.3];           % Time window of likely saccade to target (seconds from target onset)
FixWinTimes     = [0.3, 0.5];           % Time window of likely fixation on target (seconds from target onset)
VoltageRange    =[-5, 5];
EpochColors     = [1, 0 0; 1 1 0; 0 1 0];
EpochNames      = {'Pre', 'Saccade', 'Fix'};
FontSize        = 14;

%========= Generate artifical eye movement simulation
TargetLoc       = [0, 0];           % Ideal central fixation voltage
GazeWinradius   = 2;                % Initial central fixation voltage window
EyeOffset       = 0.8;
InitialOffset   = 2.5;      
FinalOffset     = -2.5;
Variance        = 0.2;
SaccadeDur      = 30;

SampleRate      = 1000;
InitWinSamples  = (InitWinTimes(1)*SampleRate)+1:(InitWinTimes(2)*SampleRate);
SacWinSamples   = (SacWinTimes(1)*SampleRate):(SacWinTimes(2)*SampleRate);
FixWinSamples   = (FixWinTimes(1)*SampleRate):(FixWinTimes(2)*SampleRate);

% Simulated eye position data
if nargin == 0
    TargetDuration = 0.3;
    EyePos = nan(2,1000);
    EyePos(:,1:200) = (randn(2,200)*Variance)+repmat(InitialOffset, [2,200]);
    EyePos(:,201:200+SaccadeDur) = repmat(linspace(InitialOffset, 0, SaccadeDur),[2,1]);
    EyePos(:,(200+SaccadeDur+1):600) = (randn(2,400-SaccadeDur)*Variance);
    EyePos(:,601:(600+SaccadeDur)) = repmat(linspace(0, FinalOffset, SaccadeDur),[2,1]);
    EyePos(:,600+SaccadeDur+1:end) = (randn(2,(1000-600-SaccadeDur))*Variance)+repmat(FinalOffset, [2,(1000-600-SaccadeDur)]);
    EyePos = EyePos+EyeOffset;
else
    TargetDuration  = c.StimDuration;
end


%============= Plot data
if FirstPlot == 1
    s.axh(1) = subplot(1,2,1);
else
    axes(s.axh(1));
end
s.ph(1) = plot(EyePos(1,:), EyePos(2,:),'-k','color', [0.5, 0.5, 0.5]);
hold on;
s.ph(2) = plot(EyePos(1,InitWinSamples), EyePos(2,InitWinSamples),'-k','color', EpochColors(1,:));
s.ph(3) = plot(EyePos(1,SacWinSamples), EyePos(2,SacWinSamples),'-k','color', EpochColors(2,:));
s.ph(4) = plot(EyePos(1,FixWinSamples), EyePos(2,FixWinSamples),'-k','color', EpochColors(3,:));
if FirstPlot == 1
    legend(s.ph(2:4), EpochNames, 'location', 'northwest');
    grid on
    axis equal
    set(gca, 'xlim', VoltageRange, 'ylim', VoltageRange, 'xtick', VoltageRange(1):1:VoltageRange(2),'color', [0.5,0.5,0.5]);
    xlabel('X voltage (V)','fontsize', FontSize);
    ylabel('Y voltage (V)','fontsize', FontSize);
    plot(VoltageRange, [0 0], '--k');
    plot([0 0], VoltageRange, '--k');
end

if FirstPlot == 1
    s.axh(2) = subplot(2,2,2);
else
    axes(s.axh(2));
end
s.ph(5) = plot(EyePos(1,:),'-r');
hold on;
s.ph(6) = plot(EyePos(2,:),'-b');
if FirstPlot == 1
    xlabel('Time (ms)','fontsize', FontSize);
    ylabel('Voltage (V)','fontsize', FontSize);
    grid on;
    legend(s.ph(5:6),{'X','Y'});
    Ylims = VoltageRange;
    patch(InitWinTimes([1,1,2,2])*SampleRate, Ylims([1,2,2,1]), zeros(1,4),'facecolor',EpochColors(1,:),'facealpha', 0.3,'edgecolor', 'none');
    patch(SacWinTimes([1,1,2,2])*SampleRate, Ylims([1,2,2,1]), zeros(1,4),'facecolor',EpochColors(2,:),'facealpha', 0.3,'edgecolor', 'none');
    patch(FixWinTimes([1,1,2,2])*SampleRate, Ylims([1,2,2,1]), zeros(1,4),'facecolor',EpochColors(3,:),'facealpha', 0.3,'edgecolor', 'none');
    plot([0, TargetDuration*SampleRate], [0 0], '-k', 'linewidth', 4);
end

if FirstPlot == 1
	s.axh(3) = subplot(2,2,4);
else
    axes(s.axh(3));
end
EyePosDist   = sqrt(EyePos(1,:).^2 + EyePos(2,:).^2);                      % Combine X and Y vectors into single position vector

BarData(1,:) = mean(EyePosDist(:,InitWinSamples)');
BarData(2,:) = mean(EyePosDist(:,SacWinSamples)');
BarData(3,:) = mean(EyePosDist(:,FixWinSamples)');
VarData(1,:) = std(EyePosDist(:,InitWinSamples)');
VarData(2,:) = std(EyePosDist(:,SacWinSamples)');
VarData(3,:) = std(EyePosDist(:,FixWinSamples)');

s.ph(7) = bar(BarData);
hold on;
s.ph(8) = errorbar(1:3, BarData, VarData, VarData, '.r','linewidth', 2);
if FirstPlot == 1
    grid on;
    ylabel('Eye position (V)','fontsize', FontSize)
    set(gca, 'xticklabel', EpochNames,'fontsize', FontSize);
end


