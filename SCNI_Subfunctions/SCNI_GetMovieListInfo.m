function StimInfo = SCNI_GetMovieListInfo(MovieDir, MovFormat)

%======================= SCNI_GetMovieListInfo.m ==========================


if nargin == 0
    MovieDir    = '/projects/murphya/Stimuli/AvatarRenders_2018/SizeDistance/Movies/';
    MovFormat   = 'mp4';
end

Renders.SBS                = 1;        % Renders in side-by-side stereoscopic 3D format?
Renders.SqueezeFrame       = 1;        % Renders in squeezed-frame format?
Renders.IPD                = 3.5;      % Rednered for subject with inter-pupillary distance (cm)
Renders.ViewingDistance    = 60;       % Renderd for subject viewing from (cm)
Renders.Dome               = 0;        % Renders on warped fish-eye foramt for hemispheric dome projection?
Renders.CyclopeanCenter    = 1;        % Avatar's cylcopean eye is always at center of frame?


AllFiles = wildcardsearch(MovieDir, MovFormat);

for m = 1:numel(AllFiles)
    [~,StimInfo(m).Filename]    = fileparts(AllFiles{m});
    StimInfo(m).Path            = MovieDir;
    StimInfo(m).FileFormat      = MovFormat;
    fprintf('Loading info from movie %s (%d/ %d)...\n', StimInfo(m).Filename, m,  numel(AllFiles));
    videoobj                    = VideoReader(AllFiles{m});
    StimInfo(m).FPS             = videoobj.FrameRate;
    StimInfo(m).Width           = videoobj.width;
    StimInfo(m).Height          = videoobj.height;
    f = 1;
    while hasFrame(videoobj)
        video.frames(f).cdata = readFrame(videoobj);
        f = f+1;
    end
    StimInfo(m).NoFrames        = numel(video.frames);
    StimInfo(m).Duration        = StimInfo(m).NoFrames/StimInfo(m).FPS;
    StimInfo(m).Renders         = Renders;
    
end

save(fullfile(MovieDir, 'StimInfo.mat'), 'StimInfo');