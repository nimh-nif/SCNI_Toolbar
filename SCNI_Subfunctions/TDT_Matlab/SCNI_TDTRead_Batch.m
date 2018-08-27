%function tdtReadingBatch(Username)

%========================== SCNI_TDTRead_Batch.m ==========================
% This script allows the user to select batches of TDT files to convert to 
% .mat format, based on experiment type and session date, using a GUI interface.
% It calls TDT2mat.m and associated subfunctions that require ActxControl
% and therefore should be run locally from the Windows PC containing the TDT 
% data, or via NifSort1 after the TDT data has been transferred to
% Nifstorage.
%
% REVISIONS:
%   01/02/2014 - Written by APM
%   06/11/2015 - Updated to work in Octave
%   05/24/2018 - Updated to work for other lab members
%   30/07/2018 - Rewritten to use TDT2mat.m
%     ___  ______  __   __
%    /   ||  __  \|  \ |  \    APM SUBFUNCTIONS
%   / /| || |__/ /|   \|   \   Aidan P. Murphy - murphyap@nih.gov
%  / __  ||  ___/ | |\   |\ \  Section on Cognitive Neurophysiology and Imaging
% /_/  |_||_|     |_| \__| \_\ Laboratory of Neuropsychology, NIMH
%==========================================================================

%================== CHECK SYSTEM
Overwrite = 1;                                                            	% Overwrite previously converted data?
                   
if ~strcmp(computer('arch'), 'win64')                                       % Check if we're on 64-bit Windows
    error('TDT to .mat file conversion can only be performed on Windows OS!');
end
if ~exist('actxcontrol', 'file')                                    
    error('ActiveX control function is requried on Matlab path (not available on Octave)!');
end
try
  PCName = char(getHostName(java.net.InetAddress.getLocalHost()));        	% Which PC are we on?
catch
  PCName = 'vrec';
end
switch PCName
    case 'NIFSORT1'
        tankPathDefault  	= '\\nifstorage1.nimh.nih.gov\rawdata\';
        savePathDefault     = '\\nifstorage1.nimh.nih.gov\rawdata\';
    case {'SCNI-Red-Neuro','SCNI-Green-Neuro','SCNI-Blue-Neuro'}
        tankPathDefault    	= 'E:\TDT_Data\';                               % Local path on TDT PC that contains raw TDT files                                                
        savePathDefault     = 'R:\';
    otherwise
        error('Unknown PC ''%s''!', PCName);
end

%================== ASK USER TO SELECT DATA
Tanks = uipickfiles('filterSpec', tankPathDefault,'Prompt', 'Select TDT tank folder(s) to convert', 'Output', 'cell' );
for t = 1:numel(Tanks)
    SubTanks{t} = wildcardsearch(Tanks{t}, '*Tbk');
    for n = 1:numel(SubTanks{t})
        TankPaths{t,n} = fileparts(SubTanks{t}{n});
    end     
end
savePath = uigetdir(savePathDefault, 'Select directory to save converted tanks to');

                    
%================== PROCESS DATA
h           = waitbar(0);
NoTanks     = numel(find(~cellfun(@isempty, TankPaths)));
NoSessions  = numel(Tanks);
f = 1;
for S = 1:NoSessions
    for B = 1:numel(SubTanks{S})
        waitbar(f/NoTanks,h, sprintf('Processing block %d of %d ...', f, NoSessions*NoTanks));
        SkipBlock       = 0;

        [a BlockName]   = fileparts(TankPaths{S, B});
        [~,SessionName]	= fileparts(a);
        SavePathFull    = fullfile(savePath, SessionName, BlockName);   

        if exist(SavePathFull,'dir')~=0
            if Overwrite == 0
                SkipBlock = 1;
                fprintf('Skipping block ''%s/%s'' (it already exists in %s!)... \n', SessionName, BlockName, savePath);
            elseif Overwrite == 1
                fprintf('Overwriting data in folder ''%s''...\n', SavePathFull);
            end
        end
        if SkipBlock == 0
            fprintf('\n****** Processing block %d of %d (''%s'')...\n', f, NoTanks, TankPaths{S,B});
            if exist(SavePathFull,'dir')==0
                mkdir(SavePathFull); 
            end
            %SCNI_TDTRead(TankPaths{S,B}, BlockName, SavePathFull);
            TDTdata    = TDT2mat_noStps(Tanks{S}, BlockName, 'VERBOSE', 1);
          	Filename   = fullfile(savePath, SessionName, sprintf('TDTconv_%s_%s.mat',SessionName,BlockName));
            save(Filename,'TDTdata','-v7.3');
        end
        f = f+1;
    end

end
delete(h);