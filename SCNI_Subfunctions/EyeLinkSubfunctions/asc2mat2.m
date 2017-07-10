function [E, EVT] = asc2mat2(ascfile)

%============================ asc2mat2.m ==================================
% Read EyeLink data from a .ASC file(s) containing both Samples and Events 
% (created from the raw .EDF file using EDFConverter.app from SR Research).
% Data are stored in the following structures, to retain compatability with
% previous code ('dat2mat.m' and 'evt2mat.m') from JN van der Geest.
% 
% INPUTS:
%   ascfile:    a cell array of full path .asc filenames
%
% OUTPUTS:
%   E:          structure containing timestamps, eye position and pupil size
%   EVT:        structure containing event timestamps and text codes
%
% REQUIREMENTS:
%   Tested with EDF Converter 3.1 Mac OS X Aug 2 2011 SR Research Ltd.
%   
%
% HISTORY:
%   04/09/2014 - Written by Aidan Murphy (murphyap@mail.nih.gov)
%==========================================================================

ascfile = '/Volumes/PROJECTS/murphya/MLP1_mix.asc';
ascEVTfile = '/Volumes/PROJECTS/murphya/MLP1_evt.asc';
ascDATfile = [];

fid=fopen(ascfile);
if fid==0
   error(sprintf('Failed to open ''%s''!',ascfile));
end
F = fread(fid);
InputText = textscan(fid,'%s','delimiter','\n');
close(fid);
F2 = char(F);



%% ========================= EXTRACT EVENTS ===============================
EVT.Nbytes = 82183;
EVT.file = ascfile;
EVT.Nlines = 2289;

HdrIndx = strfind(InputText{1},'Recorded by EyelinkToolbox');
HdrIndx = find(not(cellfun('isempty', HdrIndx)))+1;
EVT.header = InputText{1}(1:HdrIndx,:);
% EVT.msg: 
% EVT.sac: 
% EVT.fix: 
% EVT.blink:
% EVT.button: 
% EVT.block: 





%=============== Extract messages
MsgIndx = strfind(InputText{1},'MSG');
MsgRows = find(not(cellfun('isempty', MsgIndx)));
EVT.msg.n = numel(MsgRows);
for m = 1:numel(MsgRows)
    Row = char(InputText{1}(MsgRows(m),:));
    R = textscan(Row,'%s\t%d\t%s\n');
    EVT.msg.time(m) = R{2};
    EVT.msg.text{m} = R{3};
end

%=============== Extract saccades
SacIndx = strfind(InputText{1},'ESACC');
SacRows = find(not(cellfun('isempty', SacIndx)));
EVT.sac.n = numel(SacRows);




%=============== Extract fixations


%=============== Extract blinks






%%  ========================= EXTRACT SAMPLES =============================
StrFormat = '%.1f\t%.1f\t%.1f\t%.1f\t%.1f\t%.1f\t%.1f\t%s\n';
InputText{1}(HdrIndx:end,1)
for r = 1:numel(InputText{1})   
    if ~isletter(InputText{1}{r}(1))                            % If row begins with timestamp...
        Row{r} = textscan(char(InputText{1}(r,:)),StrFormat);   % Read row
        try
            Data(r,:) = cell2mat(Row{r}(1:7));               	% Convert row to matrix
        catch                                       
            for n = 1:7                                         % For each of 7 expected 
                Empty(n) = isempty(Row{r}{n});                  % Check which columns contain empty values
            end
            if any(Empty)                                       
                Data(r,find(~Empty)) = cell2mat(Row{r}(find(~Empty)));
            else
                error('Unknown error!');
            end
        end
    end
end
E.L.T = Data(:,1);
E.L.H = Data(:,2);
E.L.V = Data(:,3);
E.L.pup = Data(:,4);
E.R.T = Data(:,1);
E.R.H = Data(:,5);
E.R.V = Data(:,6);
E.R.pup = Data(:,7);
save(Matfile, 'E', 'EVT');
