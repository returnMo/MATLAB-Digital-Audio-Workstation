%% ================================================================
%  Phase 4 - Frequency Engineering & Z-Plane Analysis
%            (3-Band Parallel Equalizer)
%  Signals & Systems Project - Dr. Rezaei - Spring 1405
%  ----------------------------------------------------------------
%  Pipeline:
%    1) Load the Phase-3 FIR-echoed signal (y_fir_stable.wav).
%    2) Design three Butterworth IIR filters in PARALLEL:
%         - Bass    : low-pass   @ 300 Hz   (overall order 4)
%         - Mid     : band-pass  @ 300..2000 Hz (overall order 4)
%         - Treble  : high-pass  @ 2000 Hz  (overall order 4)
%    3) Split the signal into 3 bands, apply per-band gains,
%       then sum the branches for two presets:
%         - Bass Boost : Gbass=2.5 , Gmid=1.0 , Gtreble=0.5
%         - Muffled    : Gbass=2.0 , Gmid=0.1 , Gtreble=0.1
%    4) Analysis:
%         - freqz : magnitude responses of the 3 filters
%         - FFT   : spectrum comparison of both presets
%         - impz  : impulse responses and convergence to zero
%         - zplane: pole-zero maps and BIBO stability
%         - H(z)  : printed transfer function of the Bass filter
%  ================================================================

clear; clc; close all;

%% ---------------- 0) Basic settings -----------------------------
fs   = 8000;          % Working sample rate [Hz]
fnyq = fs/2;          % Nyquist frequency [Hz] = 4000

inputFile = 'y_fir_stable.wav';

if ~isfile(inputFile)
    error('Input file "%s" was not found. First generate Phase-3 FIR output.', inputFile);
end

fprintf('============================================================\n');
fprintf('Phase 4 started...\n');
fprintf('Input file : %s\n', inputFile);
fprintf('Working fs : %d Hz\n', fs);
fprintf('============================================================\n');

%% ---------------- 1) Load Phase-3 FIR output --------------------
[x, fs_in] = audioread(inputFile);

% If stereo, convert to mono by taking the first channel
if size(x,2) > 1
    x = x(:,1);
end

% Resample only if needed
if fs_in ~= fs
    x = resample(x, fs, fs_in);
end

x = x(:);   % force column vector

%% ---------------- 2) Design 3 Butterworth IIR filters ----------
% Cutoffs in Hz
fc_bass   = 300;
band_mid  = [300 2000];
fc_treble = 2000;

% Bass: 4th-order low-pass Butterworth
[b_bass, a_bass] = butter(4, fc_bass/fnyq, 'low');

% Mid: for band-pass in MATLAB, butter(N, [w1 w2], 'bandpass')
% gives an overall order of 2N. So N=2 is used here to obtain
% an overall 4th-order band-pass filter.
[b_mid, a_mid] = butter(2, band_mid/fnyq, 'bandpass');

% Treble: 4th-order high-pass Butterworth
[b_treble, a_treble] = butter(4, fc_treble/fnyq, 'high');

%% ---------------- 3) Split into 3 bands -------------------------
y_bass   = filter(b_bass,   a_bass,   x);
y_mid    = filter(b_mid,    a_mid,    x);
y_treble = filter(b_treble, a_treble, x);

%% ---------------- 4) Apply gains and build 2 presets -----------
% Parallel EQ formula:
% y[n] = Gbass*y_bass[n] + Gmid*y_mid[n] + Gtreble*y_treble[n]

% ---- Preset A: BASS BOOST ----
Gbass_A   = 2.5;
Gmid_A    = 1.0;
Gtreble_A = 0.5;

y_bass_boost = Gbass_A*y_bass + Gmid_A*y_mid + Gtreble_A*y_treble;
y_bass_boost = y_bass_boost / max(abs(y_bass_boost) + eps) * 0.98;   % anti-clipping
audiowrite('y_bass_boost.wav', y_bass_boost, fs);

% ---- Preset B: MUFFLED ----
Gbass_B   = 2.0;
Gmid_B    = 0.1;
Gtreble_B = 0.1;

y_muffled = Gbass_B*y_bass + Gmid_B*y_mid + Gtreble_B*y_treble;
y_muffled = y_muffled / max(abs(y_muffled) + eps) * 0.98;            % anti-clipping
audiowrite('y_muffled.wav', y_muffled, fs);

%% ---------------- Listening analysis (optional) -----------------
% Uncomment for listening comparison:
% disp('Playing BASS BOOST...'); soundsc(y_bass_boost, fs); pause(numel(y_bass_boost)/fs + 1);
% disp('Playing MUFFLED...');    soundsc(y_muffled,    fs); pause(numel(y_muffled)/fs + 1);

%% ================= PLOT 1: Frequency responses ==================
Nfft_fr = 4096;
[Hb, wb] = freqz(b_bass,   a_bass,   Nfft_fr, fs);
[Hm, wm] = freqz(b_mid,    a_mid,    Nfft_fr, fs);
[Ht, wt] = freqz(b_treble, a_treble, Nfft_fr, fs);

figFR = figure('Name','Phase 4 - Filter Frequency Responses','Color','k');
set(figFR,'InvertHardcopy','off');

plot(wb, 20*log10(abs(Hb)+eps), 'c', 'LineWidth', 1.8); hold on;
plot(wm, 20*log10(abs(Hm)+eps), 'y', 'LineWidth', 1.8);
plot(wt, 20*log10(abs(Ht)+eps), 'm', 'LineWidth', 1.8);

xline(300,  '--w', '300 Hz',  'LineWidth', 1.0, 'Alpha', 0.6);
xline(2000, '--w', '2000 Hz', 'LineWidth', 1.0, 'Alpha', 0.6);

grid on;
title('Phase 4 - 3-Band Butterworth EQ (Magnitude Response)','Color','w');
xlabel('Frequency (Hz)','Color','w');
ylabel('Magnitude (dB)','Color','w');
legend({'Bass (LP @300 Hz)','Mid (BP 300-2000 Hz)','Treble (HP @2000 Hz)'}, ...
       'TextColor','w','Color',[0.15 0.15 0.15],'Location','south');
xlim([0 fnyq]);
ylim([-60 5]);

ax = gca;
ax.Color     = 'k';
ax.XColor    = 'w';
ax.YColor    = 'w';
ax.GridColor = [0.7 0.7 0.7];

saveas(figFR, 'Phase4_Filter_Frequency_Responses.png');

%% ================= PLOT 2: FFT of both presets =================
Nfft = 2^nextpow2(numel(y_bass_boost));
f_axis = (0:Nfft/2-1) * (fs/Nfft);

Ybb = abs(fft(y_bass_boost, Nfft));
Ymf = abs(fft(y_muffled,    Nfft));
Ybb = Ybb(1:Nfft/2);
Ymf = Ymf(1:Nfft/2);

figFFT = figure('Name','Phase 4 - Output Spectrum Comparison','Color','k');
set(figFFT,'InvertHardcopy','off');

axA = subplot(2,1,1);
plot(f_axis, 20*log10(Ybb+eps), 'c', 'LineWidth', 1.0);
grid on;
title('FFT of Output - BASS BOOST  (G_{bass}=2.5, G_{mid}=1.0, G_{treble}=0.5)','Color','w');
xlabel('Frequency (Hz)','Color','w');
ylabel('|Y(f)| (dB)','Color','w');
xlim([0 fnyq]);
axA.Color     = 'k';
axA.XColor    = 'w';
axA.YColor    = 'w';
axA.GridColor = [0.7 0.7 0.7];

axB = subplot(2,1,2);
plot(f_axis, 20*log10(Ymf+eps), 'r', 'LineWidth', 1.0);
grid on;
title('FFT of Output - MUFFLED  (G_{bass}=2.0, G_{mid}=0.1, G_{treble}=0.1)','Color','w');
xlabel('Frequency (Hz)','Color','w');
ylabel('|Y(f)| (dB)','Color','w');
xlim([0 fnyq]);
axB.Color     = 'k';
axB.XColor    = 'w';
axB.YColor    = 'w';
axB.GridColor = [0.7 0.7 0.7];

saveas(figFFT, 'Phase4_Output_Spectrum_Comparison.png');

%% ================= PLOT 3: Impulse responses ===================
Nimp = 200;
[hb, nb] = impz(b_bass,   a_bass,   Nimp);
[hm, nm] = impz(b_mid,    a_mid,    Nimp);
[ht, nt] = impz(b_treble, a_treble, Nimp);

figIMP = figure('Name','Phase 4 - Impulse Responses (impz)','Color','k');
set(figIMP,'InvertHardcopy','off');

s1 = subplot(3,1,1);
stem(nb, hb, 'filled', 'c', 'MarkerSize', 3); grid on;
title('Bass (LP) Impulse Response   h[n] \rightarrow 0   (stable)','Color','w');
ylabel('Amp','Color','w');
s1.Color     = 'k';
s1.XColor    = 'w';
s1.YColor    = 'w';
s1.GridColor = [0.7 0.7 0.7];

s2 = subplot(3,1,2);
stem(nm, hm, 'filled', 'y', 'MarkerSize', 3); grid on;
title('Mid (BP) Impulse Response   h[n] \rightarrow 0   (stable)','Color','w');
ylabel('Amp','Color','w');
s2.Color     = 'k';
s2.XColor    = 'w';
s2.YColor    = 'w';
s2.GridColor = [0.7 0.7 0.7];

s3 = subplot(3,1,3);
stem(nt, ht, 'filled', 'm', 'MarkerSize', 3); grid on;
title('Treble (HP) Impulse Response   h[n] \rightarrow 0   (stable)','Color','w');
xlabel('n (samples)','Color','w');
ylabel('Amp','Color','w');
s3.Color     = 'k';
s3.XColor    = 'w';
s3.YColor    = 'w';
s3.GridColor = [0.7 0.7 0.7];

saveas(figIMP, 'Phase4_Impulse_Responses.png');

%% ================= PLOT 4: Pole-zero maps ======================
figZP = figure('Name','Phase 4 - Pole-Zero Maps (zplane)','Color','k');
set(figZP,'InvertHardcopy','off');

z1 = subplot(1,3,1);
zplane(b_bass, a_bass);
title('Bass (LP)','Color','w');
z1.Color  = 'k';
z1.XColor = 'w';
z1.YColor = 'w';

z2 = subplot(1,3,2);
zplane(b_mid, a_mid);
title('Mid (BP)','Color','w');
z2.Color  = 'k';
z2.XColor = 'w';
z2.YColor = 'w';

z3 = subplot(1,3,3);
zplane(b_treble, a_treble);
title('Treble (HP)','Color','w');
z3.Color  = 'k';
z3.XColor = 'w';
z3.YColor = 'w';

saveas(figZP, 'Phase4_PoleZero_Maps.png');

%% ================= 5) Stability check ==========================
poles_bass   = roots(a_bass);
poles_mid    = roots(a_mid);
poles_treble = roots(a_treble);

p_bass   = max(abs(poles_bass));
p_mid    = max(abs(poles_mid));
p_treble = max(abs(poles_treble));

%% ================= 6) Print H(z) of Bass filter ================
fprintf('\n===== Bass Low-Pass Transfer Function H(z) =====\n');
fprintf('Numerator   b = [ %s]\n', sprintf('%.10f ', b_bass));
fprintf('Denominator a = [ %s]\n', sprintf('%.10f ', a_bass));

fprintf('\nH_bass(z) =\n');
fprintf('  ( %.10f + %.10f z^-1 + %.10f z^-2 + %.10f z^-3 + %.10f z^-4 )\n', b_bass);
fprintf('  ----------------------------------------------------------------------\n');
fprintf('  ( %.10f + %.10f z^-1 + %.10f z^-2 + %.10f z^-3 + %.10f z^-4 )\n', a_bass);

%% ================= 7) Console summary ==========================
fprintf('\n==================== Phase 4 Summary ====================\n');
fprintf('Input signal rate : %d Hz\n', fs);
fprintf('Nyquist frequency : %d Hz\n', fnyq);
fprintf('Bass cutoff       : %d Hz\n', fc_bass);
fprintf('Mid band          : %d Hz to %d Hz\n', band_mid(1), band_mid(2));
fprintf('Treble cutoff     : %d Hz\n', fc_treble);
fprintf('\nMax |pole| values:\n');
fprintf('  Bass   = %.6f\n', p_bass);
fprintf('  Mid    = %.6f\n', p_mid);
fprintf('  Treble = %.6f\n', p_treble);
fprintf('Condition for BIBO stability: all pole magnitudes < 1\n');

fprintf('\nSaved audio files:\n');
fprintf('  y_bass_boost.wav\n');
fprintf('  y_muffled.wav\n');

fprintf('\nSaved figures:\n');
fprintf('  Phase4_Filter_Frequency_Responses.png\n');
fprintf('  Phase4_Output_Spectrum_Comparison.png\n');
fprintf('  Phase4_Impulse_Responses.png\n');
fprintf('  Phase4_PoleZero_Maps.png\n');
fprintf('==========================================================\n');
fprintf('Phase 4 done successfully.\n');
