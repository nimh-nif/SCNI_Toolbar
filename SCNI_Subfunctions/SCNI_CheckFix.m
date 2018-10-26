function Params = SCNI_CheckFix(Params, Period)


switch Period
    case 1  %=============== Trial is in progress
        FixSoFar        = Params.Run.ValidFixations(Params.Run.TrialCount, :,3);  	% Get all fixation validity data for current trial
        Proportion      = nanmean(FixSoFar);
        if 
            if Proportion < Params.Eye.FixDur/100
                Params.Run.AbortTrial = 1;
            end
        end
        
    case 2  %=============== Trial is over (inter-trial interval)
        
        
        
        
    otherwise
        error('Invalid trial period input! Must be 1 or 2.');
end