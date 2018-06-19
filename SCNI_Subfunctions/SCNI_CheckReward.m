function Params = SCNI_CheckReward(Params)

%=========================== SCNI_CheckReward.m ===========================
% Check the reward schedule and deliver reward if appropriate.


if ~isfield(Params, 'Run')
    error('SCNI_CheckReward.m requireds the input structure ''Params'' to contain a Params.Run.ValidFixations field!');
end
if ~isfield(Params,'Reward')
    Params.Reward.LastRewardTime    = GetSecs; 
    Params.Reward.NextRewardInt     = 2;
    Params.Reward.MeanIRI           = 4;
    Params.Reward.RandIRI           = 2;
    
end

if GetSecs > Params.Reward.LastRewardTime + Params.Reward.NextRewardInt                              	% If next reward is due...                       
    FixPeriodIndx   = find(Params.Run.ValidFixations(:,1) > Params.Reward.LastRewardTime & Params.Run.ValidFixations(:,1) < Params.Reward.LastRewardTime+Params.Reward.NextRewardInt);
    ProportionValid = mean(Params.Run.ValidFixations(FixPeriodIndx,2));                                 % Calulate proportion of interval that fixations were valid
    if ProportionValid > Params.Reward.Proportion                                                       % If proportion meets required proportion...
        Params = SCNI_GiveReward(Params);                                                               % Give reward
    end
    Params.Reward.NextRewardInt     = Params.Reward.MeanIRI+rand(1)*Params.Reward.RandIRI;              % Generate random interval before next reward delivery (seconds)
    Params.Reward.LastRewardTime    = GetSecs;                                                          % Update time of last reward
end