close all; clear all; clc;

addpath('C:\TDT\OpenEx\Examples\TTankX_Example\Matlab')
addpath('C:\TDT\Synapse\SynapseAPI\Matlab')

% SIGNAL AVERAGING EXAMPLE
% based on Strobe Store gizmo set to fixed duration
EVENT = 'StS1';

t = SynapseLive();

t.TYPE = {'snips', 'epocs', 'scalars'};
t.VERBOSE = false;

first_pass = true;

while 1
    
    % slow it down a little
    pause(0.1)
    
    % get the most recent data
    t.update;
    
    % grab the latest Tick events
    %r = t.get_data('Tick');
    %if isstruct(r)
    %    if ~isnan(r.data)
    %        r.onset
    %    end
    %end
    
    % SIGNAL AVERAGING EXAMPLE
    % get snippet events
    r = t.get_data(EVENT);
    if isstruct(r)
        if ~isnan(r.data)
            %r.ts
            % get channel 1
            ind = find(r.chan == 1);
            nsize = size(r.data(ind,:),1);
            
            % find average signal
            if nsize == 1
                ddd = r.data(ind,:);
            else
                ddd = mean(mean(r.data(ind,:)),1);
            end
            
            if first_pass
                nsweeps = size(ddd, 1);
                first_pass = false;
                avg_data = ddd;
            else
                avg_data = (avg_data .* nsweeps + ddd * nsize) / (nsweeps + nsize);
            end
            
            % plot it
            nsweeps = nsweeps + nsize;
            plot(avg_data)
            ttt = sprintf('nsweeps = %d', nsweeps);
            title(ttt)
            disp(ttt)
            drawnow
        end
    end
end