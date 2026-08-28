# Vibrato

Vibrato is a slow, continuous pitch wobble. It is delay-based (a short delay swept by an LFO), not a second copy of Shift’s static detune.

That distinction matters: Shift sets a *fixed* left/right pitch. Vibrato *moves* pitch over time. A static +300 cents never sounds like this section.

## Signal path

Vibrato is an independent blend on the **dry** input, in parallel with Shift:

- Dry → short modulated delay (Rate / Depth) → blend back with dry via **Mix**
- That wet/dry mix is then **added** to Shift’s output (Shift also mixed against the same dry)

Turning Vibrato Mix up does not eat into Shift Mix. At Vibrato Mix 0 % (or the section off) the output is identical to Shift + Warmth without this stage.

Warmth, if on, hears the sum of dry + Shift + Vibrato.

Turn the section **off** to remove it from the output without wiping the knobs. DSP keeps running so switching back is click-free.

## Controls

| Control | Range | What it does |
|---|---|---|
| **Rate** | 0.1 … 8 Hz | LFO speed. Slow (about 1–1.5 Hz) is the laid-back vocal swirl. Faster reads as a more obvious wobble or seasick chorus. |
| **Depth** | 0 … 8 ms | How far the delay is swept. More milliseconds = a wider pitch swing. This is delay time, not cents. |
| **Mix** | 0 … 100 % | Blend of the wobbled signal with dry. Low Mix is a hint of movement under a mostly static voice. High Mix is closer to a real vibrato replacing the static pitch. |
| **On/Off** | | Bypass for Vibrato only. |

## How to use it

- **Under a vocal** — Rate ~1.2 Hz, Depth around 3 ms, Mix 10–15 %. Present but not the main event. **JJ Cajun Moon** and **JJ Dark Vocal** sit here.
- **Leave it off** when the trick should read clean: slap, octave, one-sided pitch. **Slapback Twang**, **JJ Lies**, **Octave Width**, and **Deep Baritone** all run with Vibrato off.

If Shift is already doing a large pitch drop, adding Vibrato can sound comic rather than musical. Depth first, then Mix; Rate last.
