close all; clear all; clc;

TANK = 'C:\TDT\OpenEx\Tanks\EXAMPLE'
BLOCK = 'Block-1'
NOTE_EPOC = 'StOn'

% connect to TTank server and open our tank/block
h = figure('Visible', 'off', 'HandleVisibility', 'off');
TT = actxcontrol('TTank.X', 'Parent', h);
TT.ConnectServer('Local','Me');
TT.OpenTank(TANK, 'R');
TT.SelectBlock(BLOCK);
TT.CreateEpocIndexing();

% read the note from the first epoc timestamp
N = TT.ReadEventsSimple(NOTE_EPOC);
note_index = TT.ParseEvInfoV(0, N, 9);

ind = find(note_index > 0)
for x = ind
    note_ts = TT.ParseEvInfoV(x, 1, 6)
    note = TT.GetNote(note_index(x))
end
