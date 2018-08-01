
function SCNI_TDTReadEvents(tankName, blockName, savePath, TT)

%========================= SCNI_TDTReadEvents.m ===========================
% This function reads event codes sent to TDT from the experimental control
% system (e.g. DataPixx, MonkeyLogic, etc.).
%
% 
%==========================================================================

[TT, CloseTT] = SCNI_TDTRead_Init;

%================== READ EVENT CODES
Events.evts         = TT.ReadEventsV(100000,'Evnt',0,0,0.0,0.0,'All');
Events.codes        = TT.ParseEvV(0,Events.evts);
Events.times        = TT.ParseEvInfoV(0,Events.evts,6);
Events.SampleRate   = TT.ParseEvInfoV(0,Events.evts,9);
Events.SampleRate   = Events.SampleRate(1);

%==================SAVE EVENT CODES
SepIndx = strfind(tankName,filesep);
if SepIndx(end) == numel(tankName)
    Prefix = tankName(SepIndx(end-1)+1:SepIndx(end)-1);
else
    Prefix = tankName(SepIndx(end)+1:end);
end
save(fullfile(savePath,[Prefix,'-',blockName,'-Events']),'Events');

if exist('CloseTT','var') && CloseTT == 1
    TT.CloseTank;
    TT.ReleaseServer;
end

end