function Frame = SCNI_ModifyImage(RGB)

%========================== SCNI_ModifyImage.m ============================
% This function takes a single RGB image as a YxXx3 matrix and performs the
% requested series of modifications to the image, with each step being
% saved to a new field of the output structure 'Frame'. 
%==========================================================================



[Frame.Height, Frame.Width, Frame.Channels] = size(RGB);
Frame.MatSize       = [Frame.Height, Frame.Width, Frame.Channels];

Params.Stereo       = '2D';
Params.GaussSD      = 10;
Params.SNR          = 0.5;
Params.Thresh       = 0.5;
Params.NoTiles      = [20, 12];             % Number of tiles in grid scrambled image (X x Y)
Params.PixSize      = [20,20];

Params.PixPerTile   = round(Frame.MatSize([2,1])./[1,1]./Params.NoTiles);
Params.TileOrder    = randperm(Params.NoTiles(1)*Params.NoTiles(2));

%=========== Structure/ Colour manipulations
Frame.Original      = double(RGB)/max(double(RGB(:)));
Frame.HSL           = rgb2hsl(Frame.Original);
Frame.Greyscale     = repmat(Frame.HSL(:,:,3),[1,1,3]);
Frame.HueInv        = hsl2rgb(cat(3, Frame.HSL(:,:,1)+0.5, Frame.HSL(:,:,2:3)));     
Frame.ContrastInv   = hsl2rgb(cat(3, Frame.HSL(:,:,1:2), ones(Frame.Height,Frame.Width)-Frame.HSL(:,:,3)));
Frame.Negative      = hsl2rgb(abs(cat(3, ones(Frame.Height, Frame.Width), zeros(Frame.Height, Frame.Width), ones(Frame.Height, Frame.Width))-Frame.HSL));

%=========== Spectral manipulations
Frame.Filtered      = imgaussfilt(Frame.Original, Params.GaussSD);
Frame.Thresholded   = repmat(imbinarize(imgaussfilt(Frame.Greyscale(:,:,1), Params.GaussSD)),[1,1,3]);
Frame.Pixelated     = Pixelate(Frame, Params);

%=========== Spatial manipulations
switch Params.Stereo
    case '2D'
        Frame.MirrorHoriz   = Frame.Original(:,Frame.Width:-1:1,:);
        Frame.MirrorVert    = Frame.Original(Frame.Height:-1:1,:,:);
    case 'SBS'
        Frame.MirrorHoriz   = cat(2, Frame.Original(:,(Frame.Width/2):-1:1,:), Frame.Original(:,Frame.Width:-1:(Frame.Width/2 + 1),:));
        Frame.MirrorVert    = Frame.Original(Frame.Height:-1:1,:,:);
    case 'TB'
     	Frame.MirrorHoriz   = Frame.Original(:,Frame.Width:-1:1,:);
        Frame.MirrorVert    = cat(1, Frame.Original(Frame.Height/2:-1:1,:,:), Frame.Original(Frame.Height:-1:(Frame.Height/2+1),:,:));
end
Frame.GridScram     = GridScram(Frame.Original, Params);
Frame.SpectScram    = SpectScram(Frame.Original, Params);
Frame.Noise         = ApplySNR(Params.SNR, Frame.Original, Frame.SpectScram);


end

%% ====================== Image processign subfunctions ===================

%=============== Fourier Phase Scrambled
function newimg = SpectScram(img, Params)
    ImSize      = size(img);
    RandomPhase = angle(fft2(rand(ImSize(1), ImSize(2))));                      % Generate random phase structure
    for ch = 1:ImSize(3)
        ImFourier(:,:,ch)	= fft2(img(:,:,ch));                              	% Fast-Fourier transform 
        Amp(:,:,ch)         = abs(ImFourier(:,:,ch));                           % Amplitude spectrum
        Phase(:,:,ch)       = angle(ImFourier(:,:,ch));                         % Phase spectrum
        Phase(:,:,ch)       = Phase(:,:,ch) + RandomPhase;                      % Add random phase to original phase
        ScrambledImage(:,:,ch) = Amp(:,:,ch).*exp(sqrt(-1)*(Phase(:,:,ch))); 	% Re-combine amplitude and phase 
    end
    newimg = real(ifft2(ScrambledImage));                                       % Perform inverse Fourier & get rid of imaginery part in image (due to rounding error)
end

%=============== Grid scrambled
function newimg = GridScram(img, Params)

switch  Params.Stereo
    case '2D'
        [newimg,I,J] = randblock(img, [Params.PixPerTile(2),Params.PixPerTile(1),size(img,3)]);     % Scramble
        
    case 'SBS'
        HalfFrame{1} = img(:,1:(size(img,2)/2), :);
        HalfFrame{2} = img(:,(size(img,2)/2)+1:end, :);
        for e = 1:2
            [ScrambledImage{e},I,J] = randblock(HalfFrame{e},[Params.PixPerTile(2),Params.PixPerTile(1),size(HalfFrame{e},3)], Params.TileOrder);    % Scramble
        end
        newimg = [ScrambledImage{1}, ScrambledImage{2}];
        
    case 'TB'
        
        
end

end

function newimg = Pixelate(Frame, Params)
    Pixfun  	= @(block_struct) mean2(block_struct.data)*ones(size(block_struct.data));
    for ch = 1:3
        newimg(:,:,ch) = blockproc(Frame.HSL(:,:,ch), Params.PixSize, Pixfun);
    end
    newimg = hsl2rgb(newimg);
end
