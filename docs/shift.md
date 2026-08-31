# Shift

Shift is the core of jj-breeze: a stereo pitch + delay insert with a crossover so the low end can stay untouched.

It is not a chorus. Each side gets its own pitch and its own delay tap. Same-sign pitch (both up, or both down) stays mono-compatible and reads as a processed voice. Opposite signs (L up, R down) is the classic micro-shift width.

## Signal path

The input is split at **Focus**. Everything below that frequency stays dry. Only the band above it goes through:

1. Dual-tap pitch shifter (independent **Pitch L** / **Pitch R**)
2. Short modulated delay (**Delay L** / **Delay R**)

Those two bands are summed back together, then blended with the full dry signal via **Mix**.

Vibrato does **not** sit inside this path. It is a separate parallel blend from dry. Warmth comes after both.

Turn the section **off** to remove Shift from the output without wiping the knobs. DSP keeps running so switching back is click-free.

## Controls

| Control | Range | What it does |
|---|---|---|
| **Pitch L / Pitch R** | −1200 … +1200 cents | Per-channel pitch. Small values (± a few cents to a few hundred) are doubler / width territory. Large values, with Focus turned down, are a full-band voice shift (octave, baritone, “Lies”-style one-sided lift). The knob is skewed so the fine area near 0 still gets most of the travel. |
| **Focus** | 20 Hz … 10 kHz | Crossover, not a wet-only low cut. Below this point: dry. Above it: pitch + delay. Raise it to keep width off the low end. Drop it toward 20–25 Hz for a full-band shift or a full-band slap. |
| **Delay L / Delay R** | 0 … 250 ms | Per-channel delay tap, with a slow built-in wobble. Short times (roughly 15–40 ms) add width and de-correlation. Around 80–140 ms is a single slapback repeat. There is no feedback: one tap, not a decaying echo train. The knob is skewed toward the short end. |
| **Mix** | 0 … 100 % | Dry/wet for this section only. Does not steal from Vibrato. |
| **On/Off** | | Bypass for Shift only. |

On iOS, **Pitch** and **Delay** can be linked. Link keeps the L/R offset while you drag one side.

## How to use it

- **Width** — Pitch L and R with opposite signs, short Delay L/R, Focus high enough that bass stays put.
- **Processed vocal** — matching Pitch L/R (e.g. +300 or −300), Focus near the bottom, Mix to taste. See **JJ Cajun Moon** and **JJ Dark Vocal**.
- **One-sided shift** — Pitch L at 0, Pitch R high (or the reverse). **JJ Lies** is this: R at +470 cents.
- **Slap** — Pitch at 0, Delay around 110 / 115 ms, Focus down, Vibrato and Warmth off. **Slapback Twang**.
- **Octave** — Pitch L −1200, Pitch R 0, Focus down. **Octave Width**.

If a big pitch change “does nothing” on the body of the voice, Focus is still too high. Mix only blends; Focus decides *what* gets shifted.
