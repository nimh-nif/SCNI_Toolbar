function Params = SCNI_InitializeGrid(Params)

%========== Prepare grid for experimenter display
CircleSpacing   = Params.Display.Exp.GridSpacing*Params.Display.PixPerDeg;     	% Increase in diameter with each concentric circle
NoCircles       = floor(Params.Display.Rect(3)/CircleSpacing(1));            	% Calculate number of circles to fill screen width
Params.Display.Grid.BullsEyeWidth = 1;                                        	% Pen width for bulls eye lines (pixels)
for circleno = 1:NoCircles
    CircleDiameter(circleno,:)               = CircleSpacing*circleno;               
    Params.Display.Grid.Bullseye(:,circleno) = CenterRect([0,0,CircleDiameter(circleno,:)], Params.Display.Rect)'; 
end
Params.Display.Grid.Meridians     = [Params.Display.Rect([3,3])/2, 0, Params.Display.Rect(3); 0, Params.Display.Rect(4), Params.Display.Rect([4,4])/2];

