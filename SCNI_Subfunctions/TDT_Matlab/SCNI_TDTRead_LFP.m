function TT = SCNI_TDTRead_LFP(tankName, blockName, savePath, ChNum)

%=========================== SCNI_TDTRead_LFP.m ===========================
% This function reads TDT LFP data from tdtTank, and saves to .mat format.
%
%==========================================================================

[TT, CloseTT] = SCNI_TDTRead_Init([], tankName, blockName);

%================ Read LFP data
maxEvts     = 9000000;
LFPCodesAll = [];
LFPTimesAll = [];
h = waitbar(0,'LFP Processing...');

for i = 1:length(ChNum)   
    waitbar(i/numel(ChNum), h, sprintf('LFP channel %d/%d...',i,numel(ChNum)));
    LFPEvts         = TT.ReadEventsV(maxEvts, 'LFPs', ChNum(i), 0, 0.0, 0.0,'ALL');
    LFPCodes        = TT.ParseEvV(0,LFPEvts)';
    LFPTimes        = TT.ParseEvInfoV(0,LFPEvts,6)';
 %   LFPTimes = LFPTimes * 1000; % from second to milliseconds;
    LFPSampleRate   = TT.ParseEvInfoV(0,LFPEvts,9);
    LFPSampleRate  	= LFPSampleRate(1);
    
     LFPCodesAll(1:LFPEvts,:)   = LFPCodes(:,:);
     LFPTimesAll(1:LFPEvts)     = LFPTimes;
    
    if LFPEvts < maxEvts
%         disp('%%%%%%%%%   Congratulations! All LFP Signal Covered    %%%%%%%%%%%%%')
    else
        disp('%%%%%%%%%   Oooops, Some More LFP Signal Waiting ...    %%%%%%%%%%%%%')
    end
    
    %==================== SAVE
    % store each channel separately, otherwise Matlab will run out of memory;
    SepIndx = strfind(tankName,filesep);
    if SepIndx(end) == numel(tankName)
        Prefix = tankName(SepIndx(end-1)+1:SepIndx(end)-1);
    else
        Prefix = tankName(SepIndx(end)+1:end);
    end
     save(fullfile(savePath,[Prefix,'-',blockName,'-LFP-ch',num2str(i)]),'LFPCodesAll','LFPTimesAll','LFPSampleRate');

     clear LFPCodesAll;
     clear LFPTimesAll;
end
delete(h);
if exist('CloseTT','var') && CloseTT == 1
    TT.CloseTank;
    TT.ReleaseServer;
end

end