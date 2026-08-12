%% ================================================================
%  Phase 3 - Dynamic Echo & Convolution (FIR & IIR)
%  Signals & Systems Project - Dr. Rezaei - Spring 1405
%  ----------------------------------------------------------------
%  Pipeline:
%    1) Mix richest Phase-1 music (x_c) with clean Phase-2 voice
%       (x_antialiased) after exponential damping of the music.
%    2) Apply echo effect via two views:
%         (a) FIR  -> impulse response + direct convolution (conv)
%         (b) IIR  -> recursive difference equation (filter)
%    3) Show stable vs unstable IIR behavior.
%  ================================================================
clear; clc; close all;

%% ---------------- Working sample rate (Phase-2 rate) -------------
fs = 8000;                       % target working rate [Hz]

%% ---------------- 1) Load source signals ------------------------
% Voice: clean anti-aliased output of Phase 2 (already at 8000 Hz)
[voice, fs_voice] = audioread('../Phase2_Sampling_AntiAliasing/x_antialiased.wav');
if fs_voice ~= fs
    voice = resample(voice, fs, fs_voice);
end
voice = voice(:,1);              % force mono (column)

% Music: richest Phase-1 signal (50 harmonics) at 44100 Hz
[music, fs_music] = audioread('../Phase1_Additive_Synthesis/x_c.wav');
music = music(:,1);
% Resample music to the Phase-2 working rate (8000 Hz)
music = resample(music, fs, fs_music);

%% ---------------- 2) Exponential damping of music ---------------
% Decaying envelope so the music fades and the voice stays clear.
%   env(t) = exp(-t / tau)
tau = 1.5;                                   % decay time constant [s]
Lmusic = numel(music);
t_music = (0:Lmusic-1).' / fs;
env = exp(-t_music / tau);
music_damped = music .* env;

%% ---------------- 3) Length alignment + Mix ---------------------
% Align both signals to the SAME length (zero-pad the shorter one).
N = max(numel(voice), numel(music_damped));
voice        = [voice;        zeros(N - numel(voice), 1)];
music_damped = [music_damped; zeros(N - numel(music_damped), 1)];

% Normalize each source before mixing (avoids one dominating by scale)
voice        = voice        / max(abs(voice) + eps);
music_damped = music_damped / max(abs(music_damped) + eps);

% Mix ratio: voice MUST stay clearly intelligible over the rich music.
gVoice = 0.90;                   % speech gain (dominant)
gMusic = 0.35;                   % background music gain
x_studio = gVoice * voice + gMusic * music_damped;

% Prevent clipping of the raw studio mix
x_studio = x_studio / max(abs(x_studio) + eps) * 0.98;
audiowrite('x_studio.wav', x_studio, fs);

%% ---------------- Echo parameters -------------------------------
R          = round(fs * 0.4);    % echo delay in samples (0.4 s)
numTaps    = 5;                  % i = 0..4  -> 5 repetitions
alpha_st   = 0.6;                % stable attenuation
alpha_un   = 1.05;               % unstable feedback gain

%% ================= (A) FIR ECHO  (impulse response + conv) =======
%  h[n] = sum_{i=0}^{4} alpha^i * delta[n - i*R]
%  Last tap sits at index 4R -> exact length = 4R + 1.
h = zeros((numTaps-1)*R + 1, 1);
for i = 0:numTaps-1
    h(i*R + 1) = alpha_st^i;     % place tap of height alpha^i at delay i*R
end

y_fir = conv(x_studio, h);       % direct convolution
y_fir = y_fir / max(abs(y_fir) + eps) * 0.98;   % normalize (stable)
audiowrite('y_fir_stable.wav', y_fir, fs);

%% ================= (B) IIR ECHO  (recursive filter) =============
%  Difference equation:  y[n] = x[n] + alpha * y[n-R]
%  Transfer function:    H(z) = 1 / (1 - alpha * z^-R)
%  b = [1], a = [1, 0, ..., 0, -alpha]  (length R+1)
b = 1;

% ---- Stable IIR (alpha = 0.60) ----
a_st = zeros(R+1, 1);
a_st(1)   = 1;
a_st(R+1) = -alpha_st;
y_iir = filter(b, a_st, x_studio);
y_iir = y_iir / max(abs(y_iir) + eps) * 0.98;   % normalize (stable)
audiowrite('y_iir_stable.wav', y_iir, fs);

% ---- Unstable IIR (alpha = 1.05) ----
a_un = zeros(R+1, 1);
a_un(1)   = 1;
a_un(R+1) = -alpha_un;
y_iir_un = filter(b, a_un, x_studio);
% DO NOT normalize: keep the exponential growth, only clip to [-1,1]
% to emulate real hardware saturation / audible clipping distortion.
y_iir_un = max(min(y_iir_un, 1), -1);
audiowrite('y_iir_unstable.wav', y_iir_un, fs);

%% ================= PLOT 1: FIR impulse response =================
figFIR = figure('Name','Phase 3 - FIR Impulse Response','Color','k');
set(figFIR,'InvertHardcopy','off');          % keep black background on save

n_axis = 0:numel(h)-1;
stem(n_axis, h, 'filled', 'LineWidth', 1.2, 'Color','c', 'MarkerFaceColor','c');
grid on;
title('Phase 3 - FIR Echo Impulse Response  h[n] = \Sigma \alpha^i \delta[n-iR]', ...
      'Color','w');
xlabel('n  (samples)','Color','w');
ylabel('Amplitude','Color','w');
xlim([-R, numel(h)+R]);

ax = gca;
ax.Color     = 'k';                           % black plot area
ax.XColor    = 'w';                            % white ticks/labels
ax.YColor    = 'w';
ax.GridColor = [0.7 0.7 0.7];
% NOTE: toolbar/zoom left ON intentionally

saveas(figFIR, 'Phase3_FIR_Impulse_Response.png');

%% ================= PLOT 2: IIR stability comparison ============
t_out = (0:numel(y_iir)-1).' / fs;

figIIR = figure('Name','Phase 3 - IIR Stability Comparison','Color','k');
set(figIIR,'InvertHardcopy','off');           % keep black background on save

ax1 = subplot(2,1,1);
plot(t_out, y_iir, 'c', 'LineWidth', 0.8);
grid on;
title('Stable IIR Echo  (\alpha = 0.60)  -  Bounded / Decaying','Color','w');
xlabel('Time (s)','Color','w');  ylabel('Amplitude','Color','w');
ax1.Color = 'k';  ax1.XColor = 'w';  ax1.YColor = 'w';
ax1.GridColor = [0.7 0.7 0.7];

ax2 = subplot(2,1,2);
t_un = (0:numel(y_iir_un)-1).' / fs;
plot(t_un, y_iir_un, 'r', 'LineWidth', 0.8);
grid on;
title('Unstable IIR Echo  (\alpha = 1.05)  -  Growing / Clipped','Color','w');
xlabel('Time (s)','Color','w');  ylabel('Amplitude','Color','w');
ax2.Color = 'k';  ax2.XColor = 'w';  ax2.YColor = 'w';
ax2.GridColor = [0.7 0.7 0.7];

saveas(figIIR, 'Phase3_IIR_Stability_Comparison.png');

%% ================= Console summary ==============================
fprintf('Phase 3 done.\n');
fprintf('  fs = %d Hz | R = %d samples (%.2f s)\n', fs, R, R/fs);
fprintf('  Saved: x_studio.wav, y_fir_stable.wav, y_iir_stable.wav, y_iir_unstable.wav\n');
fprintf('  Saved: Phase3_FIR_Impulse_Response.png, Phase3_IIR_Stability_Comparison.png\n');
