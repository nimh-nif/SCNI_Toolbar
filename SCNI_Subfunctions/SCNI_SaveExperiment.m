function SCNI_SaveExperiment(Params)

%======================= SCNI_SaveExperiment.m ============================
% Save the relevant data from the Params structure for the current session.


if exist(Params.Toolbar.Session.Fullfile, 'file')
    Append = 1;
    fprintf('Appending data for current run to %s...\n', Params.Toolbar.Session.Fullfile);
else
    Append = 0;
    fprintf('Creating new data file ''%s''...\n', Params.Toolbar.Session.File);
end

%============ Gather relevant data
Fields = {'Eye','Reward','Display','DPx','Toolbar'};
switch Params.Toolbar.CurrentExp
    case 'SCNI_ShowImages'
        Fields{end+1} = 'ImageExp';
    case 'SCNI_PlayMovies'
        Fields{end+1} = 'Movie';
    case 'SCNI_GazeFollowing'
        Fields{end+1} = 'GF';
   	case 'SCNI_TemporalContinuity'
        Fields{end+1} = 'TC';
end

for f = 1:numel(Fields)
    eval(sprintf('Data.%s = Params.%s;', Fields{f}, Fields{f}));
end

%============ Save file
switch Append
    case 0
        save(Params.Toolbar.Session.Fullfile, 'Data');
    case 1
        save(Params.Toolbar.Session.Fullfile, 'Data','-append');
end