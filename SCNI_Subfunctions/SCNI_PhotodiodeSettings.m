function PD = SCNI_PhotodiodeSettings(PD)

%====================== SCNI_PhotodiodeSettings.m =========================



Fig.Handle = figure;%(typecast(uint8('SCNI_EL'),'uint32'));               	% Assign GUI arbitrary integer        
if strcmp('SCNI_PhotodiodeSettings', get(Fig.Handle, 'Tag')), return; end 	% If figure already exists, return
Fig.FontSize        = 14;
Fig.TitleFontSize   = 16;
Fig.Rect            = [0 200 600 860];                               	% Specify figure window rectangle
Fig.PannelSize      = [300, 650];                                       
Fig.PannelElWidths  = [30, 120];
set(Fig.Handle,     'Name','SCNI: Photodiode settings',...           	% Open a figure window with specified title
                    'Tag','SCNI_PhotodiodeSettings',...               	% Set figure tag
                    'Renderer','OpenGL',...                             % Use OpenGL renderer
                    'OuterPosition', Fig.Rect,...                       % position figure window
                    'NumberTitle','off',...                             % Remove figure number from title
                    'Resize', 'off',...                                 % Prevent resizing of GUI window
                    'Menu','none',...                                   % Turn off memu
                    'Toolbar','none');                                  % Turn off toolbars to save space
Fig.Background  = get(Fig.Handle, 'Color');                           	% Get default figure background color
Fig.Margin      = 20;                                                 	% Set margin between UI panels (pixels)                                 


Params.BackgroundColor  = [0.5, 0.5, 0.5];                              % Display background color
Params.PD.On            = 1;                                            % Do we have a photodiode attached to the subject's display?
Params.PD.Size          = 20;                                           % Size of photodiode marker (pixels)
Params.PD.SourceRect  	= [0,0,Params.PD.Size,Params.PD.Size];          % Create PTB 'rect' for photodiode marker
Params.PD.OnColor   	= [0 0 0];                                      % RGB color to indicate 'stimulus on' to photodiode
Params.PD.OffColor      = [255 255 255];                                % RGB color to indicate 'stimulus off' to photodiode
Params.PD.Location      = 'BottomLeft';                             	% Which corner of the subject's display is the photodiode attached to?

%=============== Get rectangles for PTB display of photodiode marker(s)
if IsLinux == 1                                                        	% If using a single "X screen" for dual displays on Linux... 
    if Params.Display.UseSBS3D == 0                                     % If NOT using a side-by-side stereoscopic 3D presentation method...
        switch Params.PD.Location                                       % Which corner of the subject's display is the photodiode attached to?
            case 'BottomLeft'
               	Params.PD.ExpRect       = Params.PD.SourceRect + Params.Display.Rect([1,4,1,4]) - Params.PD.SourceRect([1,4,1,4]);  % Specify experimenter's portion of the X screen
                Params.PD.MonkeyRect    = Params.PD.SourceRect + Params.Display.Rect([3,4,3,4]) - Params.PD.SourceRect([1,4,1,4]);	% Specify subject's portion of the X screen 
            case 'TopLeft'
                Params.PD.ExpRect       = Params.PD.SourceRect;
                Params.PD.MonkeyRect    = Params.PD.SourceRect + Params.Display.Rect([3,1,3,1]);
            case 'TopRight'
                Params.PD.ExpRect       = Params.PD.SourceRect + Params.Display.Rect([3,1,3,1]) - Params.PD.SourceRect([3,2,3,2]);
                Params.PD.MonkeyRect    = Params.PD.SourceRect + Params.Display.Rect([3,1,3,1]).*[2,1,2,1] - Params.PD.SourceRect([3,2,3,2]);
            case 'BottomRight'
                Params.PD.ExpRect       = Params.PD.SourceRect + Params.Display.Rect([3,4,3,4]) - Params.PD.SourceRect([3,4,3,4]);
                Params.PD.MonkeyRect    = Params.PD.SourceRect + Params.Display.Rect([3,4,3,4]).*[2,1,2,1] - Params.PD.SourceRect([3,4,3,4]);
        end
    elseif Params.Display.UseSBS3D == 1                                 % For presenting side-by-side stereoscopic 3D images...
       	switch Params.PD.Location
            case 'BottomLeft'
                
                Params.PD.MonkeyRect(1,:)  = (Params.PD.SourceRect./[1,1,2,1]) + Params.Display.Rect([3,1,3,1]) + Params.Display.Rect([1,4,1,4]) - Params.PD.SourceRect([1,4,1,4]);    	% Center a horizontally squashed fixation rectangle in a half screen rectangle
                Params.PD.MonkeyRect(2,:)  = (Params.PD.SourceRect./[1,1,2,1]) + Params.Display.Rect([3,1,3,1])*1.5 + Params.Display.Rect([1,4,1,4]) - Params.PD.SourceRect([1,4,1,4]);         
            case 'TopLeft'
                Params.PD.MonkeyRect = Params.PD.SourceRect + Params.Display.Rect([3,1,3,1]);
            case 'TopRight'
                Params.PD.MonkeyRect = Params.PD.SourceRect + Params.Display.Rect([3,1,3,1]).*[2,1,2,1] - Params.PD.SourceRect([3,2,3,2]);
            case 'BottomRight'
                Params.PD.MonkeyRect = Params.PD.SourceRect + Params.Display.Rect([3,4,3,4]).*[2,1,2,1] - Params.PD.SourceRect([3,4,3,4]);
        end
    end
elseif IsLinux == 0                                                     % If NOT using a single "X screen" for dual displays (e.g. stereomode 10 on OSX/ Windows)            
    Params.PD.ExpRect       = Params.PD.SourceRect;
    Params.PD.MonkeyRect    = Params.PD.ExpRect;
    
end

%=============== Display screen layout
Fig.Axh = axes('units','pixels','position', [100 100 400 200],'parent',Fig.Handle,'color',Params.BackgroundColor);




