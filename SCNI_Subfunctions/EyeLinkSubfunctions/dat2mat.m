function EE = dat2mat(file, eye_used)

% DAT2MAT - reads eye link gaze data
%
% DAT2MAT(FILE) transforms the raw EDF formatted EyeLink data file FILE
% into a matlab readable MAT-file ([FILE 'DAT.mat']).
%
% DAT2MAT(FILE,A) uses the eye specified by A (0 for both eyes (default), 1
% for the left eye, 2 for the right eye.
%
% E = DAT2MAT(...) also returns a structure. E.L contains the data for the left
% eye and E.R containts the data for the right eye. These fields have
% subfields containing the the horizontal (H) and vertical (V) gaze position in pixels, 
% timestamp (T) and pupilsize (pup). For instance, E.R.T contains the
% timestamps in milliseconds of the data of the right eye.
%
% NB1 The eyelink parser executable (EDF2ASC.EXE) should be on the windows path
%
% NB2 If the datafile holds monocular data, and both eyes are requested, the fields for the
%    left and right eye (E.L and E.R) hold the same values
%
% See also EVT2MAT

% (c) 2004 JN van der Geest, Dept of Neuroscience, Erasmus MC, Rotterdam
% Contact through http:\\www.neuro.nl
%
% Tested for PC Windows 98 and Matlab 6.5. It should work on other
% (windows) platforms and other versions of matlab as well, perhaps with minor
% modifications.
%
% This code is provided as is. No warranty of any kind is given. It be used
% and modified, but please mention me as the original developer of the code.
%
% 04/09/2014 - Updated to deal with .asc input and use EDF Converter 3.1
% for OS X - murphyap@mail.nih.gov
%

RootDir = cd;
[EyeLinkDir,b,c] = fileparts(mfilename('fullpath'));
cd(EyeLinkDir);

if ~isempty(findstr(file,'.edf'))           % Is input file an .EDF?
    if ismac                                % On OS X...
       EDF2ASC = 'EDFConverter.app';        % Use EDF converter 3.1 .app
       [s,w] = unix(EDF2ASC) ;              
    else                                    
        EDF2ASC = 'edf2asc_win32' ;   	% EyeLink Parser File, change or add path if necessary
        [s,w] = system(EDF2ASC) ;           
    end
    if (s==0) || (strcmpi(w,'Bad command or file name')==1),
        error(['Cannot execute the EyeLink Parse Executable (' EDF2ASC '), it should be on the windows path']) ;
    end
end

% argument checking
error(nargchk(1,2,nargin)) ;

if nargin==1,
    eye_used = 0 ; 
end

if ~ischar(file),
    error('First argument should be a string with the EyeLink data file') ;
end

if ~isnumeric(eye_used) && max(size(eye_used)) ~= 1 && ~any(eye_used == [1 2 3]),
    error('Second argument should be a scalar specifying eye to use (0 for both eyes, 1 for left, 2 for right eye)') ;
end

file = lower(file) ;
i = max(findstr(file,'.edf')) ;
if ~isempty(i),    
    file = file(1:i-1) ;
end
edffile = [file '.edf'] ;
if ~exist(edffile,'file'),
    error(['The EyeLink file "' upper(edffile) '" does not exist !!!'])
    return
end

% command string for 
% commandstr = [EDF2ASC ' %s.edf %s.asc -%s -miss 9999 -sg -s'] ;
% commandstr = [EDF2ASC ' %s.edf %s.asc -%s -miss 9999 -sg -s -nflags'] ; % Updated to disable flags ("..." in .asc file) - APM

% Updated for edf2asc_win32.exe!!! APM, 04/09/2014
commandstr = [EDF2ASC ' [%s.asc -%s -miss 9999 -v] %s.edf'] ;


matfile = [file 'DAT.mat'] ;

disp(['EDF DATA -> MAT for file "' upper(edffile) '". Please be patient ...'])
if eye_used ~= 2,
    disp('  Left eye')
    [s, w] = dos(sprintf(commandstr,file,file,'l')) ;
    X = load([file '.asc']) ;
    X(X==9999) = NaN ;
    system(['del ' file '.asc']) ;
    E.L.T = X(:,1) ;
    E.L.H = X(:,2) ;
    E.L.V = X(:,3) ;
    E.L.pup = X(:,4) ;    
end

if eye_used~= 1,
    disp('  Right eye')
    [s, w] = dos(sprintf(commandstr,file,file,'r')) ;
    X = load([file '.asc']) ;
    X(X==9999) = NaN ;
    system(['del ' file '.asc']) ;
    E.R.T = X(:,1) ;
    E.R.H = X(:,2) ;
    E.R.V = X(:,3) ;
    E.R.pup = X(:,4) ;    
end

if nargout, 
    EE = E ;
end

try
    save(matfile,'E') ;
    disp(['Samples saved into ' matfile]);
catch
    warning('Could not save transformed file') ;
end
cd(RootDir);