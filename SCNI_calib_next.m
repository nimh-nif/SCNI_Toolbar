function [PDS, c, s]= SCNI_calib_next(PDS, c, s)

%========================== Next trial function ===========================
% This is executed once at the beginning of each 'trial' as the first step 
% of the 'Run' action from the GUI (the other steps are 'run_trial' and 
% 'finish_trial'). This is where values are block as needed for the next trial
%
% HISTORY:
%   2017-01-23 - Written by murphyap@mail.nih.gov based on psychmetic_next.m
%   
%     ____    ___ __  _______
%    /    |  /  //  //  ____/    Neuro Imaging Facility Core
%   /  /| | /  //  //  /___      Building 49 Convent Drive
%  /  / | |/  //  //  ____/      NATIONAL INSTITUTES OF HEALTH
% /__/  |____//__//__/          
%==========================================================================

fprintf('Next calibration target...\n')

%============ Advance to next trial/ block
if s.StimNumber < c.StimPerTrial                                            % If stimulus number is less than # presentations per trial...
    s.StimNumber    = s.StimNumber+1;                                       % Advance stimulus number
elseif s.StimNumber >= c.StimPerTrial                                       % If stimulus number is equal to # presentations per trial...
    if s.TrialNumber < c.TrialsPerRun                                    	% If trial number is less than total number of trials...
        s.StimNumber        = 1;                                            % Reset within trial stimulus number to 1
        s.TrialNumber       = s.TrialNumber+1;                              % Advance trial count to next trial
    elseif s.TrialNumber == c.TrialsPerRun                                 	% If run is complete...
        c.CompletedRun = 1;
        return
    end
end

if ~isfield(c, 'CompletedRun') || c.CompletedRun ~= 1                      	% If this is not the very first trial...
    s.CondNo      = c.LocationOrder((s.TrialNumber*c.StimPerTrial)+s.StimNumber);  % Get the condition number for the current block

    if ~isfield(c,'Run') || ~isfield(c.Run, 'StartTime')
        c.Run.StartTime = GetSecs;
    end
    c.Run.CurrentTime   = GetSecs-c.Run.StartTime;                         	% Calulate time
    c.Run.CurrentMins   = floor(c.Run.CurrentTime/60);
    c.Run.CurrentSecs   = rem(c.Run.CurrentTime, 60);
    c.TextFormat        = ['Stim      %d /%d\n\n',...
                           'Trial     %d /%d\n\n',...
                           'Run time  %02d:%02.0f\n\n',...
                           'Condition %d\n\n'];
    c.TextContent   = [s.StimNumber, c.StimPerTrial, s.TrialNumber, c.TrialsPerRun, c.Run.CurrentMins, c.Run.CurrentSecs, s.CondNo];
    c.TextString    = sprintf(c.TextFormat, c.TextContent);
end
SCNI_SetBitsTDT(s.CondNo);                                                	% Send the next condition number to TDT


end