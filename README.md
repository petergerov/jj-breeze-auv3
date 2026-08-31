# jj-breeze (AUv3)

Stereo micro-pitch widener, vibrato, and warmth — an Audio Unit (AUv3) for iPhone and iPad. Companion to the desktop [jj-breeze](https://github.com/pgerov/jj-breeze) AU/VST3.

**Website:** [petergerov.github.io/jj-breeze-auv3](https://petergerov.github.io/jj-breeze-auv3)  
**Support:** [GitHub Issues](https://github.com/petergerov/jj-breeze-auv3/issues)  
**Sister app:** [Gig Songbook](https://gigsongbook.com)

## What it is

- **C++ DSP kernel** — same algorithms as the desktop plug-in (`PitchShifter`, `ModulatedDelay`, warmth/crossover)
- **`AUAudioUnit`** — buses, `AUParameterTree`, factory + user presets, render block
- **SwiftUI retro panel** — Field Green / Slate finishes, bakelite knobs, bat switches, LED meters
- **Container app** — working host with Demo Loop (and optional mic); registers the extension for GarageBand, Logic for iPad, AUM, and other AUv3 hosts

**AU identity:** type `aufx`, subtype `Jjb3`, manufacturer `Grov` — listed in hosts as **jj-breeze** (Gerov).

## Pricing

- App Store download is **free**
- **7-day trial** from first launch (no signup, no $0 IAP)
- Then one-time unlock: `com.gerov.jjbreeze.unlock` ($2.99 US)

See [APP_STORE_SUBMISSION.md](APP_STORE_SUBMISSION.md) for App Store Connect copy, IAP setup, and review notes.

## Requirements

- Xcode 16 or later
- iOS 17+
- Apple Developer team (set in Xcode Signing & Capabilities)
- App Group **`group.com.gerov.jjbreeze`** on app + extension (for shared trial/unlock state)

## Open and build

```sh
xcodegen generate
open JJBreeze.xcodeproj
```

1. Select the **jj-breeze** scheme.
2. Set your Development Team on both **JJBreeze** and **JJBreezeExtension**.
3. Run on an iPhone, iPad, or simulator.

Open the app once so the Audio Unit registers. Leave **Demo Loop** selected and tap **Play**.

## In a DAW

After the container app has been launched once:

- **GarageBand** — Audio FX → Audio Unit Extensions → jj-breeze
- **Logic for iPad** — Audio Units → Gerov → jj-breeze
- **AUM**, Cubasis, BeatMaker, and other AUv3 hosts

## Factory presets

Default, Stereo Width, JJ Cajun Moon, JJ Lies, JJ Dark Vocal, Octave Width, Deep Baritone, Slapback Twang.

User presets: tap the preset window → **Save As…**; swipe left to rename or delete. Preset names describe a *feel* — the plug-in is not affiliated with any artist or third-party vendor.

## Project layout

```
JJBreeze/                    Container app (test host)
JJBreezeExtension/
  Parameters/                AUParameterTree, presets, StoreKit unlock
  DSP/                       C++ kernel (real-time; no Swift)
  UI/                        SwiftUI editor + GearTheme finishes
  Common/                    AUAudioUnit / process glue
docs/                        Marketing site + privacy (GitHub Pages)
APP_STORE_SUBMISSION.md      App Store Connect paste-ready copy
```

Only edit `Parameters`, `DSP`, and `UI` for plug-in behaviour. The render thread lives entirely in `JJBreezeDSPKernel.hpp`.
