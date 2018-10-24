function Params = SCNI_InitKeyboard(Params)

%================= INITIALIZE KEYBOARD SHORTCUTS
KbName('UnifyKeyNames');
Params.Keys.Names          	= {'Escape','R','A','F','C','E','S','M','RightArrow','UpArrow','DownArrow','I'};         
Params.Keys.Functions     	= {'Stop','Reward','Audio','ToggleFix','Center','ChangeEye','Save','Mouse','ChangeXY','GainInc','GainDec','Invert'};
Params.Keys.List            = zeros(1,256); 
for k = 1:numel(Params.Keys.Names)
    eval(sprintf('Params.Keys.%s = KbName(''%s'');', Params.Keys.Functions{k}, Params.Keys.Names{k}));
    eval(sprintf('Params.Keys.List(Params.Keys.%s) = 1;', Params.Keys.Functions{k}));
end
Params.Keys.Interval        = 0.2;              % Minimum interval between consecutive key presses (seconds)
Params.Keys.LastPress       = GetSecs;          % Initialize last key press to current time