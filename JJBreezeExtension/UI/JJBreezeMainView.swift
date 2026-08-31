import SwiftUI

struct JJBreezeMainView: View {
    var parameterTree: ObservableAUParameterGroup
    var audioUnit: JJBreezeAudioUnit?

    @State private var linkPitch = false
    @State private var linkDelay = false
    @State private var isBypassed = false
    @State private var showPaywall = false
    @Bindable private var entitlement = EntitlementService.shared

    // Rack-panel geometry — matches the desktop design's headerHeight/
    // earWidth/footerStripHeight constants, scaled down for a
    // host-embedded extension view.
    private let earWidth: CGFloat = 18
    private let footerHeight: CGFloat = 12
    private let contentGutter: CGFloat = 12
    // Below this width the three columns don't have room to sit side by
    // side without crushing the knobs — fall back to stacking them, same
    // content, just a different arrangement.
    private let wideThreshold: CGFloat = 640

    var body: some View {
        GeometryReader { geo in
            let sideInset = earWidth + contentGutter

            ZStack(alignment: .bottom) {
                ChassisBackground(theme: GearTheme.current)

                HStack(spacing: 0) {
                    RackEar(theme: GearTheme.current).frame(width: earWidth)
                    Spacer(minLength: 0)
                    RackEar(theme: GearTheme.current).frame(width: earWidth)
                }

                ScrollView(.vertical, showsIndicators: false) {
                    // Spacers above/below the panel content, plus a
                    // minHeight matching the full container: when the host
                    // gives more height than the panel needs, this centres
                    // it in the chassis rather than pinning it to the top
                    // and leaving a dead expanse of chassis below; when the
                    // host is short, the spacers collapse and it scrolls.
                    VStack(spacing: 0) {
                        Spacer(minLength: 0)
                        panelContent(width: geo.size.width)
                        Spacer(minLength: 0)
                    }
                    .frame(minHeight: geo.size.height)
                }
                .frame(width: geo.size.width, height: geo.size.height)

                FooterRivetStrip(theme: GearTheme.current)
                    .frame(width: geo.size.width, height: footerHeight)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .onAppear {
            isBypassed = audioUnit?.shouldBypassEffect ?? false
            Task {
                await entitlement.refresh()
                audioUnit?.applyLicenseFromStore()
            }
        }
        .onChange(of: isBypassed) { _, newValue in
            audioUnit?.shouldBypassEffect = newValue
        }
        .onReceive(NotificationCenter.default.publisher(for: .jjBreezeAccessChanged)) { _ in
            audioUnit?.applyLicenseFromStore()
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView(entitlement: entitlement, showsCloseWhenAllowed: true) {
                showPaywall = false
            }
            .presentationDetents([.large])
        }
    }

    // The panel's actual content — header, divider, sections, footer — at
    // its natural size for a given width, with no outer chassis/scrolling
    // wrapper. `body` embeds this inside the always-fills GeometryReader/
    // ScrollView above; `AudioUnitViewController` also hosts it standalone
    // to *measure* the height a host should be asked for via
    // `preferredContentSize`, so that initial request reflects this view's
    // real layout instead of a hand-tuned guess that drifts out of sync
    // with it.
    func panelContent(width: CGFloat) -> some View {
        let sideInset = earWidth + contentGutter
        return VStack(spacing: 0) {
            header
                .padding(.horizontal, sideInset)
                .padding(.top, 10)
                .padding(.bottom, 8)

            // Engraved groove: a scored line with the light catching its
            // lower lip, rather than a flat hairline.
            VStack(spacing: 0) {
                Rectangle().fill(.black.opacity(0.45)).frame(height: 1)
                Rectangle().fill(GearTheme.panelEdgeLight.opacity(0.35)).frame(height: 1)
            }
            .padding(.horizontal, sideInset)

            sectionsLayout(isWide: width >= wideThreshold)
                .environment(\.knobDiameter, knobDiameter(forPanelWidth: width))
                .padding(.horizontal, sideInset)
                .padding(.top, 12)
                .padding(.bottom, 8)

            versionFooter
                .padding(.horizontal, sideInset)
                .padding(.bottom, footerHeight + 6)
        }
        .frame(width: width)
    }

    // MARK: - Header

    // One row: wordmark, preset selector, IN/OUT meters, power switch. The
    // preset selector is the only flexible item, so it takes whatever width
    // the wordmark, meters and switch leave; the strapline that used to sit
    // under the wordmark moved to versionFooter so this stays a single line.
    private var header: some View {
        VStack(spacing: 8) {
            HStack(alignment: .center, spacing: 8) {
                FinishSelector(theme: GearTheme.current)
                    .frame(width: 26, height: 26)
                    // Nudged down and given its own gap: centred on the
                    // row it reads as sitting above the wordmark, whose
                    // visual weight is below its own frame centre.
                    .offset(y: 2)
                    .padding(.trailing, 5)
                    .layoutPriority(1)

                Text("j.j.breeze")
                    .font(.custom("Georgia-BoldItalic", size: 18))
                    .foregroundStyle(GearTheme.textLight)
                    .shadow(color: .black.opacity(0.75), radius: 0, x: 0, y: 1.5)
                    .shadow(color: .black.opacity(0.35), radius: 3, x: 0, y: 2)
                    .lineLimit(1)
                    // Keeps its full size while there is room and only
                    // compresses on a narrow phone, so the preset window
                    // beside it never has to truncate first.
                    .minimumScaleFactor(0.6)
                    .layoutPriority(1)

                PresetBar(audioUnit: audioUnit)
                    .frame(minWidth: 96, maxWidth: 340)

                LevelMeterView(audioUnit: audioUnit)
                    .layoutPriority(1)

                BypassToggle(isBypassed: $isBypassed)
                    .frame(width: 22, height: 38)
                    .layoutPriority(1)
            }

            if showsAccessBanner, entitlement.accessState.bannerText != nil {
                AccessBanner(state: entitlement.accessState) {
                    showPaywall = true
                }
            }
        }
    }

    // The companion app puts its own trial banner in the chrome above the
    // panel, so a second copy inside the panel header just says the same
    // thing twice. A host has no such chrome, so there the panel keeps it —
    // it is the only way into the paywall from inside a DAW.
    private var showsAccessBanner: Bool {
        Bundle.main.bundlePath.hasSuffix(".appex")
    }

    private var versionFooter: some View {
        ModelPlate(text: "MODEL JJB-1  ·  STEREO MICRO-PITCH WIDENER  ·  \(appVersionString)")
            .frame(maxWidth: .infinity)
    }

    private var appVersionString: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        return "v\(v)"
    }

    // MARK: - Sections (Shift / Vibrato / Warmth)

    private let columnSpacing: CGFloat = 20

    // The knob size every section draws at: the width one knob gets in a
    // three-across row. Warmth's rows hold two knobs, so its slots are half
    // a column wide rather than a third — without this shared cap its knobs
    // would fill those wider slots and read as a bigger pair of controls
    // than the ones in Shift and Vibrato.
    private func knobDiameter(forPanelWidth width: CGFloat) -> CGFloat {
        let content = width - (earWidth + contentGutter) * 2
        let columnWidth = width >= wideThreshold
            ? (content - columnSpacing * 2) / 3
            : content
        let slot = (columnWidth - knobRowSpacing * 2) / 3
        return min(96, max(44, slot))
    }

    @ViewBuilder
    private func sectionsLayout(isWide: Bool) -> some View {
        if isWide {
            // fixedSize resolves the row to its tallest column's ideal
            // height, and maxHeight lets the shorter plates stretch to it —
            // three modules cut to the same height, as they would be in a
            // real rack.
            HStack(alignment: .top, spacing: columnSpacing) {
                plate(stretch: true) { shiftColumn }
                plate(stretch: true) { vibratoColumn }
                plate(stretch: true) { warmthColumn }
            }
            .fixedSize(horizontal: false, vertical: true)
        } else {
            VStack(spacing: 14) {
                plate { shiftColumn }
                plate { vibratoColumn }
                plate { warmthColumn }
            }
        }
    }

    // Each section rides on its own sub-plate, screwed onto the front
    // panel — so the sections read as separate modules the way they do on
    // the reference hardware, and the hairline dividers the old layout
    // needed are no longer necessary.
    private func plate<Content: View>(stretch: Bool = false,
                                      @ViewBuilder _ content: () -> Content) -> some View {
        content()
            .padding(.horizontal, 17)
            .padding(.top, 11)
            .padding(.bottom, 15)
            // The stretch has to happen inside the background, or the plate
            // would draw at its content height and merely sit centred in a
            // taller slot.
            .frame(maxWidth: .infinity, maxHeight: stretch ? .infinity : nil, alignment: .top)
            .background(PanelPlate(theme: GearTheme.current))
    }

    private func sectionHeader(_ title: String, enabled: ObservableAUParameter) -> some View {
        HStack(spacing: 7) {
            JewelLamp(isOn: enabled.boolValue, color: GearTheme.accent, theme: GearTheme.current)
                .frame(width: 9, height: 9)
            Text(title)
                .font(.system(size: 12, weight: .heavy))
                .tracking(2.0)
                .foregroundStyle(enabled.boolValue ? GearTheme.textLight : GearTheme.textMuted)
                .shadow(color: .black.opacity(0.7), radius: 0, x: 0, y: 1)
            Spacer(minLength: 4)
            LedToggle(param: enabled)
                .frame(width: 26, height: 40)
        }
    }

    // Shared by knob rows that need a link badge positioned between their
    // first two knobs — see linkBadge(isOn:title:) below.
    private let knobRowSpacing: CGFloat = 8

    private func knob(_ param: ObservableAUParameter, _ caption: String, skew: Float = 1,
                       symmetric: Bool = false, help: String? = nil,
                       peer: ObservableAUParameter? = nil, linked: Bool = false) -> some View {
        KnobView(param: param, caption: caption, skew: skew, symmetric: symmetric,
                 helpText: help, linkedPeer: peer, linkEnabled: linked)
            .frame(maxWidth: .infinity)
    }

    // Vertical distance from a knob row's top to the top edge of the knob
    // circles themselves — matches KnobView's caption (.frame(minHeight: 16))
    // plus its VStack's 6pt spacing before the knob. Keeps the link badge
    // aligned with the knobs' top edge rather than the row's own centre
    // (which sits lower, pulled down by the value chip below the knob).
    private let knobTopOffset: CGFloat = 30

    // Positions a LinkIconBadge in the gap between a row's first two knobs
    // (e.g. PITCH L/PITCH R) — an overlay rather than a real HStack sibling,
    // so it doesn't disturb the three knobs' otherwise-equal widths, and
    // (like the column dividers) can't leak flexible sizing into the row's
    // own layout the way a plain sibling view would.
    private func linkBadge(isOn: Binding<Bool>, title: String) -> some View {
        GeometryReader { g in
            let columnWidth = (g.size.width - knobRowSpacing * 2) / 3
            LinkIconBadge(isOn: isOn, title: title)
                .position(x: columnWidth + knobRowSpacing / 2, y: knobTopOffset)
        }
    }

    private var shiftColumn: some View {
        // Bound to a concretely-typed local rather than chaining
        // `parameterTree.shift.shiftOn.boolValue` inline — @dynamicMemberLookup
        // here only resolves reliably one hop at a time (see ObservableAUParameter.swift).
        let shiftOn: ObservableAUParameter = parameterTree.shift.shiftOn
        return VStack(alignment: .leading, spacing: 10) {
            sectionHeader("SHIFT", enabled: shiftOn)

            Group {
                HStack(spacing: knobRowSpacing) {
                    knob(parameterTree.shift.pitchL, "PITCH L", skew: 0.4, symmetric: true,
                         peer: parameterTree.shift.pitchR, linked: linkPitch)
                    knob(parameterTree.shift.pitchR, "PITCH R", skew: 0.4, symmetric: true,
                         peer: parameterTree.shift.pitchL, linked: linkPitch)
                    knob(parameterTree.shift.focus, "FOCUS", skew: 0.25,
                         help: "Crossover frequency. Frequencies below this stay dry; highs go through pitch and delay.")
                }
                .overlay { linkBadge(isOn: $linkPitch, title: "Pitch") }
                HStack(spacing: knobRowSpacing) {
                    knob(parameterTree.shift.delayL, "DELAY L", skew: 0.3,
                         help: "Left delay tap, 0–250 ms. Short times add width; around 110 ms is slapback.",
                         peer: parameterTree.shift.delayR, linked: linkDelay)
                    knob(parameterTree.shift.delayR, "DELAY R", skew: 0.3,
                         help: "Right delay tap, 0–250 ms. Short times add width; around 110 ms is slapback.",
                         peer: parameterTree.shift.delayL, linked: linkDelay)
                    knob(parameterTree.shift.mix, "MIX")
                }
                .overlay { linkBadge(isOn: $linkDelay, title: "Delay") }
            }
            .opacity(shiftOn.boolValue ? 1 : 0.42)
            // Blocks all touch input (drag, tap, long-press-for-help) to the
            // knobs and link toggles, not just the Button-based ones — a
            // disabled section shouldn't be editable, and .disabled() alone
            // wouldn't stop KnobView's raw .gesture()-based drag/long-press.
            .allowsHitTesting(shiftOn.boolValue)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var vibratoColumn: some View {
        let vibratoOn: ObservableAUParameter = parameterTree.vibrato.vibratoOn
        return VStack(alignment: .leading, spacing: 10) {
            sectionHeader("VIBRATO", enabled: vibratoOn)

            HStack(spacing: 8) {
                knob(parameterTree.vibrato.vibratoRate, "RATE", skew: 0.4)
                knob(parameterTree.vibrato.vibratoDepth, "DEPTH")
                knob(parameterTree.vibrato.vibratoMix, "MIX")
            }
            .opacity(vibratoOn.boolValue ? 1 : 0.42)
            .allowsHitTesting(vibratoOn.boolValue)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var warmthColumn: some View {
        let warmthOn: ObservableAUParameter = parameterTree.warmth.warmthOn
        return VStack(alignment: .leading, spacing: 10) {
            sectionHeader("WARMTH", enabled: warmthOn)

            Group {
                HStack(spacing: 8) {
                    knob(parameterTree.warmth.warmthTone, "TONE", skew: 0.3)
                    knob(parameterTree.warmth.warmthDrive, "DRIVE",
                         help: "Saturation amount in the warmth stage.")
                }
                HStack(spacing: 8) {
                    knob(parameterTree.warmth.warmthBody, "BODY",
                         help: "Low-shelf boost in the warmth stage. Adds weight without changing Tone.")
                    knob(parameterTree.warmth.warmthMix, "MIX")
                }
            }
            .opacity(warmthOn.boolValue ? 1 : 0.42)
            .allowsHitTesting(warmthOn.boolValue)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
