%========================= SCNI_GetPDrect.m ===============================
% This function calculates rectange positions for drawing photodiode
% marker(s) to svcreen.

function Params = SCNI_GetPDrect(Params, SBS)

    Params.Display.PD.Rect          = [0,0, Params.Display.PD.Diameter, Params.Display.PD.Diameter];
    if Params.Display.PD.Position == 1
        Params.Display.PD.On = 0;
    elseif Params.Display.PD.Position > 1
        Params.Display.PD.On = 1;
    end
    switch Params.Display.PD.Position
        case 2      %============ Bottom Left
            Params.Display.PD.ExpRect  	= Params.Display.PD.Rect + Params.Display.Rect([1,4,1,4]) - Params.Display.PD.Rect([1,4,1,4]);
            Params.Display.PD.SubRect   = Params.Display.PD.Rect + Params.Display.Rect([3,4,3,4]) - Params.Display.PD.Rect([1,4,1,4]);	% Specify subject's portion of the screen 

        case 3      %============ Top Left
            Params.Display.PD.ExpRect 	= Params.Display.PD.Rect;
            Params.Display.PD.SubRect   = Params.Display.PD.Rect + Params.Display.Rect([3,1,3,1]);

        case 4      %============ Top Right
            Params.Display.PD.ExpRect 	= Params.Display.PD.Rect + Params.Display.Rect([3,1,3,1]) - Params.Display.PD.Rect([3,2,3,2]);
            Params.Display.PD.SubRect   = Params.Display.PD.Rect + Params.Display.Rect([3,1,3,1]).*[2,1,2,1] - Params.Display.PD.Rect([3,2,3,2]);

        case 5      %============ Bottom Right
            Params.Display.PD.ExpRect 	= Params.Display.PD.Rect + Params.Display.Rect([3,4,3,4]) - Params.Display.PD.Rect([3,4,3,4]);
            Params.Display.PD.SubRect   = Params.Display.PD.Rect + Params.Display.Rect([3,4,3,4]).*[2,1,2,1] - Params.Display.PD.Rect([3,4,3,4]);
    end
    
    %========= For presenting side-by-side stereoscopic 3D images...
    if SBS == 1                                                                              
        Params.Display.PD.ExpRect     	= Params.Display.PD.Rect + Params.Display.Rect([1,4,1,4]) - Params.Display.PD.Rect([1,4,1,4]);
        Params.Display.PD.SubRect(1,:)  = (Params.Display.PD.Rect./[1,1,2,1]) + Params.Display.Rect([3,1,3,1]) + Params.Display.Rect([1,4,1,4]) - Params.Display.PD.Rect([1,4,1,4]);         	% Center a horizontally squashed fixation rectangle in a half screen rectangle
        Params.Display.PD.SubRect(2,:)  = (Params.Display.PD.Rect./[1,1,2,1]) + Params.Display.Rect([3,1,3,1])*1.5 + Params.Display.Rect([1,4,1,4]) - Params.Display.PD.Rect([1,4,1,4]);         
    end

end