function Out = ReadEyeLinkSampleData(varargin)
% READEYELINKSAMPLEDATA      reads and converts EDF files
% 
%   call: Out = ReadEyeLinkSampleData
%
%  Andreas Sprenger, Nov-28-2006
%
global DataPath     % path to edf2asc.exe program
global SamplingRate

if isempty(varargin)==1,
    [FName, Pfadname]=uigetfile({'*.edf; *.asc', 'EyeLink data(*.edf, *.asc)'; ...
        '*.*', 'All files(*.*)'}, 'File open');
else
    FName=varargin{1};
end
if isempty(FName)
    Out = [];
    uiwait(errordlg('No filename specified', 'Error'));
    return;
end
disp('Data conversion is processing ...');
if exist([DataPath, '\edf2asc.exe'], 'file') == 2,
    [s, ww]=dos([DataPath, '\edf2asc.exe -s -nmsg -y -miss 9999 ', FName]);
else
    [DName, PName] = uigetfile('*.exe', 'EDF2ASCII-Programm');
    if ischar(DName) == 1,
        [s, ww]=dos([PName, DName, ' -s -nmsg -y -miss 9999 ', FName]);
    else
        Out = [];
        uiwait(errordlg('No filename specified', 'Error'));
        return;
    end
end
disp('Ready!')

[P, D, E] = fileparts(FName);
Dateiname=[D, '.asc'];

FIn = fopen(Dateiname, 'r');
FOut = fopen('Temp.asc', 'w');

fseek(FIn, 0, 1);
DateiGroesse=ftell(FIn);
frewind(FIn); PosNr = 0;

tic;
disp('Preparing raw data...');

% Skip first line, time stamp is missing...
Zeile = fgets(FIn);
%Out = [];
h=waitbar(0,'Reading raw data...');
while feof(FIn)==0
    Zeile = fgets(FIn);
    fprintf(FOut, '%s', [Zeile(1 : length(Zeile)-3), Zeile(length(Zeile)-1:end)]); 
    %Out = [Out; MyStr2Num([Zeile(1 : length(Zeile)-3)])]; %, Zeile(length(Zeile)-1:end))]; 
    FPosition=ftell(FIn);
    if floor(FPosition*100/DateiGroesse)>PosNr,
        PosNr=PosNr+1;
        waitbar(PosNr/100, h)
    end
end

fclose(FIn); 
fclose(FOut); 
close(h)

Out = load('Temp.asc');
SamplingRate = 1000/median(diff(Out(1:10, 1)));
disp(['Loading raw data in ' num2str(toc) ' seconds'])
%delete('Temp.asc');       % deletion of files does not work on all systems
[P, D, E] = fileparts(Dateiname);
%delete([D, '.asc']);