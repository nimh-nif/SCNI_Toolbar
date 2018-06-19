function [PDS, c, s]= NIFblock_finish(PDS, c, s)

%========================== Trial finish function =========================
% 
%   
%     ____    ___ __  _______
%    /    |  /  //  //  ____/    Neuro Imaging Facility Core
%   /  /| | /  //  //  /___      Building 49 Convent Drive
%  /  / | |/  //  //  ____/      NATIONAL INSTITUTES OF HEALTH
% /__/  |____//__//__/          
%==========================================================================


disp('Finish!')

%%

 if c.Blocks.CompletedRun == 1
    c.runflag=0;
 end
% s.blockno = c.blockno;
% s.trials  = c.j;
% s.trialno = c.trinblk;
% s.current = c.trialcode;
% %% save data
% 
% if mod(c.j,500) == 1 % save data
%     nfile=num2str(c.j);
%     
%     sfile=strcat('R', datestr(date,'yymmdd'), '_attn_blkdsgn','_', nfile);
%     c.filename=sfile;
%     save(['Data/' sfile '.mat'],'PDS','c','s','-mat');
% end

%%

end