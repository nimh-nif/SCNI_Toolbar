clear, clc, close all

% signal parameters
fs = 44100;         % sampling frequency, Hz
T = 60;             % signal duration, s
N = round(fs*T);    % number of samples

% noise generation
x = rednoise(N);    % PSD falls off by 3 dB/oct, i.e. 10 dB/dec

% calculate the noise PSD
winlen = 2*fs;
window = hanning(winlen, 'periodic');
noverlap = winlen/2;
nfft = winlen;
[Pxx, f] = pwelch(x, window, noverlap, nfft, fs, 'onesided');
PxxdB = 10*log10(Pxx);

% plot the noise PSD
figure(1)
semilogx(f, PxxdB, 'r', 'LineWidth', 1.5)
grid on
xlim([1 max(f)])
set(gca, 'FontName', 'Times New Roman', 'FontSize', 14)
xlabel('Frequency, Hz')
ylabel('Magnitude, dBV^{2}/Hz')
title('Power Spectral Density of the Noise Signal')