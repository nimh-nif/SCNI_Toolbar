function SCNI_TDTRead_Analog(tankName, blockName,savePath)


%====================== SCNI_TDTRead_Analog.m =============================
% This function reads analog TDT data from tdtTank, and converts it to a 
% matlab-readable file.
% 
%==========================================================================

[TT, CloseTT] = SCNI_TDTRead_Init([], tankName, blockName);

%============ Load session data from local machine

% EyeChannels = Params.DPx.Analog;
% PDchannel   = Params.DPx.Analog;
ADCdegHV    = [134 135];  % the QNX index for eye signal conversion (voltage to deg?)

%============ Reading Eye signal
maxEvts         = 9000000;
anlgChNum       = 8;
anlgCodesAll    = [];
anlgTimesAll    = [];
h = waitbar(0,'anlg Signal Processing...');

for i=1:anlgChNum
    waitbar(i/anlgChNum);
    anlgEvts    = TT.ReadEventsV(maxEvts, 'Anlg', i, 0, 0.0, 0.0,'ALL');
    anlgCodes   = TT.ParseEvV(0,anlgEvts)';
    anlgTimes   = TT.ParseEvInfoV(0,anlgEvts,6)';
 %   anlgTimes = anlgTimes * 1000; % from second to millioseconds;
    anlgSampleRate = TT.ParseEvInfoV(0,anlgEvts,9);

    Analog(i).ChannelName   = [];
    Analog(i).Values        = reshape(anlgCodes(:,:), [1, numel(anlgCodes)]);
    Analog(i).Times         = linspace(0, anlgTimes(end), numel(anlgCodes));
    Analog(i).SampleRate    = anlgSampleRate(1);
end
delete(h);


%============== Save data
SepIndx = strfind(tankName,filesep);
if SepIndx(end) == numel(tankName)
    Prefix = tankName(SepIndx(end-1)+1:SepIndx(end)-1);
else
    Prefix = tankName(SepIndx(end)+1:end);
end
save(fullfile(savePath,[Prefix,'-',blockName,'-AnlgSignal']),'Analog');

if exist('CloseTT','var') && CloseTT == 1
    TT.CloseTank;
    TT.ReleaseServer;
end

end