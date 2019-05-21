function Params = SCNI_CheckImageTrialEyePos(Params)

%======================== SCNI_CheckImageTrialEyePos.m =========================
% This function reads all analog eye position data for the current trial
% period from DataPixx2 and assesses whether fixation requirements were met
% in order to determine appropriate feedback.
%==========================================================================


%=============== READ ANALOG INPUT DATA
Datapixx('RegWrRd');                                                                        % Update registers for GetAdcStatus
status          = Datapixx('GetAdcStatus');                                              
nReadSpls       = status.newBufferFrames;                                                 	% How many samples can we read?
[NewData, NewDataTs] = Datapixx('ReadAdcBuffer', nReadSpls, Params.DPx.adcBuffBaseAddr); 	% Read all available samples from ADCs
Datapixx('StopAdcSchedule');                                                                % Stop current schedule
if Params.Eye.EyeToUse < 3
    EyeChannels     = [Params.Eye.XYchannels{Params.Eye.EyeToUse}, Params.Eye.XYchannels{Params.Eye.EyeToUse}(2)+1];
    EyeData         = NewData(EyeChannels,:); 
    
elseif Params.Eye.EyeToUse == 3
    for e = 1:2
        SingleEyeData{e} 	= NewData(Params.Eye.XYchannels{e},:); 
        PupilData{e}        = NewData(Params.Eye.XYchannels{e}(2)+1,:);
    end
    EyeData(1,:)  	= mean([SingleEyeData{1}(1,:); SingleEyeData{2}(1,:)]);   	% X data = VERSION
    EyeData(2,:)   	= mean([SingleEyeData{1}(2,:); SingleEyeData{2}(2,:)]);     % Y data = average Y
    EyeData(3,:) 	= mean([PupilData{1}; PupilData{2}]);                       % Pupil data = average
    EyeData(4,:)    = SingleEyeData{1}(1,:) - SingleEyeData{2}(1,:);            % Z data = VERGENCE
end
  
DiodeChannel    = find(~cellfun(@isempty, strfind(Params.DPx.AnalogIn.Labels, 'Photodiode')));
DiodeData       = NewData(DiodeChannel,:);
Timestamps      = linspace(0, numel(DiodeData)/Params.DPx.AnalogInRate, numel(DiodeData));  % Analog data timestamps (seconds)

for xy = 1:2                                                                                % Convert eye position voltages to degrees
    EyeDataDVA(xy,:)        = (EyeData(xy,:) + Params.Eye.Cal.Offset{Params.Eye.EyeToUse}(xy))*Params.Eye.Cal.Gain{Params.Eye.EyeToUse}(xy); % Convert volts into degrees of visual angle
    EyeDataPix(xy,:)        = EyeDataDVA(xy,:)*Params.Display.PixPerDeg(xy);
    EyeDataPixScreen(xy,:)  = EyeDataPix(xy,:)+Params.Display.Rect(2+xy)/2;
end
StimOnsetSamples      = find(diff(DiodeData) > 1)+1;                                    	% Find photodiode onset samples
StimOffsetSamples     = find(diff(DiodeData) < -1);                                         % Find photodiode offset samples
StimOnsetSamples(find(diff(StimOnsetSamples)==1)+1) =[];                                    % Remove consecutive samples
StimOffsetSamples(find(diff(StimOffsetSamples)==1)+1) =[];                      
% 
% if numel(StimOnsetSamples) > Params.Eye.StimPerTrial-1
%     fprintf('\nWARNING: number of detected photiode onsets (%d) does not match expected number of stimuli per trials (%d)!\n', numel(StimOnsetSamples), Params.Eye.StimPerTrial);
%     fprintf('Check the analog input signals (plotted) for which channel the photodiode data appears on');
%     figure;
%     subplot(1,2,1); imagesc(Timestamps, 1:size(NewData,1), NewData);
%     ylabel('DataPixx Channel #')
%     xlabel('Time (seconds)');
%     subplot(1,2,2); plot(Timestamps, DiodeData); hold on;
%     plot(Timestamps, NewData(1,:));
%     plot(Timestamps, NewData(2,:));
%     legend({'DIode', 'LEft X', 'Left Y'});
%     title(sprintf('Photodiode = channel %d', DiodeChannel));
% end
if numel(StimOffsetSamples) < numel(StimOnsetSamples)
    StimOffsetSamples(end+1) = numel(Timestamps);
end

%=============== GET STIMULUS LOCATIONS
if Params.Eye.CenterOnly == 1
    LocIndices     = repmat(find(ismember(Params.Eye.Target.FixLocDirections,[0,0],'rows')), [1, Params.Eye.StimPerTrial]);
elseif Params.Eye.CenterOnly == 0
    LocIndices     = Params.Eye.Target.LocationOrder((Params.Run.StimCount-Params.Eye.StimPerTrial):(Params.Run.StimCount-1));
end

for stim = 1:Params.ImageExp.StimPerTrial 
    Samples         = StimOnsetSamples(stim):StimOffsetSamples(stim); 
    GazeRect        = Params.ImageExp.GazeRect;
    InRect          = (EyeDataPixScreen(1,Samples) >= GazeRect(RectLeft) & EyeDataPixScreen(1,Samples) <= GazeRect(RectRight) & ...
                        EyeDataPixScreen(2,Samples) >= GazeRect(RectTop) & EyeDataPixScreen(2,Samples) <= GazeRect(RectBottom));
    PropFix(stim)   = sum(InRect)/numel(InRect);
end
if mean(PropFix) < Params.Eye.FixPercent/100                         	% If total fixation duration percentage was less than required...
    Params.Run.ValidTrial = 0;                                       	% Invalid trial!
elseif mean(PropFix) >= Params.Eye.FixPercent/100   
    Params.Run.ValidTrial = 1;                                         	% Valid trial!
end

end