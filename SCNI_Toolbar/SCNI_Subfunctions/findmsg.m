function ind = findmsg(MSG, PAT)

% FINDMSG - finds the indices and times of specific messages
%
% I = FINDMSG(MSG, PAT) finds the occurences of the pattern PAT in the
% EyeLink messages (which is the MSG.TEXT field obtained with EVT2MAT).
% FINDMSG is case-insensitive.
%
% See REGEXP (help REGEXP) for options to use in PAT
%
% Examples:
% findmsg(MSG, '^trialid')
%    returns the indices of messages starting with the string 'trialid'
% findmsg(MSG, '[aeoui]+t')
%    returns the indices of messaged in which a 't' is preceeded by a vowel
%
% See also EVT2MAT, REGEXP

% (c) 2004 JN van der Geest, Dept of Neuroscience, Erasmus MC, Rotterdam
% Contact through http:\\www.neuro.nl

x = regexpi(MSG,PAT) ;
ind = find(~cellfun('isempty',x)) ;