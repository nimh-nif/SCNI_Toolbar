function SCNI_BasicTraining

%======================= SCNI_BasicTraining.m =============================
% This function runs a training session in which naive subjects will learn
% basic behaviours required for experimental tasks, including:
%   - to operate a lever to obtain reward
%   - to maintain fixation
%
%
%
%==========================================================================


%============== Initialize DataPixx 
Params           	= SCNI_DatapixxSettings([], 0);
Params.LeverInCh    = strfind(Params.DPx.AnalogInNames(Params.DPx.AnalogInAssign), 'Lever');
Params.RewardOutCh  = strfind(Params.DPx.AnalogInNames(Params.DPx.AnalogInAssign), 'Reward');



%============== Training Parameters
Train.PressDur      = 200;          % How long the lever must be pressed for to earn reward
Train.TimeOutDur    = 500;          % How long to wait between accepting consecutive presses
Train.RewardDur     = 50;           % How long the TTL pulse to the reward solenoid should be
Train.TimeSteps     = 10;           % Step size for changing duration parameters
Train.MustFix       = 1;            % Add a fixation requirement?
Train.FixDur        = 1;            % How long is fixation presented for per trial? (seconds)
Train.FixRadius     = 20;           % Fixation window radius (degrees visual angle)
Train.VisualCue     = 1;            % Present a visual cue?
Train.AuditoryCue   = 1;            % Present an auditory cue?


%============== Open experimenter's GUI Wwindow





%============== Open PTB window
Params = SCNI_DisplaySettings([],0);    % Load display settings
Params = SCNI_PTBinit(Params);          % Open PTB windows



%============== 
while 1
    CheckExpPress();                                  % Check for experimenter's input
    CheckSubjectPress();                              % Check subject's input
    if Fixation == 1
        CheckFix;                                     % Check subject's eye position
    end
    if CriteriaMet == 1
        GiveJuice;                                    % Delivery reward
        
        
    end
    
    
    Screen('FillRect', Params.window, Params.Display.Background);       % Draw blank grey screen
    
    
    
end


end

%% ============================ SUBFUNCTIONS ==============================

function Keys = CheckExpPress(Keys)
    [keyIsDown, secs, keyCode, deltaSecs] = KbCheck();            	% Check if any key is pressed
    if keyIsDown 
        if keyCode(Keys.Exit)                                       % If so...
            ManualAbort;                                            % Perform manual abort
        elseif keyCode(Keys.Reward)                                 % Manual reward delivery
            if secs > Keys.LastPress + c.Key_MinRewardInt           % If last registered
                Keys.LastPress = secs;                              % Update last valid reward delivery
                SCNI_GiveJuice;
            end
        elseif keyCode(Keys.Pause)
            
        end
    end
end
