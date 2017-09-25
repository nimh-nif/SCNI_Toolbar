function [PDS,c,s] = SCNI_givejuice(PDS, c, s)

%============================ SCNI_givejuice.m =============================
% Sends the pre-loaded reward delivery square wave out to the solenoid via
% the specified DAC channel of the DataPixx2.

    Delay = 0;
    Datapixx('SetDacSchedule', Delay, c.Dacrate, c.ndacsamples, c.RewardChnl, c.dacBuffAddr, c.ndacsamples);
    Datapixx('StartDacSchedule');
    Datapixx('RegWrRd');
    disp(Datapixx('GetDacStatus'));
    s.RewardCount = s.RewardCount + 1;
    
end