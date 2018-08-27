function Params = SCNI_GenerateDesign(Params, PlotDesign)

%======================== SCNI_GenerateDesign.m ===========================
% This function checks whether a design matrix has already been generated
% and saved for a given experimental session, and if so, returns it. If a
% design does not already exist it generates one and saves it to a .mat
% file, as well as appending the design field to the Params structure that
% is returned.
%
%==========================================================================

%========== Check inputs
if ~isfield(Params,'Design')
	error('The input stuct ''Params'' must contain a ''Design'' field to generate a design!');
else
    RequiredFields  = {'Type','TotalStim','StimPerTrial','TrialsPerRun'};
    PresentFields   = fieldnames(Params.Design);
    if sum(ismember(RequiredFields, PresentFields)) < numel(RequiredFields)
        error('Input struct ''Params.Design'' did not contain all necessary fields!');
    end
end

%============= 
Params.Design.StimPerRun        = Params.Design.TrialsPerRun*Params.Design.StimPerTrial;
Params.Design.RunsPerSession    = 50;                                   

%=========== Initialize random seed generator
rng(now,'twister');                     % Seed the ramdom number generator using today's date
Params.Design.Seed = rng;               % Save seed state


if Params.Design.Type == 1        %================= Randomized design
    Params.Design.NoConditions  = 1;
    StimVector                  = randi(Params.Design.TotalStim, 1, Params.Design.StimPerRun*Params.Design.RunsPerSession);
    Params.Design.StimMatrix  	= reshape(StimVector, [Params.Design.RunsPerSession, Params.Design.StimPerRun]);
    Params.Design.CondMatrix  	= ones(Params.Design.RunsPerSession, Params.Design.StimPerRun);

elseif Params.Design.Type == 2    %================= Block design
    Params.Design.FixBlockPos   = 1;      
%     Params.Design.StimMatrix    = GenerateBlockDesign(Params.Design.NoCond, Params.Design.FixBlockPos);
%     Params.Design.CondMatrix    = R;
    
end

if PlotDesign == 1
    PlotDesignMatrix(Fig, Params);
end

end

%============= Generate a Latin square balanced block design
function R = GenerateBlockDesign(NoCond, FixBlockPos)
    while 1                                     % Until acceptable sequence is generated...
        [M,R]   = latsq(NoCond);                % Generate randomized Latin square sequence
        R       = reshape(R,[1,numel(R)]);  	% Reshape matrix into vector
        ImmediateReps = find(diff(R)==0);    	% Find any consecutive repetitions
        if NoCond <= 2
            break;
        end
        if isempty(ImmediateReps)
            if BlocksPerCond > NoCond           
                if R(1)~=R(end)                   
                    R = repmat(R,[1,2]);        % Repeat sequence 
                    break;
                end
            else
                break;
            end
        end
    end
    
    %======= Add fix blocks (condition # = 0)
    switch FixBlockPos
        case 1  %======= Only first and last blocks are fixation
            R = [zeros(size(R,1),1), R, zeros(size(R,1),1)];
            
        case 2  %======= Every other block is fixation
            for r = 1:size(R,1)
                NewR(r,1) = 0;
                for c = 1:size(R,2)
                    NewR(r,c) = [R(r,c),0];
                end
            end
            R = [zeros(size(R,1), 1), NewR];
    end
end


%======= Show block design
function Fig = PlotDesignMatrix(Fig, Params)

    Fontsize    = 16;
    Fig.Fh      = figure;
    if Params.Design.Type == 1
        
        
        
        
    elseif Params.Design.Type == 2
        Fig.Imh     = imagesc(R);
        box off;
        xlabel('Block #','fontsize',Fontsize)
        ylabel('Run #','fontsize',Fontsize)
        set(gca,'tickdir','out','fontsize',Fontsize)
        cbh = colorbar;
        set(cbh, 'fontsize',Fontsize);
        set(gca,'clim', [0.5, NoCond+0.5]);
        cbh.Limits      = [0.5, NoCond+0.5];
        cbh.Ticks       = 1:NoCond; 
        cbh.Ticklabels  = ConditionNames;
        colormap(jet(NoCond));
    end
end