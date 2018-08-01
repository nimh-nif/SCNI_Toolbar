function SCNI_TDTRead(tankName, blockName, savePath, ChNum)

%============================ SCNI_TDTRead.m ==============================
% This function is used to read TDT files from tdtTank, and convert to .mat
% format. The function calls several other function to read: online-sorted 
% spikes (if available), down-sampled LFP, digital event codes and analog
% signals (e.g. eye position and photodiode signals).
%
% INPUTS:       tankName:   
%               blockName:	
%               savePath:   full path of directory to save converted .mat
%                           files to
%               ChNum:      vector of channel numbers to convert LFP data for
%
% HISTORY:
%   28/03/2013 - Chunshan
%   01/08/2014 - Updated by APM
%   05/11/2015 - modified by Chunshan, to read and save dual-elctrode data;
%   04/04/2016 - modified by APM to save multiple elecrtrode data to same path
%==========================================================================

if nargin < 4
    ChNum = 1:128;
end

fprintf('tdtReading tank ''%s'', block ''%s''...\t\t', tankName, blockName);
TT = actxcontrol('TTank.X');
TT.ConnectServer('Local','Me');
a = TT.OpenTank(tankName, 'R');
b = TT.SelectBlock(blockName);

if a==1 && b==1
    fprintf('Read successful!\n')
else
    fprintf('Error reading tank!\n')
end

%============ get absolute start and stop times (in sec)
tStart          = TT.CurBlockStartTime;
tStop           = TT.CurBlockStopTime;
tTotal          = tStop-tStart;                           % total block duration, in second;
dateStringStart = TT.FancyTime(tStart,'D-O-Y H:M:S');
dateStringStop  = TT.FancyTime(tStop,'D-O-Y H:M:S');
% dateNumber    = datenum(dateStringStart)
dateVectorStart = datevec(dateStringStart);
dateVectorStop  = datevec(dateStringStop);

%============ Read and convert data;
SCNI_TDTRead_Analog(tankName, blockName,savePath);
SCNI_TDTRead_Events(tankName, blockName,savePath);
SCNI_TDTRead_Spikes(tankName, blockName,savePath, ChNum);
SCNI_TDTRead_LFP(tankName, blockName,savePath, ChNum);


%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% LFP reconstruction and fft;
%
% figure;
% for i=1:4 % 1-4 channels;
%     i
%     allWave = TT.ReadEventsV(5000, 'LFPs', i, 0, 0.0, 0.0,'ALL'); %% LFP are stored in matrix [256*N] form;
%     waveData = TT.ParseEvV(0, allWave);
%     [segmentL,segmentN] = size(waveData);
%     LFPLength = segmentL*segmentN;
%     LFPtemp = zeros(1,LFPLength);
%
%     for j=1:segmentN
%         tempRange = (j-1)*segmentL+1:j*segmentL;
%         LFPtemp(1,tempRange) = waveData(:,j);
%     end
%     sampleRate = TT.ParseEvInfoV(0,allWave,9);
%     sampleRate = sampleRate(1);
%
%     subplot(4,2,(i-1)*2+1);
%
%     plot(1/sampleRate:1/sampleRate:LFPLength/sampleRate, LFPtemp);
%     title(['Channel ',num2str(i)],'FontSize',12);
%     axis([0 300 -500 500]);
%      xlabel('Time (second)','FontSize',12);
%      ylabel('Membrane Voltage (uv)','FontSize',12);
%
%      %% fft;
%      NFFT = 2^nextpow2(LFPLength); % Next power of 2 from length of y
%      LFPfft = fft(LFPtemp,NFFT)/LFPLength;
%      f = sampleRate/2*linspace(0,1,NFFT/2);
%
%      %% ;
%        subplot(4,2,i*2);
%      plot(f,2*abs(LFPfft(1:NFFT/2)));
%      title('Spectrum','FontSize',12);
%      xlabel('Frequency (Hz)','FontSize',12);
%      ylabel('Power','FontSize',12)
%      axis([0 200 0 5])
% end


%%%%%%%%%%%%%%%%%%%
% TT.CloseTank;
% TT.ReleaseServer;


end