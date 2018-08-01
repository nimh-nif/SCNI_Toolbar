function [EventTimes] = SCNI_GetEventTimes(data, Params)

%========================== SCNI_GetEventTimes.m ==========================
% This function extracts the onset times of different event types based on
% the SCNI event code convention implemented in SCNI_LoadEventCodes.m, as 
% well as the nearest corresponding photodiode onset times. 
%
% INPUTS:   data:   the structure output by TDT2mat.m
%           Params: the structure saved by the DataPixx PC during recording
%
%==========================================================================

Block           = data.info.blockname;


%====================== Find photodiode onsets
if Params.Display.PD.On == 1
    PDCh            = find(~cellfun(@isempty, strfind(Params.DPx.AnalogInLabels, 'Photodiode')));
    PDpolarity      = sum(Params.Display.PD.Color{2}) > sum(Params.Display.PD.Color{1});
    PDthresh        = 2.5*round(PDpolarity-0.5);
    PDsignal        = data.streams.Anlg.data(PDCh,:);
    PDtimes         = linspace(0, numel(PDsignal)/data.streams.Anlg.fs, numel(PDsignal));
    PDonsetIndx     = find(diff(PDsignal) > PDthresh);
    PDonsetTimes    = PDtimes(PDonsetIndx);
    PDoffsetIndx    = find(diff(PDsignal) < PDthresh);
    PDoffsetTimes   = PDtimes(PDoffsetIndx);
end

%====================== Find event times
if ~isfield(Params, 'Events')
    Events = SCNI_LoadEventCodes;
else
    Events = Params.Events;
end
AllEvents       = [Events.TDTnumber];
for e = 1:numel(AllEvents)
    EventIndx{e}            = find(data.scalars.Evnt.data == AllEvents(e));
    Events(e).EvntTimes     = data.scalars.Evnt.ts(EventIndx{e});
    Events(e).EventCount    = numel(EventIndx{e});
end

%====================== Find stimulus onset times
for s = 1:max(unique(data.scalars.Evnt.data < Events(1).TDTnumber));
    StimIndx{s}         = find(data.scalars.Evnt.data == s);
    Stim(s).Times       = data.scalars.Evnt.ts(StimIndx{s}-1);
    Stim(s).Count       = numel(EventIndx{e});
	Stim(s).PDOnsets    = PDonsetTimes(find(PDonsetTimes < Stim(s).Times, 'first'));
    Stim(s).PDoffsets   = PDoffsetTimes(find(PDoffsetTimes > Stim(s).Times, 'first'));;
    Stim(s).PDdur       = Stim(s).PDoffsets-Stim(s).PDOnsets;
    Stim(s).Delays      = Stim(s).Times - Stim(s).PDOnsets;
end

%====================== Plot some statistics
fh      = figure;
axh(1)  = subplot(2,2,1);
histogram(EventCount);
xlabel('Event ID','fontsize', Fontsize);
ylabel('Frequency','fontsize', Fontsize);

axh(2)  = subplot(2,2,2);
histogram(EventDelay);
xlabel('Photodiode - Event code delay (ms)','fontsize', Fontsize);
ylabel('Frequency','fontsize', Fontsize);


