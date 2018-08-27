function [TT, CloseTT] = SCNI_TDTRead_Init(TT, tankName, blockName)

if ~exist('TT','var')|| isempty(TT)    	% If TTank handle was not supplied...
    TT = actxcontrol('TTank.X');        % Open TTank
    TT.ConnectServer('Local','Me');
    CloseTT = 1;
else
    CloseTT = 0;
end
a = TT.OpenTank(tankName, 'R');
b = TT.SelectBlock(blockName);
if a ~= 1 || b ~= 1
    fprintf('Error communicating with TTank: %s\n %s\n', a, b);
end

