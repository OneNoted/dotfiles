# THIEAUDIO Hype 4 MKII - UAPP 10-Band Parametric EQ

Target: CrinEar Reference Standard S1 on Hangout.Audio 5128, 800 Hz normalized
Source preset: `thieaudio-hype-4-mkii-crinear-reference.conf`

UAPP path: Volume/EQ -> EQ -> 10-band Parametric EQ.

Set EQ gain / preamp to `-2.0 dB` if UAPP exposes a global EQ gain. If it does not, reduce UAPP's software volume/headroom by about `2 dB` to avoid clipping.

| Band | Enabled | Type | Frequency | Gain | Q |
| ---: | :---: | --- | ---: | ---: | ---: |
| 1 | On | Peak | 21 Hz | -4.6 dB | 0.50 |
| 2 | On | Peak | 130 Hz | +1.5 dB | 1.20 |
| 3 | On | Peak | 2200 Hz | -1.7 dB | 2.00 |
| 4 | On | Peak | 2900 Hz | +2.5 dB | 2.00 |
| 5 | On | Peak | 5000 Hz | +1.2 dB | 1.50 |
| 6 | On | Peak | 6100 Hz | +1.0 dB | 1.00 |
| 7 | On | Peak | 8000 Hz | -5.8 dB | 0.60 |
| 8 | On | Peak | 10000 Hz | +3.5 dB | 2.00 |
| 9 | On | High shelf | 11000 Hz | -7.0 dB | 0.70 |
| 10 | Off | Peak | 0 Hz | 0.0 dB | 0.00 |

If UAPP does not offer a high-shelf type for band 9, use a Peak filter at `11000 Hz`, `-7.0 dB`, `Q 0.70` as a fallback. It is less accurate, but close enough to evaluate the tonal direction.

After entering the values, back out of the EQ screen with UAPP's back arrow/button so the app persists the settings.
