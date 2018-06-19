
% TestTTL2

Datapixx('Open');
Datapixx('StopAllSchedules');
% %  Datapixx('EnableDoutDinLoopback');
% Datapixx('DisableDinDebounce');
% Datapixx('SetDinLog');
% Datapixx('StartDinLog');
% Datapixx('SetDoutValues',0);
Datapixx('RegWrRd');
ADCstatus     	= Datapixx('GetAdcStatus')
Datapixx('DisableDacAdcLoopback');         	
Datapixx('EnableAdcFreeRunning');           % For microsecond-precise sample windows
Datapixx('RegWrRd');                         % Synchronize Datapixx registers to local register cache


NoChannels          = 4;                                        
adcRate             = 1000;                                     % Acquire ADC data at 1 kS/s
nAdcLocalBuffSpls   = adcRate*40;                                % Preallocate a local buffer
EyeXY               = zeros(NoChannels, nAdcLocalBuffSpls);   	% We'll acquire 4 ADC channels into 4 row matrix
c.adcBuffBaseAddr  	= 4e6;                                      % Datapixx internal buffer address
c.ADCchannels       = [4,8,10,12]+1;                            	% Range = 0:15
c.ADCchannelLabels   = {'Eye_X','Eye_Y','Scanner','Eye_P',};
Datapixx('SetAdcSchedule', 0, adcRate, nAdcLocalBuffSpls, c.ADCchannels, c.adcBuffBaseAddr, nAdcLocalBuffSpls);
Datapixx('StartAdcSchedule');                                   % This will cause the acquisition to start
Datapixx('RegWrRd');                                            % make sure a Dac schedule is not running before setting a new schedule
Dacstatus           = Datapixx('GetDacStatus');                           
while Dacstatus.scheduleRunning == 1
    Dacstatus     	= Datapixx('GetDacStatus');
    WaitSecs(0.1);
end


ADCstatus     	= Datapixx('GetAdcStatus')



% Datapixx('EnableAdcFreeRunning');
Datapixx('RegWrRd');
ScannerThresh   = 2.5;
ScannerChannel  = c.ADCchannels(find(~cellfun(@isempty, strfind(c.ADCchannelLabels, 'Scanner'))));    % Find which ADC channel the scanner is connected to
TTLcount        = 0;
ScannerOn       = 0;
NoSamples       = 5; 
c.adcBuffBaseAddr  	= 4e6; 
NoTTLs = 4;
Method = 1;
ADCstatus     	= Datapixx('GetAdcStatus')

Ch3 = [];
for n = 1:2000
    Datapixx('RegWrRd');
    Data = Datapixx('GetAdcVoltages');
    Ch3 = [Ch3, Data(11)];
    WaitSecs(0.001);
end
plot(Ch3)


while TTLcount < NoTTLs

    while ScannerOn == 0
        
        Datapixx('RegWrRd')
      	switch Method
        	case 1
                Datapixx('RegWrRd')
                V 	= Datapixx('GetAdcVoltages');
                if V(ScannerChannel) < ScannerThresh
                    ScannerOn = 1;
                end
            case 2
                V2   = Datapixx('ReadAdcBuffer', NoSamples, c.adcBuffBaseAddr); 	% Read last 10 samples from ADCs
                ScannerSmpls = V2(ScannerChannel, :);                       % Check scanner ADC channel (+1 because Matlab indexing starts at 1)
                if any(ScannerSmpls < ScannerThresh)                        % If any samples drop below 2.5V... 
                    ScannerOn = 1;                                          % Scanner TTL has been received
                end
        end
    end
    
    TTLcount = TTLcount+1;
    fprintf('TTL on %d\n', TTLcount)
    if TTLcount < NoTTLs                                            % If waiting for more TTL pulses...
        while ScannerOn == 1                                        % Wait for pulse to end
            switch Method
                case 1
                    %========== Method 1
                    Datapixx('RegWrRd')
                    V 	= Datapixx('GetAdcVoltages');
        %                 AllVs(end+1) = V(ScannerChannel);
                    if V(ScannerChannel) > ScannerThresh            
                        ScannerOn = 0;
                    end
                case 2
                    %========== Method 2
                    Datapixx('RegWrRd')
                    V2   = Datapixx('ReadAdcBuffer', NoSamples, c.adcBuffBaseAddr);                % Read last 10 samples from ADCs
                    ScannerSmpls = V2(ScannerChannel, :);                   % Check scanner ADC channel
        %                 AllV2s = [AllV2s, V2(ScannerChannel, :)];
                    if any(ScannerSmpls > ScannerThresh)                    % If any samples drop below 2.5V... 
                        ScannerOn = 0;                                      % Scanner TTL has been received
                    end
            end

        end
        disp('TTL off')
    end
end
Datapixx('DisableAdcFreeRunning');
Datapixx('RegWrRd');