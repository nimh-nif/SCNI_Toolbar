function AdcStatus = SCNI_StartADC(Params)

%========================== SCNI_StartADC.m ===============================
% Start DataPixx2's ADC buffer (and optionally DAC) running.

%================== Start ADC for recording analog signals
Datapixx('RegWrRd');
AdcStatus = Datapixx('GetAdcStatus');
while AdcStatus.scheduleRunning == 1
    Datapixx('RegWrRd');
    AdcStatus = Datapixx('GetAdcStatus');
	WaitSecs(0.01);
end
Datapixx('SetAdcSchedule', 0, Params.DPx.AnalogInRate, Params.DPx.nAdcLocalBuffSpls, Params.DPx.AnalogInCh, Params.DPx.adcBuffBaseAddr, Params.DPx.nAdcLocalBuffSpls);
Datapixx('StartAdcSchedule');
Datapixx('RegWrRd');                                                    % Make sure a DAC schedule is not running before setting a new schedule

%================== Set DAC schedule for reward delivery
if Params.DPx.AnalogReward == 1
    Dacstatus = Datapixx('GetDacStatus');                               % Check DAC status
    while Dacstatus.scheduleRunning == 1
        Datapixx('RegWrRd');
        Dacstatus = Datapixx('GetDacStatus');
    end
    Datapixx('RegWrRd');
    Datapixx('WriteDacBuffer', Params.DPx.reward_Voltages, Params.DPx.dacBuffAddr, Params.DPx.RewardChnl);
    nChannels = Datapixx('GetDacNumChannels');
    Datapixx('SetDacVoltages', [0:nChannels-1; zeros(1, nChannels)]);    	% Set all DAC channels to 0V
end