close all; clear all; clear classes; clear fun; clc;

addpath('/projects/SCNI/SCNI_Datapixx/SCNI_Subfunctions/SynapseAPI/Matlab')

syn = SynapseAPI('localhost');

% iMode getMode()
% sMode getModeStr()
% bSuccess setMode(iNewMode)
% bSuccess setModeStr(sNewMode)
if 0
syn.getMode()
result = syn.setMode(1)
pause(3)
syn.getMode()
result = syn.setMode(0)
syn.getMode()

syn.getModeStr()
result = syn.setModeStr('Preview')
pause(3)
syn.getModeStr()
result = syn.setModeStr('Idle')
syn.getModeStr()

end

if 0
syn.getKnownUsers()
syn.getKnownSubjects()
syn.getKnownExperiments()
syn.getKnownTanks()
syn.getKnownBlocks()
end

if 0
syn.getCurrentUser()
syn.getCurrentSubject()
syn.getCurrentExperiment()
syn.getCurrentTank()
syn.getCurrentBlock()
end

% sUsers getKnownUsers()
% bSuccess setCurrentUser(sUser)
% sUser getCurrentUser()
if 0
xxx = syn.getKnownUsers()
if numel(xxx) < 1
    error('no users found')
end
for i = 1:numel(xxx)
    ttt = xxx{i}
    result = syn.setCurrentUser(ttt, 'user3')  % does not work with password
    % task: return false if user Login : None?
    pause(3)
    syn.getCurrentUser()
    
end
end

% sExperiments getKnownExperiments()
% bSuccess setCurrentExperiment(sExperiment)
% sExperiment getCurrentExperiment()
if 0
xxx = syn.getKnownExperiments()
if numel(xxx) < 1
    error('no experiments found')
end
for i = 1:numel(xxx)
    ttt = xxx{i}
    result = syn.setCurrentExperiment(ttt)  % eventually causes segfault if pause(1)
    pause(.1)
    syn.getCurrentExperiment()
end
end

% sSubjects knownSubjects()
% bSuccess setCurrentSubject(sSubject)
% sSubject getCurrentSubject()
if 0
xxx = syn.getKnownSubjects()
if numel(xxx) < 1
    error('no subjects found')
end
for i = 1:numel(xxx)
    ttt = xxx{i}
    result = syn.setCurrentSubject(ttt)
    pause(1)
    syn.getCurrentSubject()
end
end

% sGizmos getGizmoNames()
% sParameters getParameterNames(sGizmo)
% dValue getParameterValue(sGizmo, sParameter)
% [fValues, iCount] getParameterValues(sGizmo, sParameter, iCount, iOffset=0)
% bSuccess setParameterValues(sGizmo, sParameter, fValues, iOffset=0)
% dValue getParameterSize(sGizmo, sParameter)
% tParameterInfo getParameterInfo(sGizmo, sParameter)
if 0
if syn.getMode() < 1
    syn.setMode(2)
end
gizmo_names = syn.getGizmoNames()
if numel(gizmo_names) < 1
    error('no gizmos found')
end
for i = 1:numel(gizmo_names)
    ggg = gizmo_names{i}
    ppp = syn.getParameterNames(ggg);
    if numel(ppp) < 1
        warning(['no parameters found for gizmo ' ggg])
    end
        
    for j = 1:numel(ppp)
        disp(ppp{j})
        if strcmp(ppp{j}, 'MyArray')
            result = syn.setParameterValues(ggg, ppp{j}, 1:50, 50)
            syn.getParameterValues(ggg, ppp{j}, 100)
        elseif strcmp(ppp{j}, 'Go')
            result = syn.setParameterValue(ggg, ppp{j}, 1)  % user gizmo switch doesn't get set in TagTest
            value = syn.getParameterValue(ggg, ppp{j});
            disp(['value = ' num2str(value)]);
        end
        
        sz = syn.getParameterSize(ggg, ppp{j});
        if sz == 1
            value = syn.getParameterValue(ggg, ppp{j});
            disp(['value = ' num2str(value)]);
        elseif sz > 1
            values = syn.getParameterValues(ggg, ppp{j})
        end
        info = syn.getParameterInfo(ggg, ppp{j})
    end
end
end

% bSuccess setParameterValue(sParameter, dValue)
if 0
syn.setMode(2)
vvv = syn.getParameterValue('Filt1', 'HighPassFreq')
result = syn.setParameterValue('Filt1', 'HighPassFreq', vvv + 1)
vvv = syn.getParameterValue('Filt1', 'HighPassFreq')
end

% tStatus getSystemStatus()
if 1
syn.setMode(3);
%pause(4)
syn.getSystemStatus 
end

if 0
result = syn.setMode(2)
pause(2)
result = syn.issueTrigger(1)
pause(1)
result = syn.issueTrigger(2)
pause(1)
result = syn.issueTrigger(3)
end

% bSuccess createSubject(sName, sDesc, sIcon)
if 0
result = syn.createSubject('TEST556')
result = syn.setCurrentSubject('TEST556')
syn.getCurrentSubject()
pause(3)

result = syn.createSubject('TEST667', 'mydesc', 'dolphin')
result = syn.setCurrentSubject('TEST667')
syn.getCurrentSubject()
end


% 	bSuccess appendExperimentMemo(sExperiment, sMemo)
% 	bSuccess appendSubjectMemo(sSubject, sMemo)
% 	bSuccess appendUserMemo(sUser, sMemo)
if 0
currentUser = syn.getCurrentUser
currentExperiment = syn.getCurrentExperiment
currentSubject = syn.getCurrentSubject
result = syn.appendExperimentMemo(currentExperiment, 'experiment test from Matlab 555')
result = syn.appendSubjectMemo(currentSubject, 'subject test from Matlab 555')
result = syn.appendUserMemo(currentUser, 'user test from Matlab 555')
end

% bSuccess setCurrentTank(sTank)
if 0
syn.setMode(0)
ct = syn.getCurrentTank()
next_tank = str2double(ct(end)) + 1;
if next_tank == 4
    next_tank = 1;
end
ct(end) = num2str(next_tank);
result = syn.setCurrentTank(ct)
result = syn.setMode(3)
end

% bSuccess setCurrentBlock(sBlock)
if 0
result = syn.setMode(0)
x = int32(rem(double(tic), 55555))
result = syn.setCurrentBlock(sprintf('test%d',x))
result = syn.setMode(3)
syn.getCurrentBlock()
end

% bSuccess = createTank(sPath)
% sTanks = knownTanks() % csv list of tank paths (or just names?)
% sBlocks = knownBlocks() % csv list of blocks in that tank
if 0
TANKPATH = 'F:\TDT\MYSYNTANK8';
tanks = syn.getKnownTanks()
blocks = syn.getKnownBlocks()
result = syn.createTank(TANKPATH)
if result == 1
    result = syn.setCurrentTank(TANKPATH)
    result = syn.setModeStr('Record')
    pause(3)
    result = syn.setModeStr('Idle')
end
end


% DEMOS
if 0
syn.setMode(3)
currentBlock = syn.getCurrentBlock
currentTank = syn.getCurrentTank
currentUser = syn.getCurrentUser
currentExperiment = syn.getCurrentExperiment
currentSubject = syn.getCurrentSubject
end

if 0
currentUser = syn.getCurrentUser
currentExperiment = syn.getCurrentExperiment
currentSubject = syn.getCurrentSubject
result = syn.appendExperimentMemo(currentExperiment, 'experiment test from Matlab 2')
result = syn.appendSubjectMemo(currentSubject, 'subject test from Matlab 2')
result = syn.appendUserMemo(currentUser, 'user test from Matlab 2')
end

if 0
syn.setMode(0)
syn.getPersistModes()
syn.getPersistMode()
syn.setPersistMode('Fresh')
syn.setModeStr('Preview')
end

if 0
syn.getSamplingRates()
end

if 0
syn.delete()
end


