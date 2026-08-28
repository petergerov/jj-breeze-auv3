# Warmth

Warmth is the last tone stage: darker, rounder, slightly driven. It is not another doubler. It sits on the **fully summed** signal (dry + Shift + Vibrato), not as a third parallel blend from dry.

Use it when the vocal should sound like it went through a darker amp or an older path — rolled-off top, optional chest, gentle saturation. Leave it off when you want an open, twangy top end.

## Signal path

After Shift and Vibrato have been mixed in:

1. **Body** — low-shelf boost at a fixed 150 Hz, up to +6 dB
2. **Tone** — low-pass (the darkness)
3. **Drive** — soft tanh saturation after the filter
4. **Mix** — blend of that processed signal with the pre-Warmth chain

Unlike Shift and Vibrato, this is a finishing pass on the whole output. Mix 0 % or the section off leaves the chain unchanged.

Turn the section **off** to remove it from the output without wiping the knobs. DSP keeps running so switching back is click-free.

## Controls

| Control | Range | What it does |
|---|---|---|
| **Tone** | 500 Hz … 12 kHz | Low-pass cutoff. Lower = darker. Default 3.5 kHz. This is the main “warm / dull” control. |
| **Drive** | 0 … 100 % | Saturation after the low-pass. 0 % is filter (and Body) only, no extra harmonics. Higher Drive is denser and a bit dirtier, not a guitar amp. |
| **Body** | 0 … 100 % | Low-shelf at 150 Hz, up to +6 dB, *before* the low-pass. Adds chest / weight. A pitch-down from Shift does not add this on its own — Body does. 0 % is no boost. |
| **Mix** | 0 … 100 % | How much of the warmed signal replaces the pre-Warmth chain. |
| **On/Off** | | Bypass for Warmth only. |

Long-press **Drive** or **Body** on iOS for the same short help text.

## How to use it

- **Dark vocal** — Tone down (around 2.5–3.5 kHz), a little Drive, Mix enough to hear the roll-off. **JJ Cajun Moon** uses Warmth without extra Body.
- **Chest / baritone** — Body up as well, especially with a downward Pitch in Shift. **Deep Baritone** leans on Body + Drive; **JJ Dark Vocal** uses a lighter Mix.
- **Leave it off** for slap and sparkle. **Slapback Twang** and **JJ Lies** keep Warmth off so the repeat stays bright.

If the vocal gets woolly, raise Tone or drop Mix before touching Shift. If a big pitch-down still feels thin, that is Body, not Tone.
