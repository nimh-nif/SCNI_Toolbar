function Params = SCNI_GenerateDesign(Params)

%======================== SCNI_GenerateDesign.m ===========================
% This function checks whether a design matrix has already been generated
% and saved for a given experimental session, and if so, returns it. If a
% design doesn not already existm it generates one and saves it to .mat
% file, as well as appending the design field to the Params structure that
% is returned.
%
%==========================================================================


if ~isfield(Params,'Design')

    Params.Design.TimeGenerated   	= datestr(datetime('now'));
    
    Params.Design.Types         	= {'Randomized','Block'};
    Params.Design.Type              = 1;
    if Params.Design.Type == 1
        Params.Design.NoConditions = 1;
    end
    Params.Design.TotalStim         = 314;
    Params.Design.StimPerTrial      = 5;                                    % How many stimuli to present per 'trial' (or reward period)
    Params.Design.TrialsPerRun      = ceil(TotalStim/StimPerTrial);         % Get at least one repetition per block
    Params.Design.StimPerRun        = TrialsPerRun*StimPerTrial;
    Params.Design.RunsPerSession    = 50;                                   

    
    TrialDuration   = (StimDuration + ISI)*StimPerTrial;    % 
    MinRunDuration  = (TrialDuration + ITI)*TrialsPerRun;   % 
end


DesignMatrix    = nan(RunsPerSession, StimPerRun);
while 
    StimOrder           = randperm(TotalStim);
    StimIndx            = [];
    DesignMatrix(StimIndx)  = StimOrder;
    
end
Params.Design.CondMatrix = DesignMatrix;        % Matrix specifying order of conditions
Params.Design.StimMatrix = DesignMatrix;        % Matrix specifying order of stimuli