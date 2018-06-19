% SCNI_PlotGaze


%================== Load saved data
c.SaveDir       = fullfile('/projects/murphya/fMRI/Behaviour/');
c.FilePrefix    = sprintf('%s_%s', datestr(now,'yyyymmdd'), 'NIFblock_init');    % File prefix
c.Matfilename   = fullfile(c.SaveDir, [c.FilePrefix, '_1.mat']);
load(c.Matfilename);


plot(PDS.EyeXYP{1,1}(1,:),'-r');
plot(PDS.EyeXYP{1,1}(2,:),'-b');
xlabel('Time (s)');
ylabel('X/Y position')