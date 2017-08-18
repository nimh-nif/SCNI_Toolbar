function c = SCNI_DataPixxInit(Params)

%======================= SCNI_DataPixxInit.m ==============================
% 
%


%====================== Error handling
if nargin == 0 || isempty('Params') || ~isfield(Params,'DPx')
    Params = SCNI_DatapixxSettings([],0);       	% Load DataPixx parameters for this system
end
if Params.DPx.Installed == 0 || Params.DPx.Connected == 0
   error('Matlab does not have access to DataPixx functions!');
end
if Params.DPx.Connected == 0
    error('No DataPixx box detected! Check that it is powered on and connected.');
end

%================== General DataPixx settings
Datapixx('Open');
Datapixx('StopAllSchedules');
Datapixx('DisableDinDebounce');
Datapixx('SetDinLog');
Datapixx('StartDinLog');
Datapixx('SetDoutValues',0);
Datapixx('RegWrRd');
Datapixx('DisableDacAdcLoopback');
Datapixx('DisableAdcFreeRunning');                  % For microsecond-precise sample windows
Datapixx('RegWrRd');                                % Synchronize Datapixx registers to local register cache

%================== Prepare ADC for recording analog signals
c.ADCchannels       = Params.DPx.AnalogInCh;                                                
UnusedIndx          = find(~cellfun(@isempty, strfind(Params.DPx.AnalogInNames,'None')));   % Find ADC channels not assigned to inputs
c.ADCchannelsUsed   = find(Params.DPx.AnalogInAssign ~= UnusedIndx);                        % Find ADC channels assigned to inputs 
c.adcRate        	= Params.DPx.AnalogRate;                                                % ADC data sample rate
c.nAdcLocalBuffSpls	= c.adcRate*c.MaxTrialDur;                                              % Preallocate a local buffer
c.EyeXY             = zeros(numel(c.ADCchannelLabels), c.nAdcLocalBuffSpls);                % Preallocate matrix for ADC storage
c.adcBuffBaseAddr  	= 4e6;                                                                  % Set DataPixx internal buffer address


%================== Prepare DAC schedule for reward delivery?
if Params.DPx.TDTonDOUT == 1
    
end
c.Reward_Volt      	= 5.0;                                                                  % Set output voltage for reward trigger (Volts)
c.Reward_pad      	= 0.01;                                                                 % Pad pulse on either side with zeros (seconds)
c.Wave_time       	= c.Reward_TTLDur+c.Reward_pad;                                         % Calculate wave duration (seconds)
c.Dacrate        	= 1000;                                                                 % Set DAC sample rate
c.reward_Voltages   = [zeros(1,round(c.Dacrate*c.Reward_pad/2)), c.Reward_Volt*ones(1,int16(c.Dacrate*c.Reward_TTLDur)), zeros(1,round(c.Dacrate*c.Reward_pad/2))];
c.ndacsamples       = floor(c.Dacrate*c.Wave_time);                   
c.dacBuffAddr       = 0;
c.RewardChnl        = 0;
Datapixx('RegWrRd');
Datapixx('WriteDacBuffer', c.reward_Voltages, c.dacBuffAddr, c.RewardChnl);
nChannels = Datapixx('GetDacNumChannels');
Datapixx('SetDacVoltages', [0:nChannels-1; zeros(1, nChannels)]);                           % Set all DAC channels to 0V