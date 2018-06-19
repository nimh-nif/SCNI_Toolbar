function [PDS ,c ,s] = SCNI_savedata(PDS ,c ,s)

c.Date = datestr(now,'yyyymmdd');                                                       % Get today's date in yyyymmdd format
c.Filename = sprintf('%s_%s_%s_%d.mat', c.ExpName, c.SubjectID, c.Date, c.ScanNo);  	% Construct filename
save(fullfile(c.SaveDir, c.Filename),'PDS','c','s','-mat');                             % Save data to .mat file