function [PDS, c, s]= SCNIblock_next(PDS, c, s)

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

fprintf('Next stim...\n')

%============ Advance to next trial/ block
if c.Blocks.TrialNumber < size(c.Blocks.Stimorder, 2)                       % If 'within block trial number' is less than # trials per block...
    c.Blocks.TrialNumber    = c.Blocks.TrialNumber+1;                       % Advance trial number
elseif c.Blocks.TrialNumber >= size(c.Blocks.Stimorder, 2)                  % If 'within block trial number' is equal to # trials per block...
    if c.Blocks.Number < c.NoBlocks                                         % If block number is less than total number of blocks...
        c.Blocks.TrialNumber    = 1;                                      	% Reset within block trial number to 1
        c.Blocks.Number         = c.Blocks.Number+1;                    	% Advance block count to next block
    elseif c.Blocks.Number == c.NoBlocks                                    % If run is complete...
        c.Blocks.CompletedRun = 1;
        return
    end
end

if ~isfield(c.Blocks, 'CompletedRun') || c.Blocks.CompletedRun ~= 1                 % If this is not the very first trial...
    c.CondNo      = c.Blocks.Order(c.Blocks.Number);                                % Get the condition number for the current block
    if c.CondNo > 0
        c.ImageNo     = c.Blocks.Stimorder(c.Blocks.Number, c.Blocks.TrialNumber); 	% Get the image number for the current trial
        c.ImageTexH   = c.BlockIMGs{c.CondNo}(c.ImageNo);                       	% Get the next stimulus texture handle
        if c.Stim_AddBckgrnd == 1 && ~isempty(c.BckgrndDir{Cond})                   % If a stimulus background was requested and is available for this condition...
            c.BackgroundTexH  = c.BlockBKGs{c.CondNo}(c.ImageNo);                	% Get background texture handle
        else                                                                        % Otherwise...
            c.BackgroundTexH  = 0;                                                	% Set handle to zero
        end               
    end
    if ~isfield(c.Run, 'StartTime')
        c.Run.StartTime = GetSecs;
    end
    c.Run.CurrentTime   = GetSecs-c.Run.StartTime;                                  % Calulate time
    c.Run.CurrentMins   = floor(c.Run.CurrentTime/60);
    c.Run.CurrentSecs   = rem(c.Run.CurrentTime, 60);
    c.TextFormat        = ['Block     %d /%d\n\n',...
                           'Trial     %d /%d\n\n',...
                           'Run time  %02d:%02.0f\n\n',...
                           'Condition %d\n\n',...
                           'Stimulus  %d\n\n'];
    c.TextContent   = [c.Blocks.Number, c.Blocks.Total, c.Blocks.TrialNumber, size(c.Blocks.Stimorder, 2), c.Run.CurrentMins, c.Run.CurrentSecs, c.CondNo, c.ImageNo];
    c.TextString    = sprintf(c.TextFormat, c.TextContent);
end
SCNI_SetBitsTDT(c.ImageNo);                         % Send the next condition number to TDT


end