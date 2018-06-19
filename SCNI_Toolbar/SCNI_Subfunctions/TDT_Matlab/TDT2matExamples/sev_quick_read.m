function data = sev_quick_read(name, fmt, varargin)
%SEV_QUICK_READ  bare SEV file extraction.
%   data = sev_quick_read(NAME, FMT) where NAME and FMT are strings. If 
%   NAME is a directory, retrieves all sev data from directory NAME in 
%   format FMT. Each SEV file array is returned in one cell of the 
%   returned data. If NAME is an SEV file, returns a single row array
%   containing just the data from that file.
%   FMT is typically 'single' or 'int16'
%   optional third argument VERBOSE enables debugging output

if numel(varargin) == 0
    verbose = 0;
else
    verbose = varargin{1};
end
ALLOWED_FORMATS = {'single','int32','int16','int8','double','int64'};

if ~any(cellfun(@(x)strcmp(x,fmt), ALLOWED_FORMATS))
    error('allowed formats are ''single'',''int32'',''int16'',''int8'',''double'',''int64''')
end

isSEV = strcmp(name(end-3:end),'.sev');
fmt = ['*' fmt];

if isSEV
    data = read_one_sev(name, fmt, verbose);
else
    name = [name '\\'];
    file_list = dir([name '*.sev']);
    if length(file_list) < 1
        warning(['no sev files found in ' name])
        return
    end
    
    %if it's a dir
    data = cell(1,length(file_list));
    
    for i = 1:length(file_list)
        path = [name file_list(i).name];
        data{i} = read_one_sev(path, fmt, verbose);
    end
end
end

function data = read_one_sev(path, fmt, verbose)

% open file
fid = fopen(path, 'rb');

fread(fid, 40, 'char'); % ignore the header

data = fread(fid, inf, fmt); % read the streaming data

mx = max(data);
mn = min(data);
if verbose
    fprintf('file: %s\nmax value: %f\nmin value: %f\n', path, mx, mn);
end

fclose(fid); % close the file
end