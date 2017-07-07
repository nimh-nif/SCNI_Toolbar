Datapixx('Open');
Datapixx('StopAllSchedules');
Datapixx('RegWrRd');
Datapixx('SetDinLog');
    Datapixx('StartDinLog');
    Datapixx('SetDoutValues',0);
Datapixx('DisableDacAdcLoopback');         	
Datapixx('DisableAdcFreeRunning');           % For microsecond-precise sample windows
Datapixx('RegWrRd');                         % Synchronize Datapixx registers to local register cache


NoChannels          = 4;                                        
adcRate             = 1000;                                     % Acquire ADC data at 1 kS/s
nAdcLocalBuffSpls   = adcRate*5;                                % Preallocate a local buffer
EyeXY               = zeros(NoChannels, nAdcLocalBuffSpls);   	% We'll acquire 4 ADC channels into 4 row matrix
c.adcBuffBaseAddr  	= 4e6;                                      % Datapixx internal buffer address
c.ADCchannels       = [4,8,10,12]+1;                            	% Range = 0:15
c.ADCchannelLabels   = {'Eye_X','Eye_Y','Scanner','Eye_P',};
Datapixx('SetAdcSchedule', 0, adcRate, nAdcLocalBuffSpls, 0:15, c.adcBuffBaseAddr, nAdcLocalBuffSpls);
Datapixx('StartAdcSchedule');                                   % This will cause the acquisition to start
Datapixx('RegWrRd');

ADCstatus = Datapixx('GetAdcStatus');
while ADCstatus.scheduleRunning
    WaitSecs(0.01);
    Datapixx('RegWrRd');
    ADCstatus = Datapixx('GetAdcStatus');
    V = Datapixx('GetAdcVoltages')
end

Datapixx('RegWrRd');                    % Update registers for GetAdcStatus
status = Datapixx('GetAdcStatus');
nReadSpls = status.newBufferFrames;      % How many Spls can we read?
[NewData, NewDataTs]= Datapixx('ReadAdcBuffer', nReadSpls, c.adcBuffBaseAddr); 	% Read all available samples from ADCs
Datapixx('Close');