function data = TDT2mat(tank, block, varargin)
%TDT2MAT  TDT tank data extraction.
%   data = TDT2mat(TANK, BLOCK), where TANK and BLOCK are strings, retrieve
%   all data from specified block in struct format.
%
%   data.epocs      contains all epoc store data (onsets, offsets, values)
%   data.snips      contains all snippet store data (timestamps, channels,
%                   and raw data)
%   data.streams    contains all continuous data (sampling rate and raw
%                   data)
%   data.info       contains additional information about the block
%
%   data = TDT2mat(TANK, BLOCK,'parameter',value,...)
%
%   'parameter', value pairs
%      'SERVER'     string, data tank server (default = 'Local')
%      'T1'         scalar, retrieve data starting at T1 (default = 0 for
%                       beginning of recording)
%      'T2'         scalar, retrieve data ending at T2 (default = 0 for end
%                       of recording)
%      'SORTNAME'   string, specify sort ID to use when extracting snippets
%      'VERBOSE'    boolean, set to false to disable console output
%      'TYPE'       array of scalars or cell array of strings, specifies 
%                       what type of data stores to retrieve from the tank
%                   1: all (default)
%                   2: epocs
%                   3: snips
%                   4: streams
%                   5: scalars
%                   TYPE can also be cell array of any combination of 
%                       'epocs', 'streams', 'scalars', 'snips', 'all'
%                   examples:
%                       data = TDT2mat('MyTank','Block-1','TYPE',[1 2]);
%                           > returns only epocs and snips
%                       data = TDT2mat('MyTank','Block-1','TYPE',{'epocs','snips'});
%                           > returns only epocs and snips
%      'RANGES'     array of valid time range column vectors
%      'NODATA'     boolean, only return timestamps, channels, and sort 
%                       codes for snippets, no waveform data (default = false)
%      'STORE'      string, specify a single stream store to extract
%      'CHANNEL'    integer, choose a single channel to extract from stream
%                       or snippet events (default = 0 for all channels).
%      'TTX'        COM.TTank_X object that is already connected to a tank/block
%

data = struct('epocs', [], 'snips', [], 'streams', [], 'scalars', []);

% defaults
T1       = 0;
T2       = 0;
RANGES   = [];
VERBOSE  = 1;
TYPE     = 1;
SORTNAME = 'TankSort';
SERVER   = 'Local';
NODATA   = false;
CHANNEL  = 0;
STORE    = '';
TTX      = [];

MAXEVENTS = 1e6;
MAXCHANNELS = 1024;

% parse varargin
for i = 1:2:length(varargin)
    eval([upper(varargin{i}) '=varargin{i+1};']);
end

if iscell(TYPE)
    types = [];
    for i = 1:numel(TYPE)
       if strcmpi(TYPE{i}, 'EPOCS')
           types = [types 2];
       elseif strcmpi(TYPE{i}, 'SNIPS')
           types = [types 3];
       elseif strcmpi(TYPE{i}, 'STREAMS')
           types = [types 4];
       elseif strcmpi(TYPE{i}, 'SCALARS')
           types = [types 5];
       elseif strcmpi(TYPE{i}, 'ALL')
           types = 1:5;
           break
       end
    end
    TYPE = types;
else
    if ~isnumeric(TYPE), error('TYPE must be a scalar or number vector'), end
    if TYPE == 1, TYPE = 1:5; end
end

ReadEventsOptions = 'ALL';
if NODATA, ReadEventsOptions = 'NODATA'; end
if ~isscalar(CHANNEL), error('CHANNEL must be a scalar'), end
if CHANNEL < 0, error('CHANNEL must be non-negative'), end
CHANNEL = int32(CHANNEL);

bUseOutsideTTX = ~isempty(TTX);

if ~bUseOutsideTTX
    % create TTankX object
    h = figure('Visible', 'off', 'HandleVisibility', 'off');
    TTX = actxcontrol('TTank.X', 'Parent', h);

    % connect to server
    if TTX.ConnectServer(SERVER, 'TDT2mat') ~= 1
        close(h)
        error(['Problem connecting to server: ' SERVER])
    end

    % put the slashes in the correct direction.
    tank = strrep(tank, '/', '\');
    if tank(end) == '\'
        tank(end) = [];
    end
    % open tank
    if TTX.OpenTank(tank, 'R') ~= 1
        TTX.ReleaseServer;
        close(h);
        error(['Problem opening tank: ' tank]);
    end

    % select block
    if TTX.SelectBlock(['~' block]) ~= 1
        block_name = TTX.QueryBlockName(0);
        block_ind = 1;
        while strcmp(block_name, '') == 0
            block_ind = block_ind+1;
            block_name = TTX.QueryBlockName(block_ind);
            if strcmp(block_name, block)
                error(['Block found, but problem selecting it: ' block]);
            end
        end
        error(['Block not found: ' block]);
    end
end

% set info fields
start = TTX.CurBlockStartTime;
stop = TTX.CurBlockStopTime;
total = stop-start;

data.info.tankpath = TTX.GetTankItem(tank, 'PT');
data.info.blockname = block;
data.info.date = TTX.FancyTime(start, 'Y-O-D');
data.info.starttime = TTX.FancyTime(start, 'H:M:S');
data.info.stoptime = TTX.FancyTime(stop, 'H:M:S');
if stop > 0
    data.info.duration = TTX.FancyTime(total, 'H:M:S');
end
data.info.streamchannel = CHANNEL;
data.info.snipchannel = CHANNEL;

%data.info.notes = {};

%ind = 1;
%note = TTX.GetNote(ind);
%while ~strcmp(note, '')
%    data.info.notes{ind} = note;
%    ind = ind + 1;
%    note = TTX.GetNote(ind);
%end

if VERBOSE
    fprintf('\nTank Name:\t%s\n', tank);
    fprintf('Tank Path:\t%s\n', data.info.tankpath);
    fprintf('Block Name:\t%s\n', data.info.blockname);
    fprintf('Start Date:\t%s\n', data.info.date);
    fprintf('Start Time:\t%s\n', data.info.starttime);
    if stop > 0
        fprintf('Stop Time:\t%s\n', data.info.stoptime);
        fprintf('Total Time:\t%s\n', data.info.duration);
    else
        fprintf('==Block currently recording==\n');
    end
end

% set global tank server defaults
TTX.SetGlobalV('WavesMemLimit',1e9);
TTX.SetGlobalV('MaxReturn',MAXEVENTS);
TTX.SetGlobalV('T1', T1);
TTX.SetGlobalV('T2', T2);

ranges_size = size(RANGES,2);

if ranges_size > 0
    data.time_ranges = RANGES;
end

% parse stores
lStores = TTX.GetEventCodes(0);
for i = 1:length(lStores)
    name = TTX.CodeToString(lStores(i));
    if VERBOSE, fprintf('\nStore Name:\t%s\n', name); end
    varname = name;
    if strcmp(varname,'Stp1'); continue; end;
    if strcmp(varname,'Stp2'); continue; end;
    if strcmp(varname,'Stp4'); continue; end;
    if strcmp(varname,'MRI1'); continue; end;
    for ii = 1:numel(varname)
        if ii == 1
            if isstrprop(varname(ii), 'digit')
                varname(ii) = 'x';
            end
        end
        if ~isstrprop(varname(ii), 'alphanum')
            varname(ii) = '_';
        end
    end
    %TODO: use this instead in 2014+
    %varname = matlab.lang.makeValidName(name);
    if ~isvarname(name) && VERBOSE
        warning('%s is not a valid Matlab variable name, changing to %s', name, varname);
    end
    
    if ~strcmp(name, 'xWav')
        TTX.GetCodeSpecs(lStores(i));
        type = TTX.EvTypeToString(TTX.EvType);
        % catch RS4 header (33073)
        if bitand(TTX.EvType, 33025) == 33025, type = 'Stream'; end
    else
        type = 'Stream';
    end     
    
    if VERBOSE, fprintf('EvType:\t\t%s\n', type); end
    
    switch type
        case 'Strobe+'
            if ~any(TYPE==2), continue; end
            if VERBOSE, fprintf('Data Size:\t%d\n',TTX.EvDataSize), end
            
            if ranges_size > 0
                for ff = 1:ranges_size
                    d = TTX.GetEpocsV(name, RANGES(1, ff), RANGES(2, ff), MAXEVENTS)';
                    if ~any(isnan(d))
                        data.epocs.(varname).data{ff} = d(:,1);
                        data.epocs.(varname).onset{ff} = d(:,2);
                        %data.epocs.(name).note{ff} = zeros(size(d(:,2))); % TODO: fix
                        if d(:,3) == zeros(size(d(:,3)))
                            d(:,3) = [d(2:end,2); inf];
                        end
                        data.epocs.(name).offset{ff} = d(:,3);
                    end
                end
                if ~isfield(data.epocs, varname), continue; end
                data.epocs.(varname).data = cat(1, data.epocs.(varname).data{:});
                data.epocs.(varname).onset = cat(1, data.epocs.(varname).onset{:});
                data.epocs.(varname).offset = cat(1, data.epocs.(varname).offset{:});
                %data.epocs.(name).note = zeros(size(data.epocs.(name).offset)); % TODO: fix
                
                % get rid of Infs in middle of data set
                ind = strfind(data.epocs.(varname).offset', Inf);
                ind = ind(ind < size(data.epocs.(varname).offset,1));
                data.epocs.(varname).offset(ind) = data.epocs.(varname).onset(min(size(data.epocs.(varname).onset,1),ind+1));
            else
                d = TTX.GetEpocsV(name, T1, T2, MAXEVENTS)';
                if numel(d) == 1  % store exists but there are no timestamps (nan?)
                    data.epocs.(varname).data = d;
                    data.epocs.(varname).onset = d;
                    data.epocs.(varname).offset = d;
                    %data.epocs.(name).note = d; % TODO: check
                else
                    data.epocs.(varname).data = d(:,1);
                    data.epocs.(varname).onset = d(:,2);
                    if d(:,3) == zeros(size(d(:,3)))
                        d(:,3) = [d(2:end,2); inf];
                    end
                    data.epocs.(varname).offset = d(:,3);
                    %data.epocs.(name).note = zeros(size(d(:,3))); % TODO: default
                end
            end
            data.epocs.(varname).name = name;
        case 'Scalar'
            if ~any(TYPE==5), continue; end
            if VERBOSE, fprintf('Data Size:\t%d\n',TTX.EvDataSize), end
            if ranges_size > 0
                for ff = 1:ranges_size
                    TTX.SetGlobalV('T1', RANGES(1, ff));
                    TTX.SetGlobalV('T2', RANGES(2, ff));
                    
                    N = TTX.ReadEventsSimple(name);
                    if N > 0
                        data.scalars.(varname).data{ff} = TTX.ParseEvV(0, N)'';
                        data.scalars.(varname).ts{ff} = TTX.ParseEvInfoV(0, N, 6)'';
                        channels = TTX.ParseEvInfoV(0, N, 4)'';
                        
                        % reorganize data array by channel
                        maxchannel = max(channels);
                        newdata = zeros(maxchannel, numel(data.scalars.(varname).data{ff})/maxchannel);
                        for xx = 1:maxchannel
                            arr = data.scalars.(varname).data{ff};
                            newdata(xx,:) = arr(channels == xx);
                        end
                        data.scalars.(varname).data{ff} = newdata;
                        
                        % decimate timestamps, only use channel 1
                        os = data.scalars.(varname).ts{ff};
                        data.scalars.(varname).ts{ff} = os(channels == 1);
                        clear newdata;
                    end
                end
                % reset T1, T2
                TTX.SetGlobalV('T1', T1);
                TTX.SetGlobalV('T2', T2);
                
                if ~isfield(data.scalars, varname), continue; end
                data.scalars.(varname).data = cat(2, data.scalars.(varname).data{:});
                data.scalars.(varname).ts = cat(2, data.scalars.(varname).ts{:});
            else
                N = TTX.ReadEventsSimple(name);
                if N > 0
                    data.scalars.(varname).data = TTX.ParseEvV(0, N)'';
                    data.scalars.(varname).ts = TTX.ParseEvInfoV(0, N, 6)'';
                    channels = TTX.ParseEvInfoV(0, N, 4)'';
                    
                    % organize data by channel
                    maxchannel = max(channels);
                    newdata = zeros(maxchannel, numel(data.scalars.(varname).data)/maxchannel);
                    for xx = 1:maxchannel
                        newdata(xx,:) = data.scalars.(varname).data(channels == xx);
                    end
                    data.scalars.(varname).data = newdata;
                    
                    % decimate timestamps, only use channel 1
                    data.scalars.(varname).ts = data.scalars.(varname).ts(channels == 1);
                    clear newdata;
                end
            end
            if N > 0, data.scalars.(varname).name = name; end
        case 'Stream'
            if ~any(TYPE==4), continue; end
            if ~strcmp(STORE, '') && ~strcmp(STORE, name), continue; end
            if strcmp(varname,'Audi'), continue; end
            if VERBOSE, fprintf('Samp Rate:\t%f\n',TTX.EvSampFreq), end
            
            % read some events to see how many channels there are
            N = TTX.ReadEventsV(10000, name, 0, 0, 0, 0, 'NODATA');
            if (N < 1), continue; end
            num_channels = max(TTX.ParseEvInfoV(0, N, 4));
            if VERBOSE, fprintf('Channels:\t%d\n', num_channels), end                

            % loop through ranges, if there are any
            TTX.SetGlobalV('Channel', CHANNEL);
            if ranges_size > 0
                for ff = 1:ranges_size
                    TTX.SetGlobalV('T1', RANGES(1, ff));
                    TTX.SetGlobalV('T2', RANGES(2, ff));
                    d = TTX.ReadWavesV(name)';
                    if numel(d) > 1
                        data.streams.(varname).filtered{ff} = d;
                    end
                end
                % reset when done
                TTX.SetGlobalV('T1', T1);
                TTX.SetGlobalV('T2', T2);
                TTX.SetGlobalV('Channel', 0);
            else
                data.streams.(varname).data = TTX.ReadWavesV(name)';
                nancheck = numel(data.streams.(varname).data) == 1;
                if nancheck
                    chunk_size = 2;  % try chunk size 1/2 length
                    if T2 > 0
                        approx_length = ceil((T2-T1) * TTX.EvSampFreq); % samples
                    else
                        approx_length = ceil(total * TTX.EvSampFreq); % samples
                    end
                    data.streams.(varname).data = zeros(num_channels,approx_length);
                end
                while nancheck
                    step_size = approx_length / TTX.EvSampFreq /chunk_size;
                    warning('ReadWavesV returned NaN for %s, attempting step size %.2f', name, step_size);
                    if step_size < 0.1, error('step size < .1 second, adjust WavesMemLimit'), end
                    ind = 1;
                    for c = 0:chunk_size-1
                        new_T1 = T1 + c*step_size;
                        new_T2 = T1 + (c+1)*step_size;
                        TTX.SetGlobalV('T1', new_T1);
                        TTX.SetGlobalV('T2', new_T2);
                        temp_data = TTX.ReadWavesV(name)';
                        nancheck = numel(temp_data) == 1;
                        if nancheck
                            break;
                        end
                        if CHANNEL ~= 0
                            data.streams.(varname).data(CHANNEL,ind:ind+size(temp_data,2)-1) = temp_data;
                        else
                            data.streams.(varname).data(:,ind:ind+size(temp_data,2)-1) = temp_data;
                        end
                        ind = ind + size(temp_data,2);
                    end
                    chunk_size = chunk_size * 2;
                end
                % reset when done
                TTX.SetGlobalV('T1', T1);
                TTX.SetGlobalV('T2', T2);
                TTX.SetGlobalV('Channel', 0);
            end
            data.streams.(varname).fs = TTX.EvSampFreq;
            data.streams.(varname).name = name;
        case 'Snip'
            if ~any(TYPE==3), continue; end
            if VERBOSE, fprintf('Samp Rate:\t%f\n',TTX.EvSampFreq), end
            if VERBOSE, fprintf('Data Size:\t%d\n',TTX.EvDataSize), end
            
            TTX.SetUseSortName(SORTNAME);
            
            if ranges_size > 0
                for ff = 1:ranges_size
                    N = TTX.ReadEventsV(MAXEVENTS, name, CHANNEL, 0, RANGES(1, ff), RANGES(2, ff), ReadEventsOptions);
                    if N > 0
                        if N == MAXEVENTS
                            warning('Max Total Events (%d) Reached during range extraction, contact TDT\n', MAXEVENTS);
                        else
                            if ~NODATA
                                data.snips.(varname).data{ff} = TTX.ParseEvV(0, N)';
                            else
                                data.snips.(varname).data{ff} = [];
                            end
                            data.snips.(varname).chan{ff} = TTX.ParseEvInfoV(0, N, 4)';
                            data.snips.(varname).sortcode{ff} = TTX.ParseEvInfoV(0, N, 5)';
                            data.snips.(varname).ts{ff} = TTX.ParseEvInfoV(0, N, 6)';
                        end
                    end
                end
                if ~isfield(data.snips, varname), continue; end
                if ~NODATA
                    data.snips.(varname).data = cat(1, data.snips.(varname).data{:});
                else
                    data.snips.(varname).data = [];
                end
                data.snips.(varname).chan = cat(1, data.snips.(varname).chan{:});
                data.snips.(varname).sortcode = cat(1, data.snips.(varname).sortcode{:});
                data.snips.(varname).ts = cat(1, data.snips.(varname).ts{:});
            else
                N = TTX.ReadEventsV(MAXEVENTS, name, CHANNEL, 0, T1, T2, ReadEventsOptions);
                if N > 0
                    if N == MAXEVENTS && CHANNEL == 0
                        if VERBOSE, fprintf('Max Total Events (%d) Reached. Looping through channels\n', MAXEVENTS), end
                        firstchan = 1;
                        skipct = 0;
                        for chan = 1:MAXCHANNELS
                            NCHAN = TTX.ReadEventsV(MAXEVENTS, name, chan, 0, T1, T2, ReadEventsOptions);
                            if firstchan
                                if VERBOSE, fprintf('Reading channel %d', chan), end
                            else
                                if VERBOSE, fprintf(' %d', chan), end
                            end
                            if NCHAN > 0
                                if NCHAN == MAXEVENTS
                                    warning(sprintf('Max Events (%d) reached on channel %d. Looping through time..\n', MAXEVENTS, chan));
                                    time_slices = 10;
                                    if T2 < 0.00001, T2 = total + 3; end
                                    dT = (T2-T1)/time_slices;
                                    currT1 = T1;
                                    currT2 = currT1+dT;
                                    for dt = 1:time_slices+1
                                        NTIME = TTX.ReadEventsV(MAXEVENTS, name, chan, 0, currT1, currT2, ReadEventsOptions);
                                        if NTIME > 0
                                            if NTIME == MAXEVENTS
                                                warning(sprintf('Max Events (%d) reached on channel %d time slice %d, contact TDT\n', MAXEVENTS, chan, dt));
                                            else
                                                if firstchan
                                                    if ~NODATA
                                                        data.snips.(varname).data = TTX.ParseEvV(0, NTIME)';
                                                    end
                                                    data.snips.(varname).chan = TTX.ParseEvInfoV(0, NTIME, 4)';
                                                    data.snips.(varname).sortcode = TTX.ParseEvInfoV(0, NTIME, 5)';
                                                    data.snips.(varname).ts = TTX.ParseEvInfoV(0, NTIME, 6)';
                                                    firstchan = 0;
                                                else
                                                    if ~NODATA
                                                        data.snips.(varname).data = cat(1, data.snips.(varname).data, TTX.ParseEvV(0, NTIME)');
                                                    end
                                                    data.snips.(varname).chan = cat(1, data.snips.(varname).chan, TTX.ParseEvInfoV(0, NTIME, 4)');
                                                    data.snips.(varname).sortcode = cat(1, data.snips.(varname).sortcode, TTX.ParseEvInfoV(0, NTIME, 5)');
                                                    data.snips.(varname).ts = cat(1, data.snips.(varname).ts, TTX.ParseEvInfoV(0, NTIME, 6)');
                                                end
                                            end
                                        end
                                        currT1 = currT2;
                                        currT2 = currT1+dT;
                                    end
                                else
                                    if firstchan
                                        if ~NODATA
                                            data.snips.(varname).data = TTX.ParseEvV(0, NCHAN)';
                                        end
                                        data.snips.(varname).chan = TTX.ParseEvInfoV(0, NCHAN, 4)';
                                        data.snips.(varname).sortcode = TTX.ParseEvInfoV(0, NCHAN, 5)';
                                        data.snips.(varname).ts = TTX.ParseEvInfoV(0, NCHAN, 6)';
                                        firstchan = 0;
                                    else
                                        if ~NODATA
                                            data.snips.(varname).data = cat(1,data.snips.(varname).data, TTX.ParseEvV(0, NCHAN)');
                                        end
                                        data.snips.(varname).chan = cat(1,data.snips.(varname).chan, TTX.ParseEvInfoV(0, NCHAN, 4)');
                                        data.snips.(varname).sortcode = cat(1,data.snips.(varname).sortcode, TTX.ParseEvInfoV(0, NCHAN, 5)');
                                        data.snips.(varname).ts = cat(1,data.snips.(varname).ts, TTX.ParseEvInfoV(0, NCHAN, 6)');
                                    end
                                    if mod(chan, 16) == 0 && VERBOSE
                                        fprintf('\n')
                                    end
                                end
                                % reset skip counter
                                skipct = 0;
                            else
                                skipct = skipct + 1;
                                if skipct == 10
                                    if VERBOSE, fprintf('\nNo events found on last 10 channels, exiting loop\n'), end
                                    break;
                                end
                            end
                        end
                        % sort the data based on timestamp
                        [data.snips.(varname).ts, ind] = sort(data.snips.(varname).ts);
                        data.snips.(varname).chan = data.snips.(varname).chan(ind);
                        data.snips.(varname).sortcode = data.snips.(varname).sortcode(ind);
                        if ~NODATA
                            data.snips.(varname).data = data.snips.(varname).data(ind,:);
                        else
                            data.snips.(varname).data = [];
                        end
                    elseif N == MAXEVENTS && CHANNEL > 0
                        warning('Max events reached on a single channel.  Contact TDT.')    
                    else
                        if ~NODATA
                            data.snips.(varname).data = TTX.ParseEvV(0, N)';
                        else
                            data.snips.(varname).data = [];
                        end
                        data.snips.(varname).chan = TTX.ParseEvInfoV(0, N, 4)';
                        data.snips.(varname).sortcode = TTX.ParseEvInfoV(0, N, 5)';
                        data.snips.(varname).ts = TTX.ParseEvInfoV(0, N, 6)';
                    end
                end
            end
            if N > 0
                data.snips.(varname).name = name;
                data.snips.(varname).sortname = SORTNAME;
            end
    end
end

% check for SEV files
% TODO: RANGES for SEV files?
if any(TYPE==4)
    
    blockpath = sprintf('%s%s\\%s\\', data.info.tankpath, tank, block);
    
    file_list = dir([blockpath '*.sev']);
    if length(file_list) < 3
        if VERBOSE, disp(['info: no sev files found in ' blockpath]), end
    else
        eventNames = SEV2mat(blockpath, 'JUSTNAMES', true, 'VERBOSE', false);
        for i = 1:length(eventNames)
            if strcmp(STORE, '') ~= 1 && strcmp(eventNames{i}, STORE) ~= 1
                continue
            end
            varname = eventNames{i};
            for ii = 1:numel(varname)
                if ii == 1
                    if isstrprop(varname(ii), 'digit')
                        varname(ii) = 'x';
                    end
                end
                if ~isstrprop(varname(ii), 'alphanum')
                    varname(ii) = '_';
                end
            end
            %varname = matlab.lang.makeValidName(eventNames{i});
            if ~isvarname(eventNames{i}) && VERBOSE
                warning('%s is not a valid Matlab variable name, changing to %s', eventNames{i}, varname);
            end
    
            if ~isfield(data.streams, varname)
                if VERBOSE
                    fprintf('SEVs found in %s.\nrunning SEV2mat to extract %s', ...
                        blockpath, eventNames{i})
                end
                sev_data = SEV2mat(blockpath, 'EVENTNAME', eventNames{i}, 'VERBOSE', VERBOSE);
                
                if isfield(data.streams, varname)
                    data.streams.(varname) = sev_data.eventNames{i};
                end
            end
        end
    end
end

if ~bUseOutsideTTX
    TTX.CloseTank;
    TTX.ReleaseServer;
    close(h);
end
