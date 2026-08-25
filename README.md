# jj-breeze (AUv3)

iPhone and iPad AUv3 of [jj-breeze](https://github.com/pgerov/jj-breeze): a stereo micro-pitch widener, slapback echo, vibrato, and warmth stage.

This is the Apple-native stack, not JUCE:

- **C++ DSP kernel** — the same algorithms as the desktop AU/VST3 (`PitchShifter`, `ModulatedDelay`, `SlapbackDelay`, warmth/crossover biquads matching JUCE 9 IIR)
- **`AUAudioUnit`** — buses, `AUParameterTree`, factory presets, render block
- **SwiftUI** — analog-gear editor hosted in `AUViewController`
- **Container app** — test host that registers the extension so GarageBand, AUM, and Logic for iPad can load it

## Requirements

- Xcode 16 or later (this repo was generated against Xcode 26)
- iOS 17+
- Apple Developer team (set in Xcode Signing & Capabilities)

## Open and build

```sh
xcodegen generate
open JJBreeze.xcodeproj
```

1. Select the **jj-breeze** scheme.
2. Set your Development Team on both **JJBreeze** and **JJBreezeExtension**.
3. Run on an iPhone, iPad, or simulator.

Installing the app registers **Gerov: jj-breeze** (`aufx` / `Jjbz` / `Grov`) as an Audio Unit effect.

## In a DAW

After the container app has been launched once:

- **GarageBand** — Audio FX → Audio Unit Extensions
- **Logic for iPad** — Audio Units → Gerov
- **AUM**, Cubasis, BeatMaker, and other AUv3 hosts

The in-plugin preset menu matches the desktop factory presets (Default, JJ Cale Vocal, Cajun Moon Vocal, JJ Dark Vocal, JJ Dark Vocal (Up), Octave Width, Slapback Twang, Deep Baritone).

## Project layout

```
JJBreeze/                    Container app (test host)
JJBreezeExtension/
  Parameters/                AUParameterTree + factory presets
  DSP/                       C++ kernel (real-time; no Swift)
  UI/                        SwiftUI editor
  Common/                    Apple template glue (AUAudioUnit, process helper)
```

Only edit `Parameters`, `DSP`, and `UI` for plug-in behaviour. The render thread lives entirely in `JJBreezeDSPKernel.hpp`.
