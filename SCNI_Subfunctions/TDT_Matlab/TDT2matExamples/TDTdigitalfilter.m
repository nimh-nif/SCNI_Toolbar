function data = TDTdigitalfilter(data, varargin)
%TDTDIGITALFILTER  applies digital filter to streaming data
%   data = TDTdigitalfilter(DATA, FC, TYPE), where DATA is a stream
%   from the output of TDT2mat, FC is the cutoff frequency, TYPE is 
%   'high', 'low', 'EEG', 'LFP', 'SU'.  If FC is a two-element vector, 
%   a bandpass filter is applied by default; if TYPE is 'stop' a bandstop 
%   filter is applied.  If type is 'EEG', 'LFP' or 'SU', the bandpass 
%   filter in SpikePac's NeuroFilter macro is emulated.
%
%   data    contains stream data with digital filter applied
%
%   Example
%      data = TDT2mat('DEMOTANK2', 'Block-1');
%      data.streams.Wave = TDTdigitalfilter(data.streams.Wave, 10, 'high');

numvarargs = length(varargin);
if numvarargs > 2
    error('requires at most 2 optional inputs');
end

if nargin == 2
    Fc = varargin{1};
    if length(Fc) < 2
        warning('no filter type specified, high-pass assumed')
        type = 'high';
    else
        type = 'band';
    end
elseif nargin == 3
    Fc = varargin{1};
    type = lower(varargin{2});
    if length(Fc) > 1 
        if strcmp(type, 'stop') ~= 1 && strcmp(type, 'eeg') ~= 1 && ...
                strcmp(type, 'lfp') ~= 1 && strcmp(type, 'su') ~= 1
            warning('invalid type for two-dimensional vector, assuming ''stop''')
            type = 'stop';
        end
    else
        if strcmp(type, 'high') ~= 1 && strcmp(type, 'low') ~= 1
            warning('invalid type for one-dimensional vector, assuming ''high''')
            type = 'high';
        end
    end
end

if ~isfield(data, 'filter')
    data.filter = '';
end

if strcmp(type, 'lfp') || strcmp(type, 'eeg') || strcmp(type, 'su')
    %%% Emulate ButCoef LP in NeuroFilter
    data = TDTdigitalfilter(data, Fc(2), 'low');
    
    if strcmp(type, 'lfp') || strcmp(type, 'eeg')
        deviceSF = 24414.0625;
        fprintf('device sampling rate assumed to be %f\n', deviceSF);
    
        %%% Emulate MCSmooth HP (LFP and EEG only) in NeuroFilter
        Alpha = single(1-exp(-6.283 * Fc(1) / deviceSF));

        r2 = single(zeros(size(data.data)));
        for chan = 1:size(data.data,1)
            r2(chan,1) = data.data(chan,1);
            for i = 3:length(data.data)
                r2(chan,i) = Alpha*data.data(chan,i) + (1-Alpha)*r2(chan,i-1);
            end
            data.data(chan,:) = data.data(chan,:) - r2(chan,:);
        end
        
        % set filter string
        filter_string = sprintf('NFhigh %.1fHz;', Fc(1));
    else
        %%% Emulate ButCoef HP (SU only) in NeuroFilter
        data = TDTdigitalfilter(data, Fc(1), 'high');
        return
    end
else
    
    Fs = data.fs; %sampling rate
    N = 4; %filter order
    if strcmp(type, 'band')
        [B,A] = butter(N, Fc./(Fs/2));
    %elseif strcmp(type, 'stop')
    %    [Z, P, K] = butter(N, Fc./(Fs/2), type);
    %    [B,A] = zp2tf(Z,P,K);
    else
        [B,A] = butter(N, Fc./(Fs/2), type);
    end

    data.data = double(data.data);
    for channel = 1:size(data.data, 1)
        % use filtfilt to remove phase distortion
        data.data(channel, :) = filter(B,A,data.data(channel, :));
    end

    if length(Fc) == 1
        filter_string = sprintf('%s %.1fHz;', type, Fc);
    else
        filter_string = sprintf('%s %.1f-%.1fHz;', type, Fc);
    end
end

data.filter = strcat(data.filter, filter_string);
%fprintf('applied the filter ''%s'' to stream %s\n', filter_string, data.name);
%fprintf('aggregate filter ''%s''\n', data.filter);