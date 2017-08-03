function [Params, Success] = SCNI_InitGUI(GUItag, Fieldname, ParamsFile, OpenGUI)

%=========================== SCNI_InitGUI.m ===============================
% This function loads the requested parameter file if available, and
% performs checks on GUI windows and filenames.

Params.File   	= [];
Success         = 0;
GUIhandle       = getappdata(0,GUItag);                                  	% Check if GUI window is already open
if ishghandle(GUIhandle)                                                    % If so...
    figure(GUIhandle);                                                      % Bring current GUI window to front
    Success     = 2;
    return; 
end                 	
Fullmfilename   = mfilename('fullpath');                                    % Get m-filename
[Path,~]       	= fileparts(Fullmfilename);                                 % Get path
Params.Dir      = fullfile(Path, '../SCNI_Parameters');                     % Get the directory containing parameter files
if ~exist('ParamsFile','var') || isempty(ParamsFile)                        % If a ParamsFile input was not provided, or is empty...
    [~, CompName] = system('hostname');                                     % Get the local computer's hostname
	CompName(regexp(CompName, '\s')) = [];                                  % Remove white space
    Params.File = fullfile(Params.Dir, sprintf('%s.mat', CompName));        % Construct expected parameters filename
    ParamsFile  = Params.File;
else
    Params.File = ParamsFile;                                               
end
if ~exist('OpenGUI','var')                                                  % If input argument OpenGUI was not provided...
    OpenGUI = 1;                                                            % Default is to open a GUI window
end
if exist(Params.File,'file')                                                % If parameters file exists...
    Params      = load(Params.File);                                        % Load the parameters and assign to structure 'Params'
    Params.File = ParamsFile;
    Success     = 1;
    if OpenGUI == 0                                                         % If OpenGUI flag was zero...
        return;                                                             
    end
end
if ~isempty(Fieldname)
    if ~exist(Params.File,'file') || ~isfield(Params, Fieldname)
        if ~exist(Params.File,'file')                                           
            WarningMsg = sprintf('The parameter file ''%s'' does not exist! Loading default parameters...', Params.File);
        elseif exist(Params.File,'file') && ~isfield(Params, Fieldname)
            WarningMsg = sprintf('The parameter file ''%s'' does not contain %s parameters. Loading default parameters...', Params.File, Fieldname);
            Success = -1;
        end
        msgbox(WarningMsg,'Parameters not detected!','non-modal');
    end
end
