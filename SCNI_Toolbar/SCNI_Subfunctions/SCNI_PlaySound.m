function [PDS,c,s] = SCNI_PlaySound(PDS, c, s)

%============================ SCNI_PlaySound.m =============================
% Play a pre-loaded audio clip to the subject. This can be used to alert 
% the animal to the start of the next trial.

PsychPortAudio('Start', c.AudioError, 1);
