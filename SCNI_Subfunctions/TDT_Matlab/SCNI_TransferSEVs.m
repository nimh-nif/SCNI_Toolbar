%============================ TransferSEVs.m ==============================
% This function allows the user to select which raw, unsorted spike folders 
% (e.g. .SEV files) to transfer from the RS4 to Nifstorage.
%==========================================================================

DestRoot      	= 'R:\';                                                    % Transfer to somewhere on Nifstorage Rawdata volume
TankRoot        = 'Z:\';                                                    % Transfer from TDT RS4 streamer
TankNames       = dir(TankRoot);
TankNames       = {TankNames([TankNames.isdir]).name};
[TankSelect,ok]	= listdlg('ListString',TankNames,...                           % Ask user to select experiment(s)
                          'ListSize',[200 200],...
                          'SelectionMode', 'multiple',...
                          'PromptString','Select subject tank:');
Subject         = TankNames{TankSelect};                                        % Find subject's name
[t, Compname]   = system('hostname');                                           % Get name of local computer
if ~strcmpi(Compname(1:4),'vrec') && ~strcmpi(Compname(1:4),'MH01')             
    error('TransferSEVs.m must be run locally on PC containing SEV files!');
end
% SourceDir   = ['\\RS4-11038\data\',SubjectID];                          % Source directory
% DestDir     = ['R:\murphya\Physio\SEV_files\', SubjectID, filesep];  	% Destination directory
SourceDir   = fullfile(TankRoot, Subject);                           	% Source is setup 3's TDT RS4 streamer
DestDir     = fullfile('H:\Rawdata\', Subject);                         % Destination is Aidan's Helix account

CopyMode    = 'f';                                                      % Force copy regardless of write permissions!?
OverwriteExisting = 0;                                                  % Overwrite destination if it already exists?
if ~exist(SourceDir, 'dir')
    error('Data source directory %s was not found!', SourceDir);
end

%=========== SELECT FOLDERS
AllFolders      = struct2cell(dir(SourceDir));
AllDates        = AllFolders(2,:);
AllFolders(2:end,:) = [];
AllFolders(find(~cellfun(@isempty, strfind(AllFolders,'.')))) = [];
[BlockIndx, Ok] = listdlg('ListString', AllFolders, 'SelectionMode','multiple','ListSize',[300, 300],'PromptString','Select sessions to transfer');
Sessions        = AllFolders(BlockIndx);

%=========== COPY SELECTED FOLDERS
h = waitbar(0,'Copying data...');
for f = 1:numel(Sessions)
    waitbar(f/numel(Sessions), h);
%     SessionDate = datestr(datenum(AllDates{BlockIndx(f)}),'yyyymmdd');
    SessionDate     = Sessions{f}(1:8);
    FullSourceDir   = fullfile(SourceDir, Sessions{f});
    FullDestDir     = fullfile(DestDir, SessionDate, Sessions{f});
    fprintf('Coping %s to %s...\n', FullSourceDir, FullDestDir);
    if ~exist(fullfile(DestDir, SessionDate), 'dir')
        [success, msg, msgID] = mkdir(DestDir, SessionDate);
    end
    if ~exist(FullDestDir, 'dir')
        [success, msg, msgID] = mkdir(fullfile(DestDir, SessionDate), Sessions{f});
    else
        fprintf('WARNING: destination folder %s already exists!\n', FullDestDir);
        if OverwriteExisting == 0
            fprintf('Skipping copy.\n\n');
        end
    end
    [success, msg, msgID] = copyfile(FullSourceDir, FullDestDir, CopyMode);
    if success ~= 1
        error(msg);
    end
end
close(h);
