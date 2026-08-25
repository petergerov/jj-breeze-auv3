# App Store Connect — jj-breeze (AUv3)

Paste-ready listing, privacy answers, and review notes for the iOS/iPadOS Audio Unit.

Use these values in [App Store Connect](https://appstoreconnect.apple.com) for the **container app** `com.gerov.jjbreeze`. The AUv3 (`com.gerov.jjbreeze.AUv3`) is not a separate listing.

Before the first upload, bump the public version from `0.1.0` to **`1.0.0`** (Build can stay `1`). A `0.x` version looks unfinished to reviewers.

---

## Identity

| Field | Value |
|---|---|
| App name (30) | `jj-breeze` |
| Subtitle (30) | `Width, vibrato & warmth` |
| Bundle ID | `com.gerov.jjbreeze` |
| SKU | `jj-breeze-ios` |
| Primary language | English (U.S.) |
| Team ID | `C9LBGZNZ6P` |
| Apple Audio Unit | type `aufx`, subtype `Jjbz`, manufacturer `Grov` |
| Name in hosts | **Gerov: jj-breeze** |
| Platforms | iPhone and iPad (iOS 17+) |
| Category | **Music** |
| Secondary | Entertainment |
| Price | set in Pricing (Free or Paid) |
| Copyright | `2026 Gerov` |

---

## Promotional text (170)

Rotates without a new binary. Leave blank if unused.

```
A stereo micro-pitch widener with vibrato and a warmth stage. Open this app and tap Play, or load Gerov: jj-breeze in GarageBand, Logic for iPad, or AUM.
```

---

## Description (4000) — English

```
jj-breeze is a stereo micro-pitch widener with vibrato and a warmth tone stage. It is an Audio Unit (AUv3) effect for iPhone and iPad.

Open the app, tap Play, and listen to a built-in demo through the effect. Turn knobs, enable sections, and try factory presets. After you have launched the app once, the same plug-in is available in GarageBand, Logic for iPad, AUM, and other AUv3 hosts as Gerov: jj-breeze.

WHAT IT DOES
Shift creates width or a full-band pitch change with independent left and right pitch (±1 octave) and delay, plus a Focus crossover so the low end can stay dry. Vibrato adds a slow delay-based pitch wobble. Warmth is a final tone stage: low-shelf body, low-pass, and gentle saturation.

SECTIONS
• Shift — Pitch L/R, Delay L/R, Focus, Mix
• Vibrato — Rate, Depth, Mix
• Warmth — Tone, Drive, Body, Mix

Each section has an on/off switch. Turning a section off removes it from the sound without wiping the knobs.

FACTORY PRESETS
Default, JJ Cale Vocal, Cajun Moon Vocal, JJ Dark Vocal, JJ Dark Vocal (Up), Octave Width, Deep Baritone.

IN A DAW
1. Install and open jj-breeze once (this registers the Audio Unit).
2. GarageBand: Audio FX → Audio Unit Extensions → Gerov: jj-breeze
3. Logic for iPad: Audio Units → Gerov
4. AUM and other AUv3 hosts: look for Gerov: jj-breeze

This app is a working host, not an empty wrapper. You can hear and edit the effect without leaving the app. Microphone input in the host is optional (Demo Loop is the default).

jj-breeze is an original effect. It is not affiliated with any third-party plug-in vendor or recording artist.
```

---

## Description — German (optional localization)

```
jj-breeze ist ein stereo Micro-Pitch-Widener mit Vibrato und einer Warmth-Stufe. Es ist ein Audio-Unit-Effekt (AUv3) für iPhone und iPad.

App öffnen, Play tippen, Demo-Ton durch den Effekt hören. Regler drehen, Sektionen einschalten, Factory-Presets laden. Nach dem ersten Start erscheint dasselbe Plug-in in GarageBand, Logic für iPad, AUM und anderen AUv3-Hosts als Gerov: jj-breeze.

WAS ES TUT
Shift erzeugt Breite oder eine Vollband-Tonhöhenänderung: Pitch L/R unabhängig (±1 Oktave), Delay L/R, Focus-Crossover (Tiefen können trockenen bleiben). Vibrato ist ein langsames Delay-Vibrato. Warmth ist die letzte Klangstufe: Body-Low-Shelf, Tiefpass und sanfte Sättigung.

SEKTIONEN
• Shift — Pitch L/R, Delay L/R, Focus, Mix
• Vibrato — Rate, Depth, Mix
• Warmth — Tone, Drive, Body, Mix

Pro Sektion gibt es einen An/Aus-Schalter. Aus schaltet den Beitrag zum Sound, die Regler bleiben erhalten.

FACTORY-PRESETS
Default, JJ Cale Vocal, Cajun Moon Vocal, JJ Dark Vocal, JJ Dark Vocal (Up), Octave Width, Deep Baritone.

IN EINER DAW
1. jj-breeze einmal installieren und öffnen (registriert die Audio Unit).
2. GarageBand: Audio-FX → Audio-Unit-Erweiterungen → Gerov: jj-breeze
3. Logic für iPad: Audio Units → Gerov
4. AUM und andere AUv3-Hosts: Gerov: jj-breeze

Die App ist ein funktionierender Host, kein leerer Wrapper. Mikrofon im Host ist optional (Standard: Demo Loop).

jj-breeze ist ein eigenständiger Effekt und nicht mit Drittanbieter-Plug-ins oder Interpreten verbunden.
```

---

## Keywords (100)

No spaces after commas. Do not repeat the app name.

```
auv3,audio unit,widener,pitch shifter,vibrato,warmth,vocal,stereo,effect,chorus,detune,music
```

(92 characters)

German keywords (DE listing):

```
auv3,audio unit,widener,pitch shifter,vibrato,waerme,gesang,stereo,effekt,chorus,detune,musik
```

---

## What’s New (version 1.0.0)

```
First release. Stereo micro-pitch widener, vibrato, and warmth as an AUv3, with a built-in host so you can play a demo and edit the effect in-app. Seven factory presets. Works in GarageBand, Logic for iPad, AUM, and other Audio Unit hosts after you open this app once.
```

---

## URLs (required)

Apple rejects the submission if Support URL or Privacy Policy URL is missing.

| Field | What to put |
|---|---|
| Support URL | A page with contact email (GitHub Issues or a simple site). Example: `https://github.com/pgerov/jj-breeze-auv3` |
| Marketing URL | Optional. Same repo or a product page. |
| Privacy Policy URL | **Required.** Host the policy below on a public HTTPS page (GitHub Pages, Notion, your site). |

---

## App Review Information

Paste into App Store Connect → App Review Information.

**Contact**

- First name / last name: your name
- Phone: your number (Apple may call)
- Email: an address you actually read

**Demo account:** none. No sign-in.

**Notes for the reviewer** (paste all of this):

```
This is an Audio Unit v3 (AUv3) audio effect. The container app is a working host, not an empty shell.

HOW TO REVIEW (no GarageBand required)

1. Launch “jj-breeze”.
2. Wait until the analog-style editor appears (Gerov: jj-breeze). If you see “Audio Unit failed to load”, force-quit and reopen once so iOS can register the extension.
3. Leave the source on “Demo Loop”.
4. Tap Play (orange). You should hear a short looping tone through the effect.
5. Turn Shift knobs (Pitch L/R, Mix). The sound should change.
6. Enable Vibrato and Warmth with the section LEDs and move their Mix knobs.
7. Open the preset menu (under the title) and load “Cajun Moon Vocal” or “Deep Baritone”.
8. Tap Stop.

OPTIONAL: GARAGEBAND (iPad)

1. Keep jj-breeze installed. Open GarageBand and create or open a song.
2. Add an Audio Recorder or any audio track.
3. Plug-ins / Audio FX → Audio Unit Extensions → Gerov: jj-breeze.
4. Play the track. The same editor should appear.

IDENTITY
• Bundle ID: com.gerov.jjbreeze
• Extension: com.gerov.jjbreeze.AUv3
• AU: aufx / Jjbz / Grov — listed as “Gerov: jj-breeze”

MICROPHONE
The host can switch source to “Microphone” to hear live input. This is optional. Review with Demo Loop; you do not need to grant mic access. The Audio Unit itself does not require the microphone when hosted in GarageBand or Logic.

There is no account, no ads, no tracking, and no network requirement.
```

**Sign-in required:** No  
**Attachment:** optional screenshot of the editor with Play visible

---

## Age rating (questionnaire)

Answer **No** to all unless noted.

| Question | Answer |
|---|---|
| Cartoon or fantasy violence | None |
| Realistic violence | None |
| Sexual content / nudity | None |
| Profanity or crude humor | None |
| Alcohol, tobacco, drugs | None |
| Mature / suggestive themes | None |
| Horror / fear themes | None |
| Medical / treatment info | None |
| Gambling | None |
| Unrestricted web access | No |
| User-generated content (public) | No |
| Messaging | No |

Expected rating: **4+**

---

## App Privacy (nutrition label)

This app does not collect data.

In App Privacy → **Get Started**:

- **Do you or your third-party partners collect data?** **No**

If Apple still asks per-type:

| Type | Collects? |
|---|---|
| Contact info | No |
| Health & fitness | No |
| Financial | No |
| Location | No |
| Sensitive info | No |
| Contacts | No |
| User content | No |
| Browsing history | No |
| Search history | No |
| Identifiers | No |
| Purchases | No |
| Usage data | No |
| Diagnostics | No |
| Surroundings | No |
| Body | No |
| Other data | No |

Tracking: **No** (no ATT prompt).

Microphone: used **only locally** in the optional host “Microphone” mode. Audio is not uploaded or stored. Do **not** declare it as collected data.

---

## Export compliance / App Encryption Documentation

jj-breeze does not implement encryption. DSP (`tanh` saturation, filters, delays) is **not** cryptography. There is no HTTPS client, no custom AES/RSA, and no proprietary cipher.

`ITSAppUsesNonExemptEncryption` is already `false` in `JJBreeze/Info.plist`, so later uploads should skip this questionnaire. If App Store Connect still asks:

### What type of encryption algorithms does your app implement?

Choose **exactly this option**:

**None of the algorithms mentioned above**

Do **not** choose:

| Option | Why not |
|---|---|
| Encryption algorithms that are proprietary or not accepted as standard by international standard bodies (IEEE, IETF, ITU, etc.) | The app has no proprietary crypto. |
| Standard encryption algorithms instead of, or in addition to, using or accessing the encryption within Apple's operating system | The app does not implement AES, TLS, etc. on its own. |
| Both algorithms mentioned above | Same: no encryption in the product. |

If an earlier screen asks whether the app uses encryption at all, answer **No**.

You do **not** need an ERN (encryption registration) or export documents for this build. Revisit these answers only if you later add your own crypto or a non-exempt library.

---

## Screenshots (required)

Take them on **real devices** or the matching simulator, **without** the status-bar clock if Apple’s current overlay rules complain. Show the **editor + Play**, not a blank host.

Minimum for iPhone + iPad:

| Slot | Device | What to show |
|---|---|---|
| 1 | iPhone 6.7" (e.g. 15 Pro Max) | Editor, Default preset, Play visible |
| 2 | iPhone 6.7" | Vibrato + Warmth enabled, knobs readable |
| 3 | iPhone 6.7" | Preset menu open |
| 4 (optional) | iPhone 6.7" | Caption: “Also works in GarageBand as Gerov: jj-breeze” |
| 1 | iPad 13" | Same editor, landscape |
| 2 | iPad 13" | Play + Demo Loop |

Captions (optional, keep short):

1. Stereo micro-pitch width for vocals and instruments  
2. Vibrato and warmth, section by section  
3. Factory presets, one tap  
4. AUv3 in GarageBand, Logic for iPad, AUM  

App icon: 1024×1024, no alpha, no rounded-corner mask (App Store rounds it).

---

## Privacy policy (host this at your Privacy Policy URL)

```
Privacy Policy — jj-breeze (iOS)

Last updated: 25 August 2026

jj-breeze is an Audio Unit (AUv3) effect published by Gerov.

Data collection
We do not collect, sell, or share personal data. The app has no account, no analytics, no advertising, and no crash reporter that sends information to us.

Microphone
The optional “Microphone” mode in the companion host processes audio on the device so you can hear the effect on live input. Microphone audio is not recorded to disk by this app and is not uploaded. You can use Demo Loop instead and deny microphone permission.

Audio Unit hosts
When you load Gerov: jj-breeze in GarageBand, Logic for iPad, AUM, or another host, that host’s privacy policy applies to anything that host records or shares.

Children
The app is not directed at children and does not collect data from anyone.

Contact
Questions: [YOUR EMAIL]
```

Replace `[YOUR EMAIL]` before you publish the page.

---

## Reviewer pitfalls (AUv3)

Apple often rejects Audio Unit apps for these. This project is set up to avoid them if you follow the notes above.

1. **Empty container (4.2 Minimum Functionality)** — The app must do something on its own. Reviewers can tap Play. Do not describe the listing as “opens GarageBand only.”
2. **Extension never registers** — Review notes say to launch the app once. If the editor fails to load on first launch, they should reopen once.
3. **They cannot find the AU in GarageBand** — Full path is in the notes: Audio FX → Audio Unit Extensions → **Gerov: jj-breeze**.
4. **Microphone permission scare** — Default source is Demo Loop. Notes say mic is optional.
5. **Missing privacy policy URL** — Host the policy before you submit.
6. **Archive of the extension instead of the app** — Archive scheme **jj-breeze** so Organizer lists an **iOS App**, not Other Items. Bundle ID must be `com.gerov.jjbreeze`.
7. **No App Store Connect app record** — Create the iOS app with that bundle ID before Distribute, or you get `DistributionAppRecordProviderError`.

---

## Third-party names

Preset names (JJ Cale Vocal, Cajun Moon Vocal) describe a *sound*, not an endorsement. The public description states the product is not affiliated with third-party vendors or artists.

Do **not** put Soundtoys, MicroShift, Stillwell, or artist names in the **subtitle, keywords, or screenshots**. Keep competitor names out of promotional text.

If Legal asks you to rename presets before 1.0, change them in `JJBreezeExtension/Parameters/Presets.swift` and submit a new build.

---

## Submit checklist

- [ ] App record in App Store Connect, bundle ID `com.gerov.jjbreeze`
- [ ] Paid/Free Apps agreement accepted
- [ ] Version **1.0.0**, unique build number
- [ ] Support URL live
- [ ] Privacy Policy URL live (text above)
- [ ] English description + review notes pasted
- [ ] Age rating completed (4+)
- [ ] App Privacy = no data collected
- [ ] App Encryption Documentation: **None of the algorithms mentioned above** (or skip if plist already exempts)
- [ ] iPhone 6.7" and iPad 13" screenshots
- [ ] Archive is **jj-breeze.app** under iOS Apps
- [ ] TestFlight install: open app → Play works → GarageBand sees **Gerov: jj-breeze**
