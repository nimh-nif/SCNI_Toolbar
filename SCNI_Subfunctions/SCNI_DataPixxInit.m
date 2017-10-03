function c = SCNI_DataPixxInit(Params, c)

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
UnusedIndx                  = find(~cellfun(@isempty, strfind(Params.DPx.AnalogInNames,'None')));   % Find ADC channels not assigned to inputs
Params.DPx.ADCchannelsUsed 	= find(Params.DPx.AnalogInAssign ~= UnusedIndx);                        % Find ADC channels assigned to inputs 
Params.DPx.nAdcLocalBuffSpls= Params.DPx.AnalogInRate*c.MaxTrialDur;                            	% Preallocate a local buffer
Params.DPx.adcBuffBaseAddr  = 4e6;                                                                  % Set DataPixx internal buffer address
Params.DPx.EyeChannels      = find(~cellfun(@isempty, strfind(Params.DPx.AnalogInLabels,'Eye')));    % Find ADC channels recording eye X and Y position

%================== Prepare DAC schedule for reward delivery
Params.DPx.AnalogReward      = any(Params.DPx.AnalogOutAssign==find(~cellfun(@isempty,strfind(Params.DPx.AnalogOutLabels,'Reward'))));
if Params.DPx.AnalogReward == 1
    Reward_Volt      	= 5.0;                                                                          % Set output voltage for reward trigger (Volts)
    Reward_pad      	= 0.01;                                                                         % Pad pulse on either side with zeros (seconds)
    Wave_time       	= c.Reward_TTLDur+Reward_pad;                                                   % Calculate wave duration (seconds)
    Params.DPx.reward_Voltages   = [zeros(1,round(Params.DPx.AnalogOutRate*Reward_pad/2)), Reward_Volt*ones(1,int16(Params.DPx.AnalogOutRate*c.Reward_TTLDur)), zeros(1,round(Params.DPx.AnalogOutRate*Reward_pad/2))];
    Params.DPx.ndacsamples      = floor(Params.DPx.AnalogOutRate*Wave_time);                   
    Params.DPx.dacBuffAddr  	= 0;
    Params.DPx.RewardChnl    	= find(~cellfun(@isempty, strfind(Params.DPx.AnalogOutNames,'Reward')))-1;	% Find DAC channel to send reward TTL on                                                                         % Which DAC channel to 
    
    %Datapixx('SetDacSchedule', Delay, c.Params.DPx.AnalogOutRate, c.Params.DPx.ndacsamples, c.Params.DPx.RewardChnl, c.Params.DPx.dacBuffAddr, c.Params.DPx.ndacsamples);
    
    Datapixx('RegWrRd');
    Datapixx('WriteDacBuffer', Params.DPx.reward_Voltages, Params.DPx.dacBuffAddr, Params.DPx.RewardChnl);
    nChannels = Datapixx('GetDacNumChannels');
    Datapixx('SetDacVoltages', [0:nChannels-1; zeros(1, nChannels)]);                                   % Set all DAC channels to 0V
end


%================== Prepare digital outputs for serial communciation with TDT?
if Params.DPx.TDTonDOUT == 1                                                                
    
    
end

c.Params = Params;  