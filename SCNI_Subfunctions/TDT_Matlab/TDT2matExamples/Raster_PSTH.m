close all; clear all; clc;

TANK = 'EXAMPLE';
BLOCK = 'Block-1';
REF_EPOC = 'Levl';
SNIP_STORE = 'Spik';
SORTID = 'TankSort';
CHANNEL = 1;
SORTCODE = 0; % set to 0 to use all sorts
TRANGE = [-0.02, 0.07]; % window size [start time relative to epoc onset, window duration]
DO_RASTER = 1; % set to 0 to only see histogram

data = TDT2mat(TANK, BLOCK, 'TYPE', {'epocs', 'snips', 'scalars'}, 'SORTNAME', SORTID, 'CHANNEL', CHANNEL, 'NODATA', 1);

if DO_RASTER
    data = TDTfilter(data, REF_EPOC, 'TIME', TRANGE);
else
    data = TDTfilter(data, REF_EPOC, 'TIME', TRANGE, 'TIMEREF', 1);
end

% find matching timestamps
if SORTCODE ~= 0
    i = find(data.snips.(SNIP_STORE).chan == CHANNEL & data.snips.(SNIP_STORE).sortcode == SORTCODE);
else
    i = find(data.snips.(SNIP_STORE).chan == CHANNEL);
end
TS = data.snips.(SNIP_STORE).ts(i);
if isempty(TS)
    error('no matching timestamps found')
end

if DO_RASTER
    % match timestamp to its trial
    all_TS = cell(size(data.time_ranges, 2), 1);
    all_Y = cell(size(data.time_ranges, 2), 1);
    for trial = 1:size(data.time_ranges, 2)
        trial_TS = TS(TS >= data.time_ranges(1, trial) & TS < data.time_ranges(2, trial));
        all_TS{trial} = trial_TS - data.time_ranges(1, trial) + TRANGE(1);
        all_Y{trial} = trial * ones(numel(trial_TS), 1);
    end
    all_X = cat(1, all_TS{:});
    all_Y = cat(1, all_Y{:});

    %plot raster
    subplot(2,1,1)
    hold on;
    plot(all_X, all_Y, '.', 'MarkerEdgeColor','k', 'MarkerSize',10)
    line([0 0], [1, trial-1], 'Color','r', 'LineStyle','--')
    axis tight;
    set(gca, 'XLim', [TRANGE(1), TRANGE(1)+TRANGE(2)]);
    ylabel('trial number')
    xlabel('time, s')
    title('Raster')
    
    TS = all_X;
    subplot(2,1,2)
end

% plot histogram
NBINS = floor(numel(TS)/10);
hist(TS, NBINS);
N = hist(TS, NBINS);
hold on;
line([0 0], [0, max(N)*1.1], 'Color','r', 'LineStyle','--')
axis tight;
set(gca, 'XLim', [TRANGE(1), TRANGE(1)+TRANGE(2)]);
ylabel('number of occurrences')
xlabel('time, s')
title('Histogram')