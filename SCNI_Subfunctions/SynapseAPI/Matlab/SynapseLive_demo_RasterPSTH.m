close all; clear all; clc;

addpath('C:\TDT\OpenEx\Examples\TTankX_Example\Matlab')
addpath('C:\TDT\Synapse\SynapseAPI\Matlab')

REF_EPOC = 'Tick';
EVENT = 'eNe1';
CHANNEL = 1;
SORTCODE = 1; % set to 0 to use all sorts
TRANGE = [-0.49, 2*0.49]; % start time, duration
DO_RASTER = 1; % set to 0 to only see histogram

t = SynapseLive();
t.NEWONLY = 0;  % read all events in block every iteration
t.TIMESTAMPSONLY = 1;  % don't care what the snippets look like, just the ts

t.TYPE = {'snips', 'epocs', 'scalars'};
t.VERBOSE = false;

first_pass = true;
h = figure;

while 1
    
    % slow it down a little
    pause(0.1)
    
    % get the most recent data
    t.update;

    % get snippet events
    r = t.get_data(EVENT);
    if isstruct(r)
        if ~isnan(r.ts)
            
            if DO_RASTER
                data = TDTfilter(t.data, REF_EPOC, 'TIME', TRANGE);
            else
                data = TDTfilter(t.data, REF_EPOC, 'TIME', TRANGE, 'TIMEREF', 1);
            end
            
            if SORTCODE ~= 0
                i = find(data.snips.(EVENT).chan == CHANNEL & data.snips.(EVENT).sortcode == SORTCODE);
            else
                i = find(data.snips.(EVENT).chan == CHANNEL);
            end
            
            TS = data.snips.(EVENT).ts(i);
            if isempty(TS)
                continue
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
                title(sprintf('Raster ch=%d sort=%d, %d trials', CHANNEL, SORTCODE, trial))
                hold off;
                TS = all_X;
                subplot(2,1,2)
            end
            
            % plot PSTH
            NBINS = floor(numel(TS)/10);
            hist(TS, NBINS);
            hold on;
            N = hist(TS, NBINS);
            line([0 0], [0, max(N)*1.1], 'Color','r', 'LineStyle','--')
            axis tight;
            set(gca, 'XLim', [TRANGE(1), TRANGE(1)+TRANGE(2)]);
            ylabel('number of occurrences')
            xlabel('time, s')
            title(sprintf('Histogram ch=%d sort=%d, %d trials', CHANNEL, SORTCODE, trial))
            hold off;
            drawnow
        end
    end
end