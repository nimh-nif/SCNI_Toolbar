
%=========================== SCNI_StereoTest.m ============================
% Adaptation from QPCS_APM02.m = Work in progress!

Cue.On          = 1;                                         	% Cue to target?
Cue.Width       = 4;                                            % Cue width
Cue.Colour      = [255 0 0 20];                              	% Cue color RGBA

Fix.Colour      = [0 0 0];
Fix.Size        = 1*Display.Pixels_per_deg(1);
Fix.Rect        = CenterRect([0 0 Fix.Size Fix.Size], Display.Rect);

Dots.Size           = 3;
Dots.Density        = params(2);
Target.Disp       	= params(1)/60*Display.Pixels_per_deg(1);    
Target.Ecc          = params(3);
Dots.Rect           = round([0 0 18 18]*Display.Pixels_per_deg(1));
Dots.DestRect       = CenterRect(Dots.Rect, Display.Rect);
Dots.TotalArea      = Dots.Rect(3)*Dots.Rect(4);
Dots.AreaPerDot     = 2*pi*Dots.Size/2;
Dots.PerFrame       = round(Dots.TotalArea/Dots.AreaPerDot*Dots.Density);
Dots.Centre         = Dots.Rect([3,4])/2;
Dots.Colour         = round(rand(1,Dots.PerFrame))*255;             % Dots are black and white
Dots.Colour         = repmat(Dots.Colour,[3,1]);                                                      
for P = 1:9
   Dots.x{P} = (rand([1,Dots.PerFrame])*(Dots.DestRect(3)-Dots.DestRect(1)))-Dots.Centre(1); 
   Dots.y{P} = (rand([1,Dots.PerFrame])*(Dots.DestRect(4)-Dots.DestRect(2)))-Dots.Centre(2);
end

Stim.Window         = Dots.Rect;
Stim.Background     = Display.Background;
BorderSquares       = BackgroundSquares(Display, Stim);







%================== Present central fixation
for Eye = 1:2
    currentbuffer = Screen('SelectStereoDrawBuffer', Display.win, Eye-1);               % Select which eye to draw to
    Screen('DrawTexture', Display.win, BorderSquares);                                  % Draw background texture
    Screen('DrawDots', Display.win, [Dots.x{1}; Dots.y{1}], Dots.Size, Dots.Colour, Display.Centre, 2);      % Draw random dot field
    Screen('FillOval', Display.win, Photodiode.OffColour, Photodiode.Rect{Eye});      	% Draw Photodiode target
    Screen('FillOval', Display.win, [0 0 0], CenterRect([0 0 20 20], Display.Rect));   	% Draw explicit cue to target location
end
[CentralFixOnset, VBL] = Screen('Flip', Display.win);                                   



Target.Pos      = [params(1); params(2)]*Display.Pixels_per_deg(1);     % Coordinates of target center (pixels)
Target.Size     = params(4)*Display.Pixels_per_deg(1);                  % Target diameter (pixels) 
Target.Disp     = params(5)/60*Display.Pixels_per_deg(1);           	% Target disparity (convert from arcmin to pixels) (+ve = near, -ve = far)
stereocalib_eye = params(3);
Cue.Colour(4)   = params(6)*255;

    
    
P = randi(numel(Dots.x));
for d = 1:Dots.PerFrame                                                     % Add horizontal disparity to dots located inside the target
    if (Dots.x{P}(d)-Target.Pos(1))^2 + (Dots.y{P}(d)-Target.Pos(2))^2 <= (Target.Size/2)^2
        X{P,1}(d) = Dots.x{P}(d)+Target.Disp/2;
        X{P,2}(d) = Dots.x{P}(d)-Target.Disp/2;
    else
        X{P,1}(d) = Dots.x{P}(d);
        X{P,2}(d) = Dots.x{P}(d);
    end
end

Cue.Rect        = [Display.Centre,Display.Centre]+[-Target.Size/2+Target.Pos(1),-Target.Size/2+Target.Pos(2),Target.Size/2+Target.Pos(1),Target.Size/2+Target.Pos(2)];
Cue.DestRect{1} = Cue.Rect+[Target.Disp/2,0,Target.Disp/2,0];
Cue.DestRect{2} = Cue.Rect-[Target.Disp/2,0,Target.Disp/2,0];

for Eye = 1:2
    XY = [X{P,Eye}; Dots.y{P}];
    currentbuffer = Screen('SelectStereoDrawBuffer', Display.win, Eye-1);               % Select which eye to draw toca
    Screen('DrawTexture', Display.win, BorderSquares);                                  % Draw background texture
    Screen('DrawDots', Display.win, XY, Dots.Size, Dots.Colour, Display.Centre, 2);   	% Draw random dot field
%                 Screen('FillOval', Display.win, Fix.Colour, Fix.Rect);                % Draw central fixation marker?
    Screen('FillOval', Display.win, Photodiode.OnColour, Photodiode.Rect{Eye});      	% Draw Photodiode marker
    if Cue.On == 1
        Screen('FillOval', Display.win, Cue.Colour, Cue.DestRect{Eye});               	% Draw explicit cue to target location
    end
end
Screen('Flip', Display.win);