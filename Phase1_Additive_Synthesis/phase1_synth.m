%% ==================== PHASE 1: ADDITIVE SYNTHESIS ====================
% Signals & Systems Final Project - Phase 1
% Triangle-wave synthesis via truncated Fourier series
% =====================================================================
clear; clc; close all;

fs       = 44100;              % Sampling rate (Hz)
f0       = 440;                % Fundamental frequency, note A (Hz)
duration = 2;                  % Duration (s)
t        = 0:1/fs:duration-1/fs;

fprintf('[Phase 1] Starting additive synthesis...\n');

%% --- Preallocation ---
x_a = zeros(size(t));   % 1st harmonic only
x_b = zeros(size(t));   % first 5 odd harmonics
x_c = zeros(size(t));   % first 50 odd harmonics

coeff_base = 8 / (pi^2); % triangle-wave Fourier coefficient

%% --- Synthesis (odd harmonics only, 1/k^2 decay) ---
for k = 1                       % Signal A: harmonic 1
    x_a = x_a + coeff_base * ((-1)^((k-1)/2) / k^2) * sin(2*pi*k*f0*t);
end

for k = 1:2:9                   % Signal B: harmonics 1,3,5,7,9
    x_b = x_b + coeff_base * ((-1)^((k-1)/2) / k^2) * sin(2*pi*k*f0*t);
end

for k = 1:2:99                  % Signal C: first 50 odd harmonics
    x_c = x_c + coeff_base * ((-1)^((k-1)/2) / k^2) * sin(2*pi*k*f0*t);
end

% Normalize to [-1, 1]
x_a = x_a / max(abs(x_a));
x_b = x_b / max(abs(x_b));
x_c = x_c / max(abs(x_c));

fprintf('[Phase 1] Synthesis completed.\n');

%% --- Save audio outputs ---
audiowrite('x_a.wav', x_a, fs);
audiowrite('x_b.wav', x_b, fs);
audiowrite('x_c.wav', x_c, fs);
fprintf('[Phase 1] Audio files (x_a, x_b, x_c) saved.\n');

%% --- Time-domain plots (3 periods) ---
t_limit = 3 / f0;
idx     = t <= t_limit;

figTime = figure('Name', 'Phase 1 - Time Domain Analysis');
subplot(3,1,1);
plot(t(idx)*1e3, x_a(idx), 'LineWidth', 1.2);
title('Phase 1 - Signal A: 1 Harmonic (440 Hz)');
xlabel('Time (ms)'); ylabel('Amplitude'); grid on; axis tight;

subplot(3,1,2);
plot(t(idx)*1e3, x_b(idx), 'LineWidth', 1.2);
title('Phase 1 - Signal B: 5 Odd Harmonics (440..3960 Hz)');
xlabel('Time (ms)'); ylabel('Amplitude'); grid on; axis tight;

subplot(3,1,3);
plot(t(idx)*1e3, x_c(idx), 'LineWidth', 1.2);
title('Phase 1 - Signal C: 50 Odd Harmonics');
xlabel('Time (ms)'); ylabel('Amplitude'); grid on; axis tight;

saveas(figTime, 'Phase1_Time_Domain_Analysis.png');

%% --- Frequency spectrum (single-sided) ---
N  = length(x_c);
X  = abs(fft(x_c)) / N;      % magnitude, normalized
X  = X(1:floor(N/2)+1);      % single-sided
X(2:end-1) = 2*X(2:end-1);   % correct single-sided amplitude
f  = (0:floor(N/2)) * (fs/N);

figFreq = figure('Name', 'Phase 1 - Frequency Domain Analysis');
stem(f, X, 'Marker', 'none', 'LineWidth', 1.2);
title('Phase 1 - Frequency Spectrum of Signal C');
xlabel('Frequency (Hz)'); ylabel('|X(f)|  (normalized)');
xlim([0 5000]); grid on;

saveas(figFreq, 'Phase1_Frequency_Domain_Analysis.png');

fprintf('[Phase 1] Plots saved. Done.\n');
