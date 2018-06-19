function SCNI_TDT2mat(tankName, blockName, savePath)

%========================= SCNI_TDT2mat.m =================================
% This function converts neural, analog and event code data from the 
% proprietary format used by TDT, into Matlab-readable .mat files. This
% process requires ActiveXControl and must therefore be run on a Windows PC
% (e.g. Nifsort1). The saved files contain four structures:
%       - Events:       
%       - Anlg:         
%       - LFP:          
%       - NeuroStruct:  
%
% Written by murphyap@nih.gov
%==========================================================================

OnlineSort      = 0;
maxEvts         = 10^6;
ChannelNumbers  = 1:128;
ChannelNames    = {'Left Eye X', 'Left Eye Y', 'Left Eye Pupil', 'Right Eye X', 'Right Eye Y', 'Right Eye Pupil', 'Photodiode', 'Reward'};
NoAnlgCh        = numel(ChannelNames);
NoCh            = numel(ChannelNumbers);
 
%========= Open connection to server
TT  = actxcontrol('TTank.X');
TT.ConnectServer('Local','Me');
a   = TT.OpenTank(tankName, 'R');
b   = TT.SelectBlock(blockName);
if a~=1 && b~=1
    fprintf('Error reading block ''%s'' from tank ''%s''!\n', blockName, tankName);
end

%========= Get absolute start and stop times (in sec)
tStart      = TT.CurBlockStartTime;
tStop       = TT.CurBlockStopTime;
tTotal      = (tStop-tStart)*1000;                          % total block duration, in ms
dateString  = TT.FancyTime(tStart,'D-O-Y H:M:S');           % Convert 
dateNumber  = datenum(dateString);                          

%========= Read event codes
EventEvts         = TT.ReadEventsV(maxEvts,'Evnt',0,0,0.0,0.0,'All');
Eventcodes        = TT.ParseEvV(0,EventEvts);
Eventtimes        = TT.ParseEvInfoV(0,EventEvts,6)*1000;
EventSampleRate   = TT.ParseEvInfoV(0,EventEvts,9);
Events.SampleRate  = EventSampleRate(1);
Events.Codes       = Eventcodes;
Events.Times       = Eventtimes;

%========= Read analog signals
wbh = waitbar(0,'Processing analog input signals...');
for ch = 1:NoAnlgCh
    waitbar(wbh, ch/NoAnlgCh, sprintf('Processing analog input signals (channel %d/%d)...', ch, NoAnlgCh));
    
    anlgEvts        = TT.ReadEventsV(maxEvts, 'Anlg', ch, 0, 0.0, 0.0,'ALL');
    anlgCodes       = TT.ParseEvV(0,anlgEvts);
    anlgTimes       = TT.ParseEvInfoV(0,anlgEvts,6)*1000;                       % Convert from seconds to milliseconds                        
    anlgSampleRate  = TT.ParseEvInfoV(0,anlgEvts,9);   
    
    Anlg(ch).Name       = ChannelNames{ch};
    Anlg(ch).Samples    = reshape(anlgCodes, [1, numel(anlgCodes)]);
    Anlg(ch).SampleRate = anlgSampleRate(1); 
    Anlg(ch).TimeStamps = linspace(0, anlgTimes(end), numel(Anlg(ch).Samples));
end

%========= Read LFP signals
for ch = 1:NoCh
    waitbar(wbh, ch/NoCh, sprintf('Processing local field potential signals (channel %d/%d)...', ch, NoCh));
    
    LFPEvts         = TT.ReadEventsV(maxEvts, 'LFPs', ChannelNumbers(ch), 0, 0.0, 0.0,'ALL');
    LFPCodes        = TT.ParseEvV(0,LFPEvts);
    LFPTimes        = TT.ParseEvInfoV(0,LFPEvts,6)*1000; 
    LFPSampleRate   = TT.ParseEvInfoV(0,LFPEvts,9);

    LFP(ch).Number      = ChannelNumbers(ch);
    LFP(ch).Samples     = reshape(LFPCodes, [1, numel(LFPCodes)]);
    LFP(ch).SampleRate  = LFPSampleRate(1);
    LFP(ch).TimeStamps  = linspace(0, LFPTimes(end), numel(LFP(ch).Samples));
end

%========= Read online-sorted spikes?
if OnlineSort == 1
    i = 1;
    for ch = 1:NoCh
        waitbar(wbh, ch/NoCh, sprintf('Processing online-sorted spikes (channel %d/%d)...', ch, NoCh));
    
        SetSort         = TT.SetUseSortName('TankSort');                        % Use automated sorted data
        sortID          = 1:8;                                          % Set maximum cells per channel
        SnipTimesAll    = [];                                                 
        for k = 1:length(sortID)                                        % For each cell...
            filterID    = (['sort=',num2str(sortID(k))]);       
            Filter      = TT.SetFilterWithDescEx(filterID);             % sorted ID
            ts          = [];                                           % timeStamps
            wf          = [];                                           % waveforms
            for j = 1:NoSteps                                           % For each time segment...
                events = TT.ReadEventsV(10000, 'eNeu', channel, 0, ((j-1)*timeStep), (j*timeStep),'FILTERED');            
                if events                                               % If spike events were found...
                    timeStamps      = TT.ParseEvInfoV(0, events, 6);    % Get time stamps of spike events
                    ts              = cat(2, ts, timeStamps(1,:));      
                    SnipSampleRate  = TT.ParseEvInfoV(0,events,9);      % Get sample rate
                    SnipSampleRate  = SnipSampleRate(1);
                    waveforms       = TT.ParseEvV(0, events);           % Retrieve spike waveform; 
                    wf              = cat(2,wf,waveforms(:,:));         
                end
            end
            if length(ts) > 0         
                NeuroStruct.cells{i,1} = ch;
                NeuroStruct.cells{i,2} = k;
                NeuroStruct.cells{i,3} = ts;
                NeuroStruct.cells{i,4} = wf(1:30,:);
                i = i+1;
            end
            
        end
        
    end
    
end
close(wbh);

%========= Close tank and release server;
TT.CloseTank;
TT.ReleaseServer;

%========= Save data to .mat file
OutputFile = fullfile(savePath, );
save(OutputFile, 'Events','Anlg','LFP','NeuroStruct','-v7.3');