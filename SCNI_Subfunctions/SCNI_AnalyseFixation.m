
% SCNI_AnalyseFixation.m


RunDuration     = 

DesignMat       = 
for run = 1:Params.Run.Number
    for stim = 1:size(Params.Design.StimMatrix, 2)
        DesignMat(run, stim)    = Params.Design.StimMatrix(run, stim);
        AlphaMat(run, stim)     = min([1- Params.Design.Completed(run, stim), 0.5]);
    end
end


figure;
Imh     = imagesc(DesignMat);
alpha(Imh, AlphaMat);
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


Params.Run.ValidFixations