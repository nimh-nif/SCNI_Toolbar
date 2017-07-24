close all; clear all; clc;

NOTE_TEXT = 'Subject 12345';
NOTE_EPOC = 'Tick';

% connect to Workbench and TTank servers
h = figure('Visible', 'off', 'HandleVisibility', 'off');
TT = actxcontrol('TTank.X', 'Parent', h);
TD = actxcontrol('TDevAcc.X', 'Parent', h);
TT.ConnectServer('Local','Me');
TD.ConnectServer('Local');

% enter record mode
TD.SetSysMode(3);
fprintf('Entering Record mode.');
while TD.GetSysMode ~= 3
    fprintf('.');
    pause(.1)
end

% open current tank/block
tank = TD.GetTankName()
TT.OpenTank(tank, 'R');
block = TT.GetHotBlock()
TT.SelectBlock(block);
TT.CreateEpocIndexing();

fprintf('\nWaiting for new data to reach server.');
x = TT.GetValidTimeRangesV();
while isnan(x)
     x = TT.GetValidTimeRangesV();
     fprintf('.');
     pause(1)
end

% write our note into the first epoc event
note_index = TT.AppendNote(NOTE_TEXT);
time_stamp = TT.SetNoteIndex(NOTE_EPOC, 0, note_index);
fprintf('\n\nAdded note "%s" to %s, %s at timestamp %.5f\n', NOTE_TEXT, block, NOTE_EPOC, time_stamp);

