
%=========== SCANNER TTL TEST

Datapixx('Open');
Datapixx('StopAllSchedules');
% %  Datapixx('EnableDoutDinLoopback');
% Datapixx('DisableDinDebounce');
% Datapixx('SetDinLog');
% Datapixx('StartDinLog');
% Datapixx('SetDoutValues',0);
Datapixx('RegWrRd');
Datapixx('DisableDacAdcLoopback');         	
Datapixx('EnableAdcFreeRunning');           % For microsecond-precise sample windows
Datapixx('RegWrRd');                         % Synchronize Datapixx registers to local register cache


NoChannels          = 16;                                        
adcRate             = 1000;                                     % Acquire ADC data at 1 kS/s
nAdcLocalBuffSpls   = adcRate*4;                                % Preallocate a local buffer
EyeXY               = zeros(NoChannels, nAdcLocalBuffSpls);   	% We'll acquire 4 ADC channels into 4 row matrix
c.adcBuffBaseAddr  	= 4e6;                                      % Datapixx internal buffer address
c.ADCchannels       = 0:15;                            	% Range = 0:15
c.ADCchannelLabels   = {'Eye_X','Eye_Y','Eye_P','Scanner'};
Datapixx('SetAdcSchedule', 0, adcRate, nAdcLocalBuffSpls, c.ADCchannels, c.adcBuffBaseAddr, nAdcLocalBuffSpls);
Datapixx('StartAdcSchedule');                                   % This will cause the acquisition to start
Datapixx('RegWrRd');                                            % make sure a Dac schedule is not running before setting a new schedule
Dacstatus           = Datapixx('GetDacStatus');                           
% while Dacstatus.scheduleRunning == 1
%     Dacstatus     	= Datapixx('GetDacStatus');
%     WaitSecs(0.1);
% end
nBits = Datapixx('GetDinNumBits')
DV  = Datapixx('GetDinValues');
for bit = nBits-1:-1:0               % Easier to understand if we show in binary
    if (bitand(DV, 2^bit) > 0)
        fprintf('1');
    else
        fprintf('0');
    end
end

AV 	= Datapixx('GetAdcVoltages')        


Datapixx('RegWrRd'); 
AV 	= Datapixx('GetAdcVoltages')        


Datapixx('RegWrRd'); 
V 	= Datapixx('ReadAdcBuffer', 5)            % Read last 10 samples from ADCs



% %============ Start data collection
% Start           = GetSecs;     
% NoTTLs          = 0;
% ScannerSmpls    = [];
% 
% while NoTTLs < 4
%     ScannerOn       = 0;
%     while ScannerOn == 0
%         ScannerChannel  = c.ADCchannels(~cellfun(@isempty, strfind(c.ADCchannelLabels, 'Scanner')));    % Find which ADC channel the scanner is connected to
%         Datapixx('RegWrRd')
%         V 	= Datapixx('GetAdcVoltages');
% %         V   = Datapixx('ReadAdcBuffer', 10, -1);            % Read last 10 samples from ADCs
%         ScannerSmpls(end+1) = V(ScannerChannel+1);              % Check scanner ADC channel
%         if V(ScannerChannel+1) < 2.5                            % If any samples drop below 2.5V... 
%             ScannerOn = 1;                                      % Scanner TTL has been received
%         end
%     end
%     NoTTLs = NoTTLs+1;
%     fprintf('Scanner TTL detected at time = %.2f seconds\n', GetSecs-Start);
%     while ScannerOn == 1
%      	Datapixx('RegWrRd')
%         V 	= Datapixx('GetAdcVoltages');
%         ScannerSmpls(end+1) = V(ScannerChannel+1);              % Check scanner ADC channel
%         if V(ScannerChannel+1) > 2.5                            % If any samples drop below 2.5V... 
%             ScannerOn = 0;                                      % Scanner TTL has been received
%         end
%     end
% %     Datapixx('RegWrRd');                                    
% %     V           = Datapixx('GetAdcVoltages');
% %     newsamples  = Datapixx('ReadAdcBuffer', nAdcLocalBuffSpls, -1);
% %     adcDataset = [adcDataset, newsamples];
% end
Datapixx('Close');

% %============ Plot result
% figure;
% for n = 1:size(adcDataset,1)
%     plot(linspace(0, nAdcLocalBuffSpls/adcRate, nAdcLocalBuffSpls), adcDataset(n,:), 'linewidth',2);
%     hold on;
% end
% legend(c.ADCchannelNames);
% grid on
% xlabel('Time (seconds)');
% ylabel('Voltage (V)');