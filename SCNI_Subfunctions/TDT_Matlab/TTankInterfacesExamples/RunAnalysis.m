% This is the analysis function called by the TTI 'Run Analysis' button
function RunAnalysis()
    global CurrentServer;
    global CurrentTank;
    global CurrentBlock;
    global CurrentEvent;
    global data;
    
    disp('RunAnalysis')
    data = TDT2mat(CurrentTank, CurrentBlock);
    
end