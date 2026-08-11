# MATLAB Digital Audio Workstation (DAW) Engine

Design and implementation of a Digital Audio Workstation (DAW) signal processing engine in MATLAB. This project covers fundamental and advanced Digital Signal Processing (DSP) concepts, including Fourier series, sampling theory, digital filters (FIR/IIR), and Z-plane analysis.

## Phase 1: Additive Synthesis
In this phase, a triangular wave was synthesized using the Fourier series. Since the Fourier series of a triangular wave consists only of odd harmonics whose amplitudes decay at a rate of $1/k^2$, the signal was synthesized in three stages:
- 1st harmonic only
- First 5 odd harmonics
- First 50 odd harmonics

Frequency domain (FFT) analysis of the third case showed peaks at odd multiples of the fundamental frequency ($440$, $1320$, $2200$ Hz, etc.) with decreasing amplitudes matching the $1/k^2$ decay rate. As the number of harmonics increased, the result closely resembled a pure triangular wave both visually and audibly.

## Phase 2: Resampling, Signal Degradation, and Anti-Aliasing Filter
This phase demonstrates the practical effects of aliasing. A real audio signal sampled at $44100$ Hz was downsampled to $8000$ Hz.
Since the new sampling rate is $8000$ Hz, the Nyquist frequency is $4000$ Hz. 
- **Without Filter (Naïve Downsampling):** High-frequency components folded back into the baseband, causing noticeable audio distortion and spectral clutter.
- **With Anti-Aliasing Filter:** By applying an 8th-order Butterworth low-pass filter with a cutoff frequency of $3800$ Hz prior to downsampling, dangerous frequencies were attenuated, resulting in clean and natural audio without aliasing artifacts.

## Phase 3: Advanced Time-Domain Effects (Dynamic Echo & Convolution)
Outputs from previous phases were mixed using an exponential envelope to fade the music while keeping the speech clear. An echo effect was then implemented using two approaches:
1. **FIR Approach:** The impulse response consists of delayed impulses scaled by a factor of $\alpha$, implemented via direct convolution.
2. **IIR Approach:** A feedback loop with the transfer function $H(z) = 1/(1 - \alpha z^{-R})$. 

Results showed that the system is stable and echoes decay naturally for $|\alpha| < 1$. However, if $\alpha > 1$, the system becomes unstable and the output grows indefinitely. The FIR implementation proved highly stable for controlled, simple echoes.

## Phase 4: Frequency Engineering & Z-Plane Analysis (3-Band Equalizer)
The stable FIR output from Phase 3 was processed through a parallel 3-band equalizer using Butterworth IIR filters:
- **Bass Band:** Low-pass filter with a $300$ Hz cutoff.
- **Mid Band:** Band-pass filter from $300$ to $2000$ Hz.
- **Treble Band:** High-pass filter with a $2000$ Hz cutoff.

Two audio profiles were created:
- **Bass Boost:** Amplified the lower band, creating a deeper, fuller sound.
- **Muffled:** Severely attenuated mid and high bands, creating a "behind-the-wall" muffled effect.

Filter behaviors were verified using `freqz` and `impz`. Z-plane analysis (`zplane`) confirmed BIBO stability for all filters, as all poles were located strictly inside the unit circle (e.g., the maximum pole magnitude for the Bass filter was $0.914320 < 1$).

---
---

# موتور پردازش صوتی (DAW) در متلب 

طراحی و پیاده‌سازی موتور پردازش سیگنال یک ایستگاه کاری صوتی دیجیتال در نرم‌افزار متلب. این پروژه شامل مفاهیم پایه‌ای و پیشرفته پردازش سیگنال از جمله سری فوریه، تئوری نمونه‌برداری، فیلترهای دیجیتال (FIR/IIR) و تحلیل در صفحه Z است.

## فاز ۱: سنتز افزودنی (Additive Synthesis)
در این فاز با استفاده از سری فوریه، یک موج مثلثی ساخته شد. طبق رابطه‌ی سری فوریه‌ی موج مثلثی، فقط هارمونیک‌های فرد در ساخت این موج نقش دارند و دامنه‌ی آن‌ها با نسبت $1/k^2$ افت می‌کند. سیگنال در سه حالت سنتز شد:
- فقط هارمونیک اول
- ترکیب ۵ هارمونیک فرد اول
- ترکیب ۵۰ هارمونیک فرد اول

با بررسی طیف فرکانسی (FFT) حالت سوم، مشخص شد که قله‌ها در مضارب فرد فرکانس پایه (یعنی $440$، $1320$، $2200$ هرتز) ظاهر می‌شوند و ارتفاع آن‌ها مطابق افت $1/k^2$ کاهش می‌یابد. با افزایش هارمونیک‌ها، سیگنال هم در حوزه زمان و هم از نظر شنیداری به موج مثلثی نزدیک‌تر شد.

## فاز ۲: کاهش نرخ نمونه‌برداری و فیلتر آنتی‌الیاسینگ (Anti-Aliasing)
هدف این فاز بررسی عملی پدیده آلیاسینگ بود. صدای ضبط‌شده با نرخ $44100$ هرتز به نرخ $8000$ هرتز کاهش یافت. با نرخ جدید، فرکانس نایکوئیست $4000$ هرتز خواهد بود.
- **بدون فیلتر:** فرکانس‌های بالای $4000$ هرتز به داخل باند اصلی تا خورده و باعث اعوجاج و شلوغی طیف فرکانسی شدند.
- **با فیلتر:** با اعمال یک فیلتر پایین‌گذر Butterworth مرتبه ۸ با فرکانس قطع $3800$ هرتز قبل از کاهش نرخ، فرکانس‌های بالا تضعیف شدند و خروجی نهایی طبیعی‌تر و بدون مشکل شنیداری به دست آمد.

## فاز ۳: افکت‌های زمانی پیشرفته (اکو و کانولوشن)
خروجی‌های فازهای قبل (موسیقی و گفتار) با یک پوش نمایی میکس شدند. سپس افکت اکو به دو روش پیاده‌سازی شد:
1. **دیدگاه FIR:** پاسخ ضربه شامل چند پالس تأخیردار است که با ضریب $\alpha$ تضعیف می‌شوند (با کانولوشن مستقیم).
2. **دیدگاه IIR:** استفاده از فیدبک با تابع انتقال $H(z) = 1/(1 - \alpha z^{-R})$. 

بررسی‌ها نشان داد که برای $|\alpha| < 1$ سیستم پایدار است، اما اگر $\alpha > 1$ شود، سیستم ناپایدار شده و خروجی رشد می‌کند. ساختار FIR برای اکوهای ساده کاملاً پایدار عمل کرد.

## فاز ۴: اکولایزر ۳ بانده و تحلیل صفحه Z
خروجی پایدار فاز ۳ وارد یک اکولایزر ۳ بانده موازی شد:
- **باند Bass:** فیلتر پایین‌گذر با فرکانس قطع $300$ هرتز.
- **باند Mid:** فیلتر میان‌گذر از $300$ تا $2000$ هرتز.
- **باند Treble:** فیلتر بالاگذر با فرکانس قطع $2000$ هرتز.

دو سناریوی صوتی ایجاد شد:
-ا **Bass Boost:** تقویت باند پایین که باعث بم‌تر شدن صدا شد.
-ا **Muffled:** تضعیف شدید باندهای میانی و بالا که صدای خفه تولید کرد.

با استفاده از دستورات `freqz` و `impz`، پاسخ فیلترها بررسی شد. تحلیل `zplane` نشان داد که تمامی قطب‌ها درون دایره واحد قرار دارند (مثلاً بزرگ‌ترین قطب فیلتر Bass مقدار $0.914320 < 1$ داشت)، لذا پایداری BIBO سیستم اثبات شد.
