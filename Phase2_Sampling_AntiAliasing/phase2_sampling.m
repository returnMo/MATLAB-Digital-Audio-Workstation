%% ========================================================================
%  Phase 2 - Sampling, Signal Degradation, and Anti-Aliasing Filter
%  Signals & Systems Project - DAW Engine
% =========================================================================
clear; clc; close all;

%% Parameters
fs1      = 44100;    % Original (reference) sampling frequency [Hz]
fs2      = 8000;     % Target channel sampling frequency [Hz]
duration = 10;       % Recording duration [s]  (per doc)
fc       = 3800;     % Anti-aliasing cutoff frequency [Hz] (per doc)
order    = 8;        % Butterworth filter order

%% 1. Record reference audio (acts as the continuous reference signal)
% Say: "سلام من مبینا پورافشار به شماره دانشجویی 40318893
%       دانشجوی رشته مهندسی کامپیوتر دانشگاه خواجه نصیر هستم"
fprintf('Recording %d s at %d Hz...\n', duration, fs1);
x_original = record_audio(fs1, duration);
x_original = x_original(:);                 % force column vector

%% 2. Downsampling to fs2 = 8000 Hz
% Non-integer ratio: fs1/fs2 = 5.5125 -> decimate by picking time indices
step = fs1 / fs2;
idx  = round(1:step:length(x_original));
idx(idx < 1) = 1;
idx(idx > length(x_original)) = length(x_original);

% --- Scenario A: NAIVE decimation (no filter) -> introduces aliasing ---
x_naive = x_original(idx);

% --- Scenario B: PROPER (anti-aliasing LPF, then decimate) ---
[b, a]        = butter(order, fc/(fs1/2), 'low');  % LPF @ 3800 Hz
x_filtered    = filtfilt(b, a, x_original);        % zero-phase filtering
x_antialiased = x_filtered(idx);

%% 3. Save WAV outputs (exact names required by doc)
audiowrite('x_original.wav',    x_original,    fs1);
audiowrite('x_naive.wav',       x_naive,       fs2);
audiowrite('x_antialiased.wav', x_antialiased, fs2);
fprintf('WAV files saved.\n');

%% 4. Auditory analysis (uncomment to listen)
% sound(x_original,    fs1); pause(duration+1);
% sound(x_naive,       fs2); pause(duration+1);   % hear the aliasing noise
% sound(x_antialiased, fs2); pause(duration+1);   % clean

%% 5. Frequency analysis: FFT + fftshift, 3-panel subplot (per doc)
[f0, X0] = centeredSpectrum(x_original,    fs1);
[fn, Xn] = centeredSpectrum(x_naive,       fs2);
[fa, Xa] = centeredSpectrum(x_antialiased, fs2);

figure('Name', 'Phase 2 - Frequency Domain Analysis');
subplot(3,1,1);
plot(f0, X0, 'b'); grid on; xlim([-8000 8000]);
title('Phase 2 - Original Signal Spectrum (fs = 44100 Hz)');
xlabel('Frequency (Hz)'); ylabel('|X(f)|');

subplot(3,1,2);
plot(fn, Xn, 'r'); grid on; xlim([-4000 4000]);
title('Phase 2 - Naive Downsampled Spectrum (Aliasing present)');
xlabel('Frequency (Hz)'); ylabel('|X(f)|');

subplot(3,1,3);
plot(fa, Xa, 'g'); grid on; xlim([-4000 4000]);
title('Phase 2 - Anti-Aliased Downsampled Spectrum');
xlabel('Frequency (Hz)'); ylabel('|X(f)|');
saveas(gcf, 'Phase2_Frequency_Domain_Analysis.png');

%% 6. Time domain overview
t0 = (0:length(x_original)-1)/fs1;
tn = (0:length(x_naive)-1)/fs2;
ta = (0:length(x_antialiased)-1)/fs2;

figure('Name', 'Phase 2 - Time Domain Analysis');
subplot(3,1,1); plot(t0,x_original);    title('Phase 2 - Original (44100 Hz)');         xlabel('Time (s)'); ylabel('Amp'); grid on; axis tight;
subplot(3,1,2); plot(tn,x_naive);       title('Phase 2 - Naive Downsampled (8000 Hz)'); xlabel('Time (s)'); ylabel('Amp'); grid on; axis tight;
subplot(3,1,3); plot(ta,x_antialiased); title('Phase 2 - Anti-Aliased (8000 Hz)');      xlabel('Time (s)'); ylabel('Amp'); grid on; axis tight;
saveas(gcf, 'Phase2_Time_Domain_Analysis.png');

fprintf('Phase 2 completed.\n');

%% ---- Local function: centered (fftshift) normalized magnitude spectrum ----
function [f, mag] = centeredSpectrum(x, fs)
    x   = x(:);
    N   = length(x);
    mag = abs(fftshift(fft(x))) / N;             % length-normalized
    f   = (-floor(N/2):ceil(N/2)-1) * (fs/N);
end
