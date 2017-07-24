function data = TDTfilter(data, epoc, varargin)
%TDTFILTER  TDT tank data filter.
%   data = TDTfilter(DATA, EPOC, 'parameter', value, ...), where DATA is
%   the output of TDT2mat, EPOC is the name of the epoc to filter on,
%   and parameter value pairs define the filtering conditions
%
%   also create data.filter, a string that describes the filter applied
%
%   'parameter', value pairs
%      'VALUES', specify array of allowed values
%         ex: tempdata = TDTfilter(data, 'Freq', 'VALUES', [9000, 10000]);
%               > retrieves data when Freq = 9000 or Freq = 10000
%      'MODIFIERS', specify array of allowed modifier values.  For example,
%             only allow time ranges when allowed modifier occurred
%             sometime during that event, e.g. a correct animal response.
%         ex: tempdata = TDTfilter(data, 'Resp', 'MODIFIERS', [1]);
%               > retrieves data when Resp = 1 sometime during the allowed
%               time range.
%      'TIME', specify onset/offset pairs relative to EPOC onsets.
%         ex: tempdata = TDTfilter(data, 'Freq', 'TIME', [-0.1, 0.5]);
%               > retrieves data from 0.1 seconds before Freq onset to 0.4
%                 seconds after Freq onset. Negative time ranges are
%                 discarded.
%      'TIMEREF', all timestamps relative to EPOC onsets
%         ex: tempdata = TDTfilter(data, 'Freq', 'TIMEREF', 1);
%               > sets snip timestamps relative to Freq onset
%      'KEEPDATA', keep the original stream data array and add a new 
%              cell array called 'filtered' that holds the data from each
%              valid time range. Defaults to true
%
%  IMPORTANT! Use a TIME filter only after all VALUE filters have been set

% defaults
VALUES	  = [];
MODIFIERS = [];
TIME      = [];
TIMEREF   = 0;
KEEPDATA  = 1;

filter_string = '';

% parse varargin
for i = 1:2:length(varargin)
    eval([upper(varargin{i}) '=varargin{i+1};']);
end

if isfield(data, 'time_ranges')
    time_ranges = data.time_ranges;
else
    time_ranges = [0;1e6];
end

if isempty(data.epocs)
    error('no epocs found');
end

fff = fieldnames(data.epocs);
match = '';
all_names = {};
for i = 1:numel(fff)
    all_names{i} = data.epocs.(fff{i}).name;
    if strcmp(data.epocs.(fff{i}).name, epoc)
        match = fff{i};
    end
end

if ~isfield(data.epocs, match)
    error([epoc ' is not a valid epoc event, valid events are: ' strjoin(all_names', ', ')])
end

d = data.epocs.(match);

% VALUE FILTER, only use time ranges where epoc value is in filter array
if ~isempty(VALUES)
    
    % find valid time ranges
    valid = ismember(d.data,VALUES);
    time_ranges = [d.onset(valid)';d.offset(valid)'];
    
    % create filter string
    filter_string = sprintf('%s: VALUE in [', epoc);
    for i = 1:length(VALUES)
        filter_string = strcat(filter_string, sprintf('%.1f,', VALUES(i)));
    end
    filter_string(end:end+1) = '];';
    
    % AND time_range with existing time ranges
    if isfield(data, 'time_ranges')
        time_ranges = timerange2(time_ranges, data.time_ranges, 'AND');
    end
end

% MODIFIERS FILTER, only use time ranges where modifier epoc value is in array
if ~isempty(MODIFIERS)
    
    if ~isfield(data, 'time_ranges')
        warning('no valid time ranges to modify');
        return
    end
    
    time_ranges = data.time_ranges;
    
    % only look at epocs in our modifier set
    d.onset = d.onset(ismember(d.data,MODIFIERS));
    
    % loop through all current time ranges
    keep = zeros(size(time_ranges,2));
    for i = 1:size(time_ranges,2)
        % if valid modifier is in this time range, keep it
        for j = 1:length(d.onset)
            if d.onset(j) >= time_ranges(1,i) && d.onset(j) < time_ranges(2,i)
                keep(i) = 1;
            end
        end
    end
    
    % remove duplicates
    time_ranges = time_ranges(:, keep == 1);
    
    % create filter string
    filter_string = sprintf('%s: MODIFIER in [', epoc);
    for i = 1:length(MODIFIERS)
        filter_string = strcat(filter_string, sprintf('%.1f,', MODIFIERS(i)));
    end
    filter_string(end:end+1) = '];';
end

t1 = 0;

if ~isempty(TIME)
    
    t1 = TIME(1);
    t2 = TIME(2);
    
    if ~isfield(data, 'time_ranges') || ~isfield(data, 'filter')
        % preallocate
        time_ranges = zeros(2, length(d.onset));
        for j = 1:length(d.onset)
            time_ranges(:, j) = [d.onset(j); d.offset(j)];
        end
    else
        time_ranges = data.time_ranges;
    end
    
    % find valid time ranges
    for j = 1:size(time_ranges,2)
        time_ranges(:, j) = [time_ranges(1,j)+t1; time_ranges(1,j)+t1+t2];
    end
    
    % throw away negative time ranges
    if all(~isnan(time_ranges))
        time_ranges = time_ranges(:,time_ranges(1,:)>0);
    end
    
    % create filter string
    filter_string = sprintf('TIME: %s [%.2f:%.2f];', epoc, t1, t2);
    data.time_ref = [t1, t2];
end

if TIMEREF
    filter_string = strcat(filter_string, sprintf('%s REF', epoc));
    if numel(TIMEREF) > 1
        t1 = TIMEREF(1);
    end
end

% set filter string
if isfield(data, 'filter')
    data.filter = strcat(data.filter, filter_string);
else
    data.filter = filter_string;
end

% FILTER ALL EXISTING DATA ON THESE TIME RANGES
% filter streams
if ~isempty(data.streams)
    n = fieldnames(data.streams);
    for i = 1:length(n)
        fs = data.streams.(n{i}).fs;
        filtered = [];
        max_ind = max(size(data.streams.(n{i}).data));
        good_index = 1;
        for j = 1:size(time_ranges,2)
            onset = round(time_ranges(1,j)*fs)+1;
            offset = round(time_ranges(2,j)*fs)+1;
            % throw it away if onset or offset extends beyond recording window
            if offset <= max_ind && offset > 0 && onset <= max_ind && onset > 0
                filtered{good_index} = data.streams.(n{i}).data(:,onset:offset);
                good_index = good_index + 1;
            end
        end
        if KEEPDATA
            data.streams.(n{i}).filtered = filtered;
        else
            data.streams.(n{i}).data = filtered;
            data.streams.(n{i}).filtered = [];
        end
    end
end

% filter snips
if ~isempty(data.snips)
    n = fieldnames(data.snips);
    warning_value = -1;
    for i = 1:length(n)
        ts = data.snips.(n{i}).ts;
        
        % preallocate
        keep = zeros(1, length(ts));
        diffs = zeros(1, length(ts)); % for relative timestamps
        keep_ind = 0;
        
        for j = 1:numel(ts)
            ts_ind = find(ts(j) > time_ranges(1,:) & ts(j) < time_ranges(2,:) == 1);
            if ts_ind
                if numel(ts_ind) > 1
                    min_diff = min(abs(time_ranges(1, ts_ind(1))-time_ranges(1, ts_ind(2))), abs(time_ranges(2, ts_ind(1))-time_ranges(2, ts_ind(2))));
                    warning_value = min_diff;
                    %time_ranges(:, ts_ind(1))
                    %time_ranges(:, ts_ind(2))
                    continue
                    ts_ind = ts_ind(1);
                end
                keep_ind = keep_ind + 1;
                keep(keep_ind) = j;
                diffs(keep_ind) = ts(j) - time_ranges(1, ts_ind) + t1; % relative ts
            end
        end
        
        if warning_value > 0
            warning('time range overlap, consider a maximum time range of %.2fs', warning_value)
        end
        
        % truncate
        keep = keep(1:keep_ind)';
        diffs = diffs(1:keep_ind)';
        
        if ~isempty(data.snips.(n{i}).data)
            data.snips.(n{i}).data = data.snips.(n{i}).data(keep,:);
        end
        if TIMEREF
            data.snips.(n{i}).ts = diffs;
        else
            data.snips.(n{i}).ts = data.snips.(n{i}).ts(keep);
        end
        % if there are any extra fields, keep those
        fff = fieldnames(data.snips.(n{i}));
        for j = 1:numel(fff)
            if strcmp(fff{j}, 'ts') || strcmp(fff{j}, 'name') || strcmp(fff{j}, 'data')|| strcmp(fff{j}, 'sortname') || strcmp(fff{j}, 'fs')
                continue
            end
            data.snips.(n{i}).(fff{j}) = data.snips.(n{i}).(fff{j})(keep);
        end
    end
end

% filter scalars, include if timestamp falls in valid time range
if ~isempty(data.scalars)
    n = fieldnames(data.scalars);
    for i = 1:length(n)
        ts = data.scalars.(n{i}).ts;
        keep = get_valid_ind(ts, time_ranges);
        if keep
            % scalars can have multiple rows
            data.scalars.(n{i}).data = data.scalars.(n{i}).data(:,keep);
            data.scalars.(n{i}).ts = data.scalars.(n{i}).ts(keep);
        else
            data.scalars.(n{i}).data = [];
            data.scalars.(n{i}).ts = [];
        end
    end
end

% filter epocs, include if onset falls in valid time range
if ~isempty(data.epocs)
    n = fieldnames(data.epocs);
    for i = 1:length(n)
        ts = data.epocs.(n{i}).onset;
        keep = get_valid_ind(ts, time_ranges);
        if keep
            data.epocs.(n{i}).data = data.epocs.(n{i}).data(keep);
            data.epocs.(n{i}).onset = data.epocs.(n{i}).onset(keep);
            if isfield(data.epocs.(n{i}), 'offset')
                data.epocs.(n{i}).offset = data.epocs.(n{i}).offset(keep);
            end
        else
            data.epocs.(n{i}).data = [];
            data.epocs.(n{i}).onset = [];
            if isfield(data.epocs.(n{i}), 'offset')
                data.epocs.(n{i}).offset = [];
            end
        end
    end
end

data.time_ranges = time_ranges;
end

function valid_ranges = timerange2(tr1, tr2, logic)
% AND or OR two given time ranges

if size(tr1, 1) ~= 2 || size(tr2, 1) ~= 2
    error('invalid time range size');
end

logic = upper(logic);
bOR = strcmp(logic, 'OR');
bAND = strcmp(logic, 'AND');

% put all time ranges in order by start times first
all_ranges = sort([tr1 tr2], 2);
valid_ranges = zeros(size(all_ranges));
ind = 1;
last_ind = 1;
sz = size(all_ranges, 2);

% start with first time range, check the end timestamps
while last_ind < sz
    start1 = all_ranges(1, last_ind);
    stop1 = all_ranges(2, last_ind);
    valid_ranges(:, ind) = [start1;stop1];
    v = 0;
    for j = (1+last_ind):sz
        start2 = all_ranges(1, j);
        stop2 = all_ranges(2, j);
        % if 2nd time range starts somewhere in between first
        if start2 >= start1 && start2 < stop1
            if bOR
                % use the max end points
                valid_ranges(2, ind) = max(stop1, stop2);
            elseif bAND
                % use the min end points and shorter stopping point
                valid_ranges(1, ind) = start2;
                valid_ranges(2, ind) = min(stop1, stop2);
                v = 1;
            end
            last_ind = j+1;
            % if 2nd time range stops somewhere in between first
        elseif stop2 > start1 && stop2 <= stop1
            if bOR
                % use the min starting point
                valid_ranges(1, ind) = min(start1, start2);
            elseif bAND
                % use the max starting point and shorter stopping point
                valid_ranges(1, ind) = max(start1, start2);
                valid_ranges(2, ind) = stop2;
                v = 1;
            end
            last_ind = j+1;
        elseif start1 == start2 && stop1 == stop2 && bAND
            valid_ranges(1, ind) = start1;
            valid_ranges(2, ind) = stop1;
            v = 1;
            last_ind = j+1;
        elseif bOR
            last_ind = j;
            break;
        end
    end
    if bAND
        if v
            ind = ind + 1;
        else
            last_ind = last_ind + 1;
        end
    elseif bOR
        ind = ind + 1;
    end
end
valid_ranges = valid_ranges(:,1:ind-1);

end

function keep = get_valid_ind(ts, time_ranges)
    % preallocate
    keep = zeros(1, length(ts));
    keep_ind = 0;
    
    for j = 1:numel(ts)
        overlap = find(ts(j) >= time_ranges(1,:) & ts(j) < time_ranges(2,:));
        if any(overlap)
            keep_ind = keep_ind + 1;
            keep(keep_ind) = j;
        end
    end
    
    for j = 1:numel(ts)
        ts_ind = find(ts(j) >= time_ranges(1,:) & ts(j) < time_ranges(2,:) == 1);
        if ts_ind
            keep_ind = keep_ind + 1;
            keep(keep_ind) = j;
        end
    end
    
    % truncate
    keep = keep(1:keep_ind);
    
    %keep
    % 'stable' is a newer option that isn't supported in older versions of
    % Matlab (2007b)
    %keep = unique(keep, 'stable');
    [junk, index] = unique(keep, 'first');
    keep = keep(sort(index));
end