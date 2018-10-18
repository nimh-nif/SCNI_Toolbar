function [Params, Success, Fig] = SCNI_InitGUI(GUItag, Fieldname, ParamsFile, OpenGUI)

%=========================== SCNI_InitGUI.m ===============================
% This function loads the requested parameter file if available, and
% performs checks on GUI windows and filenames.
%
% INPUTS:   GUItag:     A string to tag the GUI window with
%           Fieldname:  Name of field to append/ update in the 'Params' structure
%           Params:     The currently loaded Params structure.
%           OpenGUI:    integer flag to indicate whether to open (1) or close
%                       (2) a Display Settings GUI window.
%
%==========================================================================

%============ Check inputs
Params.File   	= [];
Fig             = [];
Success         = 0;
GUIhandle       = getappdata(0,GUItag);                                  	% Check if GUI window is already open
if ishghandle(GUIhandle)                                                    % If so...
    figure(GUIhandle);                                                      % Bring current GUI window to front
    Success     = 2;
    return; 
end  
if ~exist('OpenGUI','var')                                                  % If input argument OpenGUI was not provided...
    OpenGUI = 1;                                                            % Default is to open a GUI window
end

%============ Check paths
Fullmfilename   = mfilename('fullpath');                                    % Get m-filename
[Path,~]       	= fileparts(Fullmfilename);                                 % Get path of m-file
SCNI_ToolbarDir = fileparts(Path);                                          % Get path of SCNI Toolbar
addpath(genpath(SCNI_ToolbarDir));                                          % Add SCNI Toolbar directories to Matlab path
Params.Dir      = fullfile(Path, '../SCNI_Parameters');                     % Get the directory containing parameter files


if ~exist('ParamsFile','var') || isempty(ParamsFile)                        % If a ParamsFile input was not provided, or is empty...
    [~, CompName] = system('hostname');                                     % Get the local computer's hostname
	CompName(regexp(CompName, '\s')) = [];                                  % Remove white space
    Params.File = fullfile(Params.Dir, sprintf('%s.mat', CompName));        % Construct expected parameters filename
    if ~exist(Params.File,'file')
        ParamsFileMatches = wildcardsearch(Params.Dir, sprintf('%s*.mat', CompName));
        if numel(ParamsFileMatches) > 1

        end
    end
    ParamsFile  = Params.File;
    
elseif exist('ParamsFile','var') & ~isempty(ParamsFile)                     % If 'ParamsFile' input was provided...
    if ischar(ParamsFile) && exist(ParamsFile,'file')                     	% If it is a file string... 
        Params = load(ParamsFile);                                          % Load it
    elseif isstruct(ParamsFile)                                             % If it's a structure...
        Params  = ParamsFile;                                               % Copy it
%         if isfield(Params, 'File') && exist(Params.File,'file')            	% If parameters file exists...
%             Params      = load(Params.File);                              	% Load the parameters and assign to structure 'Params'
%             Params.File = ParamsFile;
%         end
    end
    Success     = 1;
    if OpenGUI == 0                                               	% If OpenGUI flag was zero...
        return;                                                             
    end
end

%============ Get figure window parameters
Fig.ScreenSize   = get(0,'screensize');                                   	% Get size of display (pixels)
Fig.DisplayScale = Fig.ScreenSize(4)/1080;                                	% Calculate display scale relative to 1080p
if Fig.DisplayScale <= 1
    Fig.FontSize        = 10;                                               % Set standard font size
    Fig.TitleFontSize   = 16;                                               % Set panel title font size
elseif Fig.DisplayScale > 1
	Fig.FontSize        = 10+round((Fig.DisplayScale-1)*8);
    Fig.TitleFontSize   = 16+round((Fig.DisplayScale-1)*8);                 
end
Fig.MsgBoxRect = [Fig.ScreenSize([3,4]), round([400, 150]*Fig.DisplayScale)];

%============ Check that Params struct has requested field
if ~isempty(Fieldname)
    if ~exist(Params.File,'file') || ~isfield(Params, Fieldname)
        if ~exist(Params.File,'file')                                           
            WarningMsg = sprintf('The parameter file ''%s'' does not exist! Loading default parameters...', Params.File);
        elseif exist(Params.File,'file') && ~isfield(Params, Fieldname)
            WarningMsg = sprintf('The parameter file ''%s'' does not contain %s parameters. Loading default parameters...', Params.File, Fieldname);
            Success = -1;
        end
        h = msgbox(WarningMsg,'Parameters not detected!','non-modal');
        set(h, 'position', Fig.MsgBoxRect);
        ch = get(get(h, 'CurrentAxes'), 'Children');
        set(ch, 'FontSize', Fig.TitleFontSize);
    end
end
