function SCNI_TDTRead_Spikes(tankName, blockName, savePath, SnipChNum)

%======================== SCNI_TDTRead_Spikes.m ===========================
% This function reads TDT data from tdtTank, and saves to .mat format.
% Extracted spikes ('snip') are from TDT's OpenSorter.
% 
% History:
%   26/03/2013 - Written by Chunshan Deng
%   01/08/2014 - Updated by APM
%   10/12/2015 - modified to retrieve snip waveform (CSD)
%   13/12/2015 - updated to read data from 2 electrodes (APM)
%   28/07/2018 - Updated to provide cleaner output format (APM)
%==========================================================================

[TT, CloseTT] = SCNI_TDTRead_Init([], tankName, blockName);

%========== Get absolute start and stop times (sec)
tStart      = TT.CurBlockStartTime;
tStop       = TT.CurBlockStopTime;
tTotal      = (tStop-tStart)*1000;                  % total block duration, in ms
dateString  = TT.FancyTime(tStart,'D-O-Y H:M:S');
dateNumber  = datenum(dateString);


%========== Reading snips
% there is some bugs in openSorter, when reading via ReadEventsV, it will
% miss snips separte over 100 seconds;
maxEvts         = 10000000;  
maxTime         = 8000;                                 % maximum duration (sec)
timeStep        = 100;                                  % step size (sec)
NoSteps         = maxTime/timeStep;                     % Number of steps
SnipCodesAll    = [];
SnipSampleRate  = [];
SnipWaveforms   = [];
h               = waitbar(0,'Snip Processing...');

for i = 1:length(SnipChNum)                                 % For each channel...
    waitbar(i/length(SnipChNum), h, fprintf('Processing channel %d (%d/%d)...', SnipChNum(i), i, length(SnipChNum)));
    channel         = SnipChNum(i);                         % Get channel number 
    SetSort1        = TT.SetUseSortName('dengc');           % Use manual sorted data
%  SetSort1 = TT.SetUseSortName('TankSort');                % Use automated sorted data
    sortID          = 1:8;                                  % Set maximum cells per channel
    SnipTimesAll    = [];                                   
    
    for k = 1:length(sortID)                                % For each cell...
        filterID    = (['sort=',num2str(sortID(k))]);       
        Filter      = TT.SetFilterWithDescEx(filterID);     % sorted ID
        ts          = [];                                   % timeStamps
        wf          = [];                                   % waveforms
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
        snipNum = length(ts);                                       % to see whether we got all snips
        if ts > 0
            SnipTimesAll(k,1:snipNum)       = ts;
            SnipWaveforms(k,1:30,1:snipNum) = wf(1:30,:);           
            maxTimeSnip                     = ts(end);              % get the timestamp of last snip
            if maxTimeSnip < maxTime
                fprintf('All snips converted!\n');
            else
                disp('Oooops, Some More Snips Waiting...   ')
            end
        else
            fprintf('**No spikes found on:\t channel %d\tcell %d\n', channel, k);
        end
    end
    
    %========== Save data
 	SepIndx = strfind(tankName,filesep);
    if SepIndx(end) == numel(tankName)
        Prefix = tankName(SepIndx(end-1)+1:SepIndx(end)-1);
    else
        Prefix = tankName(SepIndx(end)+1:end);
    end
	save(fullfile(savePath,[Prefix,'-',blockName,'-Snip-ch',num2str(i)]),'SnipTimesAll','SnipSampleRate','SnipWaveforms');
 
%     a = 0;
end

close(h);               % Close wait bar
TT.CloseTank;           % close tank 
TT.ReleaseServer;       % release server

end