function EE = evt2mat(file, redo) ;

% EVT2MAT - reads eye link event data
%
% EVT2MAT(FILE) transforms the raw EDF formatted EyeLink data file FILE
% into a matlab readable MAT-file ([FILE 'EVT.mat']).
%
% E = EVT2MAT(...) also returns a structure with all the events. 
%
% NB1 The eyelink parser executable (EDF2ASC.EXE) should be on the windows path
%
% See also DAT2MAT

% (c) 2004 JN van der Geest, Dept of Neuroscience, Erasmus MC, Rotterdam
% Contact through http:\\www.neuro.nl
%
% Tested for PC Windows 98 and Matlab 6.5. It should work on other
% (windows) platforms and other versions of matlab as well, perhaps with minor
% modifications.
%
% This code is provided as is. No warranty of any kind is given. It be used
% and modified, but please mention me as the original developer of the code.

EDF2ASC = 'edf2asc_win32.exe' ; % EyeLink Parser File, change or add path if necessary

% argument checking
error(nargchk(1,2,nargin)) ;
if ~ischar(file),
    error('First argument should be a string with the EyeLink data file') ;
end

if nargin==1,
    redo = 0 ;
else
    redo = redo ~= 0 ;
end

file = lower(file) ;
i = max(findstr(file,'.edf')) ;
if ~isempty(i),    
    file = file(1:i-1) ;
end
edffile = [file '.edf'] ;
matfile = [file 'EVT.mat'] ;

if exist(matfile,'file')==2 && redo == 0,
    disp(['"' matfile '" already exists !']) ;
    disp('Loading from file ...') ;
    load(matfile,'EVT') ;
    EE = EVT ; 
    return    
end

if ~exist(edffile,'file'),
    error(['The EyeLink file "' upper(edffile) '" does not exist !!!'])
    return
end

% Check if EDF parser can be used.

[s,w] = system(EDF2ASC) ;
if (s==0) || (strcmpi(w,'Bad command or file name')==1),
    error(['Cannot execute the EyeLink Parse Executable (' EDF2ASC '), it should be on the windows path']) ;
end

commandstr = [EDF2ASC ' %s.edf %s.asc -miss 9999 -e'] ;

disp(['EDF EVENTS -> MAT for file "' upper(edffile) '". Please be patient ...'])
[s,w] = system(sprintf(commandstr,file,file)) ;

% I've added this line, because s comes out as 225 (AJL; 07/08/09)
s = 0;

if s == 0,
    EVT = ParseEvents([file '.asc']) ;
else
    error('Transformation was unsuccessfull') ;
end

try
    save(matfile,'EVT') ;
    disp(['Events saved into ' matfile]) ;
catch
    warning('Could not save transformed event file') ;
end

if nargout,
    EE = EVT ;
end

% ===============================================
% ===============================================

function D = ParseEvents (file);

% Parse the lines in the ascii file for relevant events

fid=fopen(file);
if fid==0,
   error(['Could not open ' file ' for input!'])
end
F=fread(fid);
fclose(fid);

D.Nbytes = length(F(:));
D.file = file ;
F=F';

q = F == 10 ; %  change CR/LF to CR. (DOS problem)
F = F(~q);
if sum(F==13) == length(F),
   error('Empty file');
end

% file should start and end without empty lines
while F(1)==13,
   F = F(2:end) ;
end
while F(end)==13,
   F = F(1:end-1) ;
end
F = [F 13];


q=F==13;
nl=find(q); % alle line breaks
D.Nlines = length(nl);

p0 = [1 nl(1:length(nl)-1)+1] ; % indices of line starts
p1 = nl -1 ; % indices of line ends
L1 = lower(char(F(p0))) ; % first character of the lines
L2 = lower(char(F(p0+1))); % second character of the line

% L1/L2 provide us with a selection mechanism for the type of event
% Parse each type of event separately

% HEADER LINES
% Format : *%s
q = (L1 == '*') ; % header lines starts
D.header = char(F(min(p0(q)):max(p1(q))));

% MESSAGES
% Format: msg %i %s
fprintf('[messages ...') ;
q = (L1 == 'm') & (L2 == 's') ; 
D.msg.n = sum(q) ;
if D.msg.n > 0,
    x0 = p0(q); 
    x1 = p1(q) ;
    D.msg.time = zeros(D.msg.n,1) ;
    D.msg.text = [];
    for i = 1:D.msg.n,
        s = char(F(x0(i):x1(i))) ;
        [t dum1 dum2, in] = sscanf(lower(s),'msg %f',1) ;
        s=s(min(in+1,length(s)):length(s));
        D.msg.text{i} = s ;
        D.msg.time(i) = t ;
    end
end
fprintf('%c%c%c(%i), ',8,8,8,D.msg.n) ;

% SACCADES
% Format: esacc %i ...
fprintf('saccades ...') ;
q = (L1 == 'e') & (L2 == 's') ; 
D.sac.n = sum(q) ;
if D.sac.n > 0,
    x0 = p0(q);
    x1 = p1(q) ;
    X = repmat(NaN, D.sac.n, 12) ;    
    for i = 1:D.sac.n,
        s = lower(char(F(x0(i):x1(i)))) ;
        [tt, tn] = sscanf(s,'esacc %c %f %f %f %f %f %f %f %f %f %f %f');
        X(i,1:tn) = tt(:)' ;
    end 
    X(X==9999) = NaN ;
    D.sac.eye = ones(D.sac.n,1) ; 
    D.sac.eye(X(:,1) == double('r')) == 2 ;
    D.sac.Tstart = X(:,2) ;
    D.sac.Tend = X(:,3) ;
    D.sac.dur = X(:,4) ;
    D.sac.Hstart = X(:,5) ;
    D.sac.Vstart = X(:,6) ;
    D.sac.Hend = X(:,7) ;
    D.sac.Vend = X(:,8) ;
    D.sac.amp = X(:,9) ;
    D.sac.pv = X(:,10) ;
    D.sac.xr = X(:,11) ;
    D.sac.yr = X(:,12) ;
end
fprintf('%c%c%c(%i), ',8,8,8,D.sac.n) ;
    
% FIXATIONS
% Format: efix %i ...
fprintf('fixations ...') ;
q = (L1 == 'e') & (L2 == 'f') ; 
D.fix.n = sum(q) ;
if D.fix.n > 0,
    x0 = p0(q);
    x1 = p1(q) ;
    X = repmat(NaN, D.fix.n, 9) ;    
    for i = 1:D.fix.n,
        s = lower(char(F(x0(i):x1(i)))) ;
        [tt, tn] = sscanf(s,'efix %c %f %f %f %f %f %f %f %f');
        X(i,1:tn) = tt(:)' ;
    end
    X(X==9999) = NaN ;
    D.fix.eye = ones(D.fix.n,1) ; 
    D.fix.eye(X(:,1) == double('r')) == 2 ;
    D.fix.Tstart = X(:,2) ;
    D.fix.Tend = X(:,3) ;
    D.fix.dur = X(:,4) ;
    D.fix.H = X(:,5) ;
    D.fix.V = X(:,6) ;
    D.fix.pup = X(:,7) ;
    D.fix.xr = X(:,8) ;
    D.fix.yr = X(:,9) ;
end
fprintf('%c%c%c(%i), ',8,8,8,D.fix.n) ;

% BLINKS
% Format: eblink %i ...
fprintf('blinks ...') ;
q = ((L1 == double('e')) & (L2 == double('b'))) ; 
D.blink.n = sum(q) ;
if D.blink.n>0,
    x0 = p0(q);
    x1 = p1(q) ;
    X = repmat(NaN, D.blink.n, 4) ;    
    for i = 1:D.blink.n,
        s = lower(char(F(x0(i):x1(i)))) ;
        [tt, tn] = sscanf(s,'eblink %c %f %f %f');
        X(i,1:tn) = tt(:)' ;
    end
    X(X==9999) = NaN ;
    D.blink.eye = ones(D.blink.n,1) ; 
    D.blink.eye(X(:,1) == double('r')) == 2 ;
    D.blink.Tstart = X(:,2) ;
    D.blink.Tend = X(:,3) ;
    D.blink.dur = X(:,4) ;
end
fprintf('%c%c%c(%i), ',8,8,8,D.blink.n) ;

% BUTTONS
% Format: button %f %f %f 
fprintf('blinks ...') ;
q = (L1 == 'b') & (L2 == 'u') ; 
D.button.n = sum(q) ;
if D.button.n > 0,
    x0 = p0(q);
    x1 = p1(q) ;
    X = repmat(NaN, D.button.n, 3) ;    
    for i = 1:D.button.n,
        s = lower(char(F(x0(i):x1(i)))) ;
        [tt, tn] = sscanf(s,'button %f %f %f');
        X(i,1:tn) = tt(:)' ;
    end  
    X(X==9999) = NaN ;
    D.button.T = X(:,1) ;
    D.button.number = X(:,2) ;
    D.button.press = X(:,3) ;
end
fprintf('%c%c%c(%i), ',8,8,8,D.button.n) ;

% RECORDING BLOCKS
% Format: start %f ...
% Format: end %f ...
fprintf('blocks ...') ;
q1 = (L1 == 's') & (L2 == 't') ; 
D.block.n = sum(q1) ;

q2 = (L1 == 'e') & (L2 == 'n') ; 
n2 = sum(q2) ;

if D.block.n > 0,
    x0 = p0(q1);
    x1 = p1(q1) ;    
    X = repmat(NaN, D.block.n,1) ;
    for i = 1:D.block.n,
        s = lower(char(F(x0(i):x1(i)))) ;
        X(i) = sscanf(s,'start %f');
    end    
    X(X==9999) = NaN ;
    D.block.Tstart = X ;
    x0 = p0(q2);
    x1 = p1(q2) ;    
    X = repmat(NaN, n2,1) ;
    for i = 1:n2,
        s = lower(char(F(x0(i):x1(i)))) ;
        X(i) = sscanf(s,'end %f');
    end 
    X(X==9999) = NaN ;
    D.block.Tend = X ;
    % Occasionally, the number of END events is one less than the number of
    % start events. Warn for this and fill in the time of the last event
    if n2 ~= D.block.n,
        warning (sprintf('The number of START (%i) and END(%i) events do not match'),n1,n2);
        if n2 == D.block.n-1,            
            [dum D.block.Tend(end+1)] = strread(F(p0(end):p1(end)),'%s %f',1) ;            
        end
    end
end
fprintf('%c%c%c(%i)]\n',8,8,8,D.block.n) ;

return

