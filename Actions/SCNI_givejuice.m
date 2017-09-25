function [PDS,c,s] = SCNI_givejuice(PDS, c, s)

%============================ SCNI_givejuice.m =============================
% Sends output from DataPixx2 to activate solenoid and deliver liquid reward 
% to the subject. 

if c.Params.DPx.AnalogReward == 1  %================ Write square wave to DAC analog output
    Delay = 0;
    Datapixx('SetDacSchedule', Delay, c.Params.DPx.AnalogOutRate, c.Params.DPx.ndacsamples, c.Params.DPx.RewardChnl, c.Params.DPx.dacBuffAddr, c.Params.DPx.ndacsamples);
    Datapixx('StartDacSchedule');
    Datapixx('RegWrRd');
    disp(Datapixx('GetDacStatus'));
    s.RewardCount = s.RewardCount + 1;
    
elseif c.Params.DPx.AnalogReward == 0  %============ Write to digital output
    SCNI_DigitalOutJuice(c.Reward_TTLDur);
    
end