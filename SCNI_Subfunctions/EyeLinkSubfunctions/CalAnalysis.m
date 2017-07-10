function [EL] = CalAnalysis(TargetPos, Filename)
%  [ELcentre, ELTheta, ELpix_per_deg] = CalAnalysis(TargetPos, Filename)

%============================= CalAnalysis.m ==============================
% Analyses EyeLink eye-tracker calibration data provided by
% EyelinkCalibration.m.  Input variable TargetPos is an n x 2 matrix
% containing x and y display screen coordinates of calibration target
% positions.  Filename is the name and path of the raw Eyelink data.
% Output contains the necessary parameters for normalizing Eyelink data
% collected in the current session.
%
% INPUTS:
%       TargetPos:  n x 2 matrix containing x and y display screen
%                   coordinates of target positions, in order of presentation.
%       Filename:   full path and filename of raw EyeLink data file (.edf)
%                   or processed EVT or DAT files (.mat)
%
% OUTPUTS:
%       EL.Centre:  the EyeLink coordinates (pixels) corresponding to the 
%                   display screen centre
%       EL.Theta:   the anti-clockwise angle (degrees) that EyeLink coordinates
%                   must be rotated through to match display screen
%                   orientation
%       EL.pix_per_deg: the number of EyeLink pixels per degree of visual
%                   angle on the display screen.
%
% DEPENDENCEIS:
%       The eyelink parser executable (EDF2ASC.EXE) must be in the Eyelink
%       Subfunctions folder for conversion of .edf files.
%
% REFERENCES
% Carpenter RSH (1988) Movement of the eyes.  Pion, London.
% Cornelissen FW, Peters EM & Palmer J (2002).  The Eyelink Toolbox: Eye tracking with MATLAB
%   and the Psychophysics Toolbox.  Behavior Research Methods, Instruments, &
%   Computers, 34(4): 613-617.
%
% HISTORY
% 27/02/11 - Created by Aidan Murphy (apm909@bham.ac.uk)
% 20/09/11 - Updated for current version of EyelinkCalibration.m
%     ___  ______  __   __
%    /   ||  __  \|  \ |  \    APM SUBFUNCTIONS
%   / /| || |__/ /|   \|   \   Aidan P. Murphy - apm909@bham.ac.uk
%  / __  ||  ___/ | |\   |\ \  Binocular Vision Lab
% /_/  |_||_|     |_| \__| \_\ University of Birmingham
%
%==========================================================================

SaccDelay = 300;	% Expected delay (ms) between change in target position and end of saccade (Carpenter, 1988)

%========================= LOAD EYELINK DATA ==============================
RootDir = fileparts(mfilename('fullpath'));                                         % Get just the current directory path
addpath(genpath(RootDir));                                                        	% Add EyeLink subfunction folder to path
if nargin < 2                                                                       % If a filename was not provided
    [filename filepath] = uigetfile({'*.mat';'*.edf'}, 'Select data to analyse');  	% Ask user to specify location of file for analysis
    Filename = fullfile(filepath, filename);                                        % Get full directory and file name
else
    [filepath, filename, ext] = fileparts(Filename);                                % Get component parts of Filename
end
if strcmp(Filename((end-2):end), 'edf')                                             % If an .edf file was selected...
    fprintf('Attempting .edf conversion to .mat... this may take a while!\n');    	% Inform user that conversion may take a while
    fprintf('EDF conversion started at %s\n\n', datestr(datevec(now)));            	% Print start time
    E = dat2mat(Filename);                                                          % Convert .edf to *DAT.mat containing structure E
    EVT = evt2mat(Filename);                                                        % Convert .edf to *EVT.mat containing structure EVT
    cd(filepath);
    PosFile = dir('*pos.mat');
    load(PosFile.name);
elseif strcmp (Filename((end-2):end), 'mat')                                        % If a .mat file was selected...
    pathstr = fileparts(Filename);                                                  % Get the file path
    DATfile = dir(fullfile(pathstr, '*DAT.mat'));                               	% Find the filename of the DAT file
    EVTfile = dir(fullfile(pathstr, '*EVT.mat'));                                 	% Find the filename of the EVT file
    POSfile = dir(fullfile(pathstr, '*pos.mat'));                                	% Find the filename of the pos file
    load(fullfile(pathstr, DATfile(1).name));                                   	% Load E data structure from DAT file
    load(fullfile(pathstr, EVTfile(1).name));                                    	% Load EVT data structure from EVT file
    load(fullfile(pathstr, POSfile(1).name));                                     	% Load EVT data structure from EVT file
else
    fprintf('ERROR: input file must be .mat or .edf file format!\n');
    return
end

TargetOn = EVT.msg.time(findmsg(EVT.msg.text, 'TargetOn'));                         % Find the time EyeLink received 'TargetOn' messages
TargetOn(end+1) = EVT.msg.time(findmsg(EVT.msg.text, 'StimulusOff'));               % Find the time EyeLink received 'StimulusOff' message
FixOn = EVT.msg.time(findmsg(EVT.msg.text, 'FixationOn'));                          % Find the time EyeLink received 'FixationOn' messages
FixOn = FixOn(max(find(FixOn < TargetOn(1))):end);                                  % Only include from the last 'FixOn' before the first 'TargetOn'


%===================== Check what data are available ======================
HVersionRaw = (E.L.H+E.R.H)/2;                                                  % Calculate version eye movement
VVersionRaw = (E.L.V+E.R.V)/2; 
MissingData = numel(find(isnan([HVersionRaw VVersionRaw])));
MissingDataL = numel(find(isnan([E.L.H E.L.V])));
MissingDataR = numel(find(isnan([E.R.H E.R.V])));
PMissingData = MissingData/numel([HVersionRaw VVersionRaw]);
PMissingDataL = MissingDataL/numel([E.L.H E.L.V]);
PMissingDataR = MissingDataR/numel([E.R.H E.R.V]);

% for n = 1:numel(TargetPos(:,1))
%     TargetPos(n,1) = TargetPos(n,1)*TargetPos(n,3);
%     TargetPos(n,2) = TargetPos(n,2)*TargetPos(n,3);
% end


%==================== Remove blink related saccades =======================
TotalBlinks = EVT.blink.n;                                                      % Find total number of blinks
if TotalBlinks > 0                                                              % If any blinks were recorded...
    TotalBlinkDuration = sum(EVT.blink.dur)/1000;                               % Find total blink duration (seconds)
    Saccades = nan(max(EVT.sac.dur), EVT.sac.n);                                % create an empty matrix of size = longest saccade duration x number of saccades
    for n = 1:EVT.sac.n
        Saccades(1:EVT.sac.dur(n),n) = EVT.sac.Tstart(n):EVT.sac.Tend(n);       % Populate columns with sample times for each saccade
    end
    [r, BlinkSaccades] = find(ismember(Saccades, EVT.blink.Tstart));            % Find which saccades contain sample times that are blink onsets
    BlinkSamples = find(ismember(E.L.T, Saccades(:,BlinkSaccades)));            % Find all samples that occured during blink related saccades
    E.L.H(BlinkSamples) = nan;                                                  % Remove these samples from the data
    E.R.H(BlinkSamples) = nan;
    E.L.V(BlinkSamples) = nan;                                                     
    E.R.V(BlinkSamples) = nan;
else                                                                            % If no blinks were recorded...
    TotalBlinkDuration = 0; 
end
HVersion = (E.L.H+E.R.H)/2;                                                     % Calculate version eye movement
VVersion = (E.L.V+E.R.V)/2;


%===================== FIND CENTRAL FIXATION COORDINATES ==================
AllOnsets = sortrows([FixOn; TargetOn]);
for n = 1:numel(FixOn)
    Fix = (FixOn(n)+SaccDelay):AllOnsets(find(AllOnsets==FixOn(n))+1);         	% Get sample times for each fixation period
    FixTime{n} = Fix;                                                           % Populate columns with sample times for each fixation
    FixRange = [find(E.L.T == FixTime{n}(1)),find(E.L.T == FixTime{n}(end))];
    FixH{n} = HVersion(FixRange(1):FixRange(2));     
    FixV{n} = VVersion(FixRange(1):FixRange(2));
    MedianHFix(n) = nanmedian(FixH{n});                                         % Find the median X and Y coordinates for each fixation period  
    MedianVFix(n) = nanmedian(FixV{n});
end
FixHMean = nanmean(MedianHFix); 
FixVMean = nanmean(MedianVFix);                                                 % Find the mean X and Y coordinates of all central fixation period medians
FixHSD = nanstd(MedianHFix);
FixVSD = nanstd(MedianVFix);                                                    % Find the st. dev of X and Y coordinates of all central fixation period medians
EL.centre = [FixHMean, FixVMean];                                               % Cartesian coordinates screen centre in EyeLink pixel space

HVersion = HVersion-FixHMean;                                                   % Normalize version data with respect to central fixation (0,0)
VVersion = VVersion-FixVMean;


%==================== CALCULATE HEAD/CAMERA ROTATION ANGLE ================
for n = 1:numel(TargetOn)-1
    Target = (TargetOn(n)+SaccDelay):AllOnsets(find(AllOnsets==TargetOn(n))+1);
    TargetTime{n} = Target;
    TargetRange = [find(E.L.T == TargetTime{n}(1)),find(E.L.T == TargetTime{n}(end))];
    TargetH{n} = HVersion(TargetRange(1):TargetRange(2));   
    TargetV{n} = VVersion(TargetRange(1):TargetRange(2));
    MedianHTarget(n) = nanmedian(TargetH{n}); 
    MedianVTarget(n) = nanmedian(TargetV{n});
    if TargetPos(n,1) == 0                                                          % For vertically displaced targets...
    	theta(n)= atand(MedianHTarget(n)/MedianVTarget(n));                         % Calculate theta (degrees clockwise from vertical)
    elseif TargetPos(n,1) ~= 0                                                      % For horizontally displaced targets...
    	theta(n)= atand(MedianVTarget(n)/MedianHTarget(n));                         % Calculate theta (degrees clockwise from horizontal)
    end
end

EL.Theta = nanmean(theta);                                                          % Calculate mean value for theta (degrees)
EL.ThetaSEM = nanstd(theta)/sqrt(numel(theta));                     
Outliers = theta((theta> EL.Theta+(2*nanstd(theta)) | theta< EL.Theta-(2*nanstd(theta))));  % Find theta outliers

EL.RotationMatrix = [cosd(EL.Theta), -sind(EL.Theta); sind(EL.Theta), cosd(EL.Theta)];
XY = zeros(numel(HVersion),2);
for n = 1:numel(HVersion)
    XY(n,:) = EL.RotationMatrix*[HVersion(n); VVersion(n)];                      	% Perform rotation through matrix multiplication
end
HVersion = XY(:,1);
VVersion = XY(:,2);


%========================= CALCULATE SCALE (PIX:DEG) ======================
VTargets = find(TargetPos(1,:) == 0);                                               % Find targets with vertical displacement
HTargets = find(TargetPos(2,:) == 0);                                               % Find targets with horizontal displacement
for n = 1:numel(TargetOn)-1
    TargetTime{n} = (TargetOn(n)+SaccDelay):AllOnsets(find(AllOnsets==TargetOn(n))+1);
    TargetRange = [find(E.L.T == TargetTime{n}(1)),find(E.L.T == TargetTime{n}(end))];
    TargetSamples{n} = TargetRange(1):TargetRange(2);
    TargetH{n} = HVersion(TargetRange(1):TargetRange(2));   
    TargetV{n} = VVersion(TargetRange(1):TargetRange(2));
    MedianHTarget(n) = nanmedian(TargetH{n}); 
    MedianVTarget(n) = nanmedian(TargetV{n});
    if TargetPos(n,1)~= 0
        XPixPerDeg(n) = MedianHTarget(n)/TargetPos(n,1);
    else
        XPixPerDeg(n) = NaN;
    end
    if TargetPos(n,2)~= 0
        YPixPerDeg(n) = MedianVTarget(n)/TargetPos(n,2);
    else 
        YPixPerDeg(n) = NaN;
    end
end  
AllPixPerDeg = abs([XPixPerDeg YPixPerDeg]);
EL.pix_per_deg = nanmean(AllPixPerDeg);         % Calculate mean value for number of EyeLink coordinate pixels per degree visual angle
EL.pix_per_deg_SEM = nanstd(AllPixPerDeg)/sqrt(numel(find(~isnan(AllPixPerDeg))));

HVersion = HVersion/EL.pix_per_deg;             % Convert position data from EyeLink pixels to degrees
VVersion = VVersion/EL.pix_per_deg;


%=================== PRINT SUMMARY DATA TO COMMAND LINE ===================
fprintf('\n\n=================== EYELINK CALIBRATION ANALYSIS =======================\n');
fprintf('Analysis performed.......................... %s\n', datestr(datevec(now)));
fprintf('Analysing data in........................... %s\n\n', filepath);
fprintf('Percentage of data samples missing.......... %.2f %%\n', PMissingData*100);
fprintf('Percentage missing data for LEFT eye........ %.2f %%\n', PMissingDataL*100);
fprintf('Percentage missing data for RIGHT eye....... %.2f %%\n', PMissingDataR*100);
fprintf('Total number of data samples missing........ %d\n', MissingData);
fprintf('Total duration of blinks/ missing data...... %.2f seconds\n', TotalBlinkDuration);


%====================== PLOT TRANSFORMATION DATA ==========================
Start = E.L.T(1);                                                               % Find time of first sample
ELT = (E.L.T - Start)/1000;                                                     % Convert timestamp to time since trial began (seconds)
ERT = (E.R.T - Start)/1000;


%====================== Plot HORIZONTAL GAZE POSITION
figure(1)
clf
f(1) = subplot(2,2,1);
plot(ELT, HVersion, 'b');
hold on;
for n = 1:numel(TargetTime)
    plot((TargetTime{n}-Start)/1000, TargetH{n}/EL.pix_per_deg, 'r');
end
set(gca,'fontsize',12);
xlabel('Time (s)', 'FontSize', 14, 'FontWeight','bold');                       	% Add x- and y-axis labels
ylabel('X position (degrees)', 'FontSize', 14, 'FontWeight','bold');
title('Horizontal gaze position', 'FontSize', 14, 'FontWeight','bold');
legend({'Saccade','Target'}, 'Location','Best');
hold off;

%====================== Plot EYE POSITION
f(2) = subplot(2,2,2);
% cloudPlot(HVersion, VVersion);                                            	% Plot eye position density histogram
% hold on;
plot(TargetPos(:,1),TargetPos(:,2), 'rx', 'MarkerSize',10);                     % Plot physical target positions
hold on;
plot((HVersionRaw(TargetSamples{n})-FixHMean)/EL.pix_per_deg, (VVersionRaw(TargetSamples{n})-FixVMean)/EL.pix_per_deg, 'c');
for n = 1:numel(TargetSamples)
    plot(HVersion(TargetSamples{n}), VVersion(TargetSamples{n}), 'b');                                                  % Plot eye position
end
Xlim = get(gca, 'xLim');
Ylim = get(gca, 'yLim');
plot(Xlim, [0 0], '-k');
plot([0 0], Ylim, '-k');
set(gca,'fontsize',12);
xlabel('X position (degrees)', 'FontSize', 14, 'FontWeight','bold');         	% Add x- and y-axis labels
ylabel('Y position (degrees)', 'FontSize', 14, 'FontWeight','bold');
legend({'Targets','Raw', 'Processed'}, 'Location','Best');
% axis equal;

%====================== Plot VERTICAL GAZE POSITION
f(3) = subplot(2,2,3);
plot(ELT, VVersion, 'b');
hold on;
for n = 1:numel(TargetTime)
    plot((TargetTime{n}-Start)/1000, TargetV{n}/EL.pix_per_deg, 'r');
end
set(gca,'fontsize',12);
xlabel('Time (s)', 'FontSize', 14, 'FontWeight','bold');                       	% Add x- and y-axis labels
ylabel('Y position (degrees)', 'FontSize', 14, 'FontWeight','bold');
title('Vertical gaze position', 'FontSize', 14, 'FontWeight','bold');
legend({'Saccade','Target'}, 'Location','Best');
hold off;

% %====================== Plot HORIZONTAL VELOCITY
% HVelocity = diff(HVersion)*1000;                                        % Calculate horizontal velocity (degrees/second)
% HighHVelocity = find(abs(HVelocity) > nanstd(HVelocity)*6);             % Find velocities gretaer than 6 SDs from zero
% f(4) = subplot(2,2,4);
% plot(ELT(2:end), HVelocity , 'b');
% hold on;
% plot(ELT(HighHVelocity), HVelocity(HighHVelocity), 'r.');
% ylabel('X velocity (degrees/s)', 'FontSize', 14, 'FontWeight','bold');


%====================== Plot inidivdual data points for all estimates
f(4) = subplot(2,6,10);
plot(ones(numel(MedianHFix),1), MedianHFix, 'rd');
hold on;
plot(repmat(2, numel(MedianVFix),1), MedianVFix, 'b*');
plot([0.8,1.2], [FixHMean FixHMean], '-r', 'LineWidth',2);
plot([1.8,2.2], [FixVMean FixVMean], '-b', 'LineWidth',2);
set(gca,'fontsize',12);
set(gca, 'XTick',1:2);                                               
set(gca, 'xlim',[0 3]);
set(gca, 'XTickLabel',{'X', 'Y'}); 
ylabel('Estimated centre (pixels)', 'FontSize', 12, 'FontWeight','bold');
title('Screen Centre', 'FontSize', 14, 'FontWeight','bold');

f(5) = subplot(2,6,11);
set(gca,'fontsize',12);
plot(ones(numel(theta),1),theta, 'r.');
hold on;
plot([0.8,1.2], [EL.Theta EL.Theta], '-r', 'LineWidth',2);
plot([0.8,1.2], [EL.Theta+EL.ThetaSEM EL.Theta+EL.ThetaSEM], '-r', 'LineWidth',2);
plot([0.8,1.2], [EL.Theta-EL.ThetaSEM EL.Theta-EL.ThetaSEM], '-r', 'LineWidth',2);
set(gca, 'XTick',1);                                               
set(gca, 'xlim',[0.5 1.5]);
set(gca, 'XTickLabel',{'theta'}); 
ylabel('Estimated rotation (degrees)', 'FontSize', 12, 'FontWeight','bold');
title('Screen Rotation', 'FontSize', 14, 'FontWeight','bold');

f(6) = subplot(2,6,12);
set(gca,'fontsize',12);
PixPerDegData = abs([XPixPerDeg YPixPerDeg]);
plot(ones(numel(PixPerDegData)),PixPerDegData, 'b*');
hold on;
plot([0.8,1.2], [EL.pix_per_deg EL.pix_per_deg], '-b', 'LineWidth',2);
plot([0.8,1.2], [EL.pix_per_deg+EL.pix_per_deg_SEM EL.pix_per_deg+EL.pix_per_deg_SEM], '-b', 'LineWidth',2);
plot([0.8,1.2], [EL.pix_per_deg-EL.pix_per_deg_SEM EL.pix_per_deg-EL.pix_per_deg_SEM], '-b', 'LineWidth',2);
ylim = get(gca, 'ylim');
set(gca, 'ylim',[0 ylim(2)]);
set(gca, 'XTick',1);                                               
set(gca, 'xlim',[0.5 1.5]);
set(gca, 'XTickLabel',{'Scale'});
ylabel('Estimated pixels per degree', 'FontSize', 12, 'FontWeight','bold');
title('Screen Scale', 'FontSize', 14, 'FontWeight','bold');


%===================== CALIBRATION DATA SUMMARY
MainTitle = sprintf('EyeLink Calibration Summary - %s', filename(1:3));         % Give the figure a main title

h = suptitle(MainTitle);
linkaxes(f([1 3]),'x');                                                         % Link time axes on horizontal and vertical position plots
rect = Screen('rect', max(Screen('Screens')));                                	% Get screen resolution
set(gcf, 'position', rect);                                                  	% Resize figure to fill half screen