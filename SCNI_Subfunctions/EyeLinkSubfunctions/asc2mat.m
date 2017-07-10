function [out] = asc2mat(ascfile)

%============================ asc2mat.m ===================================
% Read EyeLink data from a .ASC file(s) containing both Samples and Events 
% (created from the raw .EDF file using EDFConverter.app from SR Research).
% 
% INPUTS:
%   ascfile:    a cell array of full path .asc filenames
%
% REQUIREMENTS:
%   Tested with EDF Converter 3.1 Mac OS X Aug 2 2011 SR Research Ltd.
%   
%
% HISTORY:
%   04/09/2014 - Written by Aidan Murphy (murphyap@mail.nih.gov)
%==========================================================================




if nargin == 0
    [filename, pathname, filterindex] = uigetfile('*.asc', 'Pick .asc file(s)','multiselect','on');
    if isstr(filename)
        ascfile{1} = fullfile(pathname, filename);
    elseif iscell(filename)
        for i = 1:numel(filename)
            ascfile{i} = fullfile(pathname, filename{i});
        end
    end
end

StrFormat = '%.1f\t%.1f\t%.1f\t%.1f\t%.1f\t%.1f\t%.1f\t%s\n';
for i = 1:numel(ascfile)
    fprintf('Converting file ''%s'' (%d of %d)...\n', ascfile{i}, i, numel(ascfile));
    Indx = strfind(ascfile{i},'.asc');
    if isempty(Indx)
        error('Input file was not .asc format!');
    else
        Matfile = [ascfile{i}(1:Indx-1),'_DAT.mat'];
    end

    fid = fopen(ascfile{i},'r');
    InputText = textscan(fid,'%s','delimiter','\n');            
    fclose(fid);                                                
    Data = nan(numel(InputText{1}),7);                          % Preallocate r x 7 matrix of NaNs
    h = waitbar(0,sprintf('Processing asc. file %d of %d...',i,numel(ascfile)));
    for r = 1:numel(InputText{1})                             	% For each line...
        if mod(r, round(numel(InputText{1})/100/0.5))==0      	% Only update bar every 0.5%
            waitbar(r/numel(InputText{1}),h);                 	% Update wait bar
        end
        Row{r} = textscan(char(InputText{1}(r,:)),StrFormat);   % Read row
        try
            Data(r,:) = cell2mat(Row{r}(1:7));               	% Convert row to matrix
        catch                                       
            for n = 1:7
                Empty(n) = isempty(Row{r}{n});                  % Check which columns contain empty values
            end
            if any(Empty)                                       
                Data(r,find(~Empty)) = cell2mat(Row{r}(find(~Empty)));
            else
                error('Unknown error!');
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
    save(Matfile, 'E');
    close(h);
end