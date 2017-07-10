function varargout = FilterOKN(data, t)
% [sac_neg, sac_pos, data_filt] = FilterOKN(data, t)
%========================== FilterOKN.m ===================================

thres = 0.3;            % Set acceleration threshold (pixels/s^2)
gaps = 50;              % Set gap size (samples)
 
data_filt = bibutter(data,1000,250);
data_vel = diff(data_filt);
data_acc = diff(bibutter(data_vel,1000,100));
 
a = find(data_acc <-thres);         % Find accelerations < threshold
b = find(diff(a)>gaps);             % Find gaps in the sub-threshold data > gaps
neg_acc = a(b+1);                   % Define negative acceleration data
 
for i = 1:length(neg_acc)           
    if i ==1
        pos_vel(i,1) = max(find(data_vel(1:neg_acc(i),1)<0));
    else
        c = max(find(data_vel(neg_acc(i-1):neg_acc(i),1)<0));
        pos_vel(i,1) = c+neg_acc(i-1);
    end
end

a = find(data_acc>thres);
b = find(diff(a)>gaps);
pos_acc = a(b+1);
 
if length(pos_acc)<=length(neg_acc)
    temp_pos = pos_acc;
    for i = 1:length(pos_acc)
        [d,e] = min(abs(pos_acc(i,1)-neg_acc));
        temp_neg(i,1) = neg_acc(e);
    end
else
    temp_neg = neg_acc;
    for i = 1:length(neg_acc)
        [d,e] = min(abs(neg_acc(i,1)-pos_acc));
        temp_pos(i,1) = pos_acc(e);
    end
end
 
f = temp_neg-temp_pos;
g = find(f<0);
sac_neg(:,1)=temp_neg(g);
g = find(f>0);
sac_pos(:,1)=temp_pos(g);
 
% plot(t,data,t(sac_neg),data(sac_neg),'o',t(sac_pos),data(sac_pos),'ro');
varargout{1}=sac_neg;
varargout{2}=sac_pos;
varargout{3}=data_filt;
end
 
function [varargout] = bibutter(varargin)

%========================== bibutter ======================================
% 
% Designs a lowpass digital Butterworth filter ('butter') and applies 
% zero-phase forward and reverse digital filtering ('filtfilt').  
%
%==========================================================================

signal = varargin{1};
fs=varargin{2};             % sampling frequency
if nargin >2
    fc=varargin{3};         % cut-off frequency of filter
else fc = 12;
end
[sa,sb]=size(signal);
n=2;%order of filter
 
%============== Apply linear interpolation for missing data (nans)
nan1 = find(isnan(signal(:,1))==1);
nan2 = find(isnan(signal(:,1))==0);
if isempty(nan1)==0
    nanstart = [nan1(1);nan1(find(diff(nan1)>1)+1)];
    nanend = [nan1(find(diff(nan1)>1));nan1(end)];
    
    if min(nan1)==1
        signal(1:min(nan2),1:sb)=signal(min(nan2),1:sb);    %fill with the first value if there is no data in the first frame  
    end
    if max(nan1)==length(signal)
        signal(max(nan2):end,1:sb)=signal(max(nan2),1:sb);  %fill with the first value if there is no data in the first frame
    end
    
    nan3 = find(isnan(signal(:,1))==1);
    if isempty(nan3)==0
        nanstart = [nan3(1);nan3(find(diff(nan3)>1)+1)];
        nanend = [nan3(find(diff(nan3)>1));nan3(end)];
        for i = 1:length(nanstart)
            slope = (signal(nanend(i)+1,1:sb)-signal(nanstart(i)-1,1:sb))./(nanend(i)-nanstart(i));
            if isinf(slope(1))==1
                signal(nanend(i),1:sb) = (signal(nanstart(i)-1,1:sb)+signal(nanend(i)+1,1:sb))/2;
            else
                for j = 1:nanend(i)-nanstart(i)+1
                    signal(nanstart(i)+j-1,1:sb) = signal(nanstart(i)+j-2,1:sb)+slope(1:sb);
                end
            end
        end
    end
end
 
%============ Filter the filled data
fnorm = fc/(fs/n);
[b,a] = butter (n, fnorm);
out = filtfilt(b, a, signal);
out(nan1,1:sb)=nan;
varargout = {out};
end
