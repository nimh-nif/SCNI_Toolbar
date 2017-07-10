function FixAnalysis(EL, Filename)
% [HVersionAll, VVersionAll] = FixAnalysis(EL, Filename)

%============================= FixAnalysis.m ==============================
% Analyses EyeLink eye-tracker data for experiments in which subjects are
% required to maintain fixation within a specified window.  The input
% structure EL is the output of CalAnalysis.m, which contains information
% from EyeLink calibration, and allows conversion of raw EyeLink coordinate
% data to degrees of visual angle centred on the screen centre.
%
%
% 20/09/11 - Created by Aidan Murphy (apm909@bham.ac.uk)
%     ___  ______  __   __
%    /   ||  __  \|  \ |  \    APM SUBFUNCTIONS
%   / /| || |__/ /|   \|   \   Aidan P. Murphy - apm909@bham.ac.uk
%  / __  ||  ___/ | |\   |\ \  Binocular Vision Lab
% /_/  |_||_|     |_| \__| \_\ University of Birmingham
%
%==========================================================================

if nargin == 0
    EL.centre = [640 550];
    EL.pix_per_deg = 37;
    EL.Theta = 0;
    EL.RotationMatrix = [cosd(EL.Theta), -sind(EL.Theta); sind(EL.Theta), cosd(EL.Theta)];
    fprintf('WARNING: Calibration structure EL was not provided.\nWill use estimates for conversion to real world coordinates.\n');
end
    
%========================= LOAD EYELINK DATA ==============================
RootDir = fileparts(mfilename('fullpath'));                                         % Get just the current directory path
addpath(genpath(RootDir));                                                          % Add EyeLink analysis function folder to path
if nargin < 2                                                                       % If a filename was not provided
    Default = 'F:\Perceptual learning\SingleBlockData\4Uunambig_ALL_2blocks';
    [filename filepath] = uigetfile({'*.mat';'*edf'}, 'Select data to analyse', Default);  	% Ask user to specify location of file for analysis
    Filename = fullfile(filepath, filename);                                        % Get full directory and file name
end
if strcmp (Filename((end-2):end), 'edf')                                            % If an .edf file was selected...
    fprintf('Attempting .edf conversion to .mat... this may take a while!\n');    	% Inform user that conversion may take a while
    fprintf('EDF conversion started at %s\n\n', datestr(datevec(now)));            	% Print start time
    E = dat2mat(Filename, 0);                                                      	% Convert .edf to *DAT.mat containing data structure E
    EVT = evt2mat(Filename);                                                        % Convert .edf to *EVT.mat containing event structure EVT
elseif strcmp(Filename((end-2):end), 'mat')                                         % If a .mat file was selected...
    [pathstr filename ext] = fileparts(Filename);                                 	% Get the file path and name
    DATfile = dir(fullfile(pathstr, [filename(1:end-3),'*DAT.mat']));              	% Find the filename of the DAT file
    EVTfile = dir(fullfile(pathstr, [filename(1:end-3),'*EVT.mat']));              	% Find the filename of the EVT file
    load(fullfile(pathstr, DATfile(1).name));                                    	% Load E data structure from DAT file
    load(fullfile(pathstr, EVTfile(1).name));                                      	% Load EVT data structure from EVT file
end

%========================= IDENTIFY TRIAL DATA ============================
StartTrial = EVT.msg.time(findmsg(EVT.msg.text, 'StartTrial'));                     % Find the time EyeLink received 'TargetOn' messages
EndTrial = EVT.msg.time(findmsg(EVT.msg.text, 'EndTrial'));                         % Find the time EyeLink received 'StimulusOff' message
AllHposL = [];AllHposR = [];AllVposL = [];AllVposR = [];
for n = 1:numel(StartTrial)
    TrialTime{n} = StartTrial(n):EndTrial(n);
    Firstsample(n) = find(E.L.T== StartTrial(n));
    LastSample(n) = find(E.L.T== EndTrial(n));
    HposL{n} = E.L.H(Firstsample(n):LastSample(n));
    HposR{n} = E.R.H(Firstsample(n):LastSample(n));
    VposL{n} = E.L.V(Firstsample(n):LastSample(n));
    VposR{n} = E.R.V(Firstsample(n):LastSample(n));
    AllHposL = [AllHposL, HposL{n}'];
    AllHposR = [AllHposR, HposR{n}'];
    AllVposL = [AllVposL, VposL{n}'];
    AllVposR = [AllVposR, VposR{n}'];
end

%===================== CHECK AMOUNT OF MISSING DATA =======================
HVersionRaw = (AllHposL+AllHposR)/2;                                                  % Calculate version eye movement
VVersionRaw = (AllVposL+AllVposR)/2; 
MissingData = numel(find(isnan([HVersionRaw VVersionRaw])));
MissingDataL = numel(find(isnan([AllHposL AllVposL])));
MissingDataR = numel(find(isnan([AllHposR AllVposR])));
PMissingData = MissingData/numel([HVersionRaw VVersionRaw]);
PMissingDataL = MissingDataL/numel([AllHposL AllVposL]);
PMissingDataR = MissingDataR/numel([AllHposR AllVposR]);


%================ Clean blinks and blink related saccades out of the data
TotalBlinks = EVT.blink.n;                                                  % Find total number of blinks
TotalBlinkDuration = sum(EVT.blink.dur)/1000;                               % Find total blink duration (seconds)
for sac = 1:EVT.sac.n
    for blink = 1:EVT.blink.n
       if EVT.blink.Tstart(blink) > EVT.sac.Tstart(sac) && EVT.blink.Tstart(blink) < EVT.sac.Tend(sac)
          BlinkSaccades(blink) = sac; 
       end
    end
end
BlinkSaccades = unique(BlinkSaccades);
for BlinkSac = 1:numel(BlinkSaccades)
    if BlinkSaccades(BlinkSac)~= 0
        BlinkSamples = find(ismember(E.L.T, EVT.sac.Tstart(BlinkSaccades(BlinkSac)):EVT.sac.Tend(BlinkSaccades(BlinkSac))));
        E.L.H(BlinkSamples) = nan;                                              % Remove these samples from the data
        E.R.H(BlinkSamples) = nan;
        E.L.V(BlinkSamples) = nan;                                                     
        E.R.V(BlinkSamples) = nan;
    end
end

%=================== CALCULATE SUMMARY DATA FOR EACH TRIAL ================
for Trial = 1:numel(TrialTime)
    HVersion{Trial} = (((HposL{Trial}+HposR{Trial})/2)-EL.centre(1))/EL.pix_per_deg;	% Calculate horizontal version for each trial (degrees)
    HVelocity{Trial} = diff(HVersion{Trial})*1000;                                      % Calculate horizontal velocity (degrees/second)
    VVersion{Trial} = (((VposL{Trial}+VposR{Trial})/2)-EL.centre(2))/EL.pix_per_deg;	% Calculate vertical version for each trial (degrees)
    VVelocity{Trial} = diff(VVersion{Trial})*1000;                                      % Calculate vertical velocity (degrees/second)
    HighHVelocity{Trial} = find(abs(HVelocity{Trial}) > nanstd(HVelocity{Trial})*6);  	% Find velocities gretaer than 4 SDs from zero
    FixDeviations{Trial} = sqrt(HVersion{Trial}.^2+HVersion{Trial}.^2);                	% Calculate deviation from central fixation (degrees)
    MeanFixDev(Trial) = nanmean(FixDeviations{Trial});                               	% Calculate mean deviation from central fixation (degrees)
    SEMFixDev(Trial) = nanstd(FixDeviations{Trial})/sqrt(numel(FixDeviations{Trial}(~isnan(FixDeviations{Trial}))));
end
SessionMeanDeviation = nanmean(MeanFixDev);                                             % Calculate mean deviation from central fixation for entire block
SessionSEMDeviation = nanstd(MeanFixDev)/sqrt(numel(MeanFixDev(~isnan(MeanFixDev))));   % Calculate the standard error of the mean deviation from centre


%=================== CALCULATE SUMMARY DATA FOR THE SESSION ===============
HVersionAll = (((E.L.H + E.R.H)/2)-EL.centre(1))/EL.pix_per_deg;             	% Calculate horizontal version for each trial (degrees)
VVersionAll = (((E.L.V + E.R.V)/2)-EL.centre(2))/EL.pix_per_deg;             	% Calculate vertical version for each trial (degrees)
XY = zeros(numel(HVersionAll),2);
for n = 1:numel(HVersionAll)
    XY(n,:) = EL.RotationMatrix*[HVersionAll(n); VVersionAll(n)];             	% Perform rotation through matrix multiplication
end
HVersionAll = XY(:,1);
VVersionAll = XY(:,2);


%=============================== PLOT DATA ================================
LineColours = {'k','b','c','g'};
for Trial = 1:numel(TrialTime)
	LineColour = LineColours{ceil(Trial/100)};
    
    %======================= PLOT HORIZONTAL VERSION
    f(1) = subplot(3,2,1);
    plot(TrialTime{Trial}-TrialTime{Trial}(1), HVersion{Trial}, LineColour);
    hold on;
    
    %======================= PLOT VERTICAL VERSION
    f(2) = subplot(3,2,3);
    plot(TrialTime{Trial}-TrialTime{Trial}(1), VVersion{Trial}, LineColour);
    hold on;
    
    %======================= PLOT HORIZONTAL VELOCITY
    f(3) = subplot(3,2,5);
    plot(TrialTime{Trial}(2:end)-TrialTime{Trial}(1), HVelocity{Trial}, LineColour);
    hold on;
end


%======================= PLOT GAZE DISTRIBUTION HISTOGRAM
g(1) = subplot(2,2,4);
MonitorDim = round([31.4388   23.5791]);                                        % Set monitor dimmensions (degrees)
axisLimits = [-MonitorDim(1), MonitorDim(1), -MonitorDim(2), MonitorDim(2)]/2; 	% Set the screen limits (degrees)
bins = [];
cloudPlot(HVersionAll, VVersionAll, axisLimits, [], bins);                            % Plot eye position disribution
hold on;
colormap jet;
colorbar('vert', 'location','EastOutside');
title('Gaze distribution density plot', 'FontSize', 14, 'FontWeight','bold');
ylabel('Y position (degrees)', 'FontSize', 12, 'FontWeight','bold');            
xlabel('X position (degrees)', 'FontSize', 12, 'FontWeight','bold');
StimRect = [-3.25 -3.25 6.5 6.5];                                               % Specify stimulus presentation zones (degrees)
rectangle('Position',StimRect+[0 8.5 0 0],'Curvature',[0 0],'LineWidth',2,'LineStyle','--','EdgeColor','r','Clipping','off');
rectangle('Position',StimRect-[0 8.5 0 0],'Curvature',[0 0],'LineWidth',2,'LineStyle','--','EdgeColor','r','Clipping','off');


axes(f(1));
ylabel('Horizontal version (degrees)', 'FontSize', 12, 'FontWeight','bold');
xlabel('Time (ms)', 'FontSize', 12, 'FontWeight','bold');
set(gca, 'xlim',[0 numel(TrialTime{1})]);

axes(f(2));
ylabel('Vertical version (degrees)', 'FontSize', 12, 'FontWeight','bold');
xlabel('Time (ms)', 'FontSize', 12, 'FontWeight','bold');
set(gca, 'xlim',[0 numel(TrialTime{1})]);

axes(f(3));
ylabel('Horizontal velocity (degrees/second)', 'FontSize', 12, 'FontWeight','bold');
xlabel('Time (ms)', 'FontSize', 12, 'FontWeight','bold');
set(gca, 'xlim',[0 numel(TrialTime{1})]);


%======================= PLOT DEVIATION FROM FIXATION
g(2) = subplot(2,2,2);
errorbar(1:numel(TrialTime), MeanFixDev, SEMFixDev);
ylabel('Mean deviation from centre (degrees)', 'FontSize', 12, 'FontWeight','bold');
xlabel('Trial', 'FontSize', 12, 'FontWeight','bold');
set(gca, 'xlim',[0 numel(TrialTime)]);


MainTitle = sprintf('EyeLink Data Summary - Subject %s', filename(1:3));        % Give the figure a main title
h = suptitle(MainTitle);
linkaxes(f([1 2 3]),'x');                                                   	% Link time axes on horizontal and vertical position plots
rect = Screen('rect', max(Screen('screens')));                                	% Get screen resolution
set(gcf, 'position', rect);                                                  	% Resize figure to fill half screen


%=================== PRINT SUMMARY DATA TO COMMAND LINE ===================
fprintf('\n\n=================== EYELINK FIXATION DATA ANALYSIS =======================\n');
fprintf('Analysis performed.......................... %s\n', datestr(datevec(now)));
fprintf('Analysing data in........................... %s\n\n', filepath);
fprintf('Percentage of data samples missing.......... %.2f %%\n', PMissingData*100);
fprintf('Percentage missing data for LEFT eye........ %.2f %%\n', PMissingDataL*100);
fprintf('Percentage missing data for RIGHT eye....... %.2f %%\n', PMissingDataR*100);
fprintf('Total number of data samples missing........ %d\n', MissingData);
fprintf('Total duration of blinks/ missing data...... %.2f seconds\n', TotalBlinkDuration);
fprintf('Mean deviation of eye position from centre.. %.2f degrees (+/- %.2f)\n', SessionMeanDeviation, SessionSEMDeviation);
