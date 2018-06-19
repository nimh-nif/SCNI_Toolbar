close all; clear all; clc;

t = TDTlive();
t.TYPE = {'snips', 'epocs'};
t.VERBOSE = false;

while 1
    
    % slow it down a little
    pause(0.1)
    
    % get the most recent data
    t.update;
    
    % grab the latest Tick events
    r = t.get_data('Tick');
    if isstruct(r)
        if ~isnan(r.data)
            r.ts
        end
    end
end