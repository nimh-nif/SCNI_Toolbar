clear, clc, close all

% signal parameters
fs = 44100;         % sampling frequency, Hz
T = 0.1;            % signal duration, s
N = round(fs*T);    % number of samples
t = (0:N-1)/fs;     % time vector

% signal generation
s = 10*sin(2*pi*1000*t + pi/6);

% noise generation
SNR = 20;                       % SNR, dB
Ps = 10*log10(std(s).^2);       % signal power, dBV^2
Pn = Ps - SNR;                  % noise power, dBV^2
Pn = 10^(Pn/10);                % noise power, V^2
sigma = sqrt(Pn);               % noise RMS, V

n = sigma*pinknoise(N);         % pink noise generation
x = s + n;                      % signal + noise mixture

% plot the signal
figure(1)
plot(t, x, 'r', 'LineWidth', 1.5)
grid on
xlim([0 max(t)])
set(gca, 'FontName', 'Times New Roman', 'FontSize', 14)
xlabel('Time, s')
ylabel('Amplitude')
title('Singal + Noise in the time domain')