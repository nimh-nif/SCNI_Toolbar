function [fixmat,imagelookup]=edf2mat(fname,subject);
%Reads in an .EDF or .ASC file and converts it to a matrix 
%
% expects an EDF (ending in 'edf') or an ASC (with or without respective
% extension). Takes an optional second argument subject number (which comes
% in handy if you merge many edfs into one matrix. 
%
%Input: a file name (either an .EDF file or an .ASC event file), and
%(optionally) a number, the subject is to be indexed by (NS). 
%
%Output: fixation matrix, imagelookup
% [AXP;AYP;CALIB;DRIFT;STTIME;SPTIME;NS;COND;FIXATIONNR;NI]
% (where DRIFT is the correction BEFORE TRIAL)
%
% Remember to set up the variable 'imagewildcards' in order to index your 
% images and you may want to define your conditions... E.g. make them 
% dependent on ntrial data{ntrial}.co=mod(ntrial,2);  % or whatever else 
% you like :)
%
% based on Selim's code
% created June-12,June-13 2006 by Benjamin. Last changed: June-14
%
% 
% Example: script get_fixmats
%
% subjects=dir('data/EDF/*.EDF');
% subjects={subjects.name};
% fixmat=[];
% for s=1:length(subjects)
%     fname=subjects{s}
%     fixmat=[fixmat,[edf2mat(['data/EDF/' fname(1:end-4)],s)]]; %searches
%     % for the asc's. Remove subscript to fname for working on the edf's
% end

% old: AXP=1;AYP=2;STARTTIME=4;STOPTIME=5;NS=6;COND=7;NI=8;
% new: 
% AXP=1;AYP=2;CALIB=3;DRIFT=4;STARTTIME=5;STOPTIME=6;NS=7;COND=8;FIXN=9;NI=8; % accomodate this to your specs! 


[pathstr,name,ext] = fileparts(fname);
if all(strncmpi(ext,'.EDF',4)) 
   % data file: not necessary as only fixations are read and no raw data
    %eval(['!edf2asc  -nflags -s -miss 999999 ' fname ' ' fname(1:end-4) '_data'  ]);%transfer to asci file     
    %events only file: 
   eval(['!edf2asc  -nflags -e -miss 999999 ' fname ' ' fname(1:end-4) '_events']);%transfer to asci file
end

fname=fullfile(pathstr,name);
if ~exist([fname '_events.asc'],'file') error(['file ' fname '_events.asc does not exist']);return;end
    
if nargin==1 subject=1;end % Subject is optional parameter. Default is 1. 

EyeList = ['l','r'];

% calibration errors and drift correction for right and left eye, resp.
[s,a]=system(['grep "!CAL VALIDATION" ' fname '_events.asc | awk ''{ print $2,$7,$10}'' | sed -e s/LEFT/1/  -e s/RIGHT/2/ -e s/[[:blank:]][[:blank:]]*/","/g' ]);
[t,eyes,errors]=strread(a,'%u %u %f','delimiter',',');
c.tl=t(find(eyes==1));
c.l=errors(find(eyes==1));
c.tr=t(find(eyes==2));
c.r=errors(find(eyes==2));

[s,a]=system(['grep "DRIFTCORRECT" ' fname '_events.asc | grep OFFSET | awk ''{ print $2,$5,$9}'' | sed -e s/LEFT/1/  -e s/RIGHT/2/  -e s/[[:blank:]][[:blank:]]*/","/g'  ]);
[t,eyes,errors]=strread(a,'%u %u %f','delimiter',',');
d.t.l=t(find(eyes==1));
d.l=errors(find(eyes==1));
d.t.r=t(find(eyes==2));
d.r=errors(find(eyes==2));

[s,right_eye]=system(['grep "EFIX " ' fname '_events.asc  | awk ''{ print $2, $3, $4, $6, $7 }'' | sed -e s/R/2/ -e s/L/1/ -e s/[[:blank:]][[:blank:]]*/","/g | sed s/$/","/']);
[eyes,starttimes,stoptimes,xs,ys]=strread(right_eye,'%u %u %f %f %f','delimiter',',');
starttime.l=starttimes(find(eyes==1));starttime.r=starttimes(find(eyes==2));
stoptime.l=stoptimes(find(eyes==1));stoptime.r=stoptimes(find(eyes==2));
x.l=xs(find(eyes==1));x.r=xs(find(eyes==2));
y.l=ys(find(eyes==1));y.r=ys(find(eyes==2));


[s,offsets]=system(['grep SYNCTIME ' fname '_events.asc | awk ''{ print $2 }''']);
offsets=strread(offsets);

[s,files]=system(['grep FILL ' fname '_events.asc | awk ''{ print $6 }''']);
files=strread(files,'%s');
global imagelookup;
imagelookup=sort(files);  % sorts the used files by ASCII order (as produced by 'dir' command). 
% This can be used as a lookup table for indexing (if all the files were
% used!). Otherwise use the following: 
%imagewildcard='images/*.bmp';  % change this! 
%imagelookup=dir(imagewildcard);
%imagelookup={imagelookup.name};


id.l=zeros(size(d.t.l));id.r=zeros(size(d.t.r));
ic.l=zeros(size(c.tl));ic.r=zeros(size(c.tr));  % index for calibrations

fixmat=[];

[s,errors]=system(['grep "TRIAL ERROR" ' fname '_events.asc | awk ''{ print $2 }''']);
errors=strread(errors,'%u');
if length(errors)>0     
    display([ fname '. ' mat2str(length(errors)) ' error(s) in the experiment!']);
    [s,errorfiles]=system(['grep "FILL" ' fname '_events.asc | awk ''{ print $2 }''']);
    errorfiles=strread(errorfiles,'%u');
    for i=1:length(errors)
        display([files{find(errorfiles-errors(i)>0,1)-1} ' was not shown!']);
        files(find(errorfiles-errors(i)>0,1)-1)=[];  % don't process the file
    end
end

[s,timeout]=system(['grep "TIMEOUT" ' fname '_events.asc | awk ''{ print $2 }''']);
timeout=strread(timeout,'%u');  % fixations that are timed out are kicked out

for i=1:min(length(id.l),length(id.r))
    id.l(i)=find(offsets>d.t.l(i),1); 
    id.r(i)=find(offsets>d.t.r(i),1); 
end    
eye=EyeList(1+length(id.r)>length(id.l));
for i=1:length(id.(eye))
    id.(eye)(i)=find(offsets>d.t.(eye)(i),1); 
end

for i=1:length(ic.l)
    ic.l(i)=find(offsets>c.tl(i),1);
end
for i=1:length(ic.r)        
    ic.r(i)=find(offsets>c.tr(i),1);     % ... and calibrations
end

if length(offsets)>length(timeout)  % if there was an error (some errors) at the end: 
    % set the last timeout values according to the timeout-offsets
    % difference. This assumes a constant presentation time. 
    timeout(length(timeout):length(offsets))=offsets(length(timeout):length(offsets))+timeout(1)-offsets(1);
end

for i=1:length(files)  
    index.l=(find(starttime.l>offsets(i)&starttime.l<timeout(i)));    
    index.r=(find(starttime.r>offsets(i)&starttime.r<timeout(i)));        
    if length(index.l)>0 &  length(index.r)>0   % if there are fixations for both eyes
        eye=EyeList(1+(c.r(find(c.tr<offsets(1),1,'last'))<c.l(find(c.tl<offsets(1),1,'last'))));  % choose the better eye!
    elseif length(index.l)>0      % otherwise, take what there is
        eye='l';
    elseif length(index.r)>0       
        eye='r';
    else display([fname '. No traces found for trial ' mat2str(i)]);continue;       
    end         
    calibration=c.(eye)(find(i>=ic.(eye),1,'last'));  % take the last calibration value before the trial    
    drift=d.(eye)(find(id.(eye)==i,1,'first')); % take the first drift correction after the trial
    %if length(drifts)>0 
    %    drift(i)=drifts(end);
    %else drift(i)=NaN;
    %end
    
    image=inimagelookup(files{i}); % get image index    
    condition=1; % change this!  i corresponds to number of trial    
    fixmat=[fixmat,[round(x.(eye)(index.(eye)))';...
        round(y.(eye)(index.(eye)))';...
        ones(1,length(index.(eye)))*calibration;...
        ones(1,length(index.(eye)))*drift;...
        (starttime.(eye)(index.(eye))-offsets(i))';...
        (stoptime.(eye)(index.(eye))-offsets(i))';...
        ones(1,length(index.(eye)))*subject;...
        ones(1,length(index.(eye)))*condition;... 
        1:length(index.(eye));... 
        ones(1,length(index.(eye)))*image]];            
%    if length(find(fixmat(4,:)>8000)) keyboard;end
end


function pos=inimagelookup(W)
% returns index for a picture
global imagelookup
pos=-1;
%[pathstr,name,ext] = fileparts(W); % if you use the dir command to
%generate the lookup table you need to strip off the path
%W=[name ext];
for i=1:length(imagelookup)
    if strcmp(imagelookup{i},W)
        pos=i;
        break;
    end
end
